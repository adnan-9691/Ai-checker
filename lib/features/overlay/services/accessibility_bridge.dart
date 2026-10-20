import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_accessibility_service/accessibility_event.dart';
import 'package:flutter_accessibility_service/constants.dart';
import 'package:flutter_accessibility_service/flutter_accessibility_service.dart';

/// Bridge managing accessibility events from [FlutterAccessibilityService].
/// Keeps track of the most recently focused input field and injects text back into third-party apps.
class AccessibilityBridge {
  static final AccessibilityBridge _instance = AccessibilityBridge._internal();
  factory AccessibilityBridge() => _instance;
  AccessibilityBridge._internal();

  StreamSubscription<AccessibilityEvent>? _subscription;

  /// Holds the most recently focused or edited accessibility event
  AccessibilityEvent? _lastEvent;

  /// The text currently present in the focused input field
  String? _currentText;

  /// Current text captured from the focused input field
  String? get currentText => _currentText;

  /// The latest captured event
  AccessibilityEvent? get lastEvent => _lastEvent;

  /// Starts listening to accessibility events.
  void startListening() {
    if (_subscription != null) return;

    try {
      _subscription = FlutterAccessibilityService.accessStream.listen(
        (event) {
          // Track when a view gets focus or text is updated in an editable field
          final isEditable = event.isEditable ?? false;
          final isFocused = event.isFocused ?? false;
          final capturedText = event.text;

          debugPrint('AccessibilityBridge event: text="$capturedText", editable=$isEditable, focused=$isFocused, pkg=${event.packageName}, subNodes=${event.subNodes?.length ?? 0}');

          // Detect clicks on accessibility buttons (including the Flutter icon shortcut button)
          if (event.eventType == EventType.typeViewClicked || event.actionType == NodeAction.actionClick) {
            debugPrint('>>> [BUTTON CLICK] Click event detected on view: nodeId="${event.nodeId}", pkg="${event.packageName}", text="${event.text}"');
            if (event.packageName == 'com.android.systemui' || event.packageName?.contains('ai_checker') == true) {
              debugPrint('>>> [FLUTTER SHORTCUT LOGO CLICKED] User tapped the system accessibility shortcut button!');
            }
          }

          // 1. Direct match on root node
          if ((isEditable || isFocused) && capturedText != null && capturedText.isNotEmpty && capturedText != 'null') {
            _lastEvent = event;
            _currentText = capturedText;
            debugPrint('AccessibilityBridge -> Captured text directly: "$_currentText"');
            return;
          }

          // 2. Check child/sub-nodes for editable input elements (e.g. messaging, WhatsApp, notes)
          if (event.subNodes != null && event.subNodes!.isNotEmpty) {
            for (final sub in event.subNodes!) {
              final rawSubText = sub.text;
              if (rawSubText != null && rawSubText != 'null' && rawSubText.trim().isNotEmpty) {
                final subText = rawSubText.trim();
                debugPrint('AccessibilityBridge subNode: text="$subText", isEditable=${sub.isEditable}, isFocused=${sub.isFocused}, nodeId=${sub.nodeId}');

                final isEditable = sub.isEditable ?? false;
                final isFocused = sub.isFocused ?? false;
                
                // Prioritize editable/focused input fields, or ignore keyboard key labels
                if (isEditable || isFocused || sub.actions?.contains(NodeAction.actionSetText) == true) {
                  _lastEvent = sub;
                  _currentText = subText;
                  debugPrint('AccessibilityBridge -> Captured editable text: "$_currentText" (mapId: ${sub.mapId})');
                  return;
                } else if (_currentText == null || _currentText!.isEmpty) {
                  _lastEvent = sub;
                  _currentText = subText;
                  debugPrint('AccessibilityBridge -> Stored potential candidate text: "$_currentText"');
                }
              }
            }
          }

          // 3. Fallback: if there's any valid capturedText in an active window
          if (capturedText != null && capturedText.isNotEmpty && capturedText != 'null' && capturedText != '1:50') {
            _lastEvent = event;
            _currentText = capturedText;
            debugPrint('AccessibilityBridge -> Fallback captured text: "$_currentText"');
          }
        },
        onError: (err) {
          debugPrint('AccessibilityBridge stream error: $err');
        },
      );
    } catch (e) {
      debugPrint('AccessibilityBridge failed to start listening: $e');
    }
  }

  /// Stops listening to accessibility events.
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Injects [newText] into the currently tracked input node using NodeAction.actionSetText.
  Future<bool> injectText(String newText) async {
    final event = _lastEvent;
    if (event == null) {
      debugPrint('AccessibilityBridge: No active input node tracked to inject text.');
      return false;
    }

    try {
      final success = await FlutterAccessibilityService.performAction(
        event,
        NodeAction.actionSetText,
        newText,
      );

      if (success) {
        _currentText = newText;
        debugPrint('AccessibilityBridge: Successfully injected text.');
      } else {
        debugPrint('AccessibilityBridge: performAction returned false.');
      }
      return success;
    } catch (e) {
      debugPrint('AccessibilityBridge error injecting text: $e');
      return false;
    }
  }
}
