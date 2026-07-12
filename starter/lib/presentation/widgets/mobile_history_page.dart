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
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _onScroll();
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Infinite scroll: fetch the next page as we approach the bottom.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final nearBottom = pos.pixels >= pos.maxScrollExtent - 320;
    if (!nearBottom) return;

    final cubit = context.read<SmsConsoleCubit>();
    final state = cubit.state;
    if (state.nextCursor != null && !state.loadingMore && !state.loading) {
      cubit.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Messages'),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.transparent,
        flexibleSpace: Theme.of(context).brightness == Brightness.dark
            ? null
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: BlocBuilder<SmsConsoleCubit, SmsConsoleState>(
        builder: (context, state) {
          final cubit = context.read<SmsConsoleCubit>();
          final currency = state.cost?.currency ?? 'EUR';
          final scheme = Theme.of(context).colorScheme;

          // NOTE: adjust these fields to match your message model
          // (e.g. recipient / body / status). This is the single place
          // that controls what search looks through.
          final query = _query.trim().toLowerCase();
          final filtered = query.isEmpty
              ? state.history
              : state.history.where((m) {
                  final haystack = '${m.recipient} ${m.status.name}'
                      .toLowerCase();
                  return haystack.contains(query);
                }).toList();

          return Column(
            children: [
              // ---- Pinned search field ----
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.md,
                  Spacing.md,
                  Spacing.md,
                  Spacing.sm,
                ),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Search messages',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            tooltip: 'Clear',
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                              FocusScope.of(context).unfocus();
                            },
                          ),
                    filled: true,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: Spacing.sm,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              // ---- Scrollable, infinitely-paginated list ----
              Expanded(
                child: _buildBody(
                  context: context,
                  state: state,
                  cubit: cubit,
                  filtered: filtered,
                  currency: currency,
                  scheme: scheme,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required SmsConsoleState state,
    required SmsConsoleCubit cubit,
    required List filtered,
    required String currency,
    required ColorScheme scheme,
  }) {
    // Empty: nothing loaded at all.
    if (state.history.isEmpty && !state.loading) {
      return const Padding(
        padding: EdgeInsets.all(Spacing.lg),
        child: StatePanel(
          icon: Icons.inbox_outlined,
          title: 'No messages yet',
          message:
              'Send your first transactional SMS to see delivery activity here.',
        ),
      );
    }

    // Empty: search returned nothing.
    if (filtered.isEmpty && _query.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: StatePanel(
          icon: Icons.search_off_outlined,
          title: 'No results',
          message: 'No messages match “$_query”.',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: cubit.refresh,
      child: ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          Spacing.md,
          0,
          Spacing.md,
          Spacing.lg,
        ),
        children: [
          if (state.error != null && filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.md),
              child: StatePanel(
                icon: Icons.warning_amber,
                title: 'Action failed',
                message: state.error!,
                onRetry: cubit.refresh,
              ),
            ),

          // Titleless card holding the message list (no more "Page N").
          Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (int i = 0; i < filtered.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: HistoryTile(item: filtered[i], currency: currency),
                  ),
                  if (i < filtered.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),

          // Footer: shows a spinner while the next page loads on scroll,
          // and an end-of-list hint once everything is loaded.
          if (_query.isEmpty) _buildFooter(context, state),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, SmsConsoleState state) {
    if (state.loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: Spacing.lg),
        child: Center(
          child: SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (state.nextCursor == null && state.history.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
        child: Center(
          child: Text(
            'You’re all caught up',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    return const SizedBox(height: Spacing.sm);
  }
}
