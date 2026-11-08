import 'package:flutter/material.dart';
import 'package:foreshore_core/foreshore_core.dart';

import '../offline_queue.dart';

class DaySummaryScreen extends StatefulWidget {
  const DaySummaryScreen({
    super.key,
    required this.api,
    required this.queue,
    required this.user,
  });

  final ForeshoreApi api;
  final OfflineQueue queue;
  final AppUser user;

  @override
  State<DaySummaryScreen> createState() => _DaySummaryScreenState();
}

class _DaySummaryScreenState extends State<DaySummaryScreen> {
  CollectionDay? day;
  List<Contribution> contribs = [];
  final declared = TextEditingController();
  bool loading = true;
  String? error;

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
      final d = await widget.api.getOrCreateToday();
      final list = await widget.api.getContributions(date: d.businessDate);
      setState(() {
        day = d;
        contribs = list;
        declared.text = (d.declaredCash ?? d.systemTotal).toString();
      });
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _declare() async {
    final value = int.tryParse(declared.text.trim());
    if (value == null || day == null) return;
    try {
      final updated = await widget.api.setDeclaredCash(day!.id, value);
      setState(() => day = updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updated.hasMismatch
                  ? 'Mismatch flagged — resolve before admin sign-off'
                  : 'Cash declared matches logged total',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error!),
            FilledButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    final d = day!;
    final mismatch = d.hasMismatch;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Before you walk into the office',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          _StatTile(label: 'System logged total', value: Money(d.systemTotal).formatted),
          _StatTile(
            label: 'Pending offline',
            value: Money(widget.queue.localTotalForToday()).formatted,
          ),
          _StatTile(label: 'Collections today', value: '${contribs.length}'),
          const SizedBox(height: 16),
          TextField(
            controller: declared,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Cash on hand (₦)',
              helperText: 'The figure admin reconciles against',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _declare, child: const Text('Declare cash')),
          if (mismatch) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE8E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC45C26)),
              ),
              child: Text(
                'Mismatch: declared ${Money(d.declaredCash ?? 0)} vs logged ${Money(d.systemTotal)}',
                style: const TextStyle(
                  color: Color(0xFF8B2E0E),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'Today\'s collections',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          ...contribs.map(
            (c) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(c.customerName ?? c.customerId),
              trailing: Text(
                Money(c.amount).formatted,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(label),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
