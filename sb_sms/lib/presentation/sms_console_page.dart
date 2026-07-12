import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../theme/app_theme.dart';
import 'sms_console_controller.dart';
import 'widgets/widgets.dart';

class SmsConsolePage extends StatelessWidget {
  const SmsConsolePage({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
  });

  final bool isDark;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SmsConsoleCubit, SmsConsoleState>(
      builder: (context, state) {
        final cubit = context.read<SmsConsoleCubit>();
        return LayoutBuilder(
          builder: (context, constraints) {
            final layout = LayoutInfo(constraints.maxWidth);

            return Scaffold(
              appBar: layout.showSidebar
                  ? null
                  : AppBar(
                      title: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.forum_outlined),
                          SizedBox(width: Spacing.sm),
                          Flexible(
                            child: Text(
                              'Butterfly SMS',
                              style: TextStyle(fontWeight: FontWeight.w800),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      centerTitle: false,
                      backgroundColor: isDark
                          ? Colors.black
                          : Colors.transparent,
                      flexibleSpace: isDark
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
                      foregroundColor: isDark
                          ? Colors.white
                          : Theme.of(context).colorScheme.onPrimary,
                      actions: [
                        IconButton(
                          onPressed: onToggleTheme,
                          tooltip: isDark
                              ? 'Use light theme'
                              : 'Use dark theme',
                          icon: Icon(
                            isDark
                                ? Icons.light_mode_outlined
                                : Icons.dark_mode_outlined,
                          ),
                        ),
                        const SizedBox(width: Spacing.xs),
                      ],
                    ),
              floatingActionButton: layout.showSidebar
                  ? null
                  : SizedBox(
                      height: 64,
                      width: 64,
                      child: FloatingActionButton(
                        backgroundColor: isDark
                            ? Colors.black
                            : Theme.of(context).colorScheme.primary,
                        onPressed: () => showMobileSendDialog(context, cubit),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(99.0),
                          side: isDark
                              ? const BorderSide(
                                  color: Colors.white54,
                                  width: 1,
                                )
                              : BorderSide.none,
                        ),
                        child: const Icon(
                          Icons.send,
                          size: 28,
                          color: Colors.white,
                        ),
                      ),
                    ),
              body: RefreshIndicator(
                onRefresh: cubit.refresh,
                child: SafeArea(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: layout.showSidebar
                        ? Row(
                            key: const ValueKey('desktop_layout'),
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: layout.sidebarWidth,
                                child: SmsConsoleSidebar(
                                  cubit: cubit,
                                  state: state,
                                  isDark: isDark,
                                  onToggleTheme: onToggleTheme,
                                ),
                              ),
                              const VerticalDivider(width: 1, thickness: 1),
                              Expanded(
                                child: SmsConsoleBody(
                                  cubit,
                                  state,
                                  layout: layout,
                                ),
                              ),
                            ],
                          )
                        : SmsConsoleBody(
                            cubit,
                            state,
                            layout: layout,
                            key: const ValueKey('mobile_layout'),
                          ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
