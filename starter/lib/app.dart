import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/logging/app_logger.dart';
import 'data/fake_sms_repository.dart';
import 'domain/sms_repository.dart';
import 'presentation/sms_console_controller.dart';
import 'presentation/sms_console_page.dart';
import 'theme/app_theme.dart';

class SmsApp extends StatefulWidget {
  const SmsApp({super.key, this.repository, this.logger});
  final SmsRepository? repository;
  final AppLogger? logger;
  @override
  State<SmsApp> createState() => _SmsAppState();
}

class _SmsAppState extends State<SmsApp> {
  var _dark = false;
  late final SmsConsoleCubit cubit;
  late final AppLogger logger;
  @override
  void initState() {
    super.initState();
    logger = widget.logger ?? AppLogger.instance;
    logger.info(AppLogEvent.appStarted);
    cubit = SmsConsoleCubit(
      widget.repository ?? FakeSmsRepository(logger: logger),
      logger: logger,
    )..initialize();
  }

  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Butterfly SMS',
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
    home: BlocProvider.value(
      value: cubit,
      child: SmsConsolePage(
        isDark: _dark,
        onToggleTheme: () {
          logger.debug(AppLogEvent.themeChanged);
          setState(() => _dark = !_dark);
        },
      ),
    ),
  );
}
