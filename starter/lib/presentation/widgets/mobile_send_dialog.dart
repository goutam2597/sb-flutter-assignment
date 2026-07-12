import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../theme/app_theme.dart';
import '../sms_console_controller.dart';
import 'common_widgets.dart';

void showMobileSendDialog(BuildContext context, SmsConsoleCubit cubit) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      return BlocProvider.value(
        value: cubit,
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.xl,
          ),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: BlocBuilder<SmsConsoleCubit, SmsConsoleState>(
              builder: (context, state) {
                final scheme = Theme.of(context).colorScheme;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ---- Header ----
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        Spacing.md,
                        Spacing.md,
                        Spacing.md,
                        Spacing.md,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: scheme.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.send_outlined,
                              size: 20,
                              color: scheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: Spacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Send a message',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                Text(
                                  'Deliver a transactional SMS',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: Spacing.xs),
                          IconButton(
                            icon: const Icon(Icons.close),
                            tooltip: 'Close',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // ---- Body (scrolls when keyboard opens) ----
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(
                          Spacing.md,
                          Spacing.md,
                          Spacing.md,
                          Spacing.md,
                        ),
                        child: SendSmsForm(
                          sending: state.sending,
                          retryAfterSeconds: state.retryAfterSeconds,
                          onSend: cubit.send,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
    },
  );
}
