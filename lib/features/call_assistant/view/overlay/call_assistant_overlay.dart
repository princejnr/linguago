import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

/// The entry-point widget rendered inside the Android floating overlay window.
/// Runs in a lightweight secondary Flutter engine so it never blocks the main app.
class CallAssistantOverlay extends StatefulWidget {
  const CallAssistantOverlay({super.key});

  @override
  State<CallAssistantOverlay> createState() => _CallAssistantOverlayState();
}

class _CallAssistantOverlayState extends State<CallAssistantOverlay> {
  String _transcription = 'Listening for French speech…';
  String _translation = 'En attente de parole…';
  String _app = 'cellular'; // 'cellular', 'whatsapp', 'teams'
  bool _isCollapsed = false;
  String? _speakingReply;

  // WhatsApp quick replies (tailored for delivery drivers, Yango, errands)
  static const _whatsappReplies = [
    _QuickReplyItem(
      label: 'Where are you?',
      frenchPhrase: 'Allô, vous êtes où exactement ?',
      icon: Icons.location_on_outlined,
    ),
    _QuickReplyItem(
      label: "I'm coming down",
      frenchPhrase: "J'arrive tout de suite, je descends.",
      icon: Icons.directions_walk,
    ),
    _QuickReplyItem(
      label: 'Outside the gate',
      frenchPhrase: 'Je suis dehors devant le portail.',
      icon: Icons.door_front_door_outlined,
    ),
    _QuickReplyItem(
      label: 'Sending location',
      frenchPhrase: 'Je vous envoie ma position sur WhatsApp.',
      icon: Icons.send_and_archive_outlined,
    ),
    _QuickReplyItem(
      label: 'Wait 2 minutes',
      frenchPhrase: 'Attendez deux minutes s’il vous plaît.',
      icon: Icons.timer_outlined,
    ),
    _QuickReplyItem(
      label: 'Repeat slowly',
      frenchPhrase: 'Pouvez-vous répéter plus lentement s’il vous plaît ?',
      icon: Icons.replay,
    ),
  ];

  // Teams quick replies (tailored for remote standups, colleagues, audio checks)
  static const _teamsReplies = [
    _QuickReplyItem(
      label: 'Repeat that?',
      frenchPhrase: 'Pouvez-vous répéter cette phrase s’il vous plaît ?',
      icon: Icons.replay,
    ),
    _QuickReplyItem(
      label: 'Mic issue',
      frenchPhrase: 'Désolé, problème de micro un instant.',
      icon: Icons.mic_off_outlined,
    ),
    _QuickReplyItem(
      label: 'I agree',
      frenchPhrase: 'Je suis tout à fait d’accord avec ce point.',
      icon: Icons.thumb_up_alt_outlined,
    ),
    _QuickReplyItem(
      label: 'Audio breaking up',
      frenchPhrase: 'Votre voix coupe un peu, vous m’entendez ?',
      icon: Icons.network_check_outlined,
    ),
    _QuickReplyItem(
      label: 'Taking note',
      frenchPhrase: 'Bien noté, je m’en occupe tout de suite.',
      icon: Icons.edit_note,
    ),
    _QuickReplyItem(
      label: 'Thank you',
      frenchPhrase: 'Très clair, merci beaucoup.',
      icon: Icons.check_circle_outline,
    ),
  ];

  // Cellular / Standard quick replies
  static const _cellularReplies = [
    _QuickReplyItem(
      label: "I'm coming down",
      frenchPhrase: "J'arrive tout de suite, je descends.",
      icon: Icons.directions_walk,
    ),
    _QuickReplyItem(
      label: 'Wait 2 minutes',
      frenchPhrase: 'Attendez deux minutes s’il vous plaît.',
      icon: Icons.timer_outlined,
    ),
    _QuickReplyItem(
      label: 'I am outside',
      frenchPhrase: 'Je suis dehors devant le portail.',
      icon: Icons.door_front_door_outlined,
    ),
    _QuickReplyItem(
      label: 'Repeat slowly',
      frenchPhrase: 'Pouvez-vous répéter plus lentement s’il vous plaît ?',
      icon: Icons.replay,
    ),
  ];

  List<_QuickReplyItem> get _currentReplies {
    switch (_app.toLowerCase()) {
      case 'whatsapp':
        return _whatsappReplies;
      case 'teams':
        return _teamsReplies;
      default:
        return _cellularReplies;
    }
  }

  Color get _accentColor {
    switch (_app.toLowerCase()) {
      case 'whatsapp':
        return const Color(0xFF25D366); // WhatsApp Green
      case 'teams':
        return const Color(0xFF505AC9); // Teams Indigo/Purple
      default:
        return const Color(0xFF7C3AED); // Linguago Primary Violet
    }
  }

  String get _appBadgeTitle {
    switch (_app.toLowerCase()) {
      case 'whatsapp':
        return '🟢 WHATSAPP LIVE';
      case 'teams':
        return '🟣 TEAMS LIVE';
      default:
        return '📞 CALL LIVE';
    }
  }

  @override
  void initState() {
    super.initState();
    FlutterOverlayWindow.overlayListener.listen((data) {
      if (data is Map) {
        if (data['type'] == 'subtitle') {
          setState(() {
            _transcription = data['transcription'] as String? ?? '';
            _translation = data['translation'] as String? ?? '';
            if (data['app'] != null) {
              _app = data['app'] as String;
            }
          });
        } else if (data['type'] == 'app_context') {
          setState(() {
            if (data['app'] != null) {
              _app = data['app'] as String;
            }
          });
        }
      }
    });
  }

  Future<void> _setCollapsed(bool collapsed) async {
    setState(() => _isCollapsed = collapsed);
    if (collapsed) {
      await FlutterOverlayWindow.resizeOverlay(WindowSize.matchParent, 160, true);
    } else {
      await FlutterOverlayWindow.resizeOverlay(WindowSize.matchParent, 780, true);
    }
  }

  void _sendQuickReply(_QuickReplyItem item) {
    setState(() {
      _speakingReply = item.label;
    });
    FlutterOverlayWindow.shareData({
      'type': 'quick_reply',
      'phrase': item.frenchPhrase,
      'label': item.label,
      'app': _app,
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _speakingReply == item.label) {
        setState(() {
          _speakingReply = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.96), // Deep Slate Glass
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(
                color: _accentColor.withValues(alpha: 0.55),
                width: 1.5,
              ),
            ),
            child: _isCollapsed ? _buildCollapsedBar() : _buildFullCard(),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _accentColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _appBadgeTitle,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.expand_more, color: Colors.white70, size: 20),
            onPressed: () => _setCollapsed(false),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70, size: 20),
            onPressed: () => FlutterOverlayWindow.closeOverlay(),
          ),
        ],
      ),
    );
  }

  Widget _buildFullCard() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Bar ──────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: _accentColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.translate, color: Colors.white, size: 14),
                      const SizedBox(width: 5),
                      Text(
                        _appBadgeTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_speakingReply != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF10B981), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.volume_up, color: Color(0xFF10B981), size: 12),
                        const SizedBox(width: 4),
                        Text(
                          'Speaking: $_speakingReply',
                          style: const TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.expand_less, color: Colors.white70, size: 20),
                  onPressed: () => _setCollapsed(true),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                  onPressed: () => FlutterOverlayWindow.closeOverlay(),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Subtitle Card ───────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Caller's speech (French)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🇫🇷 ', style: TextStyle(fontSize: 14)),
                      Expanded(
                        child: Text(
                          _transcription,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 8),
                  // Translated subtitle (English)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🇬🇧 ', style: TextStyle(fontSize: 14)),
                      Expanded(
                        child: Text(
                          _translation,
                          style: const TextStyle(
                            color: Color(0xFF34D399), // Emerald translation
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Quick French Voice Responses ────────────────────────────────
            Row(
              children: [
                Text(
                  'QUICK FRENCH REPLIES (${_app.toUpperCase()})',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                const Text(
                  'TAP TO SPEAK',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _currentReplies.map((item) {
                  final isCurrentlySpeaking = _speakingReply == item.label;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      avatar: Icon(
                        isCurrentlySpeaking ? Icons.volume_up : item.icon,
                        size: 14,
                        color: Colors.white,
                      ),
                      label: Text(
                        item.label,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      backgroundColor: isCurrentlySpeaking
                          ? const Color(0xFF10B981)
                          : _accentColor.withValues(alpha: 0.7),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      onPressed: () => _sendQuickReply(item),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickReplyItem {
  const _QuickReplyItem({
    required this.label,
    required this.frenchPhrase,
    required this.icon,
  });

  final String label;
  final String frenchPhrase;
  final IconData icon;
}
