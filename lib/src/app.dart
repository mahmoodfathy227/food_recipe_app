import 'package:food_app/src/imports/core_imports.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    Widget current = _buildMaterialApp(context);

    current = ScreenUtilWrapper(child: current);

    return current;
  }

  Widget _buildMaterialApp(BuildContext context) {
    debugPrint('[App] building MaterialApp with deep-orange theme');
    return MaterialApp.router(
      title: 'Bite & Time',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(primaryColorHex: '#EA580C'),
      darkTheme: buildDarkTheme(primaryColorHex: '#EA580C'),
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      builder: (context, child) {
        Widget current = child!;
        current = SkeletonWrapper(child: current);
        debugPrint('[App] route shell ready without auth gate');
        return current;
      },
    );
  }
}