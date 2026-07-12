import 'package:flutter/material.dart';
import 'data/fake_sms_repository.dart';
import 'domain/sms_repository.dart';
import 'presentation/sms_console_controller.dart';
import 'presentation/sms_console_page.dart';
import 'theme/app_theme.dart';

class SmsApp extends StatefulWidget {
  const SmsApp({super.key, this.repository});
  final SmsRepository? repository;
  @override
  State<SmsApp> createState() => _SmsAppState();
}

class _SmsAppState extends State<SmsApp> {
  var _dark = false;
  late final SmsConsoleController controller;
  @override
  void initState() {
    super.initState();
    controller = SmsConsoleController(widget.repository ?? FakeSmsRepository())
      ..initialize();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Butterfly SMS',
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
    home: SmsConsolePage(
      controller: controller,
      isDark: _dark,
      onToggleTheme: () => setState(() => _dark = !_dark),
    ),
  );
}
