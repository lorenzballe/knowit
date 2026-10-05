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

/// Whether the developer tools are on in this run.
///
/// [kDebugTools] everywhere it is built in. On the site, whose build has it
/// off, opening the app with `?debug` in the address turns them on for that
/// visit — so they can be used from the browser without being shown to
/// everyone who opens the site. Read once, at launch, before anything can
/// change the address.
bool debugToolsOn = kDebugTools;

/// Called from main(): turns the tools on for a site visit that asked.
void readDebugToolsFromAddress({required bool web}) {
  if (web && Uri.base.queryParameters.containsKey('debug')) {
    debugToolsOn = true;
  }
}
