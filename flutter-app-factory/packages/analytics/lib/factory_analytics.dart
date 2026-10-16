abstract interface class AnalyticsSink {
  Future<void> event(String name, {Map<String, Object>? parameters});
}

/// Firebase is optional: apps can inject this adapter until analytics is authorized.
class DisabledAnalytics implements AnalyticsSink {
  const DisabledAnalytics();
  @override
  Future<void> event(String name, {Map<String, Object>? parameters}) async {}
}
