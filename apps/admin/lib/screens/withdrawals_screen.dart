import 'package:flutter/material.dart';
import 'package:foreshore_core/foreshore_core.dart';

import '../widgets/admin_ui.dart';

class WithdrawalsScreen extends StatefulWidget {
  const WithdrawalsScreen({super.key, required this.api});
  final ForeshoreApi api;

  @override
  State<WithdrawalsScreen> createState() => _WithdrawalsScreenState();
}

class _WithdrawalsScreenState extends State<WithdrawalsScreen> {
  List<Customer> customers = [];
  Customer? selected;
  Map<String, dynamic>? preview;
  bool loading = true;
  bool working = false;
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
      final list = await widget.api.listCustomers();
      setState(() => customers = list);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _select(Customer c) async {
    setState(() {
      selected = c;
      preview = null;
      working = true;
    });
    try {
      final p = await widget.api.previewWithdrawal(c.id);
      setState(() => preview = p);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Future<void> _confirm() async {
    if (selected == null) return;
    setState(() => working = true);
    try {
      final w = await widget.api.createWithdrawal(customerId: selected!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Paid ${Money(w.net)} (charge ${Money(w.charge)})'),
          ),
        );
      }
      await _load();
      setState(() {
        selected = null;
        preview = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return AdminErrorState(message: error!, onRetry: _load);
    }

    final stacked = MediaQuery.sizeOf(context).width < 980;

    return LayoutBuilder(
      builder: (context, constraints) {
        final list = _CustomerList(
          customers: customers,
          selectedId: selected?.id,
          onSelect: _select,
        );
        final panel = _PreviewPanel(
          selected: selected,
          preview: preview,
          working: working,
          onConfirm: _confirm,
        );

        if (stacked) {
          return ListView(
            padding: AdminTokens.pagePadding,
            children: [
              const AdminPageHeader(
                eyebrow: 'Payouts',
                title: 'Withdrawals',
                subtitle:
                    'Charge equals one day’s usual contribution. Preview net payout before confirming.',
              ),
              SizedBox(height: 280, child: list),
              const SizedBox(height: 16),
              panel,
            ],
          );
        }

        return Padding(
          padding: AdminTokens.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AdminPageHeader(
                eyebrow: 'Payouts',
                title: 'Withdrawals',
                subtitle:
                    'Charge equals one day’s usual contribution. Preview net payout before confirming.',
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 5, child: list),
                    const SizedBox(width: 20),
                    Expanded(flex: 4, child: panel),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CustomerList extends StatelessWidget {
  const _CustomerList({
    required this.customers,
    required this.selectedId,
    required this.onSelect,
  });

  final List<Customer> customers;
  final String? selectedId;
  final ValueChanged<Customer> onSelect;

  @override
  Widget build(BuildContext context) {
    return AdminSurface(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 16, 18, 8),
            child: Text(
              'Customers',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AdminTokens.sea,
              ),
            ),
          ),
          Expanded(
            child: Material(
              color: Colors.white,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                itemCount: customers.length,
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  color: AdminTokens.line,
                ),
                itemBuilder: (context, i) {
                  final c = customers[i];
                  final sel = selectedId == c.id;
                  return ListTile(
                    selected: sel,
                    selectedTileColor: AdminTokens.seaSoft,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: CircleAvatar(
                      backgroundColor:
                          sel ? AdminTokens.sea : AdminTokens.sand,
                      foregroundColor:
                          sel ? Colors.white : AdminTokens.sea,
                      child: Text(c.name.isNotEmpty ? c.name[0] : '?'),
                    ),
                    title: Text(
                      c.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${c.cardId} · balance ${c.balanceMoney}',
                      style: const TextStyle(color: AdminTokens.inkMuted),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => onSelect(c),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({
    required this.selected,
    required this.preview,
    required this.working,
    required this.onConfirm,
  });

  final Customer? selected;
  final Map<String, dynamic>? preview;
  final bool working;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return AdminSurface(
      accentStripe: selected == null ? null : AdminTokens.coral,
      child: selected == null
          ? const AdminEmptyState(
              icon: Icons.payments_outlined,
              title: 'Select a customer',
              body:
                  'Choose someone from the list to preview gross, charge, and net payout.',
              framed: false,
            )
          : working && preview == null
              ? const SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator()),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      selected!.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: AdminTokens.sea,
                      ),
                    ),
                    Text(
                      selected!.cardId,
                      style: const TextStyle(color: AdminTokens.inkMuted),
                    ),
                    const SizedBox(height: 20),
                    _MoneyRow(
                      label: 'Gross balance',
                      value: Money((preview?['gross'] as num?)?.toInt() ?? 0)
                          .formatted,
                    ),
                    _MoneyRow(
                      label: 'Service charge (1 day)',
                      value: Money((preview?['charge'] as num?)?.toInt() ?? 0)
                          .formatted,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: AdminTokens.line),
                    ),
                    _MoneyRow(
                      label: 'Net payout',
                      value: Money((preview?['net'] as num?)?.toInt() ?? 0)
                          .formatted,
                      emphasize: true,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: working ? null : onConfirm,
                      style: FilledButton.styleFrom(
                        backgroundColor: AdminTokens.coral,
                      ),
                      child: Text(working ? 'Processing…' : 'Confirm payout'),
                    ),
                  ],
                ),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AdminTokens.inkMuted,
                fontWeight: emphasize ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: emphasize ? FontWeight.w900 : FontWeight.w700,
                fontSize: emphasize ? 22 : 16,
                color: emphasize ? AdminTokens.coral : AdminTokens.sea,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
