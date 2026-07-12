import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../theme/app_theme.dart';
import '../sms_console_controller.dart';
import 'common_widgets.dart';

class MobileHistoryPage extends StatefulWidget {
  const MobileHistoryPage({super.key});

  @override
  State<MobileHistoryPage> createState() => _MobileHistoryPageState();
}

class _MobileHistoryPageState extends State<MobileHistoryPage> {
  int _currentPage = 0;
  static const int _pageSize = 5;

  void _goToPage(int pageIndex, SmsConsoleCubit cubit, SmsConsoleState state) {
    final maxAvailablePage = (state.history.length - 1) ~/ _pageSize;

    if (pageIndex > maxAvailablePage && state.nextCursor != null) {
      cubit.loadMore().then((_) {
        if (mounted) setState(() => _currentPage = pageIndex);
      });
    } else {
      setState(() => _currentPage = pageIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Messages'),
      ),
      body: BlocBuilder<SmsConsoleCubit, SmsConsoleState>(
        builder: (context, state) {
          final cubit = context.read<SmsConsoleCubit>();
          final currency = state.cost?.currency ?? 'EUR';
          
          final visibleHistory = state.history.skip(_currentPage * _pageSize).take(_pageSize).toList();

          if (state.history.isEmpty && !state.loading) {
            return const Padding(
              padding: EdgeInsets.all(Spacing.lg),
              child: StatePanel(
                icon: Icons.inbox_outlined,
                title: 'No messages yet',
                message: 'Send your first transactional SMS to see delivery activity here.',
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: cubit.refresh,
            child: ListView(
              padding: const EdgeInsets.all(Spacing.md),
              children: [
                if (state.error != null && visibleHistory.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.md),
                    child: StatePanel(
                      icon: Icons.warning_amber,
                      title: 'Action failed',
                      message: state.error!,
                      onRetry: cubit.refresh,
                    ),
                  ),
                  
                SectionCard(
                  title: 'Page ${_currentPage + 1}',
                  child: Column(
                    children: [
                      for (int i = 0; i < visibleHistory.length; i++) ...[
                        HistoryTile(item: visibleHistory[i], currency: currency),
                        if (i < visibleHistory.length - 1) const Divider(height: 1),
                      ],
                    ],
                  ),
                ),
                
                if (state.history.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: Spacing.xl),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: _currentPage > 0 ? () => _goToPage(_currentPage - 1, cubit, state) : null,
                        ),
                        const SizedBox(width: Spacing.sm),
                        ...List.generate(
                          ((state.history.length - 1) ~/ _pageSize) + 1 + (state.nextCursor != null ? 1 : 0),
                          (index) {
                            if (index < _currentPage - 2 || index > _currentPage + 2) {
                              if (index == _currentPage - 3 || index == _currentPage + 3) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: Spacing.xs),
                                  child: Text('...'),
                                );
                              }
                              return const SizedBox.shrink();
                            }
                            
                            final isCurrent = index == _currentPage;
                            final isLoadingThisPage = index > ((state.history.length - 1) ~/ _pageSize) && state.loadingMore;
                            
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2.0),
                              child: isLoadingThisPage
                                ? const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2))
                                : ChoiceChip(
                                    label: Text('${index + 1}'),
                                    selected: isCurrent,
                                    onSelected: (_) => _goToPage(index, cubit, state),
                                  ),
                            );
                          }
                        ),
                        const SizedBox(width: Spacing.sm),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: ((state.history.length - 1) ~/ _pageSize) > _currentPage || state.nextCursor != null
                              ? () => _goToPage(_currentPage + 1, cubit, state)
                              : null,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
