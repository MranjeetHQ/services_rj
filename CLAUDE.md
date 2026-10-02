# services_rj

Flutter utility package. The dynamic form builder lives in `lib/src/forms/` and is exported from `lib/forms.dart` (re-exported by `lib/services_rj.dart`).

## Keep the form guide in sync

`form_guide_web/` is a Flutter web site that documents the form builder, using the package through a path dependency. Any change to form fields must be reflected there in the same change:

- New or changed `FieldType` → `form_guide_web/lib/catalog/field_catalog.dart`, with a working `example`.
- New `FieldConfig.fromJson` key → add it to `FieldConfig.knownKeys` and `fieldPropertyDocs` in `form_guide_web/lib/catalog/reference_catalog.dart`.
- New style key → `FieldStyleConfig.knownKeys` and `styleDocs`.
- New `ValidatorType` / `ConditionOperator` → `validatorDocs` / `operatorDocs`.
- Behaviour changes → update the relevant page in `form_guide_web/lib/pages/`, plus `docs/forms.md` and the README forms section.

`cd form_guide_web && flutter test` fails when anything is undocumented. Run it together with the package tests (`flutter test` at the root) and the example tests (`cd example && flutter test`).

## Conventions

- Format with `dart format` (tall style).
- Demo strings in `example/` are original; do not copy the upstream json_form_engine demo text.
- The form engine is MIT code by Rupesh Rajak; keep `THIRD_PARTY_NOTICES.md` and the attribution in `lib/forms.dart`.
