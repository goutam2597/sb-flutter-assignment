# Studio Butterfly Flutter Assignment

[![Flutter checks](https://github.com/goutam2597/sb-flutter-assignment/actions/workflows/flutter.yml/badge.svg)](https://github.com/goutam2597/sb-flutter-assignment/actions/workflows/flutter.yml)

This is my submission for the Studio Butterfly Flutter take-home.

I kept the original assignment files at the repository root.

I put the rebuilt Flutter application inside `sb_sms/`.

I completed the work in five parts:

1. I reviewed the supplied AI-generated screen.
   I recorded the real security, money, tenancy, and async problems in [REVIEW.md](sb_sms/docs/REVIEW.md).
2. I rebuilt the SMS console with Cubit, typed models, exact money, tenant isolation, a fake repository, and a replaceable HTTP repository.
3. I added unit, repository, Cubit, widget, logging-privacy, and golden tests.
4. I ran the app on Chrome at 360×900 and 1400×900 and on a physical Pixel 7 Pro.
5. I added the ADR, AI disclosure, documentation, screenshots, and passing GitHub Actions checks.

The detailed explanation is in [sb_sms/docs/README.md](sb_sms/docs/README.md).

---

## Important Files

- [Implementation and run guide](sb_sms/docs/README.md)
- [My review findings](sb_sms/docs/REVIEW.md)
- [API contract](API-CONTRACT.md)
- [Assignment](ASSIGNMENT.md)
- [Architecture decision](sb_sms/docs/adr/0001-state-management-and-adaptive-layout.md)
- [AI usage disclosure](sb_sms/docs/AI-USAGE.md)

---

## Quick Start

```bash
cd sb_sms
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```


The default build uses a contract-faithful fake.

This is because the assignment does not provide a running backend.

No API key or token is needed.