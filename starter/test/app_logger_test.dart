import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:starter/core/logging/app_logger.dart';

class _MemoryOutput extends LogOutput {
  final lines = <String>[];

  @override
  void output(OutputEvent event) => lines.addAll(event.lines);
}

void main() {
  test('logs a fixed event without exposing error contents', () {
    final output = _MemoryOutput();
    final logger = AppLogger(output: output);

    logger.error(
      AppLogEvent.sendRejected,
      StateError('Bearer secret-token +4915112345678 private message body'),
    );

    final logged = output.lines.join('\n');
    expect(logged, contains('sendRejected'));
    expect(logged, contains('StateError'));
    expect(logged, isNot(contains('secret-token')));
    expect(logged, isNot(contains('+4915112345678')));
    expect(logged, isNot(contains('private message body')));
  });
}
