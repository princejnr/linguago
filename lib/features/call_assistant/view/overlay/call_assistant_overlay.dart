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
  String _transcription = 'Listening for speech…';
  String _translation = 'En attente de parole…';
  bool _isCollapsed = false;

  static const _quickReplies = [
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

  @override
  void initState() {
    super.initState();
    FlutterOverlayWindow.overlayListener.listen((data) {
      if (data is Map) {
        if (data['type'] == 'subtitle') {
          setState(() {
            _transcription = data['transcription'] as String? ?? '';
            _translation = data['translation'] as String? ?? '';
          });
        }
      }
    });
  }

  String? _speakingReply;

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
              color: const Color(0xFF1E1B4B).withValues(alpha: 0.95), // Deep Indigo / Dark Glass
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
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
            decoration: const BoxDecoration(
              color: Color(0xFF10B981), // Accent green dot
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Linguago Live',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.translate, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'FR ➔ EN LIVE',
                        style: TextStyle(
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
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(14),
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
                            color: Color(0xFF10B981), // Green highlight
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
            const Text(
              'QUICK FRENCH REPLIES (TAP TO SPEAK ALOUD)',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _quickReplies.map((item) {
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
                          : const Color(0xFF7C3AED).withValues(alpha: 0.6),
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
