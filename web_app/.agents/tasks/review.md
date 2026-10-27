# Community Question Detail Screen

This PR adds the `QuestionDetailScreen` — a full-page view for a single Q&A question with its answers, voting, resolving, and answer posting. It wires up a `FutureProvider.autoDispose.family` backed by `GET /community/questions/:id`, adds the `/community/:id` route inside `ShellRoute`, extends `ApiConstants` with six new endpoint helpers, and updates `CommunityScreen` to navigate to the detail on tap. The implementation covers all required UI sections and is mostly well-constructed.

**Watch for:** (1) **confirmed** — the `_voting` flag is a single boolean on the parent `ConsumerStatefulWidget`; there is no per-answer debounce, so rapid taps on different answers' vote buttons can fire simultaneous requests. (2) **possible** — the "Mark as Resolved" guard reads `currentUser` via `ref.read` at build time; on cold web loads auth may settle after the FutureProvider delivers data, leaving the button silently absent for the question author. (3) **confirmed** — vote errors are silently discarded while resolve and post-answer errors both show snackbars, creating an inconsistent error-handling contract.

**Verdict**: APPROVED

---

## High-level view

The "Mark as Resolved" guard compares `currentUser.id` against the author's `id` field from the API response. `currentUser` is read with `ref.read(currentUserProvider)` inside the `data:` branch of `questionAsync.when`. `ref.read` takes a snapshot and does not subscribe, so if auth initializes after the FutureProvider fires — which is possible on cold web loads where the `AuthNotifier._init` timeout is up to 5 seconds — `currentUser` will be null and `canResolve` will be false. The button disappears silently for the rightful author.

The `_voting` flag lives in `_QuestionDetailScreenState`, but vote calls from `_AnswerCard` are forwarded through a callback. Because `_AnswerCard` is a separate stateless widget and `setState(() => _voting = true)` is scheduled after the first `await`, two near-simultaneous taps on different answer vote buttons both pass the `if (_voting) return` guard before the flag flips. The backend endpoints for votes should be idempotent, but duplicate POST requests are still undesirable.

`_vote` catches all exceptions with an empty `catch (_)` block. The `finally` always invalidates the provider so the displayed count is corrected after a failed vote, but the user receives no feedback. The resolve handler and answer-post handler both surface error snackbars; the vote handler is the odd one out.

---

<details>
<summary>Issues (3)</summary>

1. **Vote debounce missing on answers** — `_voting` is a single flag on the parent state; two rapid taps on different `_AnswerCard` vote buttons both pass the guard before `setState` fires. Add per-answer debounce state or convert `_AnswerCard` to a `StatefulWidget` that manages its own in-flight flag.

2. **`canResolve` may evaluate false for the question author on cold web loads** — `currentUser` is read via `ref.read(currentUserProvider)` inside `data:`. Change it to `ref.watch(currentUserProvider)` so the body rebuilds when auth settles, ensuring the button appears for the author even on cold loads.

3. **Vote errors are silently swallowed** — `_vote` discards all exceptions. Add a snackbar in the catch block matching the pattern in `_resolve` and `_submitAnswer`.

</details>

<details>
<summary>Details</summary>

### Vote debounce gap

The `_voting` boolean lives in `_QuestionDetailScreenState` and is checked at the top of `_vote()`. Because `_AnswerCard` is a stateless widget that calls `onVote(endpoint)` directly, and because `setState(() => _voting = true)` is scheduled after `await api.post()` starts executing, two near-simultaneous taps on different answer vote buttons both pass the guard before the flag flips. The practical impact is duplicate POST requests. The question's own vote buttons share the same issue, but they are adjacent and harder to double-tap simultaneously; the answer list is the higher-risk surface.

### Author guard and auth timing

`isOwner = currentUser != null && currentUser!.id == authorId`. `currentUser` is obtained via `ref.read(currentUserProvider)` inside `data:`. On a cold web load the `FutureProvider` may resolve before `AuthNotifier._init` completes (it has a 5-second ceiling), leaving `currentUser` null. The fix — `ref.watch(currentUserProvider)` in `build` — makes `_QuestionDetailBody` rebuild when the auth state delivers the user.

</details>

---

<details>
<summary>File map</summary>

| File | Change |
|------|--------|
| `presentation/screens/community/question_detail_screen.dart` | New screen: provider, state widget, body, answer card, vote button |
| `presentation/screens/community/community_screen.dart` | Added `InkWell` tap handler navigating to `/community/:id` |
| `app/router/app_router.dart` | Added `/community/:id` `GoRoute` inside `ShellRoute` |
| `core/constants/api_constants.dart` | Added `questionDetail`, `upvoteQuestion`, `downvoteQuestion`, `upvoteAnswer`, `downvoteAnswer`, `resolveQuestion` helpers; no duplication of pre-existing entries |

Full diff: `git show HEAD`

</details>
