import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_router.dart';
import '../../../core/widgets/flag_circle.dart';
import '../../translation/data/models/language.dart';
import '../../translation/viewmodel/translation_viewmodel.dart';
import 'home_menu_sheet.dart';
import 'language_search_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // ── Top bar ──────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _CircleIconButton(
                  icon: Icons.grid_view_rounded,
                  onTap: () => HomeMenuSheet.show(context),
                ),
                _CircleIconButton(
                  icon: Icons.search_rounded,
                  onTap: () => LanguageSearchSheet.show(context),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Searched languages ────────────────────────────────────────
            Text(
              'Popular Translations',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            _PopularLanguagesRow(),

            const SizedBox(height: 20),

            // ── Feature cards row ─────────────────────────────────────────
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Purple card
                  Expanded(
                    child: _FeatureCard(
                      color: const Color(0xFF7B61FF),
                      label: 'Translate\nEvery\nWord',
                      labelColor: Colors.white,
                      onTap: () => Navigator.of(context).pushNamed(
                        AppRoutes.translator,
                        arguments: true, // open with keyboard focused
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Call Assistant feature card
                  Expanded(
                    child: _FeatureCard(
                      color: const Color(0xFF1E1B4B),
                      label: 'Call\nAssistant\nLive FR',
                      labelColor: Colors.white,
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.callAssistant),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Voice Translation card ────────────────────────────────────
            _VoiceTranslationCard(
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRoutes.translator),
            ),

            const SizedBox(height: 24),

            // ── Recommended ───────────────────────────────────────────────
            Text(
              'Recommended',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            // English → French leads because it is the only pair verified
            // end to end on real hardware; the rest are common travel and
            // business directions.
            for (final pair in const [
              (SupportedLanguages.english, SupportedLanguages.french),
              (SupportedLanguages.english, SupportedLanguages.spanish),
              (SupportedLanguages.english, SupportedLanguages.german),
              (SupportedLanguages.english, SupportedLanguages.japanese),
              (SupportedLanguages.french, SupportedLanguages.english),
              (SupportedLanguages.spanish, SupportedLanguages.english),
              (SupportedLanguages.english, SupportedLanguages.arabic),
              (SupportedLanguages.english, SupportedLanguages.chinese),
            ]) ...[
              _RecommendedCard(from: pair.$1, to: pair.$2),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Reusable sub-widgets ──────────────────────────────────────────────────────

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 22, color: Colors.black87),
      ),
    );
  }
}

/// Horizontally-scrolling row of popular world language flags.
///
/// Always visible — these are curated popular languages, not dynamic.
class _PopularLanguagesRow extends StatelessWidget {
  const _PopularLanguagesRow();

  /// Eight of the most-translated world languages, drawn from
  /// [SupportedLanguages] rather than a parallel list — so a flag or name
  /// changed there can't drift out of sync with what this row shows.
  static final _languages = <Language>[
    SupportedLanguages.english,
    SupportedLanguages.french,
    SupportedLanguages.spanish,
    SupportedLanguages.german,
    SupportedLanguages.japanese,
    SupportedLanguages.chinese,
    SupportedLanguages.arabic,
    SupportedLanguages.portuguese,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _languages.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) => _LanguageTile(language: _languages[i]),
      ),
    );
  }
}

/// A flag circle with the language name beneath it. Tapping sets it as the
/// target language and opens the translator.
class _LanguageTile extends ConsumerWidget {
  const _LanguageTile({required this.language});

  final Language language;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        final viewModel = ref.read(translationViewModelProvider.notifier);
        final current = ref.read(translationViewModelProvider);

        // Tapping the language you're already speaking means you want it as
        // the source, so flip the pair rather than ignoring the tap.
        if (language.code == current.sourceLanguage.code) {
          viewModel.swapLanguages();
        } else {
          viewModel.setTargetLanguage(language);
        }
        Navigator.of(context).pushNamed(AppRoutes.translator);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(2),
            child: FlagCircle(language: language, size: 48),
          ),
          const SizedBox(height: 4),
          Text(
            language.displayName,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.color,
    required this.label,
    required this.labelColor,
    required this.onTap,
  });

  final Color color;
  final String label;
  final Color labelColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.sizeOf(context).width * 0.45,
        height: MediaQuery.sizeOf(context).width * 0.50,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(
          children: [
            // Label — top-left
            Positioned(
              top: 18,
              left: 18,
              right: 18,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: labelColor,
                  height: 1.3,
                ),
              ),
            ),
            // Arrow button — bottom-right corner
            Positioned(
              bottom: 14,
              right: 14,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.arrow_outward_rounded,
                  color: labelColor == Colors.white
                      ? Colors.white
                      : Colors.yellow,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceTranslationCard extends StatelessWidget {
  const _VoiceTranslationCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF00D26A),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Voice\nTranslation',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _Waveform(),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Waveform extends StatelessWidget {
  const _Waveform();

  @override
  Widget build(BuildContext context) {
    const heights = [
      18.0,
      30.0,
      22.0,
      38.0,
      28.0,
      42.0,
      32.0,
      24.0,
      36.0,
      20.0,
      28.0,
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: heights
          .map(
            (h) => Container(
              width: 4,
              height: h,
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _RecommendedCard extends ConsumerWidget {
  const _RecommendedCard({required this.from, required this.to});

  final Language from;
  final Language to;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        // Set both halves, not just the target — a recommendation is a
        // direction, and honouring half of it would translate the wrong way
        // round.
        ref.read(translationViewModelProvider.notifier)
            .setLanguagePair(source: from, target: to);
        Navigator.of(context).pushNamed(AppRoutes.translator);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            // Overlapping flag pair, reading left-to-right as source → target.
            SizedBox(
              width: 64,
              height: 44,
              child: Stack(
                children: [
                  FlagCircle(language: from, size: 44),
                  Positioned(
                    left: 22,
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      padding: const EdgeInsets.all(2),
                      child: FlagCircle(language: to, size: 40),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${from.displayName} to ${to.displayName}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }
}
