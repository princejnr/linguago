import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_theme.dart';
import '../data/models/call_session.dart';
import '../viewmodel/call_assistant_viewmodel.dart';

class CallAssistantSettingsView extends ConsumerWidget {
  const CallAssistantSettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(callAssistantViewModelProvider);
    final vm = ref.read(callAssistantViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Call Assistant'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Header Card ──────────────────────────────────────────────────
          Card(
            color: AppColors.primaryPurple.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.phone_in_talk, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Live Call Subtitles',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryPurple,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Answer incoming calls on Speakerphone. A floating subtitle card will transcribe and translate French speech to English in real time, and let you speak back with quick French voice replies.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textGray,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Main Activation Switch ───────────────────────────────────────
          Card(
            child: SwitchListTile(
              activeThumbColor: AppColors.primaryPurple,
              title: const Text(
                'Enable Call Assistant',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              subtitle: Text(
                state.isEnabled
                    ? 'Monitoring phone calls automatically'
                    : 'Turn on to show floating translation on calls',
                style: const TextStyle(fontSize: 13),
              ),
              value: state.isEnabled,
              onChanged: vm.toggleEnabled,
            ),
          ),
          const SizedBox(height: 20),

          // ── Required Permissions ─────────────────────────────────────────
          const Text(
            'REQUIRED ANDROID PERMISSIONS',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: AppColors.textGray,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _PermissionTile(
                  icon: Icons.phone_android,
                  title: 'Detect Incoming Calls',
                  subtitle: 'READ_PHONE_STATE permission',
                  isGranted: state.hasPhonePermission,
                  onGrant: vm.requestPhonePermission,
                ),
                const Divider(height: 1, indent: 56),
                _PermissionTile(
                  icon: Icons.layers_outlined,
                  title: 'Display Over Other Apps',
                  subtitle: 'SYSTEM_ALERT_WINDOW permission',
                  isGranted: state.hasOverlayPermission,
                  onGrant: vm.requestOverlayPermission,
                ),
                const Divider(height: 1, indent: 56),
                _PermissionTile(
                  icon: Icons.mic_none,
                  title: 'Speakerphone Audio Capture',
                  subtitle: 'RECORD_AUDIO permission',
                  isGranted: state.hasMicPermission,
                  onGrant: vm.requestMicPermission,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Live Status ──────────────────────────────────────────────────
          const Text(
            'LIVE TELEPHONY STATUS',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: AppColors.textGray,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    state.callStatus == CallStatus.active
                        ? Icons.call
                        : state.callStatus == CallStatus.incoming
                            ? Icons.ring_volume
                            : Icons.phone_disabled,
                    color: state.callStatus == CallStatus.active
                        ? AppColors.accentGreen
                        : AppColors.textGray,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Call State: ${state.callStatus.name.toUpperCase()}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Overlay: ${state.isOverlayVisible ? "Visible" : "Hidden"}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textGray),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Testing & Simulation Tools ───────────────────────────────────
          const Text(
            'TESTING & SIMULATION',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: AppColors.textGray,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Test the floating window without needing an incoming phone call:',
                    style: TextStyle(fontSize: 13, color: AppColors.textGray),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.open_in_new, size: 18),
                          label: const Text('Open Overlay'),
                          onPressed: () => vm.simulateCallStatus(CallStatus.active),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Close Overlay'),
                          onPressed: vm.closeOverlay,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.subtitles, size: 18),
                      label: const Text('Send Sample Subtitle'),
                      onPressed: () {
                        vm.sendSampleSubtitle(
                          transcription: 'Allô patron, je suis au carrefour.',
                          translation: 'Hello boss, I am at the crossroads.',
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isGranted,
    required this.onGrant,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isGranted;
  final VoidCallback onGrant;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryPurple),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: isGranted
          ? const Chip(
              label: Text('Granted', style: TextStyle(fontSize: 11, color: Colors.white)),
              backgroundColor: AppColors.accentGreen,
              visualDensity: VisualDensity.compact,
            )
          : TextButton(
              onPressed: onGrant,
              child: const Text('Grant'),
            ),
    );
  }
}
