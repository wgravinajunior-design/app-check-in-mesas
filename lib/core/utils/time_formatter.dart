import 'package:intl/intl.dart';

class TimeFormatter {
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm:ss');
  static final DateFormat _timeFormat = DateFormat('HH:mm:ss');
  static final DateFormat _shortTimeFormat = DateFormat('HH:mm');
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '--:--:--';
    return _dateTimeFormat.format(dateTime);
  }

  static String formatTime(DateTime? dateTime) {
    if (dateTime == null) return '--:--';
    return _timeFormat.format(dateTime);
  }

  static String formatShortTime(DateTime? dateTime) {
    if (dateTime == null) return '--:--';
    return _shortTimeFormat.format(dateTime);
  }

  static String formatDateSql(DateTime dateTime) {
    return _dateFormat.format(dateTime);
  }

  /// Formata uma duração em formato de cronômetro clássico HH:MM:SS
  static String formatCronometro(Duration duration) {
    if (duration.isNegative) {
      return '00:00:00';
    }

    final int hours = duration.inHours;
    final int minutes = duration.inMinutes.remainder(60);
    final int seconds = duration.inSeconds.remainder(60);

    final String hoursStr = hours.toString().padLeft(2, '0');
    final String minutesStr = minutes.toString().padLeft(2, '0');
    final String secondsStr = seconds.toString().padLeft(2, '0');

    return '$hoursStr:$minutesStr:$secondsStr';
  }

  /// Formata a duração em texto legível como "1h 45m" ou "32 min"
  static String formatDuracaoAmigavel(Duration duration) {
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}
