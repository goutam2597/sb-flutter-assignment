# AI usage

Codex was used to inspect the assignment and API contract, propose the feature boundaries, scaffold the typed domain/repository/controller layers, implement the adaptive Flutter UI, and draft tests and documentation. Every generated file was subsequently read and checked against the contract.

## A concrete mistake and correction

The first generated fake repository returned cursors as decimal offsets and parsed them with `int.tryParse`. That violated the contract's rule that cursors are opaque to clients. It was replaced with opaque cursor tokens stored in a private lookup map; presentation code now only passes the returned string through unchanged. A regression test requests the next page using the exact returned token.

The first generated `Money` type also stored only fixed-scale units. Arithmetic was exact, but it could add EUR to USD. Currency is now part of the value object, equality includes currency, and mixed-currency addition throws. Tests cover both exact `0.0079 × 3 = 0.0237` and currency rejection.

## Areas manually reviewed

Money parsing/arithmetic, tenant generation checks, refresh-once behavior, recipient masking, error copy, and the absence of credentials/recipient logging were reviewed line by line. Analyzer output alone was not accepted as proof of contract compliance.
