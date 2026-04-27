import 'package:flutter/material.dart';

import '../views/auth/login_view.dart';
import '../views/auth/register_view.dart';
import '../views/home/home_view.dart';
import '../views/schedule/schedule_form_view.dart';
import '../views/notes/note_form_view.dart';
import '../views/splash/splash_view.dart';
import '../views/widgets/auth_guard.dart';
import '../models/schedule_model.dart';
import '../models/note_model.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String scheduleForm = '/schedule-form';
  static const String noteForm = '/note-form';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashView());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginView());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterView());
      case home:
        return MaterialPageRoute(builder: (_) => const AuthGuard(child: HomeView()));
      case scheduleForm:
        final args = settings.arguments as ScheduleModel?;
        return MaterialPageRoute(
          builder: (_) => ScheduleFormView(schedule: args),
        );
      case noteForm:
        final args = settings.arguments as NoteModel?;
        return MaterialPageRoute(
          builder: (_) => NoteFormView(note: args),
        );
      default:
        return MaterialPageRoute(builder: (_) => const LoginView());
    }
  }
}
