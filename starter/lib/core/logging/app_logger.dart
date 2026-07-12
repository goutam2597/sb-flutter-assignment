import 'package:logger/logger.dart';

enum AppLogEvent {
  appStarted,
  themeChanged,
  tenantChanged,
  refreshStarted,
  refreshCompleted,
  refreshFailed,
  sendStarted,
  sendAccepted,
  sendRejected,
  sendRateLimited,
  historyPageStarted,
  historyPageCompleted,
  historyPageFailed,
  fakeRequestStarted,
  fakeRequestCompleted,
  fakeRequestFailed,
  httpRequestStarted,
  httpRequestCompleted,
  httpRequestFailed,
  accessTokenMissing,
  tokenRefreshStarted,
  tokenRefreshCompleted,
  sessionExpired,
}

/// The only logging entry point used by the application.
///
/// Events are fixed enum values on purpose. Callers cannot attach recipients,
/// message bodies, credentials, headers, or URLs. The logger package's
/// DevelopmentFilter also suppresses every event in release builds.
class AppLogger {
  AppLogger({LogOutput? output})
    : _logger = Logger(
        filter: DevelopmentFilter(),
        printer: SimplePrinter(colors: false, printTime: true),
        output: output,
      );

  static final AppLogger instance = AppLogger();

  final Logger _logger;

  void debug(AppLogEvent event) => _logger.d(event.name);

  void info(AppLogEvent event) => _logger.i(event.name);

  void warning(AppLogEvent event) => _logger.w(event.name);

  void error(AppLogEvent event, Object error, [StackTrace? stackTrace]) =>
      _logger.e(event.name, error: error.runtimeType, stackTrace: stackTrace);
}
