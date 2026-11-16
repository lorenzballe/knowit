// Temporary: runs the paywall's tests through the App shots workflow, which
// can run on a branch, with test/'s own set-up. Removed before merging.
import '../test/flutter_test_config.dart' as config;
import '../test/paywall_doors_test.dart' as paywall;

Future<void> main() => config.testExecutable(paywall.main);
