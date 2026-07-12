# ADR 0001: ChangeNotifier state and adaptive composition

## Context

The console coordinates three asynchronous workflows: sending, cost loading, and opaque-cursor history pagination. It must also discard stale results when a tenant changes. The assignment is one screen with a 6–8 hour budget, but the state transitions must remain independently testable and widgets must contain no repository logic.

## Decision

Use one `SmsConsoleController` based on Flutter's `ChangeNotifier`, injected with an abstract `SmsRepository`. The controller owns request flags, typed results, user-safe errors, pagination cursors, and a monotonically increasing tenant generation. A result may update state only when its captured generation still matches.

Use `LayoutBuilder` at a 900 px content breakpoint. Narrow layouts form a single scrollable column; wide layouts use a fixed 410 px action rail beside a flexible history workspace. Components receive data and callbacks rather than repositories: `SendSmsForm`, `CostBreakdownRow`, `HistoryTile`, and `StatePanel`.

## Alternatives considered

- **Cubit / flutter_bloc:** excellent explicit transitions and test tooling, but adds a dependency and state-class ceremony for this small screen. It becomes preferable if more SMS workflows or independently owned features arrive.
- **Riverpod:** strong dependency composition and cancellation patterns, but introduces provider concepts that exceed the current scope.
- **Full Bloc:** events are valuable for complex concurrency, but verbose for three direct commands.
- **StatefulWidget-only:** lowest setup cost, rejected because repository calls and tenant/security rules would become coupled to widget lifetime and hard to test.

## Consequences

The approach uses only Flutter SDK primitives, is easy to inject in tests, and makes tenant invalidation visible. The downside is mutable controller state and coarse listener notifications; large features could rebuild too broadly or make transitions harder to inspect. If the screen grows, migrate behind the existing repository/component boundaries to Cubit without changing the data layer.
