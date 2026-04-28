import 'package:food_app/src/imports/core_imports.dart';
import 'package:food_app/src/imports/packages_imports.dart';
import 'package:food_app/src/ui/auth/bloc/session_bloc.dart';

/// Listens to session above [MaterialApp] routes. Navigation must use [appRouter]
/// because this [context] is not a descendant of [GoRouter].
class SessionListenerWrapper extends StatelessWidget {
  final Widget child;
  const SessionListenerWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocListener<SessionBloc, SessionState>(
      listenWhen: (prev, next) => prev.status != next.status,
      listener: (context, state) {
        if (state.status != SessionStatus.unknown) {
          FlutterNativeSplash.remove();
          if (state.status == SessionStatus.authenticated) {
            debugPrint('[SessionListenerWrapper] appRouter.go home');
            appRouter.go(AppRoutes.home);
          } else if (state.status == SessionStatus.unauthenticated) {
            debugPrint('[SessionListenerWrapper] appRouter.go onboarding');
            appRouter.go(AppRoutes.onboarding);
          }
        }
      },
      child: child,
    );
  }
}
