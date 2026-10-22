import 'package:memorio/barrel_file.dart';

class AppLogger {
  static bool globalLoggingEnabled = true;

  static void info(String message) {
    _printLog('ℹ️ [INFO]', message);
  }

  static void warning(String message) {
    _printLog('⚠️ [WARN]', message);
  }

  static void error(String message, {dynamic error, StackTrace? stackTrace}) {
    String fullMessage = message;

    if (error != null) {
      fullMessage += '\n   └─ Excepción: $error';
    }
    if (stackTrace != null) {
      fullMessage += '\n   └─ StackTrace:\n$stackTrace';
    }

    _printLog('❌ [ERROR]', fullMessage);
  }

  static void _printLog(String prefix, String message) {
    if (!globalLoggingEnabled) return;
    debugPrint('$prefix $message');
  }
}