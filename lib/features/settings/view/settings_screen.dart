import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_router.dart';
import '../../../app/app_theme.dart';
import '../../translation/viewmodel/translation_viewmodel.dart';
import '../viewmodel/settings_viewmodel.dart';

/// Kept minimal per PRD §25 — no accounts, no cloud settings.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsViewModelProvider);
    final settingsViewModel = ref.read(settingsViewModelProvider.notifier);
    final isModelReady = ref.watch(
      translationViewModelProvider.select((s) => s.isModelReady),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _SectionLabel('Speech'),
          SwitchListTile(
            activeThumbColor: AppColors.primaryPurple,
            title: const Text('Auto-play translated speech'),
            value: settings.autoPlayTranslatedSpeech,
            onChanged: settingsViewModel.setAutoPlay,
          ),
          const Divider(),
          const _SectionLabel('Phone Calls (Côte d\'Ivoire)'),
          ListTile(
            leading: const Icon(Icons.phone_in_talk, color: AppColors.primaryPurple),
            title: const Text('Call Assistant'),
            subtitle: const Text('Live floating subtitles & quick French replies'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.callAssistant),
          ),
          const Divider(),
          const _SectionLabel('Model'),
          ListTile(
            leading: Icon(
              isModelReady ? Icons.check_circle : Icons.hourglass_bottom,
              color: isModelReady ? AppColors.accentGreen : AppColors.highlightYellow,
            ),
            title: Text(isModelReady ? 'On-device model ready' : 'Preparing on-device model…'),
          ),
          const Divider(),
          const _SectionLabel('About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Linguago'),
            subtitle: Text('Offline voice translation. No accounts, no cloud, no chat history.'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy'),
            subtitle: const Text('Audio is processed on-device and never uploaded.'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.privacy),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textGray,
          fontSize: 13,
        ),
      ),
    );
  }
}
