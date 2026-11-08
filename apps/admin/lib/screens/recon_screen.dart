import 'package:flutter/material.dart';
import 'package:foreshore_core/foreshore_core.dart';
import 'package:intl/intl.dart';

import '../widgets/admin_ui.dart';

class ReconScreen extends StatefulWidget {
  const ReconScreen({super.key, required this.api});
  final ForeshoreApi api;

  @override
  State<ReconScreen> createState() => _ReconScreenState();
}

class _ReconScreenState extends State<ReconScreen> {
  List<CollectionDay> days = [];
  bool loading = true;
  String? error;
  final Map<String, TextEditingController> declaredCtrls = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in declaredCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final list = await widget.api.listCollectionDays();
      for (final d in list) {
        declaredCtrls.putIfAbsent(
          d.id,
          () => TextEditingController(
            text: (d.declaredCash ?? d.systemTotal).toString(),
          ),
        );
        declaredCtrls[d.id]!.text =
            (d.declaredCash ?? d.systemTotal).toString();
      }
      setState(() => days = list);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _saveDeclared(CollectionDay day) async {
    final value = int.tryParse(declaredCtrls[day.id]?.text.trim() ?? '');
    if (value == null) return;
    try {
      await widget.api.setDeclaredCash(day.id, value);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _signOff(CollectionDay day) async {
    try {
      await widget.api.signOffDay(day.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${day.agentName} day locked')),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: AdminTokens.coral,
          ),
        );
      }
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return AdminErrorState(message: error!, onRetry: _load);
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AdminTokens.sea,
      child: ListView(
        padding: AdminTokens.pagePadding,
        children: [
          const AdminPageHeader(
            eyebrow: 'End of day',
            title: 'Reconciliation',
            subtitle:
                'Compare each agent’s cash on hand to system totals. A mismatch blocks sign-off and keeps the day open.',
          ),
          if (days.isEmpty)
            const AdminEmptyState(
              icon: Icons.inbox_outlined,
              title: 'No collection days yet',
              body: 'Once agents sync collections, their routes appear here.',
            )
          else
            ...days.map(_dayCard),
        ],
      ),
    );
  }

  Widget _dayCard(CollectionDay d) {
    final mismatch =
        d.hasMismatch || d.status == CollectionDayStatus.mismatched;
    final closed = d.status == CollectionDayStatus.closed;
    final stripe = mismatch
        ? AdminTokens.coral
        : closed
            ? const Color(0xFF1A6B7A)
            : AdminTokens.sea;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AdminSurface(
        accentStripe: stripe,
        borderColor: mismatch ? AdminTokens.coral.withValues(alpha: 0.35) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    d.agentName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: AdminTokens.sea,
                    ),
                  ),
                ),
                _statusPill(d.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Business date ${d.businessDate}',
              style: const TextStyle(
                color: AdminTokens.inkMuted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 28,
              runSpacing: 12,
              children: [
                AdminMetricTile(
                  label: 'System total',
                  value: Money(d.systemTotal).formatted,
                ),
                AdminMetricTile(
                  label: 'Declared cash',
                  value: d.declaredCash == null
                      ? '—'
                      : Money(d.declaredCash!).formatted,
                  emphasize: mismatch,
                  hint: mismatch ? 'Does not match system' : null,
                ),
              ],
            ),
            if (!closed) ...[
              const SizedBox(height: 18),
              const Divider(color: AdminTokens.line, height: 1),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final field = TextField(
                    controller: declaredCtrls[d.id],
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Declared cash (₦)',
                      isDense: true,
                    ),
                  );
                  final actions = [
                    OutlinedButton(
                      onPressed: () => _saveDeclared(d),
                      child: const Text('Update'),
                    ),
                    FilledButton(
                      onPressed: () => _signOff(d),
                      child: const Text('Sign off & lock'),
                    ),
                  ];

                  if (constraints.maxWidth < 520) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        field,
                        const SizedBox(height: 12),
                        Wrap(spacing: 8, runSpacing: 8, children: actions),
                      ],
                    );
                  }

                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(width: 200, child: field),
                      ...actions,
                    ],
                  );
                },
              ),
            ] else if (d.signedOffAt != null) ...[
              const SizedBox(height: 14),
              Text(
                'Signed off ${DateFormat('d MMM y, HH:mm').format(d.signedOffAt!.toLocal())}',
                style: const TextStyle(
                  color: AdminTokens.inkMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  AdminStatusPill _statusPill(CollectionDayStatus status) {
    switch (status) {
      case CollectionDayStatus.closed:
        return const AdminStatusPill(
          label: 'Closed',
          background: AdminTokens.seaSoft,
          foreground: AdminTokens.sea,
        );
      case CollectionDayStatus.mismatched:
        return const AdminStatusPill(
          label: 'Mismatch',
          background: AdminTokens.coralSoft,
          foreground: Color(0xFF8B2E0E),
        );
      case CollectionDayStatus.open:
        return const AdminStatusPill(
          label: 'Open',
          background: AdminTokens.sand,
          foreground: AdminTokens.sea,
        );
    }
  }
}
