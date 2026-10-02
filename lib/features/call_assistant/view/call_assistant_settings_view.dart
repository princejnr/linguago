import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_theme.dart';
import '../data/models/call_session.dart';
import '../data/models/voip_session.dart';
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
                          'Answer calls on Speakerphone (Phone, WhatsApp, or Microsoft Teams). A floating subtitle card will transcribe and translate French speech to English in real time, and let you speak back with quick French voice replies.',
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
                    ? 'Monitoring calls & VoIP audio automatically'
                    : 'Turn on to show floating translation during calls',
                style: const TextStyle(fontSize: 13),
              ),
              value: state.isEnabled,
              onChanged: vm.toggleEnabled,
            ),
          ),
          const SizedBox(height: 20),

          // ── Supported Apps & Integrations ────────────────────────────────
          const Text(
            'SUPPORTED APPS & INTEGRATIONS',
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
                SwitchListTile(
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.chat_bubble_outline, color: Color(0xFF25D366), size: 22),
                  ),
                  title: const Text(
                    'WhatsApp Calls',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                  ),
                  subtitle: const Text(
                    'Deliveries, Yango drivers, vendors & personal calls',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: state.isWhatsAppEnabled,
                  onChanged: vm.toggleWhatsAppEnabled,
                  activeThumbColor: const Color(0xFF25D366),
                ),
                const Divider(height: 1, indent: 56),
                SwitchListTile(
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF505AC9).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.groups_outlined, color: Color(0xFF505AC9), size: 22),
                  ),
                  title: const Text(
                    'Microsoft Teams Calls',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                  ),
                  subtitle: const Text(
                    'Remote work, standups & team meetings',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: state.isTeamsEnabled,
                  onChanged: vm.toggleTeamsEnabled,
                  activeThumbColor: const Color(0xFF505AC9),
                ),
              ],
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
            'LIVE AUDIO & CALL STATUS',
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        state.isInAnyCall ? Icons.phone_in_talk : Icons.phone_disabled,
                        color: state.isInAnyCall ? AppColors.accentGreen : AppColors.textGray,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.isVoipActive
                                  ? 'Active Call: ${state.activeApp.displayName.toUpperCase()}'
                                  : 'Telephony Call: ${state.callStatus.name.toUpperCase()}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Floating Overlay: ${state.isOverlayVisible ? "Visible" : "Hidden"}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textGray),
                            ),
                          ],
                        ),
                      ),
                      if (state.isInAnyCall)
                        Chip(
                          label: Text(
                            state.activeApp.shortTag,
                            style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: state.activeApp == VoipApp.whatsapp
                              ? const Color(0xFF25D366)
                              : state.activeApp == VoipApp.teams
                                  ? const Color(0xFF505AC9)
                                  : AppColors.primaryPurple,
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
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
                    'Simulate incoming calls from WhatsApp, Teams, or Cellular to inspect floating overlay styling and quick replies:',
                    style: TextStyle(fontSize: 13, color: AppColors.textGray),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.chat_bubble, size: 16),
                          label: const Text('WhatsApp Call', style: TextStyle(fontSize: 12)),
                          onPressed: () async {
                            await vm.simulateVoipCall(app: VoipApp.whatsapp, active: true);
                            await vm.sendSampleSubtitle(
                              transcription: 'Allô patron, je suis en bas avec votre livraison.',
                              translation: 'Hello boss, I am downstairs with your delivery.',
                              app: VoipApp.whatsapp,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF505AC9),
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.groups, size: 16),
                          label: const Text('Teams Call', style: TextStyle(fontSize: 12)),
                          onPressed: () async {
                            await vm.simulateVoipCall(app: VoipApp.teams, active: true);
                            await vm.sendSampleSubtitle(
                              transcription: 'Bonjour Julius, est-ce que tu peux partager ton écran ?',
                              translation: 'Hello Julius, could you please share your screen?',
                              app: VoipApp.teams,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.call, size: 16),
                          label: const Text('Cellular Call', style: TextStyle(fontSize: 12)),
                          onPressed: () async {
                            await vm.simulateCallStatus(CallStatus.active);
                            await vm.sendSampleSubtitle(
                              transcription: 'Allô patron, je suis au carrefour.',
                              translation: 'Hello boss, I am at the crossroads.',
                              app: VoipApp.cellular,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Close Overlay', style: TextStyle(fontSize: 12)),
                          onPressed: vm.closeOverlay,
                        ),
                      ),
                    ],
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
