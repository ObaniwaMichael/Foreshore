import 'package:flutter/material.dart';
import 'package:foreshore_core/foreshore_core.dart';

import '../widgets/admin_ui.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key, required this.api});
  final ForeshoreApi api;

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  List<Loan> loans = [];
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
      final list = await widget.api.listLoans();
      setState(() => loans = list);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _decide(Loan loan, bool approve) async {
    try {
      await widget.api.decideLoan(loan.id, approve: approve);
      await _load();
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
      return AdminErrorState(message: error!, onRetry: _load);
    }

    final pending = loans.where((l) => l.status == LoanStatus.pending).toList();
    final others = loans.where((l) => l.status != LoanStatus.pending).toList();

    return RefreshIndicator(
      onRefresh: _load,
      color: AdminTokens.sea,
      child: ListView(
        padding: AdminTokens.pagePadding,
        children: [
          const AdminPageHeader(
            eyebrow: 'Credit',
            title: 'Loan book',
            subtitle:
                'Tenure and daily average at a glance. Repayable is principal plus a flat 20% charge.',
          ),
          Text(
            'Pending approval',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AdminTokens.sea,
                ),
          ),
          const SizedBox(height: 10),
          if (pending.isEmpty)
            const AdminEmptyState(
              icon: Icons.verified_outlined,
              title: 'Queue clear',
              body: 'No loan requests waiting for a decision.',
            )
          else
            ...pending.map(
              (l) => _LoanCard(
                loan: l,
                actions: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton(
                      onPressed: () => _decide(l, true),
                      child: const Text('Approve'),
                    ),
                    OutlinedButton(
                      onPressed: () => _decide(l, false),
                      child: const Text('Decline'),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 28),
          Text(
            'Active & history',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AdminTokens.sea,
                ),
          ),
          const SizedBox(height: 10),
          if (others.isEmpty)
            const AdminEmptyState(
              icon: Icons.account_balance_outlined,
              title: 'No loans on book',
              body: 'Approved and repaid loans will show up here.',
            )
          else
            ...others.map((l) => _LoanCard(loan: l)),
        ],
      ),
    );
  }
}

class _LoanCard extends StatelessWidget {
  const _LoanCard({required this.loan, this.actions});
  final Loan loan;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final overdue = loan.status == LoanStatus.overdue;
    final pending = loan.status == LoanStatus.pending;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AdminSurface(
        accentStripe: overdue
            ? AdminTokens.coral
            : pending
                ? AdminTokens.sea
                : null,
        borderColor: overdue ? AdminTokens.coral.withValues(alpha: 0.35) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    loan.customerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: AdminTokens.sea,
                    ),
                  ),
                ),
                AdminStatusPill(
                  label: loan.status.name.toUpperCase(),
                  background: overdue
                      ? AdminTokens.coralSoft
                      : pending
                          ? AdminTokens.seaSoft
                          : AdminTokens.sand,
                  foreground: overdue
                      ? const Color(0xFF8B2E0E)
                      : AdminTokens.sea,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 24,
              runSpacing: 14,
              children: [
                AdminMetricTile(
                  label: 'Principal',
                  value: Money(loan.principal).formatted,
                ),
                AdminMetricTile(
                  label: 'Interest (20%)',
                  value: Money(loan.interestAmount).formatted,
                ),
                AdminMetricTile(
                  label: 'Total repayable',
                  value: Money(loan.totalRepayable).formatted,
                  emphasize: pending,
                ),
                AdminMetricTile(
                  label: 'Outstanding',
                  value: Money(loan.outstanding).formatted,
                ),
                AdminMetricTile(
                  label: 'Tenure',
                  value: '${loan.tenureDays} days',
                ),
                AdminMetricTile(
                  label: 'Daily average',
                  value: Money(loan.dailyAverage).formatted,
                ),
                AdminMetricTile(label: 'Due', value: loan.dueDate),
              ],
            ),
            if (actions != null) ...[
              const SizedBox(height: 16),
              const Divider(color: AdminTokens.line, height: 1),
              const SizedBox(height: 14),
              actions!,
            ],
          ],
        ),
      ),
    );
  }
}
