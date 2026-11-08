import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:foreshore_core/foreshore_core.dart';
import 'package:google_fonts/google_fonts.dart';

import 'offline_queue.dart';
import 'screens/day_summary_screen.dart';
import 'screens/login_screen.dart';
import 'screens/new_customer_screen.dart';
import 'screens/route_screen.dart';
import 'theme.dart';

String defaultApiBase() {
  const fromEnv = String.fromEnvironment('API_BASE');
  if (fromEnv.isNotEmpty) return fromEnv;
  if (kIsWeb) return 'http://localhost:8000';
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return 'http://10.0.2.2:8000';
    default:
      return 'http://localhost:8000';
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AgentApp());
}

class AgentApp extends StatefulWidget {
  const AgentApp({super.key});

  @override
  State<AgentApp> createState() => _AgentAppState();
}

class _AgentAppState extends State<AgentApp> {
  late final ForeshoreApi api = ForeshoreApi(baseUrl: defaultApiBase());
  late final OfflineQueue queue = OfflineQueue();
  AppUser? user;

  @override
  void initState() {
    super.initState();
    queue.init();
  }

  void _onLoggedIn(AppUser u) => setState(() => user = u);

  void _logout() {
    api.setToken(null);
    setState(() => user = null);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Foreshore Agent',
      debugShowCheckedModeBanner: false,
      theme: foreshoreTheme(GoogleFonts.dmSansTextTheme()),
      home: user == null
          ? LoginScreen(api: api, onLoggedIn: _onLoggedIn)
          : AgentShell(api: api, queue: queue, user: user!, onLogout: _logout),
    );
  }
}

class AgentShell extends StatefulWidget {
  const AgentShell({
    super.key,
    required this.api,
    required this.queue,
    required this.user,
    required this.onLogout,
  });

  final ForeshoreApi api;
  final OfflineQueue queue;
  final AppUser user;
  final VoidCallback onLogout;

  @override
  State<AgentShell> createState() => _AgentShellState();
}

class _AgentShellState extends State<AgentShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      RouteScreen(api: widget.api, queue: widget.queue, user: widget.user),
      NewCustomerScreen(api: widget.api, queue: widget.queue),
      DaySummaryScreen(api: widget.api, queue: widget.queue, user: widget.user),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(index == 0
            ? "Today's route"
            : index == 1
                ? 'New customer'
                : 'Day summary'),
        actions: [
          IconButton(
            tooltip: 'Sync',
            onPressed: () async {
              try {
                final n = await widget.queue.flush(widget.api);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(n == 0 ? 'Already synced' : 'Synced $n items'),
                    ),
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
            icon: const Icon(Icons.cloud_sync_outlined),
          ),
          IconButton(
            tooltip: 'Log out',
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route),
            label: 'Route',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_add_outlined),
            selectedIcon: Icon(Icons.person_add),
            label: 'New',
          ),
          NavigationDestination(
            icon: Icon(Icons.summarize_outlined),
            selectedIcon: Icon(Icons.summarize),
            label: 'Day',
          ),
        ],
      ),
    );
  }
}
