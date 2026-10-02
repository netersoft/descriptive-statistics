# Statistique Descriptive - Agent Guide

Descriptive statistics calculator (discrete, continuous and qualitative variables), published
on the Play Store as `com.neteru.tixtat`. The Dart package is `descriptive_statistics`.
See README.md for the feature list.

## Project Setup

```bash
cp .env.example .env
flutter pub get
dart run slang                                            # translations
dart run build_runner build --delete-conflicting-outputs  # Riverpod, Hive, injectable
flutter run
```

Generated files (`*.g.dart`, `locator.config.dart`) are not committed: rerun the two
generators after changing translations, providers, Hive types or injectable services.

## Code Quality

```bash
dart format .
flutter analyze
flutter test
```

CI fails on unformatted code, analyzer issues, failing tests, or hand-written line
coverage under 10%.

## Architecture

- **Calculations** (`lib/core/stats/`): pure Dart functions returning immutable result
  objects. Every value is rounded with `arrondi` to the user's precision, which the result
  carries along.
- **State** (`lib/core/providers/`): Riverpod with code generation.
- **Views** (`lib/view/`): screens and components. Calculator UI pieces are in
  `lib/view/components/calculators/`.
- **Storage**: Hive CE for backups (`lib/core/data/backups/`), SharedPreferences for
  settings.
- **Routing**: go_router. **DI**: GetIt + injectable for infrastructure singletons.
- **i18n**: Slang. Sources are in `assets/i18n/*.i18n.json`, French is the base locale, and
  every key must exist in fr, en, de, es and pt. Use `context.t` in widgets.

## Statistics conventions

- Continuous classes are [L1 ; L2[. Default classes follow the Sturges rule, with widths
  rounded to 1, 2, 2.5 or 5 ×10^k.
- Formulas and wording follow the legacy Android app this app rewrites. When the new app
  deliberately differs, a comment explains why.

## Testing

Unit and widget tests live under `test/`, mirroring `lib/`. Infrastructure singletons are
mocked with `mocktail` through a GetIt test-locator override (`test/helpers/test_utils.dart`).
Widget tests run in French, so finders use the French strings.

```bash
flutter test
```

## Release

Bump `version` in `pubspec.yaml`, then
`flutter build appbundle --release --flavor prod` with `android/key.properties` present.
Never commit `key.properties`, `*.jks` or `*.keystore`.
