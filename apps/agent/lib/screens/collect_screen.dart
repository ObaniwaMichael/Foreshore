import 'package:flutter/material.dart';
import 'package:foreshore_core/foreshore_core.dart';
import 'package:intl/intl.dart';

import '../offline_queue.dart';

class CollectScreen extends StatefulWidget {
  const CollectScreen({
    super.key,
    required this.api,
    required this.queue,
    required this.customer,
  });

  final ForeshoreApi api;
  final OfflineQueue queue;
  final Customer customer;

  @override
  State<CollectScreen> createState() => _CollectScreenState();
}

class _CollectScreenState extends State<CollectScreen> {
  late final TextEditingController amount;
  List<Contribution> history = [];
  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    amount = TextEditingController(
      text: widget.customer.usualDailyAmount.toString(),
    );
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final list = await widget.api.getContributions(customerId: widget.customer.id);
      setState(() => history = list.take(8).toList());
    } catch (_) {
      // Offline — history may be empty
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _save() async {
    final value = int.tryParse(amount.text.replaceAll(',', '').trim());
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }
    setState(() => saving = true);
    try {
      await widget.queue.collect(
        api: widget.api,
        customerId: widget.customer.id,
        customerName: widget.customer.name,
        amount: value,
      );
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.customer;
    final df = DateFormat('d MMM');

    return Scaffold(
      appBar: AppBar(title: Text(c.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(c.cardId, style: Theme.of(context).textTheme.labelLarge),
          Text(
            'Balance ${c.balanceMoney}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: amount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Amount (₦)',
              helperText: 'Pre-filled to usual daily saving — edit for top-up or less',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: saving ? null : _save,
            child: Text(saving ? 'Saving…' : 'Log collection'),
          ),
          const SizedBox(height: 28),
          Text(
            'Recent contributions',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          if (loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (history.isEmpty)
            Text(
              'No history yet — or offline.',
              style: TextStyle(color: Colors.grey.shade700),
            )
          else
            ...history.map(
              (h) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(Money(h.amount).formatted),
                subtitle: Text(df.format(h.collectedAt.toLocal())),
                trailing: const Icon(Icons.check, size: 18),
              ),
            ),
        ],
      ),
    );
  }
}
