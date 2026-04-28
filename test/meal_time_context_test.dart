import 'package:flutter_test/flutter_test.dart';
import 'package:food_app/src/utils/meal_time_context.dart';

void main() {
  test('MealTimeContext maps morning hour to breakfast', () {
    final c = MealTimeContext.fromDateTime(DateTime(2026, 4, 27, 8, 0));
    expect(c.categoryFilter, 'Breakfast');
    expect(c.userLabel, 'Morning');
  });
}
