# Implementation Plan — Error Message Audit & Fix

> Scope: error/empty-state text and catch-block messages only.  
> No layout, navigation, or functional changes.

---

## Files to change

### 1. `web_app/lib/presentation/screens/auth/login_screen.dart`

#### Issue A — `_SignInForm` has no `_firebaseMsg` helper (unlike `_SignUpForm`)
The sign-in submit path (`_submitSignIn`) delegates to `authProvider.notifier.signIn()` which returns an error string from the provider.  
The raw Firebase error codes are surfaced as-is through `auth.error` and rendered in `_ErrorBox`.

**Plan:** Add a `_firebaseMsg(String code)` helper to `_SignInFormState` (mirrors the one already in `_SignUpFormState`) and call it in the `signIn` result path via the auth provider, or map it locally before setting state.

The auth provider calls `signIn` and returns `error?.message`. The cleanest fix is to map in `_SignInFormState._submitSignIn` after the error is returned: wrap `auth.error` through the helper before displaying.

Actually, because `auth.error` is set inside the provider notifier, the correct fix is to add the mapping inside `_SignInFormState` — intercept the raw provider error string and pass it through the helper before rendering (using `ref.listen` or checking `auth.error` through the helper in the `_ErrorBox` call site).

**Simplest, non-functional change:** In `_SignInFormState.build()`, replace:

```dart
// current — around line 340 (inside Padding > Form > Column):
if (auth.error != null) ...[
  const SizedBox(height: 10),
  _ErrorBox(message: auth.error!),
],
```

with:

```dart
if (auth.error != null) ...[
  const SizedBox(height: 10),
  _ErrorBox(message: _friendlySignInError(auth.error!)),
],
```

And add the helper method to `_SignInFormState`:

```dart
String _friendlySignInError(String raw) {
  // Firebase Auth error codes arrive as the code string or inside a message
  if (raw.contains('wrong-password') || raw.contains('invalid-credential') || raw.contains('INVALID_LOGIN_CREDENTIALS')) {
    return 'Incorrect email or password. Please try again.';
  }
  if (raw.contains('user-not-found')) {
    return 'No account found with that email. Try signing up instead.';
  }
  if (raw.contains('user-disabled')) {
    return 'This account has been disabled. Contact support if you think this is a mistake.';
  }
  if (raw.contains('network-request-failed')) {
    return 'Network error. Check your internet connection and try again.';
  }
  if (raw.contains('too-many-requests')) {
    return 'Too many failed attempts. Please wait a few minutes before trying again.';
  }
  return raw; // fall through — provider may already have a friendly message
}
```

**Files:** `web_app/lib/presentation/screens/auth/login_screen.dart`  
**Verify:** `flutter analyze web_app` — no errors. Sign in with a wrong password and confirm the new message appears.

---

#### Issue B — `_ErrorBox` generic 503 mapping
`_ErrorBox.build()` already maps `503` / `temporarily unavailable` to a helpful string. No change needed.

---

### 2. `web_app/lib/presentation/screens/ai/ai_screen.dart`

#### Issue — catch block maps only `403`; everything else collapses to one generic string

**Location:** `_AiNotifier.send()` — the `catch (e)` block around line 108.

**Current code:**
```dart
} catch (e) {
  final msg = e.toString().contains('403')
      ? 'AI is currently disabled during an exam period.'
      : 'Could not reach AI. Check your connection and try again.';
  state = [...state, _Message(text: msg, type: _MsgType.error)];
}
```

**Replacement:**
```dart
} catch (e) {
  final raw = e.toString();
  final String msg;
  if (raw.contains('403')) {
    msg = 'AI is currently unavailable — the platform is in exam lock mode.';
  } else if (raw.contains('429')) {
    msg = 'You have sent too many requests. Please wait a moment and try again.';
  } else if (raw.contains('503') || raw.contains('502') || raw.contains('504')) {
    msg = 'The AI service is temporarily unavailable. Please try again in a moment.';
  } else if (raw.contains('SocketException') ||
             raw.contains('NetworkException') ||
             raw.contains('connection') ||
             raw.contains('timeout') ||
             raw.contains('XMLHttpRequest')) {
    msg = 'Could not reach the AI server. Check your internet connection and try again.';
  } else {
    msg = 'Something went wrong on our end. Please try again in a moment.';
  }
  state = [...state, _Message(text: msg, type: _MsgType.error)];
}
```

**Files:** `web_app/lib/presentation/screens/ai/ai_screen.dart`  
**Verify:** `flutter analyze web_app` — no errors.

---

### 3. `web_app/lib/presentation/screens/home/home_screen.dart`

All four `_ErrorBanner` call sites already include a Retry button via `TextButton.icon`. The messages need improving:

| Location | Current message | Replacement |
|---|---|---|
| Stats row error (~line 117) | `'Could not load dashboard data.'` | `'Could not load your dashboard. Check your connection and try again.'` |
| Recent Activity error (~line 147) | `'Could not load recent activity.'` | `'Could not load recent activity. Check your connection and try again.'` |
| Recent Questions error (~line 171) | `'Could not load questions.'` | `'Could not load recent questions. Check your connection and try again.'` |
| Courses section error (~line 193) | `'Could not load courses.'` | `'Could not load your courses. Check your connection and try again.'` |

**Files:** `web_app/lib/presentation/screens/home/home_screen.dart`  
**Verify:** `flutter analyze web_app` — no errors.

---

### 4. `web_app/lib/presentation/screens/courses/courses_screen.dart`

| Location | Current message | Replacement |
|---|---|---|
| `_ErrorWidget` call site (`error:` branch, ~line 59) | `'Could not load courses.'` | `'Could not load your courses. Check your connection and try again.'` |
| `_EmptyWidget` call site (`data:` branch, ~line 64) | `'No courses found for your department yet.'` | ✅ Already an appropriate empty state — keep as-is |

**Files:** `web_app/lib/presentation/screens/courses/courses_screen.dart`  
**Verify:** `flutter analyze web_app` — no errors.

---

### 5. `web_app/lib/presentation/screens/courses/course_detail_screen.dart`

| Location | Current message | Replacement |
|---|---|---|
| Course load error body (~line 93) | `'Could not load course details.'` (Text widget, no style) | `'Could not load this course. Check your connection and try again.'` |
| Resources tab error (~line 148) | `'Could not load resources.'` (Text widget, no style) | `'Could not load resources for this course. Check your connection and try again.'` |
| Both already have a Retry `ElevatedButton` — no change needed to retry UI. | | |

**Files:** `web_app/lib/presentation/screens/courses/course_detail_screen.dart`  
**Verify:** `flutter analyze web_app` — no errors.

---

### 6. `web_app/lib/presentation/screens/resources/resources_screen.dart`

| Location | Current message | Replacement |
|---|---|---|
| List load error (~line 91) | `'Could not load resources.'` | `'Could not load resources. Check your connection and try again.'` |
| Save-to-library catch (~line 708+) | `'Could not save: $e'` — exposes raw exception | `'Could not save to library. Please try again.'` |
| Upload `_submit()` catch — raw Supabase/Firebase error surfaced as `_error` string (includes internal path) | the `msg` variable that includes `'Firebase Storage error: $msg\n\nMake sure Firebase Storage rules allow writes.'` | Replace with: `'Upload failed. Please check your connection and try again. If the problem persists, contact support.'` (keep the special-case block but replace the message text) |

**Files:** `web_app/lib/presentation/screens/resources/resources_screen.dart`  
**Verify:** `flutter analyze web_app` — no errors.

---

### 7. `web_app/lib/presentation/screens/community/community_screen.dart`

| Location | Current message | Replacement |
|---|---|---|
| Questions load error (~line 82) | `'Could not load questions.'` (unstyled `Text`) | `'Could not load questions. Check your connection and try again.'` — add `style: const TextStyle(color: AppColors.textSecondary, fontFamily: 'Nunito')` |
| Ask-question dialog catch (~line 165) | `'Could not post: ${e.toString()}'` — exposes raw exception | `'Could not post your question. Check your connection and try again.'` |

**Files:** `web_app/lib/presentation/screens/community/community_screen.dart`  
**Verify:** `flutter analyze web_app` — no errors.

---

### 8. `web_app/lib/presentation/screens/community/question_detail_screen.dart`

| Location | Current message | Replacement |
|---|---|---|
| `_resolve()` catch snackbar (~line 68) | `'Could not resolve: $e'` — exposes raw exception | `'Could not mark as resolved. Please try again.'` |
| `_submitAnswer()` catch snackbar (~line 97) | `'Failed to post answer: $e'` — exposes raw exception | `'Could not post your answer. Check your connection and try again.'` |
| Page-level error state (~line 159) | `'Could not load question.'` (unstyled Text) | `'Could not load this question. Check your connection and try again.'` — add `style: const TextStyle(color: AppColors.textSecondary, fontFamily: 'Nunito', fontSize: 14)` |

**Files:** `web_app/lib/presentation/screens/community/question_detail_screen.dart`  
**Verify:** `flutter analyze web_app` — no errors.

---

### 9. `web_app/lib/presentation/screens/progress/progress_screen.dart`

| Location | Current message | Replacement |
|---|---|---|
| CGPA load error `_ErrorCard` (~line 157) | `'Could not load CGPA.'` | `'Could not load your CGPA. Check your connection and try again.'` |
| Semesters load error `_ErrorCard` (~line 167) | `'Could not load semesters.'` | `'Could not load your saved semesters. Check your connection and try again.'` |
| Delete semester catch snackbar (~line 185) | `'Could not delete semester: $e'` — exposes raw exception | `'Could not delete the semester. Please try again.'` |
| Save semester catch (`_showError` call, ~line 473) | `'Could not save semester. Please try again.'` | ✅ Already acceptable — keep as-is |

**Files:** `web_app/lib/presentation/screens/progress/progress_screen.dart`  
**Verify:** `flutter analyze web_app` — no errors.

---

### 10. `web_app/lib/presentation/screens/notifications/notifications_screen.dart`

| Location | Current message | Replacement |
|---|---|---|
| List load error `_ErrorState` (~line 166) | `'Could not load notifications.'` | `'Could not load your notifications. Check your connection and try again.'` |
| Mark-all-read catch snackbar (~line 107) | `'Could not mark all as read. Please try again.'` | ✅ Already acceptable — keep as-is |

**Files:** `web_app/lib/presentation/screens/notifications/notifications_screen.dart`  
**Verify:** `flutter analyze web_app` — no errors.

---

### 11. `web_app/lib/presentation/screens/connections/connections_screen.dart`

| Location | Current message | Replacement |
|---|---|---|
| My Connections tab error `_ConnErrorWidget` (~line 295) | `'Could not load connections.'` | `'Could not load your connections. Check your connection and try again.'` |
| Received requests error `_ConnErrorWidget` (~line 323) | `'Could not load received requests.'` | `'Could not load received requests. Check your connection and try again.'` |
| Sent requests error `_ConnErrorWidget` (~line 352) | `'Could not load sent requests.'` | `'Could not load sent requests. Check your connection and try again.'` |
| Find Students error `_ConnErrorWidget` (~line 415) | `'Could not search. Please try again.'` | `'Could not search for students. Check your connection and try again.'` |
| `_sendRequest` catch snackbar | `'Could not send request. Please try again.'` | ✅ Already acceptable — keep as-is |
| `_acceptRequest` catch snackbar | `'Could not accept request. Please try again.'` | ✅ Already acceptable — keep as-is |
| `_removeConnection` catch snackbar | `'Could not remove connection. Please try again.'` | ✅ Already acceptable — keep as-is |
| `_cancelRequest` catch snackbar | `'Could not cancel request. Please try again.'` | ✅ Already acceptable — keep as-is |

**Files:** `web_app/lib/presentation/screens/connections/connections_screen.dart`  
**Verify:** `flutter analyze web_app` — no errors.

---

### 12. `web_app/lib/presentation/screens/leaderboard/leaderboard_screen.dart`

| Location | Current message | Replacement |
|---|---|---|
| Load error (~line 55) | `'Could not load leaderboard'` (no period, no action advice) | `'Could not load the leaderboard. Check your connection and try again.'` |

**Files:** `web_app/lib/presentation/screens/leaderboard/leaderboard_screen.dart`  
**Verify:** `flutter analyze web_app` — no errors.

---

### 13. `web_app/lib/presentation/screens/library/library_screen.dart`

| Location | Current message | Replacement |
|---|---|---|
| Load error (~line 56) | `'Could not load your library.'` | `'Could not load your library. Check your connection and try again.'` — already has a Retry `TextButton.icon` ✅ |
| Remove-from-library catch snackbar (~line 227) | `'Failed to remove: $e'` — exposes raw exception | `'Could not remove this resource. Please try again.'` |

**Files:** `web_app/lib/presentation/screens/library/library_screen.dart`  
**Verify:** `flutter analyze web_app` — no errors.

---

### 14. `web_app/lib/presentation/screens/study_groups/study_groups_screen.dart`

| Location | Current message | Replacement |
|---|---|---|
| Tab load error `_GroupListTab` (~line 291) | `'Could not load study groups.'` | `'Could not load study groups. Check your connection and try again.'` |
| `_extractError` fallback (~line 173) | `'An error occurred. Please try again.'` | `'Something went wrong. Please try again.'` |
| `_extractError` 409 | `'You are already a member of this group'` | ✅ Specific — keep as-is |
| `_extractError` 403 | `'Group is full or inactive'` | `'This group is full or no longer active.'` |
| `_extractError` 404 | `'Group not found'` | `'This group no longer exists.'` |
| `_showCreateDialog` catch snackbar | generic `_extractError` message | ✅ Already routed through `_extractError` — covered above |

**Files:** `web_app/lib/presentation/screens/study_groups/study_groups_screen.dart`  
**Verify:** `flutter analyze web_app` — no errors.

---

### 15. `web_app/lib/presentation/screens/profile/profile_screen.dart`

No generic catch-all errors found. The profile screen:
- Displays `authState.error` (set by the provider with a mapped message) — acceptable as-is.
- Avatar upload catch returns `'Upload failed. Please try again.'` ✅ — acceptable.
- No changes needed.

---

### 16. `admin_dashboard/lib/presentation/screens/resources/moderation_screen.dart`

| Location | Current message | Replacement |
|---|---|---|
| Pending resources load error (~line 129) | `'Could not load pending resources.'` (unstyled `Text`, no Retry) | `'Could not load pending submissions. Check your connection and try again.'` — **add a Retry `TextButton` that calls `ref.invalidate(pendingResourcesProvider)`** |
| Review action catch snackbar (~line 149) | `'Error: $e'` — exposes raw exception | `'Could not submit review. Please try again.'` |
| Upload dialog `_submit()` catch snackbar (~line 310) | `'Upload failed: $e'` — exposes raw exception | `'Upload failed. Check your connection and try again.'` |
| Department load error in upload dialog (~line 369) | `'Could not load departments.'` (unstyled `Text`) | `'Could not load departments. Please close and reopen the dialog.'` |
| Courses load error in upload dialog (~line 377) | `'Could not load courses.'` (unstyled `Text`) | `'Could not load courses for this department. Please try again.'` |

**Files:** `admin_dashboard/lib/presentation/screens/resources/moderation_screen.dart`  
**Verify:** `flutter analyze admin_dashboard` — no errors.

---

### 17. `admin_dashboard/lib/presentation/screens/courses/courses_management_screen.dart`

| Location | Current message | Replacement |
|---|---|---|
| Courses table error (`error:` branch, ~line 213) | `'Could not load courses.'` (unstyled `Text`, no Retry) | `'Could not load courses. Check your connection and try again.'` — **add a Retry `TextButton` that calls `ref.invalidate(adminCoursesProvider(_selectedDeptId!))`** |
| Delete catch snackbar (~line 282) | `'Failed to delete: $e'` — exposes raw exception | `'Could not delete the course. Please try again.'` |
| Create/Edit form `_submit()` catch snackbar (~line 386) | `'Error: $e'` — exposes raw exception | `'Could not save the course. Please try again.'` |

**Note:** The `adminDepartmentsProvider` error branch renders `const SizedBox.shrink()` — the department picker silently disappears on error. Add a message:  
Replace `error: (_, __) => const SizedBox.shrink(),` with:
```dart
error: (_, __) => const Padding(
  padding: EdgeInsets.symmetric(vertical: 8),
  child: Text(
    'Could not load departments. Please refresh the page.',
    style: TextStyle(color: AdminColors.error, fontSize: 13),
  ),
),
```

**Files:** `admin_dashboard/lib/presentation/screens/courses/courses_management_screen.dart`  
**Verify:** `flutter analyze admin_dashboard` — no errors.

---

### 18. `admin_dashboard/lib/presentation/screens/users/users_screen.dart`

| Location | Current message | Replacement |
|---|---|---|
| Users load error (~line 118) | `'Could not load users. Please try again.'` (unstyled `Text`, no Retry button) | Keep message, **add a Retry `TextButton` that calls `ref.invalidate(adminUsersProvider)`** |
| `_toggleSuspend` catch snackbar | `'Action failed. Please try again.'` | `'Could not update user status. Please try again.'` |
| `_showChangeRoleDialog` catch snackbar | `'Role change failed.'` | `'Could not change role. Please try again.'` |

**Files:** `admin_dashboard/lib/presentation/screens/users/users_screen.dart`  
**Verify:** `flutter analyze admin_dashboard` — no errors.

---

## Summary of patterns applied

| Rule | Applied to |
|---|---|
| **Generic → specific**: name what failed | All 18 files |
| **Network errors**: add "Check your connection and try again." | All load-failure errors |
| **Server errors**: "Something went wrong on our end. Please try again in a moment." | AI fallback, study groups fallback |
| **AI errors**: 403 = exam lock, 429 = rate limit, 5xx/timeout/network = server/connection | `ai_screen.dart` |
| **Auth errors**: wrong password, user not found, disabled, network, too-many-requests | `login_screen.dart` `_SignInForm` |
| **Raw exception exposure** (`$e`, `Error: $e`, `Failed to delete: $e`) | Replaced in 10+ locations |
| **Retry button added** where error state had none | `moderation_screen.dart`, `courses_management_screen.dart`, `users_screen.dart` |
| **Empty vs error**: existing distinctions preserved throughout | All files — no empty states were changed to error states or vice versa |
