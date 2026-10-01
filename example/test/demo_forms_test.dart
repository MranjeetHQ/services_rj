import 'package:flutter_test/flutter_test.dart';
import 'package:services_rj/services_rj.dart';
import 'package:services_rj_example/demo_enums.dart';
import 'package:services_rj_example/forms/event_rsvp.dart';
import 'package:services_rj_example/forms/job_application.dart';
import 'package:services_rj_example/forms/styling_lab.dart';
import 'package:services_rj_example/main.dart';

void main() {
  setUpAll(registerDemoEnums);

  test('every demo form parses and attaches', () {
    for (final json in [eventRsvpForm, jobApplicationForm, stylingLabForm]) {
      final c = DynamicFormController()..attach(FormParser.parse(json));
      expect(c.fieldOrder, isNotEmpty);
      c.dispose();
    }
  });

  test('saved RSVP prefill restores guests', () {
    final c = DynamicFormController()
      ..attach(FormParser.parse(eventRsvpForm), initialData: savedRsvp);
    expect(c.entriesOf('guests'), hasLength(2));
    expect(c.getEnum('tier', TicketTier.values), TicketTier.premium);
    expect(c.validate(), isTrue);
    c.dispose();
  });

  testWidgets('home lists the demos', (tester) async {
    await tester.pumpWidget(const FormsDemoApp());
    expect(find.text('Meetup RSVP'), findsOneWidget);
    await tester.tap(find.text('Meetup RSVP'));
    await tester.pumpAndSettle();
    expect(find.text('Guest 1'), findsOneWidget);
  });
}
