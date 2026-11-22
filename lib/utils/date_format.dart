const List<String> _shortWeekdays = <String>[
  'Sen',
  'Sel',
  'Rab',
  'Kam',
  'Jum',
  'Sab',
  'Min',
];

const List<String> _shortMonths = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

String shortWeekdayLabel(DateTime date) => _shortWeekdays[date.weekday - 1];

String formatThousandsId(int value) {
  final isNegative = value < 0;
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final fromEnd = digits.length - i;
    if (i > 0 && fromEnd % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(digits[i]);
  }
  return isNegative ? '-${buffer.toString()}' : buffer.toString();
}

List<DateTime> buildWeekWindow(DateTime selectedDate, {DateTime? now}) {
  final today = startOfDay(now ?? DateTime.now());
  final target = startOfDay(selectedDate);
  final recentWindowStart = DateTime(today.year, today.month, today.day - 6);
  final DateTime end;
  if (!target.isBefore(recentWindowStart) && !target.isAfter(today)) {
    end = today;
  } else {
    final candidateEnd = DateTime(target.year, target.month, target.day + 3);
    end = candidateEnd.isAfter(today) ? today : candidateEnd;
  }
  final start = DateTime(end.year, end.month, end.day - 6);
  return List<DateTime>.generate(
    7,
    (index) => DateTime(start.year, start.month, start.day + index),
  );
}

DateTime startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String formatTimeHm(DateTime date) {
  final hh = date.hour.toString().padLeft(2, '0');
  final mm = date.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}

String formatRelativeDay(DateTime date, {DateTime? now}) {
  final reference = startOfDay(now ?? DateTime.now());
  final target = startOfDay(date);
  if (isSameDay(target, reference)) {
    return 'Hari Ini';
  }
  if (isSameDay(target, reference.subtract(const Duration(days: 1)))) {
    return 'Kemarin';
  }
  final weekday = _shortWeekdays[target.weekday - 1];
  final month = _shortMonths[target.month - 1];
  if (target.year != reference.year) {
    return '$weekday, ${target.day} $month ${target.year}';
  }
  return '$weekday, ${target.day} $month';
}
