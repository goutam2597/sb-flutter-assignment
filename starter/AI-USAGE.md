# How I used AI

I used Codex heavily during this assignment. I gave it the assignment, API contract, and starter code, then used it to scaffold models, repositories, Cubit state, widgets, tests, documentation, and CI.

I did not accept a clean analyzer result as proof that the implementation was correct. I read the generated code against the contract, ran the failure cases, tested on Android and Web, and changed several generated decisions.

## Where the AI was wrong

### Cursor handling

The first fake repository used decimal offsets and parsed cursors with `int.tryParse`. That directly violated the contract because the client must treat the cursor as opaque. I replaced it with a private token-to-position lookup. The UI now only passes the returned string back.

### Money and currency

The first `Money` type used exact fixed-scale units, but it did not store currency. That meant EUR and USD could be added. I made currency part of the value and added a mixed-currency test.

### State management

The first state layer used `ChangeNotifier`. It was functional, but it did not match the Bloc decision and exposed mutable fields. I replaced it with `SmsConsoleCubit` and immutable state.

### Successful send finalizer

After a successful send, `refresh()` advanced the generation before the send `finally` block ran. The generated guard could therefore leave `sending=true`. I changed the finalizer to check the current tenant and actual sending state, then added a regression assertion.

### CI golden platform

The first CI workflow compared a Windows-generated golden on Ubuntu. GitHub reported 18 passed and one failed. I tagged the golden, kept the platform-neutral suite on Ubuntu, and added a pinned Windows golden job. Both public jobs now pass.

## What I reviewed myself

I manually reviewed and took ownership of:

- fixed-scale money and currency rules;
- tenant generation checks and the slow-A/fast-B race;
- authorization headers and refresh-once behavior;
- the rule that tokens, phone numbers, and message bodies must not be logged;
- `202 ACCEPTED` wording and duplicate-send protection;
- every regression test and golden change; and
- the real Pixel and Chrome captures.

I also asked Codex to add the `logger` package, but I kept it behind `AppLogger` with fixed event names. Exceptions log only their runtime type. I added a test that puts a fake token, full phone number, and message text inside an exception and confirms none of that content reaches the logger output.

AI helped me move faster, but it also produced mistakes that looked reasonable on a quick read. The review, tests, platform runs, and corrections are the parts I consider my engineering work.
