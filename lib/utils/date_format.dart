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
