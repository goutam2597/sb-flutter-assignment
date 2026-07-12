import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../sms_console_controller.dart';
import 'common_widgets.dart';

class MessageHistory extends StatelessWidget {
  const MessageHistory(this.cubit, this.state, {super.key});

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
                      'Accepted by ${state.receipt!.provider}. '
                      'Delivery is still pending.',
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
