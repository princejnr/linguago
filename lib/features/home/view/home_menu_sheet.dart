import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_router.dart';
import '../../../app/app_theme.dart';
import '../../translation/viewmodel/translation_viewmodel.dart';

/// The grid button's menu: the app's few destinations in one place, plus a
/// plain answer to "is the model ready?" — the question most likely to be on
/// someone's mind after a 2.6 GB download.
class HomeMenuSheet extends ConsumerWidget {
  const HomeMenuSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const HomeMenuSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isModelReady = ref.watch(
      translationViewModelProvider.select((s) => s.isModelReady),
    );

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.backgroundGray,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.mic_none_rounded),
            title: const Text('Translate'),
            subtitle: const Text('Speak or type a phrase'),
            onTap: () => Navigator.of(context)
              ..pop()
              ..pushNamed(AppRoutes.translator),
          ),
          ListTile(
            leading: const Icon(Icons.phone_in_talk_outlined, color: AppColors.primaryPurple),
            title: const Text('Call Assistant'),
            subtitle: const Text('Live French call subtitles & overlay'),
            onTap: () => Navigator.of(context)
              ..pop()
              ..pushNamed(AppRoutes.callAssistant),
          ),
          ListTile(
            leading: Icon(
              isModelReady ? Icons.check_circle : Icons.hourglass_bottom,
              color: isModelReady ? AppColors.accentGreen : AppColors.highlightYellow,
            ),
            title: Text(
              isModelReady ? 'Offline model ready' : 'Preparing offline model…',
            ),
            subtitle: const Text('Translation runs entirely on this device'),
          ),
          const Divider(height: 8),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () => Navigator.of(context)
              ..pop()
              ..pushNamed(AppRoutes.settings),
          ),
        ],
      ),
    );
  }
}
