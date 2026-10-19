# Project Architecture & Logic Reference

This document serves as the persistent architectural source of truth for the **AI Checker** Flutter application (Grammarly-like mobile app). It outlines design decisions, folder structure conventions, state management rules, and completed phases to prevent regression and hallucination in subsequent development phases.

---

## 1. Clean Architecture & Folder Structure Guidelines

The project strictly follows a **Feature-First Clean Architecture**:

```text
lib/
├── features/
│   ├── [feature_name]/
│   │   ├── data/                 # Repositories, data sources, API clients (when needed)
│   │   ├── models/               # Data transfer objects and domain models
│   │   ├── services/             # Direct backend & third-party service wrappers
│   │   └── presentation/         # UI layer
│   │       ├── providers/        # State management (ChangeNotifier / Provider)
│   │       ├── screens/          # Full page widgets
│   │       └── widgets/          # Feature-scoped reusable UI components
├── core/                         # Shared utilities, constants, theme, network client
└── main.dart                     # App entry point, MultiProvider setup, root theme
```

---

## 2. Phase 1: Authentication & Foundation Architecture

### 2.1 Services Layer: `FirebaseAuthService`
- **Location:** [`lib/features/auth/services/firebase_auth_service.dart`](firebase_auth_service.dart)
- **Role:** Pure service layer wrapping Firebase Authentication SDK (`FirebaseAuth.instance`).
- **Key Logic:**
  - Decoupled from Flutter UI and `BuildContext`.
  - Custom [`AuthException`](firebase_auth_service.dart) encapsulates error messages and Firebase error codes.
  - Translates cryptic Firebase codes into user-friendly strings (`user-not-found`, `wrong-password`, `invalid-credential`, `email-already-in-use`, `weak-password`, `too-many-requests`, `network-request-failed`).
  - Core methods:
    - `signInWithEmailAndPassword({required String email, required String password}) -> Future<UserCredential>`
    - `registerWithEmailAndPassword({required String email, required String password}) -> Future<UserCredential>`
    - `signOut() -> Future<void>`
    - `currentUser -> User?`
    - `authStateChanges -> Stream<User?>`

### 2.2 State Management Layer: `AuthProvider`
- **Location:** [`lib/features/auth/presentation/providers/auth_provider.dart`](auth_provider.dart)
- **Role:** `ChangeNotifier` state container consumed by UI using `context.watch<AuthProvider>()` or `context.read<AuthProvider>()`.
- **State Fields:**
  - `_currentUser` (`User?`): The active user object.
  - `_isLoading` (`bool`): Active transaction flag for disabling controls and showing spinners.
  - `_errorMessage` (`String?`): Last user-facing error message. Cleared automatically on new attempts.
  - `isAuthenticated` (`bool`): Shortcut getter (`currentUser != null`).
- **Logic Invariants:**
  - Listens to `_authService.authStateChanges` stream to update state automatically.
  - `signIn` and `register` return boolean success flags so UI can immediately branch (e.g. show toast, navigate, or pop).
  - Clean error clearing via `clearError()`.

### 2.3 Presentation Layer: `LoginScreen` & `RegisterScreen`
- **Location:**
  - [`lib/features/auth/presentation/screens/login_screen.dart`](login_screen.dart)
  - [`lib/features/auth/presentation/screens/register_screen.dart`](register_screen.dart)
- **UI & UX Standards:**
  - Material 3 styled with consistent typography and color scheme (Grammarly-inspired green seed `#10A37F`).
  - Validation rules:
    - Email: Regex format check `^[^@\s]+@[^@\s]+\.[^@\s]+$`.
    - Password: Min length 6 characters.
    - Confirm Password: Must match password field on register.
  - Form state controls:
    - Obscure password toggle icon buttons.
    - Fields and submission buttons disabled while `isLoading` is true.
    - Unfocuses keyboard prior to form submission.
    - Feedback surfaced via floating `SnackBar` widgets using theme error/primary palettes.

---

## 3. Project Configuration & Dependencies
- `firebase_core`: Foundation initialization in `main.dart`.
- `firebase_auth`: User auth handling.
- `provider`: App-wide dependency injection and state management.
- `permission_handler`: Android system-level permission handling.
- `flutter_overlay_window`: System alert window overlay handling.
- `flutter_accessibility_service`: Native accessibility integration helper.

---

## 4. Roadmap & Future Phases
- **Phase 1 (Complete):** Foundation, Firebase Auth Service, AuthProvider, Login & Register screens. (See [AUTH_LOGIC.md](AUTH_LOGIC.md)).
- **Phase 2 (Complete):** Core Editor with squiggly underline engine, Android Accessibility Service, System Alert Window floating logo, and permission management. (See [PHASE_2_EDITOR_AND_OVERLAY.md](PHASE_2_EDITOR_AND_OVERLAY.md)).
- **Phase 3 (Upcoming):** AI Grammar & Tone Engine integration (LLM / API for grammar, clarity, conciseness checks).
- **Phase 4 (Upcoming):** Suggestions UI (Interactive suggestion cards, one-tap accept/reject replacements).
- **Phase 5 (Upcoming):** Document management, history, and user settings/profiles.

