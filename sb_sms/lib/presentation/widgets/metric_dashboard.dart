import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../../theme/app_theme.dart';
import '../sms_console_controller.dart';
import 'layout_info.dart';

/// A single metric definition so the same data drives both layouts.
class Metric {
  const Metric({
    required this.icon,
    required this.value,
    required this.label,
    this.accentColor,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color? accentColor;
}

class MetricDashboard extends StatelessWidget {
  const MetricDashboard(this.state, {super.key, required this.layout});

  final SmsConsoleState state;
  final LayoutInfo layout;

  @override
  Widget build(BuildContext context) {
    final delivered = state.history
        .where((m) => m.status == DeliveryStatus.delivered)
        .length;
    final failed = state.history
        .where((m) => m.status == DeliveryStatus.failed)
        .length;
    final currentSpend = state.cost?.totalCost.format() ?? '—';
    final providerSpend = state.cost?.rows.isNotEmpty == true
        ? state.cost!.rows.first.totalCost.format()
        : '—';
    final providerName = state.cost?.rows.isNotEmpty == true
        ? state.cost!.rows.first.provider
        : 'Provider';
    final errorColor = Theme.of(context).colorScheme.error;

    final metrics = <Metric>[
      Metric(
        icon: Icons.account_balance_wallet_outlined,
        value: currentSpend,
        label: 'Current spend',
      ),
      Metric(
        icon: Icons.receipt_long_outlined,
        value: providerSpend,
        label: '$providerName spend',
      ),
      Metric(
        icon: Icons.mark_chat_read_outlined,
        value: '${state.history.length}',
        label: layout.isCompact ? 'Recent' : 'Recent messages',
      ),
      Metric(
        icon: Icons.check_circle_outline,
        value: '$delivered',
        label: 'Delivered',
      ),
      Metric(
        icon: Icons.cancel_outlined,
        value: '$failed',
        label: 'Failed',
        accentColor: errorColor,
      ),
    ];

    // -------- MOBILE: clean, uniform 2-column tile grid --------
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: layout.isCompact
          ? Column(
              key: const ValueKey('metrics_compact'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < metrics.length; i++) ...[
                  MetricTile(metrics[i]),
                  if (i < metrics.length - 1)
                    const SizedBox(height: Spacing.sm),
                ],
              ],
            )
          : Row(
              key: const ValueKey('metrics_wide'),
              children: [
                for (var i = 0; i < metrics.length; i++) ...[
                  Expanded(child: MetricCard(metrics[i])),
                  if (i != metrics.length - 1)
                    const SizedBox(width: Spacing.md),
                ],
              ],
            ),
    );
  }
}

/// Compact horizontal tile used on mobile. Fixed height keeps the grid tidy.
class MetricTile extends StatelessWidget {
  const MetricTile(this.metric, {super.key});

  final Metric metric;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = metric.accentColor ?? scheme.primary;
    final iconBg = metric.accentColor != null
        ? accent.withValues(alpha: 0.12)
        : scheme.primaryContainer;
    final iconFg = metric.accentColor ?? scheme.onPrimaryContainer;

    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(metric.icon, size: 20, color: iconFg),
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    metric.value,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: metric.accentColor ?? scheme.onSurface,
                      height: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
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

/// Larger vertical card used on desktop/tablet (original look).
class MetricCard extends StatelessWidget {
  const MetricCard(this.metric, {super.key});

  final Metric metric;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final iconBg = metric.accentColor != null
        ? metric.accentColor!.withValues(alpha: 0.12)
        : scheme.primaryContainer;
    final iconFg = metric.accentColor ?? scheme.onPrimaryContainer;
    final valueFg = metric.accentColor ?? scheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(Spacing.sm),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(metric.icon, color: iconFg),
            ),
            const SizedBox(height: Spacing.md),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                metric.value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: valueFg,
                ),
              ),
            ),
            const SizedBox(height: Spacing.xxs),
            Text(
              metric.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
