import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  late final SmsConsoleCubit cubit;
  @override
  void initState() {
    super.initState();
    cubit = SmsConsoleCubit(widget.repository ?? FakeSmsRepository())
      ..initialize();
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
        onToggleTheme: () => setState(() => _dark = !_dark),
      ),
    ),
  );
}
