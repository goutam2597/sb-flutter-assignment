# ADR 0001: Cubit state management and adaptive composition

## Context

The console coordinates initial cost/history loading, sending, rate-limit countdowns, refresh, and opaque-cursor pagination. Tenant changes must immediately clear scoped data and reject stale responses. These transitions must be testable without rendering widgets, while the project remains proportional to a single-screen take-home.

## Decision

Use `flutter_bloc` with one `SmsConsoleCubit` and immutable `SmsConsoleState`. The Cubit is injected with `SmsRepository`; widgets render state through `BlocBuilder` and invoke commands through `context.read<SmsConsoleCubit>()`. State contains typed results, independent loading flags, user-safe error text, the current tenant, pagination cursor, accepted receipt, and rate-limit seconds.

Each asynchronous operation captures the tenant ID and a monotonically increasing generation. It may emit a result only when both still match. `close()` cancels the countdown timer. This makes concurrency and cleanup part of the state boundary rather than widget lifecycle code.

Use `LayoutBuilder` at a 900 px content breakpoint. Narrow layouts form one scrollable column; wide layouts use a fixed 410 px action rail beside a flexible history workspace. Reusable components receive typed values and callbacks, never repositories.

## Alternatives considered

- **Full event-based Bloc:** explicit events help large workflows, but add ceremony when the public API is only `refresh`, `send`, `loadMore`, and `switchTenant`.
- **Riverpod:** strong dependency composition and cancellation, but introduces provider concepts beyond this screen's needs.
- **ChangeNotifier:** initially attractive because it is SDK-only, but mutable public fields and coarse notifications make async transitions less explicit.
- **StatefulWidget-only:** rejected because repository, billing, and tenant-security rules would couple to widget lifetime and become difficult to test.

## Consequences

State transitions are explicit, immutable, observable, and independently testable. Bloc adds one runtime dependency and developers must understand emission ordering. A single state object can rebuild more of the page than necessary; `BlocSelector` can narrow rebuilds if profiling later shows a real cost.
