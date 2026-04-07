int calculateStreak(List<DateTime> dates) {
  dates.sort((a, b) => b.compareTo(a));

  int streak = 0;

  for (int i = 0; i < dates.length; i++) {
    if (i == 0) {
      if (dates[i].difference(DateTime.now()).inDays == 0) {
        streak++;
      }
    } else {
      if (dates[i - 1].difference(dates[i]).inDays == 1) {
        streak++;
      } else {
        break;
      }
    }
  }

  return streak;
}
