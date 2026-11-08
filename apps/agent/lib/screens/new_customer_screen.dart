import 'package:flutter/material.dart';
import 'package:foreshore_core/foreshore_core.dart';

import '../offline_queue.dart';

class NewCustomerScreen extends StatefulWidget {
  const NewCustomerScreen({
    super.key,
    required this.api,
    required this.queue,
  });

  final ForeshoreApi api;
  final OfflineQueue queue;

  @override
  State<NewCustomerScreen> createState() => _NewCustomerScreenState();
}

class _NewCustomerScreenState extends State<NewCustomerScreen> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();
  final daily = TextEditingController(text: '1000');
  bool saving = false;

  Future<void> _save() async {
    final amt = int.tryParse(daily.text.trim());
    if (name.text.trim().isEmpty || phone.text.trim().isEmpty || amt == null || amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name, phone, and daily amount are required')),
      );
      return;
    }
    setState(() => saving = true);
    try {
      final c = await widget.api.createCustomer(
        name: name.text.trim(),
        phone: phone.text.trim(),
        address: address.text.trim(),
        usualDailyAmount: amt,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Created ${c.cardId} — ${c.name}')),
      );
      name.clear();
      phone.clear();
      address.clear();
      daily.text = '1000';
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Onboard mid-route',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Creates a digital card instantly — ready to collect against tomorrow.',
          style: TextStyle(color: Colors.grey.shade700),
        ),
        const SizedBox(height: 20),
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Full name')),
        const SizedBox(height: 12),
        TextField(
          controller: phone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Phone'),
        ),
        const SizedBox(height: 12),
        TextField(controller: address, decoration: const InputDecoration(labelText: 'Address')),
        const SizedBox(height: 12),
        TextField(
          controller: daily,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Usual daily amount (₦)'),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: saving ? null : _save,
          child: Text(saving ? 'Saving…' : 'Create customer card'),
        ),
      ],
    );
  }
}
