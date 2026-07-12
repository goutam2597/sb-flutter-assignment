# Studio Butterfly Flutter Assignment

[![Flutter checks](https://github.com/goutam2597/sb-flutter-assignment/actions/workflows/flutter.yml/badge.svg)](https://github.com/goutam2597/sb-flutter-assignment/actions/workflows/flutter.yml)

This repository contains the Studio Butterfly SMS Console take-home submission.

- [Implementation overview and run instructions](starter/README.md)
- [Code review findings](REVIEW.md)
- [API contract](API-CONTRACT.md)
- [Assignment brief](ASSIGNMENT.md)
- [AI usage disclosure](starter/AI-USAGE.md)
- [Architecture decision](starter/docs/adr/0001-state-management-and-adaptive-layout.md)

The Flutter project lives in `starter/`:

```bash
cd starter
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

The application uses a contract-faithful fake repository and requires no backend or credentials.
