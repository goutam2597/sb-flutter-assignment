# ADR 0001: Why I used Cubit and an adaptive layout

## Context

I needed one screen to manage several async operations at the same time: initial cost/history loading, sending, a rate-limit countdown, refresh, pagination, and tenant switching. The difficult part was not drawing the widgets. It was making sure an old tenant response could not update the new tenant screen and that every loading state finished.

I also needed the same feature to work as a 360 px phone screen and a 1400 px desktop screen without stretching a mobile card across the window.

## Decision

I chose `flutter_bloc` and implemented `SmsConsoleCubit` with immutable `SmsConsoleState`.

The Cubit receives `SmsRepository`. Widgets read state through `BlocBuilder` and call Cubit methods. They do not perform repository calls or calculate money.

For tenant isolation, every async operation captures the current tenant and a generation number. The operation can emit only if both still match when it completes. I cancel the rate-limit timer when the Cubit closes.

For layout, I use `LayoutBuilder` with a 900 px breakpoint. Below the breakpoint I show one scrollable column. Above it I use a 410 px send/spend rail and a flexible history area. Reusable widgets receive typed data and callbacks rather than the Cubit or repository where that is not needed.

## Alternatives I considered

### Full Bloc

I rejected full event-based Bloc for this screen. Events would be useful if the feature had many external event sources, but here the public commands are only refresh, send, load more, and switch tenant. Cubit gives me explicit immutable transitions with less ceremony.

### Riverpod

Riverpod has good dependency and cancellation support. I did not choose it because it would introduce a second set of provider concepts for one screen, while the repository injection and generation check already solve the required problems.

### ChangeNotifier

My first implementation used `ChangeNotifier`. It worked, but its mutable public fields and broad notifications made the async transitions harder to review. I replaced it with Cubit instead of defending the first draft.

### StatefulWidget only

I rejected this because tenant, money, retry, and repository rules would move into widget lifecycle code and become harder to test without rendering the UI.

## Consequences

The result is easy to test without widgets, and the tenant-race behavior is visible in one place. The cost is one extra dependency and the need to understand Cubit emission order. The single state object can also rebuild more of the page than necessary. If profiling later shows that as a real issue, I would use `BlocSelector` for the busy sections rather than splitting state prematurely.

The layout has one explicit breakpoint instead of a general responsive framework. That is enough for the required phone and desktop widths, but more product screens may justify shared adaptive layout primitives later.
