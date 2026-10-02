import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Overridden in `main()` with the instance loaded before the app starts.
///
/// Resolving it up front rather than asynchronously inside the widget tree is
/// what lets the first frame land on the right screen — a returning user never
/// sees Get Started flash by before being redirected away from it.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw StateError(
    'sharedPreferencesProvider must be overridden in main() with the '
    'instance from SharedPreferences.getInstance().',
  );
});

final appPreferencesProvider = Provider<AppPreferences>((ref) {
  return AppPreferences(ref.watch(sharedPreferencesProvider));
});

/// Small, local, on-device key/value storage. Nothing here leaves the phone,
/// and nothing here is speech content (PRD §23).
class AppPreferences {
  AppPreferences(this._prefs);

  final SharedPreferences _prefs;

  static const _kHasSeenGetStarted = 'has_seen_get_started';
  static const _kAutoPlaySpeech = 'auto_play_translated_speech';
  static const _kSourceLanguage = 'preferred_source_language';
  static const _kTargetLanguage = 'preferred_target_language';

  bool get hasSeenGetStarted => _prefs.getBool(_kHasSeenGetStarted) ?? false;

  Future<void> setHasSeenGetStarted(bool value) =>
      _prefs.setBool(_kHasSeenGetStarted, value);

  bool get autoPlayTranslatedSpeech => _prefs.getBool(_kAutoPlaySpeech) ?? true;

  Future<void> setAutoPlayTranslatedSpeech(bool value) =>
      _prefs.setBool(_kAutoPlaySpeech, value);

  static const _kCallAssistantEnabled = 'call_assistant_enabled';
  static const _kWhatsAppEnabled = 'whatsapp_call_assistant_enabled';
  static const _kTeamsEnabled = 'teams_call_assistant_enabled';

  bool get isCallAssistantEnabled => _prefs.getBool(_kCallAssistantEnabled) ?? false;

  Future<void> setCallAssistantEnabled(bool value) =>
      _prefs.setBool(_kCallAssistantEnabled, value);

  bool get isWhatsAppEnabled => _prefs.getBool(_kWhatsAppEnabled) ?? true;

  Future<void> setWhatsAppEnabled(bool value) =>
      _prefs.setBool(_kWhatsAppEnabled, value);

  bool get isTeamsEnabled => _prefs.getBool(_kTeamsEnabled) ?? true;

  Future<void> setTeamsEnabled(bool value) =>
      _prefs.setBool(_kTeamsEnabled, value);

  String get sourceLanguageCode => _prefs.getString(_kSourceLanguage) ?? 'en';

  String get targetLanguageCode => _prefs.getString(_kTargetLanguage) ?? 'fr';

  Future<void> setLanguagePair({required String source, required String target}) async {
    await _prefs.setString(_kSourceLanguage, source);
    await _prefs.setString(_kTargetLanguage, target);
  }

  // ── Recent languages ────────────────────────────────────────────────────────

  static const _kRecentLanguages = 'recent_language_codes';

  /// Maximum number of codes kept. Oldest entries are evicted once the list
  /// would exceed this, so the row never grows unbounded.
  static const int maxRecent = 8;

  /// Ordered list of recently-used target language codes, most-recent first.
  List<String> get recentLanguageCodes =>
      _prefs.getStringList(_kRecentLanguages) ?? [];

  /// Prepends [code] to the list, de-duplicates, and trims to [maxRecent].
  Future<void> addRecentLanguage(String code) async {
    final updated = [
      code,
      ...recentLanguageCodes.where((c) => c != code),
    ].take(maxRecent).toList();
    await _prefs.setStringList(_kRecentLanguages, updated);
  }
}
