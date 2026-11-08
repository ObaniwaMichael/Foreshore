import 'package:flutter/material.dart';
import 'package:foreshore_core/foreshore_core.dart';
import 'package:intl/intl.dart';

import '../widgets/admin_ui.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, required this.api});
  final ForeshoreApi api;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DashboardStats? stats;
  List<Customer> customers = [];
  Map<String, dynamic>? statement;
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
      final s = await widget.api.getStats();
      final c = await widget.api.listCustomers();
      setState(() {
        stats = s;
        customers = c;
      });
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _openStatement(Customer c) async {
    try {
      final st = await widget.api.customerStatement(c.id);
      setState(() => statement = st);
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
    final s = stats!;
    final wide = MediaQuery.sizeOf(context).width >= 980;

    return RefreshIndicator(
      onRefresh: _load,
      color: AdminTokens.sea,
      child: ListView(
        padding: AdminTokens.pagePadding,
        children: [
          const AdminPageHeader(
            eyebrow: 'Visibility',
            title: 'Reports',
            subtitle:
                'Cash position across savings held, loans outstanding, and today’s collections.',
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth >= 900
                  ? 4
                  : constraints.maxWidth >= 560
                      ? 2
                      : 1;
              final width = (constraints.maxWidth - (12.0 * (cols - 1))) / cols;
              final cards = [
                AdminStatCard(
                  label: "Today's collections",
                  value: Money(s.todayCollections).formatted,
                  icon: Icons.today_outlined,
                ),
                AdminStatCard(
                  label: 'Total savings held',
                  value: Money(s.totalSavings).formatted,
                  icon: Icons.savings_outlined,
                ),
                AdminStatCard(
                  label: 'Loans outstanding',
                  value: Money(s.totalLoansOutstanding).formatted,
                  icon: Icons.account_balance_wallet_outlined,
                ),
                AdminStatCard(
                  label: 'Interest on book',
                  value: Money(s.totalInterestEarned).formatted,
                  icon: Icons.trending_up_rounded,
                ),
              ];
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final card in cards)
                    SizedBox(width: width, child: card),
                ],
              );
            },
          ),
          const SizedBox(height: 28),
          Text(
            'Customer statements',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AdminTokens.sea,
                ),
          ),
          const SizedBox(height: 12),
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _customerList()),
                const SizedBox(width: 16),
                Expanded(child: _statementPanel()),
              ],
            )
          else ...[
            _customerList(),
            const SizedBox(height: 16),
            _statementPanel(),
          ],
        ],
      ),
    );
  }

  Widget _customerList() {
    return AdminSurface(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 16, 18, 4),
            child: Text(
              'Savers',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Material(
            color: Colors.white,
            child: Column(
              children: [
                for (final c in customers)
                  Builder(
                    builder: (context) {
                      final selected = statement != null &&
                          (statement!['customer'] as Map)['id'] == c.id;
                      return ListTile(
                        selected: selected,
                        selectedTileColor: AdminTokens.seaSoft,
                        leading: CircleAvatar(
                          backgroundColor:
                              selected ? AdminTokens.sea : AdminTokens.sand,
                          foregroundColor:
                              selected ? Colors.white : AdminTokens.sea,
                          child: Text(c.name.isNotEmpty ? c.name[0] : '?'),
                        ),
                        title: Text(
                          c.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${c.cardId} · ${c.balanceMoney}',
                          style: const TextStyle(color: AdminTokens.inkMuted),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _openStatement(c),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statementPanel() {
    if (statement == null) {
      return const AdminEmptyState(
        icon: Icons.description_outlined,
        title: 'No statement open',
        body: 'Select a customer to review contributions, withdrawals, and loans.',
      );
    }

    final customer = statement!['customer'] as Map;
    final contribs = statement!['contributions'] as List;
    final withdrawals = statement!['withdrawals'] as List;
    final loans = statement!['loans'] as List;
    final df = DateFormat('d MMM y');

    return AdminSurface(
      accentStripe: AdminTokens.sea,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${customer['name']}',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: AdminTokens.sea,
            ),
          ),
          Text(
            '${customer['card_id']} · balance ${Money((customer['savings_balance'] as num).toInt()).formatted}',
            style: const TextStyle(color: AdminTokens.inkMuted),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              AdminStatusPill(
                label: '${contribs.length} contributions',
                background: AdminTokens.seaSoft,
                foreground: AdminTokens.sea,
              ),
              AdminStatusPill(
                label: '${withdrawals.length} withdrawals',
                background: AdminTokens.sand,
                foreground: AdminTokens.sea,
              ),
              AdminStatusPill(
                label: '${loans.length} loans',
                background: AdminTokens.coralSoft,
                foreground: const Color(0xFF8B2E0E),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Recent contributions',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (contribs.isEmpty)
            const Text(
              'None yet',
              style: TextStyle(color: AdminTokens.inkMuted),
            )
          else
            ...contribs.take(12).map((raw) {
              final m = raw as Map<String, dynamic>;
              final at = DateTime.tryParse(m['collected_at'] as String);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        at == null ? '${m['collected_at']}' : df.format(at.toLocal()),
                        style: const TextStyle(color: AdminTokens.inkMuted),
                      ),
                    ),
                    Text(
                      Money((m['amount'] as num).toInt()).formatted,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
