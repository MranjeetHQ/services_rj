import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:services_rj/services_rj.dart';

/// Subscription tiers used by the labs that demo enum-backed options.
enum LabPlan {
  /// No cost, limited seats.
  free,

  /// Individual paid plan.
  pro,

  /// Shared plan for groups.
  team,
}

/// Conference topics used by the labs that demo multi-select enums.
enum LabTopic {
  /// Screen readers and inclusive design.
  accessibility,

  /// Motion and transitions.
  animations,

  /// Unit, widget and integration tests.
  testing,

  /// Frame budgets and profiling.
  performance,

  /// Sold out, so the option is disabled.
  security,

  /// Build runners and linters.
  tooling,
}

/// Registers the enums that the form labs reference with `"enum": ...`.
///
/// Safe to call repeatedly.
void registerLabEnums() {
  FormEnumRegistry.register(
    'LabPlan',
    LabPlan.values,
    label: (p) => switch (p) {
      LabPlan.free => 'Free',
      LabPlan.pro => 'Pro',
      LabPlan.team => 'Team',
    },
    description: (p) => switch (p) {
      LabPlan.free => 'Up to 3 seats',
      LabPlan.pro => 'Unlimited seats for one person',
      LabPlan.team => 'Shared workspace',
    },
    icon: (p) => switch (p) {
      LabPlan.free => 'tag',
      LabPlan.pro => 'star',
      LabPlan.team => 'people',
    },
  );
  FormEnumRegistry.register(
    'LabTopic',
    LabTopic.values,
    description: (t) => t == LabTopic.security ? 'Sold out' : null,
    icon: (t) => 'info',
    enabled: (t) => t != LabTopic.security,
  );
}

/// Pretty-prints any form value (maps, lists, scalars) for log lines.
String labPretty(Object? value) =>
    const JsonEncoder.withIndent('  ', _fallback).convert(value);

/// Compact single-line variant of [labPretty].
String labCompact(Object? value) => jsonEncode(value, toEncodable: _fallback);

Object? _fallback(Object? o) => o.toString();

/// Collects every [FieldConfig] under [fields], including children of
/// groups, expansions and repeaters.
Iterable<FieldConfig> labWalkFields(Iterable<FieldConfig> fields) sync* {
  for (final f in fields) {
    yield f;
    yield* labWalkFields(f.fields);
  }
}

/// A wrap of small buttons, each running a callback.
class LabActions extends StatelessWidget {
  /// Creates the button strip.
  const LabActions({super.key, required this.actions});

  /// Button label to callback.
  final Map<String, VoidCallback> actions;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final e in actions.entries)
        OutlinedButton(onPressed: e.value, child: Text(e.key)),
    ],
  );
}
