import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_accessibility_service/flutter_accessibility_service.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:permission_handler/permission_handler.dart';

/// Models text interaction events received from the global Accessibility Service.
class AccessibilityTextEvent {
  final bool isFocused;
  final String text;
  final String packageName;

  const AccessibilityTextEvent({
    required this.isFocused,
    required this.text,
    required this.packageName,
  });

  factory AccessibilityTextEvent.fromMap(Map<dynamic, dynamic> map) {
    return AccessibilityTextEvent(
      isFocused: map['isFocused'] as bool? ?? false,
      text: map['text'] as String? ?? '',
      packageName: map['packageName'] as String? ?? '',
    );
  }

  @override
  String toString() =>
      'AccessibilityTextEvent(isFocused: $isFocused, text: "$text", package: $packageName)';
}

/// Service managing system overlay and accessibility permissions,
/// as well as streaming accessibility input events.
class PermissionService {
  static const MethodChannel _methodChannel =
      MethodChannel('com.example.ai_checker/a11y_channel');
  static const EventChannel _eventChannel =
      EventChannel('com.example.ai_checker/a11y_events');

  Stream<AccessibilityTextEvent>? _textEventsStream;

  /// Check whether the overlay permission ("Display over other apps") is granted.
  Future<bool> isOverlayPermissionGranted() async {
    try {
      final isGrantedByPlugin = await FlutterOverlayWindow.isPermissionGranted();
      if (isGrantedByPlugin) return true;

      // Fallback check through native MethodChannel
      final bool? isGrantedNative =
          await _methodChannel.invokeMethod<bool>('canDrawOverlays');
      return isGrantedNative ?? false;
    } catch (_) {
      final status = await Permission.systemAlertWindow.status;
      return status.isGranted;
    }
  }

  /// Request the overlay permission, opening system settings if needed.
  Future<bool> requestOverlayPermission() async {
    try {
      final granted = await FlutterOverlayWindow.requestPermission();
      if (granted == true) return true;

      await _methodChannel.invokeMethod('openOverlaySettings');
      return await isOverlayPermissionGranted();
    } catch (_) {
      final status = await Permission.systemAlertWindow.request();
      return status.isGranted;
    }
  }

  /// Check whether our custom Accessibility Service is enabled in Android settings.
  Future<bool> isAccessibilityServiceEnabled() async {
    try {
      final pluginEnabled =
          await FlutterAccessibilityService.isAccessibilityPermissionEnabled();
      if (pluginEnabled) return true;

      final bool? enabled = await _methodChannel
          .invokeMethod<bool>('isAccessibilityServiceEnabled');
      return enabled ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Open the Android Accessibility Settings screen for the user.
  Future<void> openAccessibilitySettings() async {
    try {
      await _methodChannel.invokeMethod('openAccessibilitySettings');
    } catch (e) {
      // Fallback
      await openAppSettings();
    }
  }

  /// Broadcast stream emitting events when editable fields gain/lose focus or text changes.
  Stream<AccessibilityTextEvent> get textEventsStream {
    _textEventsStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((event) => AccessibilityTextEvent.fromMap(event as Map<dynamic, dynamic>));
    return _textEventsStream!;
  }
}
