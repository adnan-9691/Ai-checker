import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:ai_checker/core/services/permission_service.dart';
import 'package:ai_checker/features/overlay/services/overlay_service.dart';
import '../widgets/grammar_text_controller.dart';


/// Provider managing state for text editing, permission statuses,
/// and global overlay trigger settings.
class EditorProvider extends ChangeNotifier {
  final PermissionService _permissionService;
  final OverlayService _overlayService;

  StreamSubscription<AccessibilityTextEvent>? _textEventsSub;

  bool _isOverlayPermissionGranted = false;
  bool _isAccessibilityEnabled = false;
  bool _isGlobalOverlayEnabled = true;
  String _currentExtractedText = '';
  String _currentActivePackage = '';

  EditorProvider({
    PermissionService? permissionService,
    OverlayService? overlayService,
  })  : _permissionService = permissionService ?? PermissionService(),
        _overlayService = overlayService ?? OverlayService() {
    _init();
  }

  bool get isOverlayPermissionGranted => _isOverlayPermissionGranted;
  bool get isAccessibilityEnabled => _isAccessibilityEnabled;
  bool get isGlobalOverlayEnabled => _isGlobalOverlayEnabled;
  bool get hasAllPermissions => _isOverlayPermissionGranted && _isAccessibilityEnabled;
  String get currentExtractedText => _currentExtractedText;
  String get currentActivePackage => _currentActivePackage;

  Future<void> _init() async {
    await checkPermissions();
    _startListeningToAccessibility();
  }

  /// Refreshes the status of system permissions.
  Future<void> checkPermissions() async {
    _isOverlayPermissionGranted =
        await _permissionService.isOverlayPermissionGranted();
    _isAccessibilityEnabled =
        await _permissionService.isAccessibilityServiceEnabled();
    notifyListeners();
  }

  /// Request the system alert window permission.
  Future<bool> requestOverlayPermission() async {
    final granted = await _permissionService.requestOverlayPermission();
    _isOverlayPermissionGranted = granted;
    notifyListeners();
    return granted;
  }

  /// Open Android accessibility settings so user can toggle our service.
  Future<void> openAccessibilitySettings() async {
    await _permissionService.openAccessibilitySettings();
  }

  /// Toggle user preference for the global floating overlay.
  Future<void> setGlobalOverlayEnabled(bool enabled) async {
    _isGlobalOverlayEnabled = enabled;
    if (!enabled) {
      await _overlayService.hideFloatingLogo();
    }
    notifyListeners();
  }

  /// Listen to accessibility stream from Android native service.
  void _startListeningToAccessibility() {
    _textEventsSub?.cancel();
    _textEventsSub = _permissionService.textEventsStream.listen(
      (event) async {
        _currentExtractedText = event.text;
        _currentActivePackage = event.packageName;
        notifyListeners();

        // If user has enabled global overlay and an input field is focused
        if (_isGlobalOverlayEnabled && _isOverlayPermissionGranted) {
          if (event.isFocused) {
            await _overlayService.showFloatingLogo();
          } else {
            // Optional delay before hiding
            await Future.delayed(const Duration(seconds: 1));
            await _overlayService.hideFloatingLogo();
          }
        }
      },
      onError: (err) {
        debugPrint('Accessibility event stream error: $err');
      },
    );
  }

  /// Demonstrates grammar highlights by inserting mock errors into the controller.
  void injectSampleErrors(GrammarTextEditingController controller) {
    final text = controller.text;
    if (text.isEmpty) {
      if (controller.errors.isNotEmpty) {
        controller.clearErrors();
        notifyListeners();
      }
      return;
    }

    // Check for common words to illustrate squiggly underlines
    final sampleErrors = <GrammarError>[];

    final words = ['teh', 'thier', 'alot', 'dont', 'definately', 'recieve'];
    for (final word in words) {
      final index = text.toLowerCase().indexOf(word);
      if (index != -1) {
        sampleErrors.add(
          GrammarError(
            start: index,
            end: index + word.length,
            originalText: text.substring(index, index + word.length),
            suggestions: ['the', 'their', 'a lot', "don't", 'definitely', 'receive'],
            explanation: 'Possible spelling or typographical error.',
            type: GrammarErrorType.spelling,
          ),
        );
      }
    }

    // Only update if count or positions changed to prevent cyclic notifications
    if (controller.errors.length != sampleErrors.length) {
      controller.setErrorsSilently(sampleErrors);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _textEventsSub?.cancel();
    super.dispose();
  }
}

