import 'package:flutter/material.dart';
import 'package:foreshore_core/foreshore_core.dart';

import '../offline_queue.dart';
import 'collect_screen.dart';

class RouteScreen extends StatefulWidget {
  const RouteScreen({
    super.key,
    required this.api,
    required this.queue,
    required this.user,
  });

  final ForeshoreApi api;
  final OfflineQueue queue;
  final AppUser user;

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  List<Customer> customers = [];
  bool loading = true;
  String? error;
  int serverTodayTotal = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await widget.queue.flush(widget.api);
      final route = await widget.api.getRoute();
      final contribs = await widget.api.getContributions(date: _today());
      setState(() {
        customers = route;
        serverTodayTotal =
            contribs.fold<int>(0, (s, c) => s + c.amount);
      });
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _today() {
    final n = DateTime.now();
    return '${n.year.toString().padLeft(4, '0')}-'
        '${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}';
  }

  int get runningTotal => serverTodayTotal + widget.queue.localTotalForToday();

  Future<void> _openCollect(Customer c) async {
    final collected = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CollectScreen(
          api: widget.api,
          queue: widget.queue,
          customer: c,
        ),
      ),
    );
    if (collected == true) await _load();
  }

  Future<void> _quickCollect(Customer c) async {
    await widget.queue.collect(
      api: widget.api,
      customerId: c.id,
      customerName: c.name,
      amount: c.usualDailyAmount,
    );
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logged ${Money(c.usualDailyAmount)} for ${c.name}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null && customers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Retry')),
              const SizedBox(height: 8),
              Text(
                'Pending offline: ${widget.queue.pendingCount}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    final done = customers.where((c) => c.collectedToday || widget.queue.hasLocalCollection(c.id)).length;

    return RefreshIndicator(
      onRefresh: _load,
      child: Column(
        children: [
          if (widget.queue.pendingCount > 0)
            MaterialBanner(
              content: Text('${widget.queue.pendingCount} offline collections waiting to sync'),
              actions: [
                TextButton(
                  onPressed: () async {
                    try {
                      final n = await widget.queue.flush(widget.api);
                      await _load();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Synced $n')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Sync failed: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Sync now'),
                ),
              ],
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${widget.user.name} · $done/${customers.length} visited',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: customers.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final c = customers[i];
                final collected =
                    c.collectedToday || widget.queue.hasLocalCollection(c.id);
                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _openCollect(c),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: collected
                                ? const Color(0xFF1A6B7A)
                                : const Color(0xFF0B3D4A).withValues(alpha: 0.12),
                            foregroundColor:
                                collected ? Colors.white : const Color(0xFF0B3D4A),
                            child: Text(c.name.isNotEmpty ? c.name[0] : '?'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '${c.cardId} · usual ${c.usualMoney}',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (collected)
                            const Icon(Icons.check_circle, color: Color(0xFF1A6B7A))
                          else
                            FilledButton(
                              onPressed: () => _quickCollect(c),
                              child: Text(c.usualMoney.formatted),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            decoration: const BoxDecoration(
              color: Color(0xFF0B3D4A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Text(
                  "Today's logged total",
                  style: TextStyle(color: Colors.white70),
                ),
                const Spacer(),
                Text(
                  Money(runningTotal).formatted,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
