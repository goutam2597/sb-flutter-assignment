# AI usage

Codex was used heavily as an implementation partner. It read the assignment and contract, proposed feature boundaries, scaffolded the fixed-scale money and repository layers, generated the first Cubit/UI/test drafts, and drafted the README, ADR, and CI workflow. I reviewed the resulting files against the contract, ran the application on Chrome and a physical Pixel 7 Pro, and kept only behavior I can explain and defend.

## Concrete mistakes caught and replaced

1. The first fake repository represented cursors as decimal offsets and parsed them with `int.tryParse`. That violated the contract's opaque-cursor rule. It was replaced with private token-to-position lookup; presentation code only passes the returned string back. Repository tests protect the round trip.
2. The first `Money` value stored exact fixed-scale units but no currency, allowing EUR and USD to be added. Currency is now part of identity and mixed-currency addition throws. Tests cover `0.0079 × 3 = 0.0237`, malformed decimals, and currency mismatch.
3. The initial state draft used mutable `ChangeNotifier` fields. That did not match the selected Bloc architecture. It was replaced with `flutter_bloc`, immutable `SmsConsoleState`, and `SmsConsoleCubit`; tenant-race and duplicate-send tests exercise it without widgets.
4. The first CI draft ran a Windows-generated golden on Ubuntu, producing 18 passes and one pixel-comparison failure. CI now runs platform-neutral tests on Ubuntu and the tagged golden on a pinned Windows job.

## Work manually owned and reviewed

I manually reviewed the mechanisms where generated code was not trusted by default:

- fixed-scale arithmetic, currency equality, formatting, and use of authoritative server cost;
- the request generation/tenant checks that reject stale Tenant A results after switching to Tenant B;
- refresh-once behavior, including refresh failure and second-401 termination;
- HTTP headers, HTTPS enforcement, timeout/status mapping, and the absence of token or recipient logging;
- recipient masking and the rule that cost rows never invent phone numbers;
- `202 ACCEPTED` copy, duplicate billable-send protection, and rate-limit recovery;
- every regression assertion, the committed golden, physical Android output, and both web breakpoints.

AI output was therefore treated as a draft requiring contract review, not as evidence of correctness. Analyzer, tests, real platform runs, and the documented manual checks are the evidence used for this submission.
