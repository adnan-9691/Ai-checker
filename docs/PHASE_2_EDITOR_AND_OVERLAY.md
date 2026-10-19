# Phase 2: Core Editor & System Overlay Permissions

This document records the exact architectural implementation, native Android bridge, and state flows for **Phase 2: The Core Editor & System Overlay Permissions**.

---

## 1. Overview of Phase 2

Phase 2 builds the core user experience for AI writing assistance:
1. **Background Accessibility Service (`GrammarAccessibilityService` in Kotlin):** Detects user interaction with editable text fields across external apps (e.g., WhatsApp, Chrome, Notes) and streams event payloads (`isFocused`, `text`, `packageName`) to Flutter.
2. **System Alert Window Overlay (`FloatingLogoOverlay`):** Displays a floating, draggable, animated circular "G" logo over any active app when input focus is detected.
3. **In-App Text Editor (`EditorScreen` & `GrammarTextEditingController`):** A distraction-free editing canvas featuring an overridden `buildTextSpan` implementation capable of painting custom wavy squiggly underlines on detected errors.
4. **Permissions Service & State Management (`PermissionService` & `EditorProvider`):** Manages Android permission lifecycles, configuration bottom sheets, and the toggle for global assistant features.

---

## 2. Android Native Architecture & Bridge

### 2.1 Native Components
- **Accessibility Service Class:** `android/app/src/main/kotlin/com/example/ai_checker/GrammarAccessibilityService.kt`
- **Config XML:** `android/app/src/main/res/xml/accessibility_service_config.xml`
- **String Resources:** `android/app/src/main/res/values/strings.xml`
- **Activity Host:** `android/app/src/main/kotlin/com/example/ai_checker/MainActivity.kt`
- **Manifest:** `android/app/src/main/AndroidManifest.xml`

### 2.2 Permissions Declared in `AndroidManifest.xml`
```xml
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE"
    tools:ignore="ProtectedPermissions" />
<uses-permission android:name="android.permission.INTERNET" />
```

### 2.3 Service Declaration in `AndroidManifest.xml`
```xml
<service
    android:name="com.example.ai_checker.GrammarAccessibilityService"
    android:permission="android.permission.BIND_ACCESSIBILITY_SERVICE"
    android:exported="true">
    <intent-filter>
        <action android:name="android.accessibilityservice.AccessibilityService" />
    </intent-filter>
    <meta-data
        android:name="android.accessibilityservice"
        android:resource="@xml/accessibility_service_config" />
</service>
```

### 2.4 Communication Channels
- **MethodChannel:** `com.example.ai_checker/a11y_channel`
  - `isAccessibilityServiceEnabled`: Checks `Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES`.
  - `openAccessibilitySettings`: Launches `Settings.ACTION_ACCESSIBILITY_SETTINGS`.
  - `canDrawOverlays`: Checks `Settings.canDrawOverlays(context)`.
  - `openOverlaySettings`: Launches `Settings.ACTION_MANAGE_OVERLAY_PERMISSION`.
- **EventChannel:** `com.example.ai_checker/a11y_events`
  - Emits real-time map: `{ "isFocused": bool, "text": String, "packageName": String }`.

---

## 3. Flutter Layer Components

### 3.1 Permission Service (`lib/core/services/permission_service.dart`)
- Combines `flutter_overlay_window`, `permission_handler`, and native `MethodChannel`/`EventChannel`.
- Exposes `isOverlayPermissionGranted()`, `requestOverlayPermission()`, `isAccessibilityServiceEnabled()`, `openAccessibilitySettings()`, and `textEventsStream`.

### 3.2 Custom Controller (`lib/features/editor/presentation/widgets/grammar_text_controller.dart`)
- Subclasses `TextEditingController`.
- Overrides `buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing})`.
- Renders `TextDecoration.underline` with `TextDecorationStyle.wavy` and configurable colors:
  - **Red (`0xFFEF4444`):** Grammar errors.
  - **Orange (`0xFFF97316`):** Spelling errors.
  - **Blue (`0xFF3B82F6`):** Clarity suggestions.
  - **Purple (`0xFF8B5CF6`):** Tone enhancements.

### 3.3 Editor State Management (`lib/features/editor/presentation/providers/editor_provider.dart`)
- Tracks permission status (`isOverlayPermissionGranted`, `isAccessibilityEnabled`, `hasAllPermissions`).
- Listens to `textEventsStream` to automatically show/hide the floating overlay window when external text fields are focused.
- Allows user to toggle `isGlobalOverlayEnabled`.

### 3.4 Floating Logo Overlay (`lib/features/overlay/presentation/widgets/floating_logo_overlay.dart`)
- Rendered in a standalone Flutter engine via `@pragma("vm:entry-point") void overlayMain()`.
- Features an animated pulsing white-and-green "G" badge with subtle gradient, shadows, and tap expansion.

### 3.5 In-App Editor Screen (`lib/features/editor/presentation/screens/editor_screen.dart`)
- Minimalist, distraction-free document editor.
- Displays dynamic error count chips, word count statistics, and permission configuration bottom sheet.
- Re-checks permissions on `AppLifecycleState.resumed`.
