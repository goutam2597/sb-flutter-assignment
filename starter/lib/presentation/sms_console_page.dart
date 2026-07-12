import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/models.dart';
import '../theme/app_theme.dart';
import 'sms_console_controller.dart';
import 'widgets.dart';

class SmsConsolePage extends StatelessWidget {
  const SmsConsolePage({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
  });
  final bool isDark;
  final VoidCallback onToggleTheme;
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<SmsConsoleCubit, SmsConsoleState>(
        builder: (context, state) {
          final cubit = context.read<SmsConsoleCubit>();
          return Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  _Header(
                    cubit: cubit,
                    state: state,
                    isDark: isDark,
                    onToggleTheme: onToggleTheme,
                  ),
                  Expanded(child: _Body(cubit, state)),
                ],
              ),
            ),
          );
        },
      );
}

class _Header extends StatelessWidget {
  const _Header({
    required this.cubit,
    required this.state,
    required this.isDark,
    required this.onToggleTheme,
  });
  final SmsConsoleCubit cubit;
  final SmsConsoleState state;
  final bool isDark;
  final VoidCallback onToggleTheme;
  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width <= 600;
    final delivered = state.history
        .where((message) => message.status == DeliveryStatus.delivered)
        .length;
    final summary = [
      _SummarySignal(
        Icons.mark_chat_read_outlined,
        '${state.history.length}',
        'recent',
      ),
      _SummarySignal(Icons.check_circle_outline, '$delivered', 'delivered'),
      _SummarySignal(
        Icons.account_balance_wallet_outlined,
        state.cost?.totalCost.format() ?? '—',
        'provider spend',
      ),
    ];
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.forum_outlined,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Butterfly SMS',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      compact
                          ? 'SMS operations'
                          : 'Communications command center',
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!compact)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: DropdownButtonFormField<Tenant>(
                    initialValue: state.tenant,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Active tenant',
                      isDense: true,
                    ),
                    items: SmsConsoleCubit.tenants
                        .map(
                          (t) =>
                              DropdownMenuItem(value: t, child: Text(t.name)),
                        )
                        .toList(),
                    onChanged: (t) {
                      if (t != null) cubit.switchTenant(t);
                    },
                  ),
                )
              else
                PopupMenuButton<Tenant>(
                  tooltip: 'Change active tenant',
                  onSelected: cubit.switchTenant,
                  itemBuilder: (_) => SmsConsoleCubit.tenants
                      .map((t) => PopupMenuItem(value: t, child: Text(t.name)))
                      .toList(),
                  child: Semantics(
                    button: true,
                    label: 'Active tenant ${state.tenant.name}. Change tenant',
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            state.tenant.name.split(' ').first,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: Spacing.xxs),
                          const Icon(Icons.expand_more, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: Spacing.xs),
              if (!compact)
                IconButton(
                  onPressed: onToggleTheme,
                  tooltip: isDark ? 'Use light theme' : 'Use dark theme',
                  icon: Icon(
                    isDark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                  ),
                ),
              IconButton(
                onPressed: state.loading ? null : cubit.refresh,
                tooltip: 'Refresh dashboard',
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.sm,
              vertical: Spacing.xs,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: compact ? summary.take(2).toList() : summary),
          ),
        ],
      ),
    );
  }
}

class _SummarySignal extends StatelessWidget {
  const _SummarySignal(this.icon, this.value, this.label);
  final IconData icon;
  final String value, label;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Semantics(
      label: '$value $label',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: Spacing.xs),
          Flexible(
            child: Text(
              '$value $label',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Body extends StatelessWidget {
  const _Body(this.cubit, this.state);
  final SmsConsoleCubit cubit;
  final SmsConsoleState state;
  @override
  Widget build(BuildContext context) {
    if (state.loading && state.history.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(semanticsLabel: 'Loading SMS console'),
      );
    }
    if (state.error != null && state.history.isEmpty) {
      return StatePanel(
        icon: Icons.cloud_off_outlined,
        title: 'Could not load this tenant',
        message: state.error!,
        onRetry: cubit.refresh,
      );
    }
    return LayoutBuilder(
      builder: (context, b) {
        final left = Column(
          children: [
            SectionCard(
              title: 'Send a message',
              child: SendSmsForm(
                sending: state.sending,
                retryAfterSeconds: state.retryAfterSeconds,
                onSend: cubit.send,
              ),
            ),
            const SizedBox(height: Spacing.lg),
            _Costs(state),
          ],
        );
        final history = _History(cubit, state);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1320),
            child: Center(
              child: b.maxWidth >= 900
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 410, child: left),
                        const SizedBox(width: Spacing.lg),
                        Expanded(child: history),
                      ],
                    )
                  : Column(
                      children: [
                        _TenantLabel(state.tenant),
                        const SizedBox(height: Spacing.md),
                        left,
                        const SizedBox(height: Spacing.lg),
                        history,
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _TenantLabel extends StatelessWidget {
  const _TenantLabel(this.t);
  final Tenant t;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Text(t.name, style: Theme.of(context).textTheme.titleMedium),
  );
}

class _Costs extends StatelessWidget {
  const _Costs(this.state);
  final SmsConsoleState state;
  @override
  Widget build(BuildContext context) {
    final cost = state.cost;
    if (cost == null) return const SizedBox.shrink();
    return SectionCard(
      title: 'Current spend',
      trailing: Text(
        cost.totalCost.format(),
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
      child: Column(
        children: [
          for (final row in cost.rows)
            CostBreakdownRow(row: row, currency: cost.currency),
          const Divider(),
          Row(
            children: [
              const Icon(Icons.info_outline, size: 18),
              const SizedBox(width: Spacing.xs),
              Expanded(
                child: Text(
                  'Provider-reported cost • four-decimal precision',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _History extends StatelessWidget {
  const _History(this.cubit, this.state);
  final SmsConsoleCubit cubit;
  final SmsConsoleState state;
  @override
  Widget build(BuildContext context) {
    final currency = state.cost?.currency ?? 'EUR';
    return SectionCard(
      title: 'Message history',
      trailing: Text(
        '${state.history.length} recent',
        style: Theme.of(context).textTheme.labelLarge,
      ),
      child: Column(
        children: [
          if (state.receipt != null)
            Container(
              margin: const EdgeInsets.only(bottom: Spacing.md),
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mark_email_unread_outlined),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Text(
                      'Accepted by ${state.receipt!.provider}. Delivery is still pending.',
                    ),
                  ),
                ],
              ),
            ),
          if (state.error != null)
            StatePanel(
              icon: Icons.warning_amber,
              title: 'Latest action failed',
              message: state.error!,
              onRetry: cubit.refresh,
            ),
          if (state.history.isEmpty)
            const StatePanel(
              icon: Icons.inbox_outlined,
              title: 'No messages yet',
              message:
                  'Send your first transactional SMS to see delivery activity here.',
            )
          else ...[
            for (final item in state.history) ...[
              HistoryTile(item: item, currency: currency),
              const Divider(height: 1),
            ],
            if (state.nextCursor != null)
              Padding(
                padding: const EdgeInsets.only(top: Spacing.lg),
                child: OutlinedButton.icon(
                  onPressed: state.loadingMore ? null : cubit.loadMore,
                  icon: state.loadingMore
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.expand_more),
                  label: Text(state.loadingMore ? 'Loading…' : 'Load more'),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
