extension WeekNumber on DateTime {
  int get weekNumber {
    final startOfYear = DateTime(year, 1, 1);
    final days = difference(startOfYear).inDays + startOfYear.weekday;
    return (days / 7).ceil();
  }
}
