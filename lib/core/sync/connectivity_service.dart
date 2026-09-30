import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// StreamProvider providing real-time online/offline boolean status.
/// true = online (wifi, mobile, or ethernet connected)
/// false = offline (none)
final connectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();

  // Initial check
  try {
    final initial = await connectivity.checkConnectivity();
    final isOnline = initial.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet);
    yield isOnline;
  } catch (_) {
    yield true;
  }

  // Stream updates
  await for (final results in connectivity.onConnectivityChanged) {
    final isOnline = results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet);
    yield isOnline;
  }
});
