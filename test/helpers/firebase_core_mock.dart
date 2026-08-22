import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/src/pigeon/mocks.dart';
import 'package:flutter_test/flutter_test.dart';

var _initialized = false;

/// Initialises a stubbed default Firebase app.
///
/// `firebase_ui_auth` calls `configureProviders()`, which throws unless
/// `Firebase.initializeApp()` has completed. There is no fake for Firebase Core
/// the way there is for Auth and Firestore, so this leans on the platform
/// interface's own `setupFirebaseCoreMocks()` to stub the native channel.
/// Without it, none of the sign-in UI is testable.
///
/// Safe to call repeatedly; only the first call initialises.
Future<void> setUpMockFirebaseCore() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();

  if (_initialized) return;
  await Firebase.initializeApp();
  _initialized = true;
}
