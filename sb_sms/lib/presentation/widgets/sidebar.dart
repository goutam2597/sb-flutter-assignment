import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../../theme/app_theme.dart';
import '../sms_console_controller.dart';
import 'common_widgets.dart';

class SmsConsoleSidebar extends StatelessWidget {
  const SmsConsoleSidebar({
    super.key,
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
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        right: false,
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: Spacing.sm),
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
                    child: Text(
                      'Butterfly SMS',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.xl),
              DropdownButtonFormField<Tenant>(
                borderRadius: BorderRadius.circular(16),
                initialValue: state.tenant,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Active tenant',
                  prefixIcon: Icon(Icons.business_outlined),
                ),
                items: SmsConsoleCubit.tenants
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                    .toList(),
                onChanged: (t) {
                  if (t != null) cubit.switchTenant(t);
                },
              ),
              const SizedBox(height: Spacing.xl),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SectionCard(
                        title: 'Send a message',
                        child: SendSmsForm(
                          sending: state.sending,
                          retryAfterSeconds: state.retryAfterSeconds,
                          onSend: cubit.send,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: state.loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                title: const Text('Refresh dashboard'),
                onTap: state.loading ? null : cubit.refresh,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                ),
                title: Text(isDark ? 'Light theme' : 'Dark theme'),
                onTap: onToggleTheme,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
