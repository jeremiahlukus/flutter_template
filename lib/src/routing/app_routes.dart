/// Every route in the app, in one place.
///
/// Screens navigate with `context.goNamed(AppRoute.profile.name)` rather than
/// raw strings, so a path rename is a single-line change and typos are caught
/// by the compiler.
enum AppRoute {
  onboarding('/welcome', 'onboarding'),
  signIn('/sign-in', 'sign-in'),
  notes('/', 'notes'),
  noteEditor('/notes/:id', 'note-editor'),
  profile('/profile', 'profile'),
  settings('/settings', 'settings');

  const AppRoute(this.path, this.name);

  final String path;
  final String name;

  /// Routes reachable without a signed-in user.
  static const publicPaths = {'/sign-in', '/welcome'};

  static bool isPublic(String location) =>
      publicPaths.any((p) => location == p || location.startsWith('$p/'));

  /// Every declared path. Used to validate an externally-supplied route — from a
  /// push payload or a deep link — before navigating to it.
  static Set<String> get paths => AppRoute.values.map((r) => r.path).toSet();
}
