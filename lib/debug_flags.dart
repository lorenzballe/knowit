/// Temporary developer tools, shown at the bottom of the profile.
///
/// This cannot key off `kDebugMode`: the builds that reach a phone through
/// TestFlight are release builds, and those are exactly the ones the tools are
/// needed in. So it is an explicit switch — flip it here, or pass
/// `--dart-define=DEBUG_TOOLS=false`, when the app goes out to anyone real.
const bool kDebugTools = bool.fromEnvironment(
  'DEBUG_TOOLS',
  defaultValue: true,
);
