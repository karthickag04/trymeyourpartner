import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../shared/state/matrimonial_provider.dart';
import '../../app/di/service_locator.dart';
import '../../core/services/message_service.dart';
import '../../core/services/realtime_service.dart';
import '../../core/services/presence_service.dart';
import '../../core/services/typing_service.dart';
import '../../shared/models/presence_status.dart';
import 'typing_provider.dart';
import '../../shared/models/icebreaker.dart';
import '../../shared/widgets/storage_image.dart';

class ChatThreadScreen extends StatefulWidget {
  final String otherProfileId;
  final String? otherName;
  final String? otherImageUrl;
  const ChatThreadScreen({
    super.key,
    required this.otherProfileId,
    this.otherName,
    this.otherImageUrl,
  });

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  List<_ThreadMessage> _thread = [];
  bool _loading = true;
  String? _myId;
  Object? _channel;
  final Set<String> _seenIds = <String>{};
  Object? _receiptChannel;
  late final MessageService _msgService;
  late final RealtimeService _realtime;
  late final PresenceService _presence;
  late final TypingService _typing;
  List<Icebreaker> _prompts = const [];
  bool _loadingPrompts = false;
  PresenceStatus? _presenceStatus;
  Timer? _presencePoll;
  Timer? _heartbeatTimer;
  Timer? _typingPoll;
  DateTime? _lastTypingSentAt;
  bool _otherTyping = false;
  bool? _meActive;
  bool? _otherActive;

  @override
  void initState() {
    super.initState();
    _msgService = sl.messageService;
    _realtime = sl.realtimeService;
    _presence = sl.presenceService;
    _typing = sl.typingService;
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    try {
      _realtime.unsubscribe(_channel);
      _realtime.unsubscribe(_receiptChannel);
    } catch (_) {}
    _channel = null;
    _receiptChannel = null;
    _presencePoll?.cancel();
    _heartbeatTimer?.cancel();
    _typingPoll?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final me = context.read<MatrimonialProvider>().currentUserProfile;
    _myId = me?.id;
    if (_myId == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      // Check activity states early
      _meActive = await sl.matrimonialService.isProfileActive(_myId!);
      _otherActive = await sl.matrimonialService.isProfileActive(
        widget.otherProfileId,
      );
      // Subscribe first to avoid missing inserts during initial fetch
      _subscribeRealtime();

      // Initial load
      final rows = await _msgService.getThread(_myId!, widget.otherProfileId);
      final msgs = rows.map((row) {
        final id = row['id']?.toString() ?? '';
        final from = row['from_profile_id']?.toString() ?? '';
        final to = row['to_profile_id']?.toString() ?? '';
        final text = (row['message'] ?? '').toString();
        final at =
            DateTime.tryParse(row['created_at']?.toString() ?? '') ??
            DateTime.now();
        return _ThreadMessage(
          id: id,
          fromId: from,
          toId: to,
          text: text,
          at: at,
          deliveredAt: null,
          readAt: null,
        );
      }).toList();
      if (!mounted) return;
      setState(() {
        _thread = [...msgs]..sort((a, b) => a.at.compareTo(b.at));
        _seenIds.clear();
        for (final m in msgs) {
          _seenIds.add(m.id);
        }
        _loading = false;
      });
      // Immediately mark received messages as read
      final toRead = msgs
          .where((m) => m.toId == _myId && m.id.isNotEmpty)
          .map((m) => m.id)
          .toList();
      if (toRead.isNotEmpty) {
        _msgService.markMessagesRead(toRead);
      }
      _scrollToBottom();
      _maybeLoadIcebreakers();
      _startPresenceLoops();
      _startTypingLoop();
      // Mark received messages as delivered/read can be handled server-side or via RPC.
      // Optional: delivery receipts if supported; noop for HTTP
      // sl.messageService doesn't expose receipts yet; handled server-side or via RPC.
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load chat: $e')));
    }
  }

  Future<void> _maybeLoadIcebreakers() async {
    if (_loadingPrompts) return;
    setState(() => _loadingPrompts = true);
    try {
      final list = await sl.icebreakerService.list();
      if (!mounted) return;
      setState(() => _prompts = list);
    } catch (_) {
      // ignore silently; button will fallback to default suggestions
    } finally {
      if (mounted) setState(() => _loadingPrompts = false);
    }
  }

  void _startPresenceLoops() {
    if (_myId == null) return;
    // Initial heartbeat and presence fetch
    _presence.heartbeat(myProfileId: _myId!);
    _refreshPresence();
    // Heartbeat every 60s
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      final id = _myId;
      if (id != null) {
        _presence.heartbeat(myProfileId: id);
      }
    });
    // Poll presence every 60s
    _presencePoll?.cancel();
    _presencePoll = Timer.periodic(const Duration(seconds: 60), (_) {
      _refreshPresence();
    });
  }

  Future<void> _refreshPresence() async {
    try {
      final status = await _presence.getPresence(widget.otherProfileId);
      if (!mounted) return;
      setState(() => _presenceStatus = status);
    } catch (_) {}
  }

  void _startTypingLoop() {
    // Keep existing local polling for backward-compat; additionally expose provider for composer.
    _typingPoll?.cancel();
    _typingPoll = Timer.periodic(const Duration(seconds: 3), (_) async {
      final me = _myId;
      if (me == null) return;
      try {
        final t = await _typing.isTyping(
          myProfileId: me,
          otherProfileId: widget.otherProfileId,
        );
        if (!mounted) return;
        if (t != _otherTyping) {
          setState(() => _otherTyping = t);
        }
      } catch (_) {}
    });
  }

  void _subscribeRealtime() {
    if (_myId == null) return;
    _channel = _realtime.subscribeThreadMessages(
      _myId!,
      widget.otherProfileId,
      onInsert: (row) async => _onInsert(row),
      onReceiptUpdate: (row) async => _onReceiptUpdate(row),
    );
  }

  void _onInsert(Map<String, dynamic> row) {
    if (!mounted) return;
    try {
      if ((row['interaction_type'] as String?) != 'message') return;
      final from = row['from_profile_id'] as String?;
      final to = row['to_profile_id'] as String?;
      if (from == null || to == null) return;
      final a = _myId!;
      final b = widget.otherProfileId;
      final isThisThread = (from == a && to == b) || (from == b && to == a);
      if (!isThisThread) return;
      final id = row['id']?.toString() ?? '';
      if (id.isNotEmpty && _seenIds.contains(id)) return;
      final at =
          DateTime.tryParse(row['created_at']?.toString() ?? '') ??
          DateTime.now();
      final msg = _ThreadMessage(
        id: id.isEmpty ? '${from}_${to}_${at.microsecondsSinceEpoch}' : id,
        fromId: from,
        toId: to,
        text: row['message']?.toString() ?? '',
        at: at,
        deliveredAt: null,
        readAt: null,
      );
      setState(() {
        _thread.add(msg);
        _thread.sort((a, b) => a.at.compareTo(b.at));
        if (msg.id.isNotEmpty) _seenIds.add(msg.id);
      });
      _scrollToBottom();
    } catch (_) {}
  }

  void _onReceiptUpdate(Map<String, dynamic> row) {
    if (!mounted) return;
    try {
      final mid = row['message_id']?.toString();
      if (mid == null || mid.isEmpty) return;
      final delivered = row['delivered_at']?.toString();
      final read = row['read_at']?.toString();
      setState(() {
        final idx = _thread.indexWhere((m) => m.id == mid);
        if (idx >= 0) {
          final old = _thread[idx];
          _thread[idx] = _ThreadMessage(
            id: old.id,
            fromId: old.fromId,
            toId: old.toId,
            text: old.text,
            at: old.at,
            deliveredAt: delivered != null && delivered.isNotEmpty
                ? DateTime.tryParse(delivered)
                : old.deliveredAt,
            readAt: read != null && read.isNotEmpty
                ? DateTime.tryParse(read)
                : old.readAt,
          );
        }
      });
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
      // Heuristic: when scrolled to bottom, mark received messages as read
      final unreadIds = _thread
          .where((m) => m.toId == _myId && m.id.isNotEmpty)
          .map((m) => m.id)
          .toList();
      if (unreadIds.isNotEmpty) {
        _msgService.markMessagesRead(unreadIds);
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _myId == null) return;
    try {
      await _msgService.sendMessage(_myId!, widget.otherProfileId, text);
      final saved = _ThreadMessage(
        id: '',
        fromId: _myId!,
        toId: widget.otherProfileId,
        text: text,
        at: DateTime.now(),
        deliveredAt: null,
        readAt: null,
      );
      setState(() {
        // Use the row returned by DB to get canonical id/created_at
        _thread.add(saved);
        _thread.sort((a, b) => a.at.compareTo(b.at));
        if (saved.id.isNotEmpty) _seenIds.add(saved.id);
        _controller.clear();
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
    }
  }

  void _onTypingChanged() {
    final now = DateTime.now();
    // Throttle to once every ~3 seconds
    if (_lastTypingSentAt == null ||
        now.difference(_lastTypingSentAt!) > const Duration(seconds: 3)) {
      _lastTypingSentAt = now;
      final me = _myId;
      if (me != null) {
        _typing.sendTyping(
          myProfileId: me,
          otherProfileId: widget.otherProfileId,
        );
      }
    }
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final local = dt.toLocal();
    final isSameDay =
        now.year == local.year &&
        now.month == local.month &&
        now.day == local.day;
    String two(int n) => n.toString().padLeft(2, '0');
    String ap(int h) => h >= 12 ? 'PM' : 'AM';
    int h12(int h) {
      final x = h % 12;
      return x == 0 ? 12 : x;
    }

    final time = '${h12(local.hour)}:${two(local.minute)} ${ap(local.hour)}';
    if (isSameDay) return time;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = local.day;
    final mon = months[local.month - 1];
    return '$mon $day, $time';
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.otherName ?? widget.otherProfileId;
    return ChangeNotifierProvider(
      create: (_) {
        final me = context.read<MatrimonialProvider>().currentUserProfile?.id;
        final prov = TypingProvider(_typing, me ?? '', widget.otherProfileId);
        if (me != null) prov.start();
        return prov;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                child:
                    (widget.otherImageUrl != null &&
                        widget.otherImageUrl!.isNotEmpty)
                    ? ClipOval(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: StorageImage(
                            src: widget.otherImageUrl!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    : Text(title.characters.first.toUpperCase()),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    _buildPresenceOrTyping(),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            if ((_meActive == false) || (_otherActive == false))
              Container(
                width: double.infinity,
                color: Colors.amber.withValues(alpha: 0.15),
                padding: const EdgeInsets.all(8),
                child: Text(
                  _meActive == false
                      ? 'Your profile is deactivated. Reactivate to send messages.'
                      : 'This profile is not active currently. You can read previous messages but cannot send new ones.',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            Consumer<TypingProvider>(
              builder: (_, tp, __) {
                final show = _otherTyping || tp.isOtherTyping;
                if (!show) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Typing…',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                );
              },
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      itemCount: _thread.length,
                      itemBuilder: (context, index) {
                        final m = _thread[index];
                        final isMe = m.fromId == _myId;
                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? Colors.blue.shade50
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Flexible(child: Text(m.text, softWrap: true)),
                                const SizedBox(width: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _formatTimestamp(m.at),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    if (isMe)
                                      _TickIcon(
                                        deliveredAt: m.deliveredAt,
                                        readAt: m.readAt,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Suggest prompt',
                      onPressed: (_meActive == false) || (_otherActive == false)
                          ? null
                          : _showIcebreakers,
                      icon: const Icon(Icons.lightbulb_outline),
                    ),
                    Expanded(
                      child: Consumer<TypingProvider>(
                        builder: (_, tp, __) => TextField(
                          controller: _controller,
                          minLines: 1,
                          maxLines: 4,
                          onChanged:
                              (_meActive == false) || (_otherActive == false)
                              ? null
                              : (_) {
                                  tp.onUserTyping();
                                  _onTypingChanged();
                                },
                          decoration: const InputDecoration(
                            hintText: 'Type a message',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          enabled:
                              !((_meActive == false) ||
                                  (_otherActive == false)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: (_meActive == false) || (_otherActive == false)
                          ? null
                          : _send,
                      icon: const Icon(Icons.send),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresenceOrTyping() {
    if (_otherTyping) {
      return Text(
        'Typing…',
        style: TextStyle(fontSize: 11, color: Colors.green.shade700),
      );
    }
    final p = _presenceStatus;
    if (p == null) {
      return const SizedBox.shrink();
    }
    if (p.isOnline) {
      return const Text(
        'Online',
        style: TextStyle(fontSize: 11, color: Colors.white70),
      );
    }
    final last = p.lastActiveAt;
    final label = last != null ? _formatLastSeen(last) : 'Offline';
    return Text(
      label,
      style: const TextStyle(fontSize: 11, color: Colors.white70),
    );
  }

  String _formatLastSeen(DateTime last) {
    final now = DateTime.now();
    final diff = now.difference(last);
    if (diff.inMinutes < 1) return 'Last seen just now';
    if (diff.inMinutes < 60) return 'Last seen ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Last seen ${diff.inHours}h ago';
    final days = diff.inDays;
    return 'Last seen ${days}d ago';
  }

  void _showIcebreakers() async {
    if (_prompts.isEmpty && !_loadingPrompts) {
      await _maybeLoadIcebreakers();
    }
    final prompts = _prompts.isNotEmpty
        ? _prompts.map((e) => e.text).toList()
        : <String>[
            'What\'s something you\'re passionate about outside of work?',
            'Weekend plans: chill at home or explore outside?',
            'What\'s a small joy that made your day recently?',
          ];
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.all(12),
          itemBuilder: (context, index) {
            final t = prompts[index];
            return ListTile(
              title: Text(t),
              onTap: () {
                Navigator.pop(context);
                _controller.text = t;
                _controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: _controller.text.length),
                );
              },
            );
          },
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemCount: prompts.length,
        ),
      ),
    );
  }
}

class _TickIcon extends StatelessWidget {
  final DateTime? deliveredAt;
  final DateTime? readAt;
  const _TickIcon({required this.deliveredAt, required this.readAt});

  @override
  Widget build(BuildContext context) {
    // Sent: one grey check; Delivered: two grey checks; Read: two blue checks
    final isRead = readAt != null;
    final isDelivered = deliveredAt != null;
    if (isRead) {
      return Icon(Icons.done_all, size: 16, color: Colors.blue.shade400);
    }
    if (isDelivered) {
      return const Icon(Icons.done_all, size: 16, color: Colors.grey);
    }
    return const Icon(Icons.done, size: 16, color: Colors.grey);
  }
}

class _ThreadMessage {
  final String id;
  final String fromId;
  final String toId;
  final String text;
  final DateTime at;
  final DateTime? deliveredAt;
  final DateTime? readAt;

  _ThreadMessage({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.text,
    required this.at,
    required this.deliveredAt,
    required this.readAt,
  });
}
