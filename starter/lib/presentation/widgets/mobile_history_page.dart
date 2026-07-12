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
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      final cubit = context.read<SmsConsoleCubit>();
      if (!cubit.state.loadingMore && cubit.state.nextCursor != null) {
        cubit.loadMore();
      }
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll - 200); // 200px threshold
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Messages'),
      ),
      body: BlocBuilder<SmsConsoleCubit, SmsConsoleState>(
        builder: (context, state) {
          final currency = state.cost?.currency ?? 'EUR';
          
          if (state.history.isEmpty && !state.loading) {
            return const StatePanel(
              icon: Icons.inbox_outlined,
              title: 'No messages yet',
              message: 'Send your first transactional SMS to see delivery activity here.',
            );
          }

          return RefreshIndicator(
            onRefresh: context.read<SmsConsoleCubit>().refresh,
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: Spacing.md),
              itemCount: state.history.length + (state.nextCursor != null ? 1 : 0),
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                if (index >= state.history.length) {
                  return Padding(
                    padding: const EdgeInsets.all(Spacing.lg),
                    child: Center(
                      child: state.error != null
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(state.error!, textAlign: TextAlign.center),
                                const SizedBox(height: Spacing.sm),
                                OutlinedButton.icon(
                                  onPressed: context.read<SmsConsoleCubit>().loadMore,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Try again'),
                                ),
                              ],
                            )
                          : const SizedBox.square(
                              dimension: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                    ),
                  );
                }
                return HistoryTile(item: state.history[index], currency: currency);
              },
            ),
          );
        },
      ),
    );
  }
}
