import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../theme/app_theme.dart';
import '../sms_console_controller.dart';
import 'common_widgets.dart';
import 'layout_info.dart';
import 'mobile_history_page.dart';

class MessageHistory extends StatefulWidget {
  const MessageHistory(
    this.cubit,
    this.state, {
    required this.layout,
    super.key,
  });

  final SmsConsoleCubit cubit;
  final SmsConsoleState state;
  final LayoutInfo layout;

  @override
  State<MessageHistory> createState() => _MessageHistoryState();
}

class _MessageHistoryState extends State<MessageHistory> {
  int _currentPage = 0;
  static const int _pageSize = 5;

  @override
  void didUpdateWidget(MessageHistory oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset page when tenant changes
    if (oldWidget.state.tenant.id != widget.state.tenant.id) {
      _currentPage = 0;
    }
  }

  void _goToPage(int pageIndex) {
    final maxAvailablePage = (widget.state.history.length - 1) ~/ _pageSize;

    if (pageIndex > maxAvailablePage && widget.state.nextCursor != null) {
      widget.cubit.loadMore().then((_) {
        if (mounted) setState(() => _currentPage = pageIndex);
      });
    } else {
      setState(() => _currentPage = pageIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = widget.state.cost?.currency ?? 'EUR';
    final isMobile = widget.layout.isCompact;

    final visibleHistory = isMobile
        ? widget.state.history.take(_pageSize).toList()
        : widget.state.history
              .skip(_currentPage * _pageSize)
              .take(_pageSize)
              .toList();

    return SectionCard(
      title: 'Message history',
      trailing: Text(
        isMobile
            ? '${visibleHistory.length} recent'
            : 'Page ${_currentPage + 1}',
        style: Theme.of(context).textTheme.labelLarge,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.state.receipt != null)
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
                      'Accepted by ${widget.state.receipt!.provider}. Delivery is still pending.',
                    ),
                  ),
                ],
              ),
            ),

          if (widget.state.error != null)
            StatePanel(
              icon: Icons.warning_amber,
              title: 'Latest action failed',
              message: widget.state.error!,
              onRetry: widget.cubit.refresh,
            ),

          if (widget.state.history.isEmpty && widget.state.error == null)
            const StatePanel(
              icon: Icons.inbox_outlined,
              title: 'No messages yet',
              message:
                  'Send your first transactional SMS to see delivery activity here.',
            )
          else ...[
            for (final item in visibleHistory) ...[
              HistoryTile(item: item, currency: currency),
              const Divider(height: 1),
            ],

            if (isMobile) ...[
              if (widget.state.history.length > _pageSize ||
                  widget.state.nextCursor != null)
                Padding(
                  padding: const EdgeInsets.only(top: Spacing.md),
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => BlocProvider.value(
                            value: widget.cubit,
                            child: const MobileHistoryPage(),
                          ),
                        ),
                      );
                    },
                    child: const Text('See all messages'),
                  ),
                ),
            ] else ...[
              // Desktop Numbered Pagination
              if (widget.state.history.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: Spacing.lg),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: _currentPage > 0
                            ? () => _goToPage(_currentPage - 1)
                            : null,
                      ),
                      const SizedBox(width: Spacing.sm),
                      // Determine how many pages we know about
                      ...List.generate(
                        ((widget.state.history.length - 1) ~/ _pageSize) +
                            1 +
                            (widget.state.nextCursor != null ? 1 : 0),
                        (index) {
                          // Only show up to 5 page numbers to prevent overflow
                          if (index < _currentPage - 2 ||
                              index > _currentPage + 2) {
                            if (index == _currentPage - 3 ||
                                index == _currentPage + 3) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: Spacing.xs,
                                ),
                                child: Text('...'),
                              );
                            }
                            return const SizedBox.shrink();
                          }

                          final isCurrent = index == _currentPage;
                          final isLoadingThisPage =
                              index >
                                  ((widget.state.history.length - 1) ~/
                                      _pageSize) &&
                              widget.state.loadingMore;

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 2.0,
                            ),
                            child: isLoadingThisPage
                                ? const SizedBox.square(
                                    dimension: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : ChoiceChip(
                                    label: Text('${index + 1}'),
                                    selected: isCurrent,
                                    onSelected: (_) => _goToPage(index),
                                  ),
                          );
                        },
                      ),
                      const SizedBox(width: Spacing.sm),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed:
                            ((widget.state.history.length - 1) ~/ _pageSize) >
                                    _currentPage ||
                                widget.state.nextCursor != null
                            ? () => _goToPage(_currentPage + 1)
                            : null,
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }
}
