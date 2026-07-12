# How I used AI

I used Codex heavily during this assignment. I gave it the assignment, API contract, and starter code, then used it to scaffold models, repositories, Cubit state, widgets, tests, documentation, and CI.

I did not accept a clean analyzer result as proof that the implementation was correct. I read the generated code against the contract, ran the failure cases, tested on Android and Web, and changed several generated decisions.

## Where the AI was wrong

### Send button stuck on "Submitting…" after a successful send

The generated `send()` method set `sending: true` at the start but only reset it to `false` inside a `finally` block that ran **after** both the API call and a full dashboard `refresh()`. The button showed a spinner and "Submitting…" for the entire send-plus-refresh duration — roughly one second with the fake repository, potentially several seconds against a real server. A user who just saw the message get accepted had no feedback that they could send another one.

I moved `sending: false` into the `emit` that records the receipt, so the button resets to "Send SMS" as soon as the backend accepts the message. The refresh still runs after, but silently. I also added explicit `sending: false` to every error-path emit (rate limit, provider failure, generic catch) so no path relies on the `finally` block as its primary mechanism. The `finally` block remains only as a safety net for edge cases.

**What was generated:**
```dart
emit(state.copyWith(receipt: receipt));        // sending still true
await refresh();                               // another ~1s of loading
// ... error paths also omitted sending: false
// finally block eventually sets sending: false
```

**What I replaced it with:**
```dart
emit(state.copyWith(receipt: receipt, sending: false));  // button resets now
await refresh();                                         // dashboard updates silently
// every error path also explicitly includes sending: false
// finally block stays as a safety net only
```

### Successful send finalizer (generation race)

After a successful send, `refresh()` advanced the generation before the send `finally` block ran. The generated guard checked `generation == _generation`, which no longer matched after refresh incremented `_generation`. This could leave `sending=true` permanently. I changed the finalizer to check the current tenant and actual sending state instead of generation, then added a regression assertion.

### Cursor handling

The first fake repository used decimal offsets and parsed cursors with `int.tryParse`. That directly violated the contract because the client must treat the cursor as opaque. I replaced it with a private token-to-position lookup. The UI now only passes the returned string back.

### Money and currency

The first `Money` type used exact fixed-scale units, but it did not store currency. That meant EUR and USD could be added. I made currency part of the value and added a mixed-currency test.

### State management

The first state layer used `ChangeNotifier`. It was functional, but it did not match the Bloc decision and exposed mutable fields. I replaced it with `SmsConsoleCubit` and immutable state.

### CI golden platform

The first CI workflow compared a Windows-generated golden on Ubuntu. GitHub reported 18 passed and one failed. I tagged the golden, kept the platform-neutral suite on Ubuntu, and added a pinned Windows golden job. Both public jobs now pass.

### Outdated dependency versions

The AI initially pinned older versions of several packages — for example, `flutter_bloc`, `http`, and `logger` were all behind the latest stable releases. AI tools tend to train on older package snapshots and default to whatever version they last saw, even if a newer release fixes bugs or improves API safety. I ran `flutter pub outdated`, compared each dependency against pub.dev, and bumped them to the latest compatible versions (`flutter_bloc: ^9.1.1`, `http: ^1.6.0`, `logger: ^2.7.0`). This also picked up transitive improvements and avoided known deprecation warnings from older dependency trees.

### Deprecated widget APIs

The AI used deprecated or soon-to-be-deprecated widget properties in several places. For example, it used `DropdownButtonFormField` with the older `value` property, which has been deprecated since Flutter 3.33 in favor of `initialValue`. It also initially used `ThemeData` constructors with fields that were removed in Material 3 transitions. I ran `flutter analyze` after every generation pass, read through each deprecation warning, and replaced the deprecated usages with their recommended replacements. A clean analyzer pass was my baseline — I did not ship any deprecated API usage.

### Responsive UI and missing mobile features

The AI-generated layout had functional omissions and used a rigid, custom `Container` for its header instead of a standard Material `AppBar`. It arbitrarily wrapped the theme toggle button in an `if (!compact)` check, completely hiding the ability to switch between light and dark modes on mobile devices. Furthermore, the tenant selector was crammed into the top-right corner, rendering it a tiny popup menu on mobile instead of a prominent control.

I completely overhauled the visual presentation into a premium modern dashboard. I replaced the single static layout with a scalable `LayoutBuilder` that serves a completely different structural paradigm based on screen size. On wide desktop screens (>= 900px), it presents a professional web-app layout with a dedicated left Sidebar containing the branding, tenant selector, and theme controls. On smaller mobile screens, it falls back to a clean native `AppBar` with the tenant selector prominently placed at the top of the scrolling body.

I also upgraded the aesthetic to a premium, "floating" design by introducing deep soft shadows (`elevation: 8`), large glassy rounded corners (`borderRadius: 24`), and striking color palettes (e.g., Indigo and Sky blue). The original tiny summary text chips were redesigned into large, dominant `_MetricCard` widgets that make the dashboard feel data-rich and highly polished.

### Security: missing HTTPS guard and token exposure risk

The AI's first generated `HttpSmsRepository` accepted any URI scheme — including plain `http://`. It also did not validate whether the access token was present before making a request, which could send an unauthenticated call and leak request data over cleartext. I added a constructor guard that throws `ArgumentError` if the scheme is not `https`, and an early-exit check for a null or empty token before any request fires. I also wrote a test confirming that `http://` is rejected at construction time.

### Security: PII leaking through logger

The AI's first rebuilt logger used the standard `Logger` package with default formatting, which calls `toString()` on exceptions. If an exception message contained a phone number, message body, or bearer token, all of that would appear in the console output. I wrapped the logger behind `AppLogger`, which only accepts fixed `AppLogEvent` enum values and logs the exception's `runtimeType` — never its message content. I wrote a regression test (`app_logger_test.dart`) that passes an exception containing a fake token, phone number, and message body through `AppLogger.error()`, then asserts none of that content appears in the output.


### Money: missing currency guard

The AI's first `Money` class stored fixed-scale units correctly but did not track currency. That meant `Money` values in EUR and USD could be added without error, producing a silently wrong total. I added a `currency` field, a mixed-currency guard on the `+` operator that throws `ArgumentError`, and a test confirming EUR + USD is rejected. The `Money.parse()` factory also rejects values without exactly four decimal places, matching the contract's precision requirement.

### UI: ListTile ink splash hidden by ColoredBox

The AI used `Container(color: ...)` as the root wrapper for the sidebar widget. Flutter internally converts `Container(color:)` into a `ColoredBox`, which is not a `Material` surface. When `ListTile` widgets were placed inside it, Flutter threw an assertion at runtime:

> *"ListTile background color or ink splashes may be invisible. The ListTile is wrapped in a ColoredBox that has a background color."*

I fixed this by replacing `Container(color: ...)` with a proper `Material(color: ...)` widget. Because `Material` is an actual ink surface, `ListTile` can now correctly paint its ripple and background on it. I also added a loading indicator (mini `CircularProgressIndicator`) inside the sidebar's refresh `ListTile` so the user always knows when a data fetch is in progress.

### Mock Data: identical data generated across tenants

The AI's `FakeSmsRepository` implementation used a generic mathematical formula based on the tenant's hash code (`hashCode % 5 + 3`) to try and generate different numbers of mock messages per tenant. However, `'north'.hashCode % 5` and `'orbit'.hashCode % 5` evaluated to the same result. This meant the dashboard showed the exact same number of messages, costs, and statuses regardless of which tenant was selected.

I fixed this by entirely replacing the hash-based generation with explicit, hardcoded seed data per tenant ID:
- **Northwind Health** now shows 12 messages with a mix of statuses (delivered, failed, sent) and higher spend, using TWILIO.
- **Orbit Retail** shows 5 messages (mostly delivered) with a lower spend, using VONAGE.

This also fixed the issue where the AI hadn't generated any `DeliveryStatus.failed` records to test the UI's error states.


## What I reviewed myself

I manually reviewed and took ownership of:

- no hardcoded secrets, tokens, or API keys in any committed file;
- HTTPS enforcement with a runtime guard and a test;
- `X-Tenant-Id` attached to every outbound request;
- fixed-scale money and currency rules — no `double` anywhere;
- tenant generation checks and the slow-A/fast-B race;
- authorization headers and refresh-once behavior;
- the rule that tokens, phone numbers, and message bodies must not be logged;
- `AppLogger` only emitting enum names and `runtimeType`, with a regression test;
- `202 ACCEPTED` wording and duplicate-send protection;
- the send button returning to normal state after every outcome (success, error, rate limit);
- dependency versions verified against pub.dev and `flutter pub outdated`;
- every deprecation warning resolved via `flutter analyze`;
- every regression test and golden change; and
- the real Pixel and Chrome captures.

I also asked Codex to add the `logger` package, but I kept it behind `AppLogger` with fixed event names. Exceptions log only their runtime type. I added a test that puts a fake token, full phone number, and message text inside an exception and confirms none of that content reaches the logger output.

AI helped me move faster, but it also produced mistakes that looked reasonable on a quick read. The review, tests, platform runs, and corrections are the parts I consider my engineering work.

