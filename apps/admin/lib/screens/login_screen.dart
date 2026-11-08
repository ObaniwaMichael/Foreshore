import 'package:flutter/material.dart';
import 'package:foreshore_core/foreshore_core.dart';

import '../widgets/admin_ui.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({
    super.key,
    required this.api,
    required this.onLoggedIn,
  });

  final ForeshoreApi api;
  final ValueChanged<AppUser> onLoggedIn;

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final phone = TextEditingController(text: '08011110002');
  final password = TextEditingController(text: 'admin123');
  bool loading = false;
  String? error;

  Future<void> _submit() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final auth = await widget.api.login(phone.text.trim(), password.text);
      if (auth.user.role == UserRole.agent) {
        setState(() => error = 'Use admin or management credentials');
        return;
      }
      widget.onLoggedIn(auth.user);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stacked = MediaQuery.sizeOf(context).width < 860;

    final brand = Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AdminTokens.seaDeep,
            AdminTokens.sea,
            Color(0xFF1A6B7A),
          ],
        ),
      ),
      padding: EdgeInsets.all(stacked ? 32 : 56),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'OPERATIONS',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          ),
          SizedBox(height: stacked ? 18 : 28),
          const Text(
            'FORESHORE\nHOLDINGS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 44,
              fontWeight: FontWeight.w900,
              height: 1.02,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: const Text(
              'Reconcile daily collections, approve loans, and keep the cash position honest.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );

    final form = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: AdminSurface(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Sign in',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AdminTokens.sea,
                      ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Admin and management access only.',
                  style: TextStyle(color: AdminTokens.inkMuted),
                ),
                const SizedBox(height: 22),
                TextField(
                  controller: phone,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                  onSubmitted: (_) => _submit(),
                ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    error!,
                    style: const TextStyle(
                      color: AdminTokens.coral,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: loading ? null : _submit,
                  child: Text(loading ? 'Signing in…' : 'Continue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      body: stacked
          ? ListView(
              children: [
                SizedBox(height: 280, child: brand),
                form,
              ],
            )
          : Row(
              children: [
                Expanded(child: brand),
                Expanded(child: ColoredBox(color: AdminTokens.mist, child: form)),
              ],
            ),
    );
  }
}
