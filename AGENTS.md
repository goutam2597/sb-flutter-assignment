# Repository Guidelines

## Project Structure & Module Organization

The repository root contains the assignment, API contract, Part 1 review, and submission landing page. The Flutter application is under `starter/`. Inside it, `lib/domain/` defines exact money, typed failures, SMS records, and repository interfaces; `lib/data/` supplies fake and HTTP adapters; `lib/presentation/` contains Cubit state, the adaptive page, and reusable widgets; and `lib/theme/` centralizes Material 3 themes and spacing. Architecture rationale lives in `starter/docs/adr/`, while AI disclosure is in `starter/AI-USAGE.md`. The original insecure `starter/lib/sms_console.dart` remains an unimported Part 1 audit artifact and is excluded from analysis.

## Build, Test, and Development Commands

Run Flutter commands from `starter/`:

- `flutter pub get` resolves dependencies.
- `flutter run -d chrome` runs the fake-backed console on web.
- `flutter analyze` applies `flutter_lints` and analyzer checks.
- `flutter test` runs all unit, controller, widget, and golden tests.
- `flutter test test/controller_test.dart` runs one test file.
- `flutter test --update-goldens test/golden_test.dart` intentionally regenerates the committed 360 px golden.
- `dart format --output=none --set-exit-if-changed lib test` checks formatting.

## Coding Style & Naming Conventions

Use Dart formatter output and the rules in `starter/analysis_options.yaml`. Keep repository and financial logic out of widgets. Model API results with typed immutable classes; do not introduce `dynamic` casts at call sites. Monetary values remain fixed-scale decimal strings converted to `Money`, never `double`. Preserve opaque cursors and generation checks when editing pagination or tenant flows.

## Testing Guidelines

Tests use `flutter_test`. Add regressions near the relevant layer: money/auth/network mapping in unit tests, tenant races in Cubit tests, and customer-visible behavior in widget tests. Golden changes must be intentional and visually reviewed.

## Commit & Pull Request Guidelines

This repository begins without prior commit conventions. Use concise imperative prefixes such as `feat:`, `fix:`, `test:`, `docs:`, and `ci:`. PR descriptions should identify contract impact, commands actually run, and any deliberately unverified platform behavior.
