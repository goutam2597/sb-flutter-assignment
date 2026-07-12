# Butterfly SMS Console

This is my rebuild of the supplied SMS console. I did not treat it as a visual cleanup because the original problems were mainly security, money, tenant isolation, and failed async flows.

The app runs with a fake repository by default. The assignment explicitly allows a stub because the real backend is not supplied. I also added `HttpSmsRepository` to show how I would connect the same UI and Cubit to the real API without bringing the old insecure code back.

## How I ran it

I used Flutter 3.44.5 stable and Dart 3.12.2.

```bash
flutter pub get
flutter run -d chrome
flutter run -d <android-device-id>
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

I only regenerate the golden when I intentionally approve a visual change:

```bash
flutter test --update-goldens test/golden_test.dart
```

CI pins Flutter 3.44.5. Ubuntu runs formatting, analysis, and the 19 platform-neutral tests. Windows runs the tagged golden because the committed pixels were generated on Windows. I split these jobs after the first CI version incorrectly compared a Windows golden on Ubuntu.

## What I changed

### State management

I used `flutter_bloc` with `SmsConsoleCubit` and immutable `SmsConsoleState`. The widgets only render state and call Cubit methods. They do not know whether data comes from the fake or HTTP repository.

I chose Cubit instead of full event-based Bloc because this screen has four clear commands: refresh, send, load more, and switch tenant. Full Bloc would add events and handlers without solving an extra problem here. My full reasoning is in [ADR 0001](docs/adr/0001-state-management-and-adaptive-layout.md).

### Project structure

```text
lib/
├── app.dart
├── core/logging/app_logger.dart
├── domain/
│   ├── models.dart
│   └── sms_repository.dart
├── data/
│   ├── fake_sms_repository.dart
│   └── http_sms_repository.dart
├── presentation/
│   ├── sms_console_controller.dart
│   ├── sms_console_page.dart
│   └── widgets.dart
└── theme/app_theme.dart
```

I kept the structure small because this is one feature. I did not add empty use-case classes or layers only to make the folder tree look more complicated.

### Exact money

The API sends money as decimal strings with four decimal places. My `Money` value stores ten-thousandths as an integer and keeps the ISO currency code with the amount. It never uses `double`.

This means:

```text
0.0079 × 3 = 0.0237 exactly
```

Adding EUR to USD throws instead of producing a believable but invalid total. The UI formats the actual API/fake response cost and does not calculate a guessed provider rate.

### Fake and HTTP repositories

`FakeSmsRepository` is the default so that a reviewer can run every screen without a backend or credentials. It provides bounded delay, masked recipients, authoritative fake costs, accepted sends, typed failures, and opaque cursor tokens.

`HttpSmsRepository` is the real network boundary. I rebuilt the useful intent from the starter but did not reuse its unsafe constants or request code. It:

- rejects a non-HTTPS base URL;
- gets a short-lived access token from an injected provider;
- sends `Authorization` and `X-Tenant-Id` on every request;
- applies a timeout;
- maps `400`, `401`, `403`, `429` with `Retry-After`, and `502` to typed failures;
- parses JSON inside the data layer; and
- passes history cursors through without decoding them.

When the real authentication composition is wired, `HttpSmsRepository.configuredBaseUri()` reads the base URL from:

```bash
flutter run --dart-define=SMS_API_BASE_URL=https://example.invalid
```

That define is configuration only; it does not switch the default fake repository by itself. The HTTP repository also needs an injected access-token provider. Tokens and provider secrets must never be compiled into Flutter.

`RefreshingSmsRepository` retries an unauthorized operation once after refresh. A failed refresh or second unauthorized response becomes a session-expired failure, so it cannot loop forever.

### Tenant isolation

I treat tenant switching as a security boundary. Switching tenant clears cost, history, cursor, accepted receipt, error, and rate-limit state immediately.

Every request captures both its tenant and a generation number. If Tenant A completes after the user has moved to Tenant B, the Cubit ignores A's result. The regression test deliberately completes the requests in the wrong order.

### Debug logging

I use the `logger` package through one wrapper: `AppLogger`. I do not create `Logger()` instances in features.

The wrapper accepts fixed `AppLogEvent` values instead of arbitrary user data. I log lifecycle events such as `sendStarted`, `sendAccepted`, `refreshFailed`, and `tokenRefreshStarted`. I do **not** log:

- access or refresh tokens;
- authorization headers;
- recipient numbers;
- SMS bodies;
- tenant identifiers; or
- full URLs/query parameters.

When an exception is logged, `AppLogger` records only its runtime type, not its message. The `logger` package's `DevelopmentFilter` suppresses these logs in release builds. A test passes a token, full phone number, and message text inside an exception and proves none of them reach the log output.

### Send flow and user states

The form validates an E.164-like recipient before calling the repository. The UI disables the action while sending, and the Cubit has a second guard, so two fast submissions still create one repository call.

A 202 response is shown as “Accepted by provider,” not delivered. `429` starts a visible retry countdown and blocks another send. A provider failure says that no message was sent. Every loading flag has a success or failure exit.

I extracted these reusable boundaries:

- `SendSmsForm` owns text fields and validation display;
- `CostBreakdownRow` renders provider totals without inventing recipients;
- `HistoryTile` renders already-masked history records; and
- `StatePanel` handles empty and recoverable error states consistently.

## Tests I added

The suite currently has 20 tests: 19 platform-neutral tests and one golden.

- exact decimal multiplication, malformed decimals, and mixed currencies;
- required auth and tenant headers;
- HTTPS enforcement and typed response parsing;
- `429`, `502`, timeout, and malformed-response handling;
- opaque cursor forwarding and fake pagination;
- refresh once and session-expired termination;
- slow Tenant A not overwriting Tenant B;
- rapid duplicate send producing one billable call;
- successful send returning `sending` to false;
- invalid phone validation;
- provider failure recovery;
- accepted-not-delivered wording;
- logging output not exposing error contents; and
- the 360 px light-theme golden.

Commands I ran successfully before this documentation update:

```text
dart format: clean
flutter analyze: no issues
flutter test --exclude-tags golden: 19 passed
flutter test test/golden_test.dart: 1 passed
```

## Platforms I actually checked

I ran Part 4 on 12 July 2026:

- Pixel 7 Pro over wireless ADB, Android 17/API 37, Impeller Vulkan;
- Chrome 150 on Windows at 360×900; and
- Chrome 150 on Windows at 1400×900.

| Pixel 7 Pro | Chrome at 360×900 |
|---|---|
| <img src="docs/screenshots/android-pixel-7-pro.png" width="280" alt="Butterfly SMS on Pixel 7 Pro"> | <img src="docs/screenshots/web-360.png" width="280" alt="Butterfly SMS in Chrome at 360 by 900"> |

### Chrome at 1400×900

![Desktop two-column SMS console](docs/screenshots/web-1400.png)

### What I noticed across platforms

- At 360 px I needed a compact labelled tenant button, one scrolling column, and a `FloatingActionButton` that opens a sleek modal dialog to compose SMS messages.
- At 1400 px I used a 410 px action/spend rail and gave the remaining width to history. I capped the content instead of stretching it edge to edge, transitioning smoothly between the mobile and desktop states using `AnimatedSwitcher` and `AnimatedContainer`.
- To support a premium desktop/mobile feel, I implemented a custom "pure black" OLED dark mode that forces `#000000` backgrounds with distinct white borders, overriding the default Material tinted surfaces.
- `SafeArea` kept the Pixel status and navigation areas clear.
- Android and Chrome use different font metrics. Flexible rows and no fixed text heights prevented clipping in the captures.
- Flutter Web uses a canvas, so normal browser DOM automation does not see all controls until Flutter's accessibility bridge is active. I therefore kept widget semantics tests as well as visual browser checks.
- I made message IDs selectable for desktop. TalkBack, VoiceOver, and full physical-keyboard traversal still need dedicated manual passes.

## What I deliberately did not do

I did not build a backend, bulk SMS UI, complete sign-in flow, secure token persistence, WebSocket client, localization, analytics, or complex animations. These were outside the 6–8 hour assignment priority and some are not defined by the API contract.

The contract does not define push delivery updates, so I used manual refresh instead of inventing an endpoint.

## What I would do with another week

I would connect `HttpSmsRepository` to the real identity flow and platform secure storage, add cancellation as well as generation checks, expand fake delivery-status progression, run TalkBack and VoiceOver, and add verified iOS, Windows, and macOS runs.

## Security notes

The runtime has no API/provider secret, access token, refresh token, full recipient log, or cleartext service URL. I retained `lib/sms_console.dart` only as the reviewed Part 1 artifact. It is not imported by the app and the original credential literal was redacted before the public repository was created.
