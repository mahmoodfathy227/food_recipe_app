import 'src/imports/core_imports.dart';
import 'src/imports/packages_imports.dart';
import 'src/app.dart';


Future<void> main() async {
  final WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  await EasyLocalization.ensureInitialized();
  await dotenv.load(fileName: '.env');
  
  await AppConfig.init();
  (await StorageService.instance.init()).fold(
    (f) {
      debugPrint('[main] StorageService: ${f.message}');
    },
    (_) {},
  );
  await MealReminderService.init();
  debugPrint('[main] core services online');

  runApp(
    const LocalizationWrapper(
      child: StateWrapper(
        child: App(),
      ),
    ),
  );
}