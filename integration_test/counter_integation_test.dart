// // The application under test.
// import 'package:flutter_template/main_development.dart' as app;
// import 'package:flutter_test/flutter_test.dart';
// import 'package:integration_test/integration_test.dart';

// void main() {
//   IntegrationTestWidgetsFlutterBinding.ensureInitialized();

//   group('Counter end-to-end test', () {
//     testWidgets('tap on the increment floating action button; verify counter',
//         (WidgetTester tester) async {
//       app.main();
//       await tester.pumpAndSettle();
//       // Finds the floating action button to tap on.
//       final fab = find.byTooltip('Increment');
//       // Emulate a tap on the floating action button.
//       await tester.tap(fab);
//       await tester.pumpAndSettle();
//       expect(find.text('1'), findsOneWidget);
//     });

//     testWidgets('tap on the decrement floating action button; verify counter',
//         (WidgetTester tester) async {
//       app.main();
//       await tester.pumpAndSettle();
//       // Finds the floating action button to tap on.
//       final fab = find.byTooltip('Decrement');
//       // Emulate a tap on the floating action button.
//       await tester.tap(fab);
//       await tester.pumpAndSettle();
//       expect(find.text('-1'), findsOneWidget);
//     });

//     //   testWidgets('I Fail', (WidgetTester tester) async {
//     //     app.main();
//     //     await tester.pumpAndSettle();
//     //     // Finds the floating action button to tap on.
//     //     final fab = find.byTooltip('Decrement');
//     //     // Emulate a tap on the floating action button.
//     //     await tester.tap(fab);
//     //     await tester.pumpAndSettle();
//     //     expect(find.text('99'), findsOneWidget);
//     //   });
//   });
// }
