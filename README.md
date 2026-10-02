# Statistique Descriptive

[![Flutter CI](https://github.com/netersoft/descriptive-statistics/actions/workflows/flutter.yml/badge.svg)](https://github.com/netersoft/descriptive-statistics/actions/workflows/flutter.yml)

## Description

A descriptive statistics calculator for students, published on the Play Store as
[Statistique Descriptive](https://play.google.com/store/apps/details?id=com.neteru.tixtat)
(`com.neteru.tixtat`). It is the Flutter rewrite of a legacy native Android app.

- **Three calculators**: discrete variables (Xi, Ni), continuous variables (classes
  [L1 ; L2[, Ni) and qualitative variables (modalities, effectifs).
- **Entry**: row by row, bulk import, or a raw series ("3 5 5 7 3") tallied into rows.
  For continuous variables, classes default to the Sturges rule.
- **Results**: frequency table, means, mode, median, quartiles, deciles, variance,
  standard deviation, covariance/correlation, coefficient of variation, with a
  step-by-step explanation of every calculation.
- **Charts**: bar, line and box plot (quantitative), bar and pie (qualitative), chosen
  in Settings.
- **Backups**: save a result, reopen it in its calculator, share it as text.
- **Languages**: French (base), English, German, Spanish, Portuguese.

## Tech stack

- Flutter (stable channel), Dart SDK `>=3.8.0 <4.0.0`
- State: Riverpod with code generation (`riverpod_generator`)
- Routing: go_router
- Storage: Hive CE (backups) + SharedPreferences (settings)
- i18n: [Slang](https://pub.dev/packages/slang)
- Charts: fl_chart (the box plot is a `CustomPainter`)
- Android build: Gradle 9.3.1, AGP 9.1.0, Kotlin 2.4.0, Java 17

## Installation

```bash
cp .env.example .env
flutter pub get
dart run slang
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## Environment variables

`.env` is bundled as an asset, so everything in it is public. It only holds the theme
colors:

| Variable | Description | Example |
|----------|-------------|---------|
| `APP_PRIMARY_COLOR` | Primary theme color, hex | `#353839` |
| `APP_SECONDARY_COLOR` | Secondary theme color, hex | `#009ee3` |
| `APP_ACCENT_COLOR` | Accent theme color, hex | `#f5f5f5` |

## Running tests

```bash
flutter test
# with coverage, as run in CI:
flutter test --coverage
```

Unit and widget tests live under `test/`, mirroring `lib/`. Infrastructure singletons
are mocked with `mocktail` through a GetIt test-locator override
(`test/helpers/test_utils.dart`).

## Architecture

- `lib/main.dart`: entry point.
- `lib/core/bootstrap/app_bootstrap.dart`: env, Hive, DI and locale setup.
- `lib/app.dart`: root widget, theme and router.
- `lib/core/stats/`: the calculations, as pure functions (`computeDiscreteStats`,
  `computeContinuousStats`, `computeQualitativeStats`, raw-series grouping). They have
  no Flutter dependency and are the most heavily tested part.
- `lib/core/providers/`: Riverpod providers (calculator entry state, settings, home tab).
- `lib/core/data/backups/`: saved results (Hive).
- `lib/view/screens/`: calculators, backups, documentation, tutorial, settings, onboarding.
- `lib/view/components/calculators/`: entry form, dialogs, stats table, explanations,
  charts.

Generated files (`*.g.dart`, `locator.config.dart`) are not committed; rebuild them with
`dart run slang` and `dart run build_runner build`.

## Quality

```bash
dart format .
flutter analyze
flutter test
```

## Release

1. Bump `version` in `pubspec.yaml` (on a branch + PR).
2. Build the App Bundle with the release keystore (`android/key.properties`, never
   committed):

    ```bash
    flutter build appbundle --release --flavor prod
    ```

3. Upload `build/app/outputs/bundle/prodRelease/app-prod-release.aab` to the Play
   Console.

CI (`.github/workflows/flutter.yml`) runs formatting, analysis, tests and a coverage
floor on every PR and push to `master`. On `v*` tags or a manual dispatch, it also builds
a release APK (debug-signed, for QA only) and an unsigned iOS build. Nothing is
published to a store.

## Build flavors

`dev`, `staging` and `prod` only change the app identity (`applicationId` suffix and
name), so they can be installed side by side:

```bash
flutter run --flavor dev
```

iOS has no flavor schemes; build it without `--flavor`.

## Contacts

- Maintainer: Noé Gnanih ([@noeGnh](https://github.com/noeGnh))
