import 'package:flutter/material.dart';
import 'package:foreshore_core/foreshore_core.dart';

import '../widgets/admin_ui.dart';
import 'loans_screen.dart';
import 'recon_screen.dart';
import 'reports_screen.dart';
import 'withdrawals_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({
    super.key,
    required this.api,
    required this.user,
    required this.onLogout,
  });

  final ForeshoreApi api;
  final AppUser user;
  final VoidCallback onLogout;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int index = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  static const destinations = [
    (Icons.fact_check_outlined, Icons.fact_check, 'Reconcile'),
    (Icons.account_balance_outlined, Icons.account_balance, 'Loans'),
    (Icons.payments_outlined, Icons.payments, 'Withdraw'),
    (Icons.insights_outlined, Icons.insights, 'Reports'),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      ReconScreen(api: widget.api),
      LoansScreen(api: widget.api),
      WithdrawalsScreen(api: widget.api),
      ReportsScreen(api: widget.api),
    ];
    final wide = adminWide(context);
    final compact = adminCompact(context);

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TopBar(
          user: widget.user,
          onLogout: widget.onLogout,
          showMenu: compact,
          onMenu: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        Expanded(child: pages[index]),
      ],
    );

    if (compact) {
      return Scaffold(
        key: _scaffoldKey,
        drawer: Drawer(
          child: SafeArea(
            child: _SideNav(
              extended: true,
              index: index,
              onSelect: (i) {
                setState(() => index = i);
                Navigator.of(context).pop();
              },
              onLogout: widget.onLogout,
            ),
          ),
        ),
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) => setState(() => index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.fact_check_outlined),
              selectedIcon: Icon(Icons.fact_check),
              label: 'Reconcile',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_outlined),
              selectedIcon: Icon(Icons.account_balance),
              label: 'Loans',
            ),
            NavigationDestination(
              icon: Icon(Icons.payments_outlined),
              selectedIcon: Icon(Icons.payments),
              label: 'Withdraw',
            ),
            NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights),
              label: 'Reports',
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          _SideNav(
            extended: wide,
            index: index,
            onSelect: (i) => setState(() => index = i),
            onLogout: widget.onLogout,
          ),
          Container(width: 1, color: AdminTokens.line),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.user,
    required this.onLogout,
    required this.showMenu,
    required this.onMenu,
  });

  final AppUser user;
  final VoidCallback onLogout;
  final bool showMenu;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(showMenu ? 8 : 28, 14, 16, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AdminTokens.line)),
      ),
      child: Row(
        children: [
          if (showMenu)
            IconButton(
              onPressed: onMenu,
              icon: const Icon(Icons.menu_rounded),
            ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Foreshore Holdings',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AdminTokens.sea,
                  ),
                ),
                Text(
                  'Operations desk',
                  style: TextStyle(
                    color: AdminTokens.inkMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: AdminTokens.seaSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 11,
                      backgroundColor: AdminTokens.sea,
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'A',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${user.name} · ${user.role.name}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: AdminTokens.sea,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Log out',
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
    );
  }
}

class _SideNav extends StatelessWidget {
  const _SideNav({
    required this.extended,
    required this.index,
    required this.onSelect,
    required this.onLogout,
  });

  final bool extended;
  final int index;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        child: SizedBox(
          width: extended ? 220 : 88,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(extended ? 20 : 12, 20, 12, 8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AdminTokens.sea, Color(0xFF1A6B7A)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'FH',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (extended) ...[
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Admin',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AdminTokens.sea,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < _AdminShellState.destinations.length; i++)
                _NavItem(
                  extended: extended,
                  selected: index == i,
                  icon: _AdminShellState.destinations[i].$1,
                  selectedIcon: _AdminShellState.destinations[i].$2,
                  label: _AdminShellState.destinations[i].$3,
                  onTap: () => onSelect(i),
                ),
              const Spacer(),
              if (extended)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: TextButton.icon(
                    onPressed: onLogout,
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Sign out'),
                    style: TextButton.styleFrom(
                      foregroundColor: AdminTokens.inkMuted,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: IconButton(
                    tooltip: 'Sign out',
                    onPressed: onLogout,
                    icon: const Icon(Icons.logout_rounded),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.extended,
    required this.selected,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.onTap,
  });

  final bool extended;
  final bool selected;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: extended ? 12 : 10, vertical: 3),
      child: Material(
        color: selected ? AdminTokens.seaSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: extended ? 12 : 0,
              vertical: 12,
            ),
            child: extended
                ? Row(
                    children: [
                      Icon(
                        selected ? selectedIcon : icon,
                        color: selected ? AdminTokens.sea : AdminTokens.inkMuted,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        label,
                        style: TextStyle(
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color:
                              selected ? AdminTokens.sea : AdminTokens.inkMuted,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Icon(
                        selected ? selectedIcon : icon,
                        color: selected ? AdminTokens.sea : AdminTokens.inkMuted,
                        size: 22,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color:
                              selected ? AdminTokens.sea : AdminTokens.inkMuted,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
