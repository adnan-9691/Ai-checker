# Phase 1: Authentication Logic & Flow Specification

This document details the exact business logic, exception mappings, and state transitions implemented in **Phase 1: Foundation & Authentication**.

---

## 1. Authentication Flow Diagram

```text
[User] 
  │
  ▼
[LoginScreen / RegisterScreen] (Form Validation & Controllers)
  │
  ▼ Calls provider method
[AuthProvider] 
  ├── sets isLoading = true
  ├── clears errorMessage
  ├── notifies listeners
  │
  ▼ Invokes service
[FirebaseAuthService]
  ├── Calls FirebaseAuth.instance
  ├── Catches FirebaseAuthException -> transforms to human-readable message via AuthException
  └── Returns UserCredential or throws AuthException
  │
  ▼
[AuthProvider]
  ├── On Success: updates _currentUser, sets isLoading = false, returns true
  └── On Failure: sets _errorMessage, sets isLoading = false, returns false
  │
  ▼
[UI Layer]
  ├── Shows error SnackBar if false
  └── Shows success SnackBar and navigates if true
```

---

## 2. FirebaseAuth Exception Error Code Mapping

The following mapping in [`FirebaseAuthService._mapFirebaseError`](../lib/features/auth/services/firebase_auth_service.dart) guarantees consistent and friendly error feedback:

| Firebase Code | User-Facing Message | Rationale |
|---|---|---|
| `user-not-found` | *No user found with this email address.* | Avoids technical terms. |
| `wrong-password` | *Incorrect password. Please verify and try again.* | Clear user guidance. |
| `invalid-credential` | *Invalid email or password. Please try again.* | Firebase Auth modern unified credential code. |
| `email-already-in-use` | *An account already exists for this email address.* | Informs user to switch to Login. |
| `invalid-email` | *The email address format is invalid.* | Backup validation if regex passes edge cases. |
| `weak-password` | *The password is too weak. Please use at least 6 characters.* | Firebase password complexity warning. |
| `user-disabled` | *This user account has been disabled. Please contact support.* | Account suspension feedback. |
| `operation-not-allowed` | *Email/password sign-in is not enabled. Please contact support.* | Configuration warning for Firebase Console. |
| `too-many-requests` | *Too many attempts. Access is temporarily disabled. Try again later.* | Rate-limiting mitigation message. |
| `network-request-failed` | *Network error. Please check your internet connection.* | Offline or dropped connection clarity. |
| *Fallback* | `e.message` or default string | Graceful degradation for unknown codes. |

---

## 3. AuthProvider State Contract

| Property / Method | Signature | Purpose |
|---|---|---|
| `currentUser` | `User?` | Current Firebase `User` instance. |
| `isLoading` | `bool` | True during in-flight sign-in/sign-up/sign-out requests. |
| `errorMessage` | `String?` | Human-readable error message from latest failed operation. |
| `isAuthenticated` | `bool` | Convenience getter (`currentUser != null`). |
| `clearError()` | `void` | Resets `errorMessage` to null and notifies listeners. |
| `signIn(...)` | `Future<bool>` | Signs in with credentials; returns true on success. |
| `register(...)` | `Future<bool>` | Registers new account; returns true on success. |
| `signOut()` | `Future<bool>` | Signs out active session. |

---

## 4. UI Invariants & Validations

1. **Email Field:**
   - Must be non-empty.
   - Must match standard email regex `^[^@\s]+@[^@\s]+\.[^@\s]+$`.
   - Trimmed before passing to service layer.
2. **Password Field:**
   - Must be non-empty.
   - Must be at least 6 characters.
   - Obscure text toggle button available on trailing edge.
3. **Confirm Password Field (Registration only):**
   - Must match password field exactly.
4. **Form Submission Behavior:**
   - Focus is unfocused (`FocusScope.of(context).unfocus()`) on submit.
   - Buttons display an inline `CircularProgressIndicator` during `isLoading == true`.
   - Interaction is blocked while `isLoading` is true.
   - Screen uses floating `SnackBar` for alerts.
