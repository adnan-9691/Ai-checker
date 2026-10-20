import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

/// Service managing the display and lifecycle of the floating overlay window.
class OverlayService {
  bool _isOverlayOpen = false;

  /// Whether the overlay window is currently visible.
  bool get isOverlayOpen => _isOverlayOpen;

  /// Initialize overlay settings and verify visibility status.
  Future<void> init() async {
    _isOverlayOpen = await FlutterOverlayWindow.isActive();
  }

  /// Show the floating logo over other applications.
  Future<bool> showFloatingLogo() async {
    try {
      final isGranted = await FlutterOverlayWindow.isPermissionGranted();
      if (!isGranted) {
        final granted = await FlutterOverlayWindow.requestPermission();
        if (granted != true) return false;
      }

      final isActive = await FlutterOverlayWindow.isActive();
      if (isActive) {
        _isOverlayOpen = true;
        return true;
      }

      await FlutterOverlayWindow.showOverlay(
        enableDrag: true,
        overlayTitle: "AI Writing Assistant",
        overlayContent: "Tap to fix grammar with AI",
        flag: OverlayFlag.defaultFlag,
        alignment: OverlayAlignment.centerRight,
        visibility: NotificationVisibility.visibilityPrivate,
        positionGravity: PositionGravity.auto,
        width: 400,
        height: 160,
      );

      _isOverlayOpen = true;
      return true;
    } catch (e) {
      debugPrint('Error showing overlay: $e');
      return false;
    }
  }

  /// Close / hide the floating overlay window.
  Future<void> hideFloatingLogo() async {
    try {
      final isActive = await FlutterOverlayWindow.isActive();
      if (isActive) {
        await FlutterOverlayWindow.closeOverlay();
      }
      _isOverlayOpen = false;
    } catch (e) {
      debugPrint('Error closing overlay: $e');
    }
  }
}
