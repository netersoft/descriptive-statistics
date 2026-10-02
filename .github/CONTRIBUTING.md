# Contributing to Statistique Descriptive

## Git workflow

This repo follows **GitHub Flow**: `master` is the only long-lived branch and is always
releasable. There's no `develop`, `release`, or long-lived environment branch.

1. Branch from `master` (see naming convention below).
2. Keep branches short-lived — open a PR as soon as there's something reviewable rather
   than letting a branch accumulate a large diff.
3. Merge back into `master` via PR once CI is green and approved. Never push directly to
   `master`.
4. Hotfixes follow the exact same path — branch from `master`, PR, merge.
5. Delete the branch once merged.

## Branches

- `feature/<short-name>` — new feature
- `fix/<short-name>` — bug fix
- `chore/<short-name>` — technical task with no functional impact

## Commits

One short sentence in the imperative mood, saying what the change does:

```text
Add a box plot chart to the discrete and continuous calculators
Fix the median class when two classes tie
```

PRs are squash-merged, so the PR title becomes the commit on `master`: write it the same
way.

## Code quality

CI must pass before merge. Run the same checks locally:

```bash
dart format .
flutter analyze
flutter test
```

CI also fails when hand-written line coverage drops under its floor (see
`.github/workflows/flutter.yml`): add tests with the code they cover.

Every user-visible string goes through Slang (`assets/i18n/*.i18n.json`) and must exist in
all five languages (fr, en, de, es, pt).

## Opening a Pull Request

1. Branch from `master` following the naming convention above.
2. Fill in the PR template — do not delete sections, mark items not applicable as N/A.
3. Make sure CI is green before requesting a review.
4. Squash-merge once approved.

## Reporting a bug / requesting a feature

Use the issue templates — they ask for the information needed to reproduce or evaluate the
request.
