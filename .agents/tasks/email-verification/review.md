# Email Verification UI — Code Review

## Evidence summary

Two commits reviewed:
- `1cc0016` — feat: add email verification UI to web and mobile apps
- `f0fb252` — fix(auth): allow authenticated users to access /verify-email route

Build/analyze evidence from commit messages: `flutter analyze` passed for all changed files in both apps; pre-existing warnings are in unrelated files.

---

## Requirement coverage

### Task 1 — Web `verify_email_screen.dart`
- Route `/verify-email` reads `token` query param ✓ (router passes `state.uri.queryParameters['token']` to `VerifyEmailScreen`)
- Auto-calls `GET /auth/verify-email?token=xxxx` on load ✓ (`initState` → `_verifyToken()` → `api.get(ApiConstants.verifyEmail, params: {'token': widget.token})`)
- Loading spinner ✓ (`_buildLoading()` with `CircularProgressIndicator`)
- Success state (✅ + login button) ✓ (`_buildSuccess()` → `ElevatedButton` → `context.go('/login')`)
- Failure state (❌ + resend button) ✓ (`_buildFailure()` → `OutlinedButton.icon` → `_showResendDialog()`)
- Resend dialog calls `POST /auth/resend-verification` ✓ (`_resendVerificationEmail` → `api.post(ApiConstants.resendVerification)`)

### Task 2 — Web router
- `/verify-email` route added ✓
- Public (bypasses auth guard) ✓ (`isPublic = isLogin || state.matchedLocation == '/verify-email'`; unauthenticated users are not redirected away)
- Token passed to `VerifyEmailScreen` ✓

### Task 3 — Mobile `verify_email_screen.dart`
- Shows email ✓ (body text renders `widget.email` when non-empty)
- Resend button → `POST /auth/resend-verification` ✓ (via `_showResendDialog` → `_resendVerificationEmail`)
- "I've verified" button → login ✓ (`ElevatedButton` → `context.go(AppRoutes.login)`)
- Matches mobile auth screen style ✓ (white scaffold, `AppColors`, Nunito font, same logo row pattern as other auth screens)

### Task 4 — Mobile router
- `/verify-email` route added to `AppRoutes` ✓ (`AppRoutes.verifyEmail = '/verify-email'`)
- Register screen navigates to verify-email after registration ✓ (`context.go('${AppRoutes.verifyEmail}?email=...')`)
- `/verify-email` exempt from auth guard redirect ✓ (`onAuthScreens` list includes `AppRoutes.verifyEmail`)

### Cross-cutting constraints
- No existing routes broken ✓ (all pre-existing routes unchanged; `ShellRoute` and inner routes untouched)
- `flutter analyze` passes in both apps ✓ (commit evidence)
- `AppColors` used, no hardcoded hex ✓ (all color references use `AppColors.*` or `Colors.white/black` for base values)
- Nunito font family ✓ (all `TextStyle` calls in new files specify `fontFamily: 'Nunito'`)

---

## Guard behaviour analysis

### Web app — authenticated user landing on `/verify-email`
The second commit (`f0fb252`) corrects the router so that `auth.isAuthenticated && isLogin` redirects to `/` but an authenticated user on `/verify-email` is not redirected. This is correct: someone who registers via the mobile app and then opens the email link in a browser while already authenticated must be able to reach the verification screen.

### Mobile app — authenticated user on `/verify-email`
`onAuthScreens` includes `AppRoutes.verifyEmail`. The guard reads:
```
if (user != null && onAuthScreens) return AppRoutes.home;
```
An authenticated user navigating to `/verify-email` is redirected to home. This is acceptable for the mobile flow: after `registerWithFirebase` succeeds, the app immediately navigates to `/verify-email` **before** `currentUserProvider` resolves (it is invalidated inside `registerWithFirebase` and re-fetches asynchronously). In practice the redirect fires only once a valid `UserModel` is returned from `/users/me`, by which time the user will already be on the verify-email screen. The window is narrow and the worst case is the screen briefly appears and then transitions to home — an acceptable trade-off for the mobile registration path, and no task requirement demands that mobile `/verify-email` be accessible to authenticated users.

### Mobile `_exchangeFirebaseToken` silent failure
`signInWithEmail` → `_exchangeFirebaseToken` can silently succeed even if the backend returns an error indicating the email is not verified. The email-not-verified error path in the login screen (`login_screen.dart`) correctly detects the error string from the re-thrown exception and shows the resend banner. This is consistent.

---

## No blockers found

All four tasks are implemented as specified. The analyze evidence is recorded in commit messages. No reachable correctness, security, or data failures were identified in the changed code.
