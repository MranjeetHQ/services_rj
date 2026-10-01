import 'package:services_rj/services_rj.dart';

/// Ticket tiers for the event RSVP demo.
enum TicketTier { standard, premium, backstage }

/// Meal preferences for each guest.
enum MealChoice { vegetarian, vegan, jain, nonVegetarian, noMeal }

/// How a candidate wants to work.
enum WorkMode { onSite, hybrid, remote }

/// Contract type of a past job.
enum EmploymentKind { fullTime, partTime, contract, internship, freelance }

/// Registers every demo enum so JSON can say `"enum": "TicketTier"`.
void registerDemoEnums() {
  FormEnumRegistry.register(
    'TicketTier',
    TicketTier.values,
    description: (t) => switch (t) {
      TicketTier.standard => 'General entry',
      TicketTier.premium => 'Reserved seating + lounge',
      TicketTier.backstage => 'Meet the speakers',
    },
    icon: (t) => switch (t) {
      TicketTier.standard => 'tag',
      TicketTier.premium => 'star',
      TicketTier.backstage => 'badge',
    },
  );
  FormEnumRegistry.register('MealChoice', MealChoice.values);
  FormEnumRegistry.register(
    'WorkMode',
    WorkMode.values,
    label: (m) => switch (m) {
      WorkMode.onSite => 'On-site',
      WorkMode.hybrid => 'Hybrid',
      WorkMode.remote => 'Remote',
    },
  );
  FormEnumRegistry.register('EmploymentKind', EmploymentKind.values);
}
