import 'package:flutter/material.dart';
import '../../services/accessibility_bridge.dart';
import '../../../grammar/services/gemini_grammar_service.dart';

/// Entry-point UI widget for the floating overlay window.
/// Displays an interactive, draggable Grammarly-style floating circular logo.
/// When tapped, it extracts text from the focused third-party input node,
/// sends it to Gemini (gemini-1.5-flash) for grammar correction,
/// and injects the corrected text back into the application.
class FloatingLogoOverlay extends StatefulWidget {
  const FloatingLogoOverlay({super.key});

  @override
  State<FloatingLogoOverlay> createState() => _FloatingLogoOverlayState();
}

class _FloatingLogoOverlayState extends State<FloatingLogoOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  
  final AccessibilityBridge _bridge = AccessibilityBridge();
  late final GeminiGrammarService _geminiService;

  bool _isLoading = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _geminiService = GeminiGrammarService();
    _bridge.startListening();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleFixGrammar() async {
    debugPrint('FloatingLogoOverlay: tapped!');
    if (_isLoading) return;

    final originalText = _bridge.currentText;
    debugPrint('FloatingLogoOverlay: original text is "$originalText"');

    if (originalText == null || originalText.trim().isEmpty) {
      _showFeedback('No text found');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Fixing...';
    });

    try {
      final correctedText = await _geminiService.fixGrammar(originalText);
      debugPrint('FloatingLogoOverlay: corrected text: "$correctedText"');

      if (correctedText != null && correctedText.isNotEmpty) {
        if (correctedText.trim() == originalText.trim()) {
          _showFeedback('Looks good!');
        } else {
          final injected = await _bridge.injectText(correctedText);
          if (injected) {
            _showFeedback('Fixed!');
          } else {
            _showFeedback('Injection failed');
          }
        }
      } else {
        _showFeedback('Check failed');
      }
    } catch (e) {
      debugPrint('Overlay error during grammar fix: $e');
      _showFeedback('Error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showFeedback(String message) {
    if (!mounted) return;
    setState(() {
      _statusMessage = message;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _statusMessage = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final showExpanded = _isLoading || _statusMessage != null;

    return Material(
      color: Colors.transparent,
      child: Center(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => debugPrint('>>> [LOGO CLICK] Floating "G" logo touch down detected!'),
          onTapUp: (_) => debugPrint('>>> [LOGO CLICK] Floating "G" logo touch up detected!'),
          onTapCancel: () => debugPrint('>>> [LOGO CLICK] Floating "G" logo touch cancelled!'),
          onTap: () {
            debugPrint('>>> [LOGO CLICK] Floating "G" logo tapped by user!');
            if (!_isLoading) {
              _handleFixGrammar();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            width: showExpanded ? 140 : 54,
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10A37F), Color(0xFF0D8A6A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(27),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10A37F).withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoading)
                  const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'G',
                        style: TextStyle(
                          color: Color(0xFF10A37F),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'sans-serif',
                        ),
                      ),
                    ),
                  ),
                if (showExpanded) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _statusMessage ?? 'Fixing...',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
