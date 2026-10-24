enum LocationAccess { denied, granted, blocked, restricted }

enum LocationOutcome {
  ready,
  permissionNeeded,
  denied,
  blocked,
  restricted,
  serviceDisabled,
  poorFix,
  failed,
  cancelled,
}

final class LocationFix {
  const LocationFix({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.capturedAt,
  });

  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final DateTime capturedAt;
}

final class LocationResult {
  const LocationResult(this.outcome, {this.fix});

  final LocationOutcome outcome;
  final LocationFix? fix;
}

abstract interface class LocationGateway {
  Future<LocationAccess> checkAccess();
  Future<LocationAccess> requestAccess();
  Future<bool> serviceEnabled();
  Future<bool> requestService();
  Future<bool> openAppSettings();
  Future<LocationFix> readFix({required Duration timeout});
  Future<void> cancelRead();
}
