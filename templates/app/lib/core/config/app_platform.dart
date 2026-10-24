import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract final class AppPlatform {
  static Future<void> configure({
    List<DeviceOrientation> orientations = const [],
  }) async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }
    // Empty means OS policy. A lock must be an explicit product requirement.
    await SystemChrome.setPreferredOrientations(orientations);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
}
