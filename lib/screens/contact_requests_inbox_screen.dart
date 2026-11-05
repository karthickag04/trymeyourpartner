import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../di/service_locator.dart';
import '../models/contact_request.dart';
import '../providers/matrimonial_provider.dart';

class ContactRequestsInboxScreen extends StatefulWidget {
  const ContactRequestsInboxScreen({super.key});

  @override
  State<ContactRequestsInboxScreen> createState() =>
      _ContactRequestsInboxScreenState();
}

class _ContactRequestsInboxScreenState
    extends State<ContactRequestsInboxScreen> {
  bool _loading = true;
  List<ContactRequest> _received = const [];
  List<ContactRequest> _sent = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final me = context.read<MatrimonialProvider>().currentUserProfile;
      if (me == null) {
        setState(() {
          _received = const [];
          _sent = const [];
          _loading = false;
        });
        return;
      }
      final r = await sl.contactExchangeService.listReceived(me.id);
      final s = await sl.contactExchangeService.listSent(me.id);
      if (!mounted) return;
      setState(() {
        _received = r;
        _sent = s;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Requests')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                children: [
                  const _SectionHeader('Received (approve/decline)'),
                  ..._received.map(
                    (r) => _RequestTile(
                      r,
                      onAccept: () async {
                        await sl.contactExchangeService.accept(
                          r.targetProfileId,
                          r.requesterProfileId,
                        );
                        if (mounted) _load();
                      },
                      onDecline: () async {
                        await sl.contactExchangeService.decline(
                          r.targetProfileId,
                          r.requesterProfileId,
                        );
                        if (mounted) _load();
                      },
                    ),
                  ),
                  if (_received.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No received requests.'),
                    ),
                  const Divider(height: 1),
                  const _SectionHeader('Sent (pending)'),
                  ..._sent.map(
                    (s) => ListTile(
                      title: Text('To: ${s.targetProfileId}'),
                      subtitle: Text('Status: ${s.status.value}'),
                    ),
                  ),
                  if (_sent.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No sent requests.'),
                    ),
                ],
              ),
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Text(title, style: Theme.of(context).textTheme.titleMedium),
  );
}

class _RequestTile extends StatelessWidget {
  final ContactRequest r;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  const _RequestTile(this.r, {required this.onAccept, required this.onDecline});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.contact_phone),
      title: Text('From: ${r.requesterProfileId}'),
      subtitle: Text('Requested at: ${r.createdAt.toLocal()}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(onPressed: onDecline, child: const Text('Decline')),
          const SizedBox(width: 8),
          ElevatedButton(onPressed: onAccept, child: const Text('Accept')),
        ],
      ),
    );
  }
}
