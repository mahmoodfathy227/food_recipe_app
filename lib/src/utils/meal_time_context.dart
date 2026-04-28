/// Maps local clock to TheMealDB-friendly primary categories and labels.
class MealTimeContext {
  final MealSlot slot;
  final String categoryFilter;
  final String userLabel;

  const MealTimeContext({
    required this.slot,
    required this.categoryFilter,
    required this.userLabel,
  });

  /// Morning: breakfast; midday: light protein; evening: heartier; late: light snack/dessert.
  factory MealTimeContext.fromDateTime(DateTime now) {
    final h = now.hour;
    if (h >= 5 && h < 11) {
      return const MealTimeContext(
        slot: MealSlot.morning,
        categoryFilter: 'Breakfast',
        userLabel: 'Morning',
      );
    }
    if (h >= 11 && h < 16) {
      return const MealTimeContext(
        slot: MealSlot.midday,
        categoryFilter: 'Chicken',
        userLabel: 'Lunch',
      );
    }
    if (h >= 16 && h < 22) {
      return const MealTimeContext(
        slot: MealSlot.evening,
        categoryFilter: 'Beef',
        userLabel: 'Dinner',
      );
    }
    return const MealTimeContext(
      slot: MealSlot.late,
      categoryFilter: 'Dessert',
      userLabel: 'Evening',
    );
  }
}

enum MealSlot { morning, midday, evening, late }
