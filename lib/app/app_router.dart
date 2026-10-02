import 'package:flutter/material.dart';

import '../features/call_assistant/view/call_assistant_settings_view.dart';
import '../features/home/view/home_screen.dart';
import '../features/model_setup/view/model_setup_screen.dart';
import '../features/onboarding/view/get_started_screen.dart';
import '../features/settings/view/privacy_screen.dart';
import '../features/settings/view/settings_screen.dart';
import '../features/translation/view/translation_screen.dart';

/// Route names. Kept as plain named routes (no router package) — the app has
/// only a handful of screens, so `Navigator` is all it needs.
abstract final class AppRoutes {
  static const getStarted = '/';
  static const modelSetup = '/model-setup';
  static const home = '/home';
  static const translator = '/translator';
  static const settings = '/settings';
  static const privacy = '/privacy';
  static const callAssistant = '/call-assistant';
}

class AppRouter {
  const AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.modelSetup:
        return MaterialPageRoute(builder: (_) => const ModelSetupScreen());
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case AppRoutes.translator:
        final startWithKeyboard = settings.arguments as bool? ?? false;
        return MaterialPageRoute(
          builder: (_) => TranslationScreen(startWithKeyboard: startWithKeyboard),
        );
      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case AppRoutes.privacy:
        return MaterialPageRoute(builder: (_) => const PrivacyScreen());
      case AppRoutes.callAssistant:
        return MaterialPageRoute(builder: (_) => const CallAssistantSettingsView());
      case AppRoutes.getStarted:
      default:
        return MaterialPageRoute(builder: (_) => const GetStartedScreen());
    }
  }
}
