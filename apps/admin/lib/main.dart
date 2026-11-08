import 'package:flutter/material.dart';
import 'package:foreshore_core/foreshore_core.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/login_screen.dart';
import 'screens/shell.dart';
import 'theme.dart';

String defaultApiBase() {
  const fromEnv = String.fromEnvironment('API_BASE');
  if (fromEnv.isNotEmpty) return fromEnv;
  return 'http://localhost:8000';
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AdminApp());
}

class AdminApp extends StatefulWidget {
  const AdminApp({super.key});

  @override
  State<AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
  late final ForeshoreApi api = ForeshoreApi(baseUrl: defaultApiBase());
  AppUser? user;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Foreshore Admin',
      debugShowCheckedModeBanner: false,
      theme: adminTheme(GoogleFonts.dmSansTextTheme()),
      home: user == null
          ? AdminLoginScreen(
              api: api,
              onLoggedIn: (u) => setState(() => user = u),
            )
          : AdminShell(
              api: api,
              user: user!,
              onLogout: () {
                api.setToken(null);
                setState(() => user = null);
              },
            ),
    );
  }
}
