# How I Used AI

I used AI as a coding assistant during this assignment.

I worked with two tools: Codex and Antigravity.

I used Codex for most of the code generation, refactoring, and test scaffolding.

I used Antigravity for in-editor assistance, exploration, and quick iteration while building out the UI and wiring the state.

I gave the tools the assignment, the API contract, and the starter code.

I then used them to help scaffold models, repositories, Cubit state, widgets, tests, documentation, and CI.

The tools produced the first draft.

I remained the engineer who reviewed, corrected, and owned the result.

I did not accept a clean analyzer result as proof that the implementation was correct.

I read the generated code against the contract.

I ran the failure cases.

I tested on Android and Web.

I changed several generated decisions where they were wrong.

---

## Where the AI Was Wrong

### Send button stuck on "Submittingâ€¦" after a successful send

The generated `send()` method set `sending: true` at the start.

It only reset it to `false` inside a `finally` block.

That block ran **after** both the API call and a full dashboard `refresh()`.

The button showed a spinner and "Submittingâ€¦" for the entire send-plus-refresh duration.

This was roughly one second with the fake repository.

It could be several seconds against a real server.

A user who just saw the message get accepted had no feedback that they could send another one.

I moved `sending: false` into the `emit` that records the receipt.

This means the button resets to "Send SMS" as soon as the backend accepts the message.

The refresh still runs after, but silently.

I also added explicit `sending: false` to every error-path emit: rate limit, provider failure, and generic catch.

This means no path relies on the `finally` block as its primary mechanism.

The `finally` block remains only as a safety net for edge cases.

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

After a successful send, `refresh()` advanced the generation before the send `finally` block ran.

The generated guard checked `generation == _generation`.

This no longer matched after refresh incremented `_generation`.

This could leave `sending = true` permanently.

I changed the finalizer to check the current tenant and the actual sending state instead of generation.

I then added a regression assertion.

### Cursor handling

The first fake repository used decimal offsets.

It parsed cursors with `int.tryParse`.

This directly violated the contract, because the client must treat the cursor as opaque.

I replaced it with a private token-to-position lookup.

The UI now only passes the returned string back.

### Money and currency

The first `Money` type used exact fixed-scale units.

It did not store currency.

This meant EUR and USD could be added together.

I made currency part of the value.

I added a mixed-currency test.

### State management

The first state layer used `ChangeNotifier`.

It was functional.

However, it did not match the Bloc decision and it exposed mutable fields.

I replaced it with `SmsConsoleCubit` and immutable state.

### CI golden platform

The first CI workflow compared a Windows-generated golden on Ubuntu.

GitHub reported 18 passed and one failed.

I tagged the golden.

I kept the platform-neutral suite on Ubuntu.

I added a pinned Windows golden job.

Both public jobs now pass.

### Outdated dependency versions

The AI initially pinned older versions of several packages.

For example, `flutter_bloc`, `http`, and `logger` were all behind the latest stable releases.

AI tools tend to train on older package snapshots.

They default to whatever version they last saw, even when a newer release fixes bugs or improves API safety.

I ran `flutter pub outdated`.

I compared each dependency against pub.dev.

I bumped them to the latest compatible versions: `flutter_bloc: ^9.1.1`, `http: ^1.6.0`, and `logger: ^2.7.0`.

This also picked up transitive improvements.

It avoided known deprecation warnings from older dependency trees.

### Deprecated widget APIs

The AI used deprecated or soon-to-be-deprecated widget properties in several places.

For example, it used `DropdownButtonFormField` with the older `value` property.

That property has been deprecated since Flutter 3.33 in favor of `initialValue`.

It also initially used `ThemeData` constructors with fields that were removed in Material 3 transitions.

I ran `flutter analyze` after every generation pass.

I read through each deprecation warning.

I replaced the deprecated usages with their recommended replacements.

A clean analyzer pass was my baseline.

I did not ship any deprecated API usage.

### Responsive UI and missing mobile features

The AI-generated layout had functional omissions.

It used a rigid, custom `Container` for its header instead of a standard Material `AppBar`.

It arbitrarily wrapped the theme toggle button in an `if (!compact)` check.

This completely hid the ability to switch between light and dark modes on mobile devices.

The tenant selector was also crammed into the top-right corner.

This rendered it as a tiny popup menu on mobile instead of a prominent control.

I overhauled the visual presentation into a modern dashboard.

I replaced the single static layout with a scalable `LayoutBuilder`.

It serves a different structural paradigm based on screen size.

On wide desktop screens (>= 900px), it presents a web-app layout with a dedicated left sidebar.

The sidebar contains the branding, tenant selector, and theme controls.

On smaller mobile screens, it falls back to a clean native `AppBar`.

The tenant selector is placed prominently at the top of the scrolling body.

I also upgraded the aesthetic to a "floating" design.

I introduced deep soft shadows (`elevation: 8`), large rounded corners (`borderRadius: 24`), and clear color palettes such as Indigo and Sky blue.

The original tiny summary text chips were redesigned into large `_MetricCard` widgets.

These make the dashboard feel data-rich and polished.

### Security: missing HTTPS guard and token exposure risk

The AI's first generated `HttpSmsRepository` accepted any URI scheme, including plain `http://`.

It also did not validate whether the access token was present before making a request.

This could send an unauthenticated call and leak request data over cleartext.

I added a constructor guard that throws `ArgumentError` if the scheme is not `https`.

I added an early-exit check for a null or empty token before any request fires.

I also wrote a test confirming that `http://` is rejected at construction time.

### Security: PII leaking through logger

The AI's first rebuilt logger used the standard `Logger` package with default formatting.

That formatting calls `toString()` on exceptions.

If an exception message contained a phone number, message body, or bearer token, all of that would appear in the console output.

I wrapped the logger behind `AppLogger`.

`AppLogger` only accepts fixed `AppLogEvent` enum values.

It logs the exception's `runtimeType`, never its message content.

I wrote a regression test (`app_logger_test.dart`).

It passes an exception containing a fake token, phone number, and message body through `AppLogger.error()`.

It then asserts that none of that content appears in the output.

### Money: missing currency guard

The AI's first `Money` class stored fixed-scale units correctly.

It did not track currency.

This meant `Money` values in EUR and USD could be added without error, producing a silently wrong total.

I added a `currency` field.

I added a mixed-currency guard on the `+` operator that throws `ArgumentError`.

I added a test confirming that EUR + USD is rejected.

The `Money.parse()` factory also rejects values without exactly four decimal places.

This matches the contract's precision requirement.

### UI: ListTile ink splash hidden by ColoredBox

The AI used `Container(color: ...)` as the root wrapper for the sidebar widget.

Flutter internally converts `Container(color:)` into a `ColoredBox`.

A `ColoredBox` is not a `Material` surface.

When `ListTile` widgets were placed inside it, Flutter threw an assertion at runtime:

> "ListTile background color or ink splashes may be invisible. The ListTile is wrapped in a ColoredBox that has a background color."

I fixed this by replacing `Container(color: ...)` with a proper `Material(color: ...)` widget.

`Material` is an actual ink surface.

This means `ListTile` can now correctly paint its ripple and background on it.

I also added a mini `CircularProgressIndicator` inside the sidebar's refresh `ListTile`.

This means the user always knows when a data fetch is in progress.

### Mock data: identical data generated across tenants

The AI's `FakeSmsRepository` used a generic formula based on the tenant's hash code (`hashCode % 5 + 3`).

It tried to generate a different number of mock messages per tenant.

However, `'north'.hashCode % 5` and `'orbit'.hashCode % 5` evaluated to the same result.

This meant the dashboard showed the same number of messages, costs, and statuses regardless of which tenant was selected.

I replaced the hash-based generation with explicit, hardcoded seed data per tenant ID:
- **Northwind Health** now shows 12 messages with a mix of statuses (delivered, failed, sent) and higher spend, using TWILIO.
- **Orbit Retail** shows 5 messages (mostly delivered) with lower spend, using VONAGE.

This also fixed the issue where the AI had not generated any `DeliveryStatus.failed` records to test the UI's error states.

### Scroll performance: eager list building caused scroll jank

The AI generated the mobile "All Messages" history page using `ListView(children: [...])`.

It used a `for` loop that eagerly built every message tile inside a `Container > Column`.

This meant all 30+ items were laid out and painted upfront on every frame, even the ones off-screen.

On a real device (Pixel 7 Pro), the list visibly stuttered during fast scrolling.

The same problem existed on the home screen.

The `MessageHistory` widget sat inside a `SingleChildScrollView`.

There was no `RepaintBoundary`.

This meant the entire history section was repainted on every scroll frame of the parent, even though its content had not changed.

**What was generated:**

```dart
// mobile_history_page.dart â€” builds ALL items eagerly
ListView(
  children: [
    Container(
      child: Column(
        children: [
          for (int i = 0; i < filtered.length; i++) ...[
            HistoryTile(item: filtered[i], currency: currency),
            if (i < filtered.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    ),
  ],
);
```

**What I replaced it with:**

```dart
// mobile_history_page.dart â€” lazy building, only visible items are rendered
ListView.builder(
  controller: _scrollController,
  itemCount: totalItems,
  itemBuilder: (context, index) {
    // Each item built on demand with per-item border decoration
    return Container(
      decoration: BoxDecoration(/* per-item rounded borders */),
      child: HistoryTile(item: filtered[itemIndex], currency: currency),
    );
  },
);

// body.dart â€” prevents unnecessary repaints during parent scroll
RepaintBoundary(child: history);
```

---

## What I Reviewed Myself

I manually reviewed and took ownership of the following:
- No hardcoded secrets, tokens, or API keys in any committed file
- HTTPS enforcement with a runtime guard and a test
- `X-Tenant-Id` attached to every outbound request
- Fixed-scale money and currency rules, with no `double` anywhere
- Tenant generation checks and the slow-A/fast-B race
- Authorization headers and refresh-once behavior
- The rule that tokens, phone numbers, and message bodies must not be logged
- `AppLogger` only emitting enum names and `runtimeType`, with a regression test
- `202 ACCEPTED` wording and duplicate-send protection
- The send button returning to a normal state after every outcome: success, error, and rate limit
- Dependency versions verified against pub.dev and `flutter pub outdated`
- Every deprecation warning resolved via `flutter analyze`
- Every regression test and golden change
- The real Pixel and Chrome captures

I also asked the assistant to add the `logger` package.

I kept it behind `AppLogger` with fixed event names.

Exceptions log only their runtime type.

I added a test that puts a fake token, full phone number, and message text inside an exception.

It confirms that none of that content reaches the logger output.

AI helped me move faster.

It also produced mistakes that looked reasonable on a quick read.

The review, tests, platform runs, and corrections are the parts I consider my engineering work.