import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart' as ftz;
import 'package:food_app/src/data/remote/themealdb_remote_data_source.dart';
import 'package:food_app/src/data/repositories/recipe_repository.dart';
import 'package:food_app/src/imports/imports.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

const _kChannel = 'meal_context';
const _androidIcon = '@mipmap/ic_launcher';
const int _kBreakId = 801;
const int _kLunchId = 1201;
const int _kDinnerId = 1801;

class MealReminderService {
  MealReminderService._();
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tzdata.initializeTimeZones();
    final info = await ftz.FlutterTimezone.getLocalTimezone();
    try {
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e) {
      debugPrint('[MealReminderService] timezone fallback, err=$e');
    }

    const android = AndroidInitializationSettings(_androidIcon);
    const darwin = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: android,
      iOS: darwin,
    );
    await _plugin.initialize(
      settings: initSettings,
    );
    const androidCh = AndroidNotificationChannel(
      _kChannel,
      'Meal inspiration',
      description: 'Nudges at breakfast, lunch, and dinner',
      importance: Importance.defaultImportance,
    );
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(androidCh);
    debugPrint('[MealReminderService] init zone=${info.identifier}');
  }

  /// Permission flow + TheMealDB copy + daily 8:00 / 14:00 / 20:00.
  static Future<void> requestAndSchedule(RecipeRepository repository) async {
    var status = await Permission.notification.status;
    if (status.isDenied) {
      status = await Permission.notification.request();
    }
    if (!status.isGranted) {
      AppLogger.info('[MealReminderService] notification permission denied');
      return;
    }

    final remote = TheMealDbRemoteDataSource();
    final breakfast = await remote.pickIdFromCategory('Breakfast');
    final lunch = await remote.pickIdFromCategory('Chicken');
    final dinner = await remote.pickIdFromCategory('Beef');
    String extra(Either<Failure, String?> r) {
      return r.toNullable() != null ? ' (ready to view)' : '';
    }

    await _cancelMealNudges();
    await _schedule(
      _kBreakId,
      8,
      0,
      'Breakfast time',
      'Open Bite & Time for today’s first meal${extra(breakfast)}',
    );
    await _schedule(
      _kLunchId,
      14,
      0,
      'Lunch',
      'Take a break — new ideas in Bite & Time${extra(lunch)}',
    );
    await _schedule(
      _kDinnerId,
      20,
      0,
      'Dinner',
      'Wind down with something delicious${extra(dinner)}',
    );
    debugPrint('[MealReminderService] scheduled; repo ref=${repository.hashCode}');
  }

  static Future<void> _cancelMealNudges() async {
    await _plugin.cancel(id: _kBreakId);
    await _plugin.cancel(id: _kLunchId);
    await _plugin.cancel(id: _kDinnerId);
  }

  static Future<void> _schedule(
    int id,
    int hour,
    int minute,
    String title,
    String body,
  ) async {
    final next = _nextTime(hour, minute);
    debugPrint('[MealReminderService] scheduling id=$id at $hour:$minute');
    const android = AndroidNotificationDetails(
      _kChannel,
      'Meal inspiration',
      channelDescription: 'Meal nudges',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const darwin = DarwinNotificationDetails(); // ignore: prefer_const_constructors
    const details = NotificationDetails(
      android: android,
      iOS: darwin,
    );
    final tzTime = tz.TZDateTime.from(next, tz.local);
    try {
      await _plugin.zonedSchedule(
        id: id,
        scheduledDate: tzTime,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: title,
        body: body,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('[MealReminderService] zonedSchedule id=$id err=$e');
    }
  }

  static DateTime _nextTime(int h, int m) {
    final n = DateTime.now();
    var t = DateTime(n.year, n.month, n.day, h, m);
    if (t.isBefore(n)) {
      t = t.add(const Duration(days: 1));
    }
    return t;
  }
}
