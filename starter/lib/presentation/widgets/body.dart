import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../../theme/app_theme.dart';
import '../sms_console_controller.dart';
import 'common_widgets.dart';
import 'history.dart';
import 'layout_info.dart';
import 'metric_dashboard.dart';

class SmsConsoleBody extends StatelessWidget {
  const SmsConsoleBody(
    this.cubit,
    this.state, {
    required this.layout,
    super.key,
  });

  final SmsConsoleCubit cubit;
  final SmsConsoleState state;
  final LayoutInfo layout;

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

    final history = MessageHistory(cubit, state, layout: layout);

    return SingleChildScrollView(
      padding: EdgeInsets.all(layout.horizontalPadding),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: layout.contentMaxWidth),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Mobile / tablet header banner + tenant switcher (no sidebar there).
                if (!layout.showSidebar) ...[
                  const SizedBox(height: 10),
                  DropdownButtonFormField<Tenant>(
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                    initialValue: state.tenant,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
                      labelText: 'Switch tenant',
                      prefixIcon: Icon(Icons.business_outlined),
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
                  const SizedBox(height: Spacing.md),
                ],
                MetricDashboard(state, layout: layout),
                const SizedBox(height: Spacing.xl),
                history,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
