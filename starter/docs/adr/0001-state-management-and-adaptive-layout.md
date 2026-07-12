# ADR 0001: Why I Used Cubit and an Adaptive Layout

## Context

I needed one screen to handle several async operations at the same time.

These operations were:
- Initial cost and history loading
- Sending a message
- A rate-limit countdown
- Refresh
- Pagination
- Tenant switching

The hard part was not drawing the widgets.

The hard part was correctness under race conditions.

Two things had to be true:
- An old tenant response must never update the new tenant screen.
- Every loading state must finish, even when a request fails.

The same screen also had to work at two very different sizes.

It had to work as a 360 px phone screen and as a 1400 px desktop screen.

A mobile card should not stretch across the full width of a desktop window.

---

## Decision

I chose `flutter_bloc`.

I implemented `SmsConsoleCubit` with an immutable `SmsConsoleState`.

The Cubit receives `SmsRepository`.

Widgets read state through `BlocBuilder` and call Cubit methods.

Widgets do not call the repository directly.

Widgets do not calculate money.

This keeps all business rules in one place and out of the UI.

### Tenant isolation

Every async operation captures the current tenant and a generation number.

The operation can emit a result only if both still match when it completes.

This means a response from an old tenant is discarded instead of being shown.

I also cancel the rate-limit timer when the Cubit closes.

This prevents the timer from firing after the screen is gone.

### Layout

I use `LayoutBuilder` with a single 900 px breakpoint.

Below the breakpoint, I show one scrollable column.

This layout uses a native `AppBar` and a `FloatingActionButton`.

The button opens a custom modal dialog for sending messages.

Above the breakpoint, I use a 410 px send/spend rail and a flexible history area.

I wrapped the responsive switches in `AnimatedSwitcher` and `AnimatedContainer`.

This means the layout transitions smoothly as the window resizes, rather than snapping between states.

### Dark mode

The design had to feel intentional, not like an afterthought.

To support this, I designed a custom "pure black" OLED-style dark mode.

It overrides the default Material tinted surfaces.

It locks all dialogs, app bars, and backgrounds to true black (`#000000`).

It uses distinct white borders for spatial separation.

---

## Alternatives I Considered

### Full Bloc

I rejected full event-based Bloc for this screen.

Events would help if the feature had many external event sources.

Here, the public commands are only refresh, send, load more, and switch tenant.

Cubit gives me explicit immutable transitions with less ceremony.

### Riverpod

Riverpod has good dependency and cancellation support.

I did not choose it because it would add a second set of provider concepts for one screen.

The repository injection and generation check already solve the required problems.

### ChangeNotifier

My first implementation used `ChangeNotifier`.

It worked.

However, its mutable public fields and broad notifications made the async transitions harder to review.

I replaced it with Cubit instead of defending the first draft.

### StatefulWidget only

I rejected this approach.

It would move tenant, money, retry, and repository rules into widget lifecycle code.

This means the logic would become harder to test without rendering the UI.

---

## Consequences

The result is easy to test without widgets.

The tenant-race behavior is visible in one place.

The cost is one extra dependency.

It also requires understanding Cubit emission order.

The single state object can rebuild more of the page than necessary.

If profiling later shows this is a real issue, I would use `BlocSelector` for the busy sections.

I would not split the state prematurely.

The layout has one explicit breakpoint instead of a general responsive framework.

This is enough for the required phone and desktop widths.

More product screens may justify shared adaptive layout primitives later.