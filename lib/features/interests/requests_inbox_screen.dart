import 'package:flutter/material.dart';
import '../../app/di/service_locator.dart';
import '../../shared/models/contact_request.dart';
import '../../core/services/profile_service.dart';
import '../../shared/models/profile.dart' as basic;
import '../../shared/state/matrimonial_provider.dart';
import 'package:provider/provider.dart';

class RequestsInboxScreen extends StatefulWidget {
  const RequestsInboxScreen({super.key});

  @override
  State<RequestsInboxScreen> createState() => _RequestsInboxScreenState();
}

class _RequestsInboxScreenState extends State<RequestsInboxScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  bool _loading = true;
  List<ContactRequest> _received = [];
  List<ContactRequest> _sent = [];
  Map<String, basic.Profile> _profiles = {};

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final me = context.read<MatrimonialProvider>().currentUserProfile;
    if (me == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final svc = sl.contactExchangeService;
      final rec = await svc.listReceived(me.id);
      final sent = await svc.listSent(me.id);
      final ids = <String>{
        ...rec.map((e) => e.requesterProfileId),
        ...rec.map((e) => e.targetProfileId),
        ...sent.map((e) => e.requesterProfileId),
        ...sent.map((e) => e.targetProfileId),
      }.toList();
      final ProfileService ps = sl.profileService;
      final map = await ps.getProfilesByProfileIds(ids);
      if (!mounted) return;
      setState(() {
        _received = rec;
        _sent = sent;
        _profiles = map;
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
      appBar: AppBar(
        title: const Text('Contact Requests'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Received'),
            Tab(text: 'Sent'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: TabBarView(
                controller: _tab,
                children: [
                  _buildList(_received, received: true),
                  _buildList(_sent, received: false),
                ],
              ),
            ),
    );
  }

  Widget _buildList(List<ContactRequest> list, {required bool received}) {
    if (list.isEmpty) {
      return const Center(child: Text('No requests'));
    }
    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final r = list[i];
        final otherId = received ? r.requesterProfileId : r.targetProfileId;
        final other = _profiles[otherId];
        final title = other?.name ?? otherId;
        final subtitle = 'Status: ${r.status.name}';
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: received && r.status == ContactRequestStatus.pending
              ? Wrap(
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: () async {
                        await sl.contactExchangeService.accept(
                          context
                              .read<MatrimonialProvider>()
                              .currentUserProfile!
                              .id,
                          r.requesterProfileId,
                        );
                        if (!mounted) return;
                        _load();
                      },
                      child: const Text('Accept'),
                    ),
                    TextButton(
                      onPressed: () async {
                        await sl.contactExchangeService.decline(
                          context
                              .read<MatrimonialProvider>()
                              .currentUserProfile!
                              .id,
                          r.requesterProfileId,
                        );
                        if (!mounted) return;
                        _load();
                      },
                      child: const Text('Decline'),
                    ),
                  ],
                )
              : null,
        );
      },
    );
  }
}
