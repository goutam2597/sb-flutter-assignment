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

Regenerate the committed golden only when intentionally reviewing a visual change:

```bash
flutter test --update-goldens test/golden_test.dart
```

## Part 2: what was rebuilt

### Architecture and state management

Widgets depend on a `SmsConsoleController`, never on networking. The controller is a lean `ChangeNotifier` state machine that coordinates initial loading, refresh, sending, and load-more operations. The repository remains an interface so a production HTTP implementation can replace the fake without presentation changes.

The detailed trade-off is recorded in [ADR 0001](docs/adr/0001-state-management-and-adaptive-layout.md). ChangeNotifier was chosen for proportionality: one screen and no third-party state dependency. The important boundary is not the package name; it is that tenant, money, pagination, retry, and duplicate-submit rules are outside widgets and directly testable.

```text
lib/
├── app.dart                         dependency wiring and theme mode
├── domain/
│   ├── models.dart                  Money, records, failures
│   └── sms_repository.dart          repository + refresh-once decorator
├── data/fake_sms_repository.dart    contract-faithful local implementation
├── presentation/
│   ├── sms_console_controller.dart  async state and tenant generation
│   ├── sms_console_page.dart        adaptive page composition
│   └── widgets.dart                 reusable customer-facing components
└── theme/app_theme.dart             Material 3 themes and spacing tokens
```

### Exact money

`Money` stores ten-thousandths as an integer and carries its ISO currency code. It never parses to `double`. Multiplication is integer multiplication, so `0.0079 × 3` produces exactly `0.0237`. Adding different currencies throws instead of silently creating a false total. Formatting is centralized and preserves four decimal places and the server currency code.

### Data contract and backend strategy

`SmsRepository` exposes typed send, history, and cost results. `FakeSmsRepository` is the default runtime dependency and simulates bounded latency, seeded masked recipients, accepted send responses, exact provider costs, opaque cursor tokens, and typed failures. Tests can set a failure deterministically without exposing scenario controls in the customer UI.

A real HTTP repository would implement the same interface, parse JSON only inside model/data factories, take its HTTPS base URL from environment configuration, and attach both `Authorization: Bearer …` and `X-Tenant-Id` through a shared client. Permanent provider credentials never belong in Flutter. `RefreshingSmsRepository` performs one refresh and one retry after unauthorized; refresh failure or a second unauthorized response becomes `SessionFailure`, preventing loops.

### Tenant isolation

Tenant switching immediately clears cost, history, receipt, cursor, and error state. Each async operation captures a monotonically increasing generation. Results and finalizers are ignored if the generation changed while the request was in flight. Cache/state is therefore tenant-scoped, and a regression test proves a slow Northwind result cannot overwrite faster Orbit data.

### Customer states and component boundaries

- `SendSmsForm` owns controllers and validation presentation; it receives only `sending` and an async callback. It disables submission in flight, while the controller provides a second duplicate guard.
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
- Unauthorized → refresh → retry exactly once.
- Refresh failure terminates as session-expired.
- Slow Tenant A cannot overwrite Tenant B.
- Invalid phone validation performs no send.
- Provider failure stops progress and restores the send action.
- Successful send is labelled accepted, never delivered.
- 360 px light-theme loaded golden.

## Platform notes and screenshots

The layout is implemented and golden-tested at 360 px. Desktop composition activates at 900 px and is constrained for 1400 px windows. Mobile keyboards reduce usable height, so the entire body scrolls; desktop users need mouse-wheel scrolling, focus indication, resizing, and selectable IDs. Native font metrics can shift wrapping, and web text selection differs from mobile gestures.

Actual Android and desktop screenshots are intentionally not included yet because those platform runs have not been performed in this environment. Add only real captures after running both targets; do not substitute fabricated images.

## Deliberate cuts and another week

Within the time-box, this submission does not implement a real HTTP backend, bulk SMS, full sign-in UI, secure-device token persistence, WebSockets, localization, analytics, or elaborate animation. The contract defines no push endpoint, so history uses manual refresh.

With another week I would add a production HTTP adapter with model parsing fixtures and header-interceptor tests, secure token storage integrated with the real identity flow, cancellation in addition to generation checks, status progression in the fake, rate-limit countdown UI, more screen-reader testing, Android/Windows/Web platform runs, and real screenshots at 360 and 1400 px.

## Security posture

The runtime contains no API/provider secrets, tokens, full recipient logs, or cleartext service URL. The original insecure `lib/sms_console.dart` is retained only as the Part 1 review artifact, excluded from analysis, and never imported by the application. In a real client, only short-lived user tokens would be stored using platform secure storage; permanent credentials remain server-side.
