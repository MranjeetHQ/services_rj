# Contributing

Thanks for helping improve services_rj. Issues and pull requests are welcome.

## Set up

```sh
git clone https://github.com/MranjeetHQ/services_rj.git
cd services_rj
flutter pub get
```

Branch from `develop` and open pull requests against `master`.

## Who can merge

Only the owner (`@MranjeetHQ`) merges into `master`, and only after CI is green. Reviews are requested automatically from `.github/CODEOWNERS`. The owner can add maintainers there when needed. Nobody pushes to `master` directly.

## Before you open a pull request

Run the same checks as CI:

```sh
dart format .                              # tall style
flutter analyze --fatal-infos
flutter test                               # package tests
(cd example && flutter test)               # example app
(cd form_guide_web && flutter test)        # guide website
```

Add or update tests for what you change.

## Changing the form builder

The guide website must stay in sync with the form fields. `cd form_guide_web && flutter test` fails when something is undocumented. Update these in the same pull request:

| You changed | Update |
| --- | --- |
| A `FieldType` | `form_guide_web/lib/catalog/field_catalog.dart`, with a working `example` |
| A `FieldConfig.fromJson` key | `FieldConfig.knownKeys` and `fieldPropertyDocs` in `reference_catalog.dart` |
| A style key | `FieldStyleConfig.knownKeys` and `styleDocs` |
| A `ValidatorType` or `ConditionOperator` | `validatorDocs` or `operatorDocs` |
| Behaviour | the relevant page in `form_guide_web/lib/pages/`, `docs/forms.md` and the README forms section |

Also add a line to `CHANGELOG.md`.

## Style

- Format with `dart format` (tall style).
- Demo strings in `example/` are original text.
- The form engine is MIT code by Rupesh Rajak. Keep `THIRD_PARTY_NOTICES.md` and the attribution in `lib/forms.dart`.

## Reporting bugs

Open an issue with the Flutter version (`flutter --version`), the package version, a minimal JSON form or code that reproduces it, and what you expected. For security problems, see [SECURITY.md](SECURITY.md) instead.

By contributing you agree your work is released under the [MIT License](LICENSE).
