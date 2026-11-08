import 'package:flutter/material.dart';

/// Shared Foreshore admin visual tokens and layout helpers.
abstract final class AdminTokens {
  static const sea = Color(0xFF0B3D4A);
  static const seaDeep = Color(0xFF072F38);
  static const seaSoft = Color(0xFFE6F1F0);
  static const mist = Color(0xFFF4F8F7);
  static const sand = Color(0xFFF7F3EC);
  static const coral = Color(0xFFC45C26);
  static const coralSoft = Color(0xFFFCEEE6);
  static const inkMuted = Color(0xFF5A6B70);
  static const line = Color(0xFFE2EAE8);

  static const pagePadding = EdgeInsets.fromLTRB(28, 20, 28, 28);
  static const radius = 16.0;
}

bool adminWide(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= 1100;

bool adminCompact(BuildContext context) =>
    MediaQuery.sizeOf(context).width < 900;

class AdminPageHeader extends StatelessWidget {
  const AdminPageHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow.toUpperCase(),
            style: const TextStyle(
              color: AdminTokens.coral,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: AdminTokens.sea,
                ),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Text(
              subtitle,
              style: const TextStyle(
                color: AdminTokens.inkMuted,
                height: 1.45,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminSurface extends StatelessWidget {
  const AdminSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderColor,
    this.accentStripe,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final Color? accentStripe;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AdminTokens.radius),
        border: Border.all(color: borderColor ?? AdminTokens.line),
        boxShadow: [
          BoxShadow(
            color: AdminTokens.sea.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      foregroundDecoration: accentStripe == null
          ? null
          : BoxDecoration(
              borderRadius: BorderRadius.circular(AdminTokens.radius),
              border: Border(
                left: BorderSide(color: accentStripe!, width: 4),
              ),
            ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class AdminStatusPill extends StatelessWidget {
  const AdminStatusPill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class AdminMetricTile extends StatelessWidget {
  const AdminMetricTile({
    super.key,
    required this.label,
    required this.value,
    this.hint,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final String? hint;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AdminTokens.inkMuted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.3,
            color: emphasize ? AdminTokens.coral : AdminTokens.sea,
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: 2),
          Text(
            hint!,
            style: const TextStyle(color: AdminTokens.inkMuted, fontSize: 11),
          ),
        ],
      ],
    );
  }
}

class AdminEmptyState extends StatelessWidget {
  const AdminEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.framed = true,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool framed;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AdminTokens.seaSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AdminTokens.sea),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AdminTokens.sea,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: const TextStyle(
                  color: AdminTokens.inkMuted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (!framed) return content;
    return AdminSurface(child: content);
  }
}

class AdminErrorState extends StatelessWidget {
  const AdminErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: AdminSurface(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, color: AdminTokens.coral, size: 32),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AdminTokens.inkMuted),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminStatCard extends StatelessWidget {
  const AdminStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AdminSurface(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AdminTokens.seaSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AdminTokens.sea, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AdminTokens.inkMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: -0.4,
                    color: AdminTokens.sea,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
