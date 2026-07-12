# Butterfly SMS Console

A contract-driven Flutter rebuild of the Studio Butterfly take-home starter. The runtime uses a deterministic fake backend, so reviewers can exercise sending, billing, history, errors, and tenant switching without credentials or a server.

## Run and verify

Prerequisites: Flutter stable. This implementation was developed with Flutter 3.44.5 and Dart 3.12.2.

```bash
flutter pub get
flutter run -d chrome
flutter run -d windows
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

CI pins Flutter 3.44.5. Platform-neutral analysis and tests run on Ubuntu; the tagged golden runs separately on Windows because rasterized golden pixels are OS-specific. This keeps the visual assertion active rather than silently accepting cross-platform pixel drift.

Regenerate the committed golden only when intentionally reviewing a visual change:

```bash
flutter test --update-goldens test/golden_test.dart
```

## Part 2: what was rebuilt

### Architecture and state management

Widgets consume immutable `SmsConsoleState` through `BlocBuilder` and send commands to `SmsConsoleCubit`; they never perform networking. The Cubit coordinates loading, refresh, sending, rate-limit recovery, tenant changes, and pagination.

The detailed trade-off is recorded in [ADR 0001](docs/adr/0001-state-management-and-adaptive-layout.md). Cubit was chosen over full event-based Bloc because the command surface is small but still benefits from immutable, observable async transitions.

```text
lib/
├── app.dart                         dependency wiring and theme mode
├── domain/
│   ├── models.dart                  Money, records, failures
│   └── sms_repository.dart          repository + refresh-once decorator
├── data/fake_sms_repository.dart    contract-faithful local implementation
├── presentation/
│   ├── sms_console_controller.dart  Cubit, immutable state, tenant generation
│   ├── sms_console_page.dart        adaptive page composition
│   └── widgets.dart                 reusable customer-facing components
└── theme/app_theme.dart             Material 3 themes and spacing tokens
```

### Exact money

`Money` stores ten-thousandths as an integer and carries its ISO currency code. It never parses to `double`. Multiplication is integer multiplication, so `0.0079 × 3` produces exactly `0.0237`. Adding different currencies throws instead of silently creating a false total. Formatting is centralized and preserves four decimal places and the server currency code.

### Data contract and backend strategy

`SmsRepository` exposes typed send, history, and cost results. `FakeSmsRepository` is the default runtime dependency and simulates bounded latency, seeded masked recipients, accepted send responses, exact provider costs, opaque cursor tokens, and typed failures. Tests can set a failure deterministically without exposing scenario controls in the customer UI.

`HttpSmsRepository` reconstructs the starter's network intent safely. It requires HTTPS, obtains a short-lived token from an injected provider, attaches `Authorization` and `X-Tenant-Id`, sends typed JSON, forwards opaque cursors, applies timeouts, and maps `400`, `401`, `403`, `429`/`Retry-After`, and `502` into typed failures. Supply the base URL with `--dart-define=SMS_API_BASE_URL=https://…`; credentials are never compiled into the app.

`RefreshingSmsRepository` decorates a repository and performs one refresh plus one retry after unauthorized; refresh failure or a second unauthorized response becomes `SessionFailure`, preventing loops. Permanent provider credentials never belong in Flutter.

### Tenant isolation

Tenant switching immediately clears cost, history, receipt, cursor, and error state. Each async operation captures a monotonically increasing generation. Results and finalizers are ignored if the generation changed while the request was in flight. Cache/state is therefore tenant-scoped, and a regression test proves a slow Northwind result cannot overwrite faster Orbit data.

### Customer states and component boundaries

- `SendSmsForm` owns text controllers and validation presentation; it receives only send state and an async callback. It disables submission in flight, while the Cubit provides a second duplicate guard.
- `CostBreakdownRow` receives a typed provider row and renders authoritative cost/message count. It never invents a recipient.
- `HistoryTile` displays already-masked recipients, status text/icon, segment count, ID, and cost.
- `StatePanel` provides consistent empty/error/retry states.

Initial failures replace the empty dashboard with a recovery action. Later failures preserve loaded data. A 202 result says “Accepted” and explicitly warns that delivery is pending. Provider failure states say no message was sent. Loading flags terminate in guarded `finally` blocks, and fake calls have an eight-second bound.

### Adaptive layout, theme, and accessibility

At narrow widths the page is one keyboard-safe scroll column. At 900 px and above it becomes a two-column operations workspace with a 410 px action/cost rail and flexible history. Content is constrained to 1320 px rather than stretching phone cards across desktop.

Material 3 light and dark themes centralize `ColorScheme`, surfaces, inputs, cards, buttons, typography, and spacing. Interactive icons have tooltips, the send action has semantics, controls meet 48 px targets, form labels persist, message input grows rather than using a fixed height, and status uses icon/text in addition to color. Message identifiers are selectable for desktop workflows.

## Tests and defect protection

- Exact fixed-scale multiplication and decimal validation.
- Mixed-currency addition rejection.
- Opaque cursor round trip.
- Required authorization and tenant headers on HTTP requests.
- HTTPS-only base URL enforcement and typed JSON parsing.
- `429 Retry-After`, `502`, timeout, and malformed-response mapping.
- Unauthorized → refresh → retry exactly once.
- Refresh failure terminates as session-expired.
- Slow Tenant A cannot overwrite Tenant B.
- Rapid duplicate sends produce one billable repository call.
- Invalid phone validation performs no send.
- Provider failure stops progress and restores the send action.
- Successful send is labelled accepted, never delivered.
- 360 px light-theme loaded golden.

## Platform notes and screenshots

Part 4 was run on two real targets on 12 July 2026:

- **Android:** Pixel 7 Pro connected wirelessly, Android 17 / API 37, Impeller Vulkan renderer.
- **Web:** Chrome 150 on Windows, explicitly resized to 360×900 and 1400×900.

### Verified captures

| Android — Pixel 7 Pro | Chrome Web — 360×900 |
|---|---|
| <img src="docs/screenshots/android-pixel-7-pro.png" width="280" alt="Butterfly SMS running on a Pixel 7 Pro"> | <img src="docs/screenshots/web-360.png" width="280" alt="Butterfly SMS in Chrome at 360 by 900 pixels"> |

#### Chrome Web — 1400×900

![Butterfly SMS desktop two-column layout](docs/screenshots/web-1400.png)

### What actually changed or needed attention

- At 360 px, the desktop tenant field becomes a compact labelled tenant button, the refresh action is reduced, the operational strip shows two signals, and all content becomes one scrollable column.
- At 1400 px, the content is capped rather than stretched: send and spend occupy a 410 px rail while history uses the remaining workspace. All seven seeded messages fit without turning the desktop into a wide phone card.
- The Pixel status/navigation areas are respected through `SafeArea`; the send action and tenant selector remain comfortably thumb-sized.
- Native Android and Chrome use different font metrics. Flexible rows, unfixed text heights, and the shortened mobile subtitle prevented clipping in the captured runs.
- Flutter Web renders through a canvas. Browser automation can resize and capture it, but its controls do not appear in the normal accessibility tree until Flutter's accessibility bridge is enabled. Semantics and focus behavior are therefore also protected by widget tests rather than relying only on DOM automation.
- Message IDs are `SelectableText` for mouse-based desktop support. Touch selection, physical-keyboard traversal, and screen-reader behavior should still be checked manually on the final release devices.

## Deliberate cuts and another week

Within the time-box, this submission does not implement a real HTTP backend, bulk SMS, full sign-in UI, secure-device token persistence, WebSockets, localization, analytics, or elaborate animation. The contract defines no push endpoint, so history uses manual refresh.

With another week I would connect the HTTP adapter to the real identity flow and secure token storage, add cancellation in addition to generation checks, expand status progression in the fake, perform TalkBack/VoiceOver testing, and add iOS, Windows, and macOS runs to the verified Android/Web matrix.

## Security posture

The runtime contains no API/provider secrets, tokens, full recipient logs, or cleartext service URL. The original insecure `lib/sms_console.dart` is retained only as the Part 1 review artifact, excluded from analysis, and never imported by the application. In a real client, only short-lived user tokens would be stored using platform secure storage; permanent credentials remain server-side.
