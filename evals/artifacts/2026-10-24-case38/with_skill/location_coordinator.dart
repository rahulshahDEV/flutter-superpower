import 'dart:async';

import 'location_gateway.dart';

/// Owns a single foreground location attempt and explicit Settings recovery.
final class LocationCoordinator {
  LocationCoordinator(
    this._gateway, {
    required DateTime Function() now,
    required Duration maxAge,
    required double maxAccuracyMeters,
    required Duration readTimeout,
  }) : _now = now,
       _maxAge = maxAge,
       _maxAccuracyMeters = maxAccuracyMeters,
       _readTimeout = readTimeout {
    if (maxAge.isNegative ||
        !maxAccuracyMeters.isFinite ||
        maxAccuracyMeters < 0 ||
        readTimeout <= Duration.zero) {
      throw ArgumentError('Invalid location quality or timeout policy');
    }
  }

  final LocationGateway _gateway;
  final DateTime Function() _now;
  final Duration _maxAge;
  final double _maxAccuracyMeters;
  final Duration _readTimeout;
  final Completer<LocationResult> _disposedResult = Completer<LocationResult>();
  Future<LocationResult>? _active;
  Future<bool>? _settingsLaunch;
  Future<void>? _disposal;
  Future<void>? _readCancellation;
  bool _reading = false;
  bool _disposed = false;
  bool _settingsPending = false;

  Future<LocationResult> locate({bool interactive = false}) {
    if (_disposed) return Future.value(_cancelled);
    final active = _active;
    if (active != null) return active;
    final attempt = Future.any([_attempt(interactive), _disposedResult.future]);
    final shared = attempt.whenComplete(() => _active = null);
    _active = shared;
    return shared;
  }

  static const _cancelled = LocationResult(LocationOutcome.cancelled);

  Future<LocationResult> _attempt(bool interactive) async {
    try {
      var access = await _gateway.checkAccess();
      if (_disposed) return _cancelled;
      if (access == LocationAccess.denied && interactive) {
        access = await _gateway.requestAccess();
        if (_disposed) return _cancelled;
        if (access == LocationAccess.denied) {
          return const LocationResult(LocationOutcome.denied);
        }
      }
      final accessFailure = _accessFailure(access);
      if (accessFailure != null) return accessFailure;
      var enabled = await _gateway.serviceEnabled();
      if (_disposed) return _cancelled;
      if (!enabled && interactive) {
        final accepted = await _gateway.requestService();
        if (_disposed) return _cancelled;
        if (!accepted) {
          return const LocationResult(LocationOutcome.serviceDisabled);
        }
        enabled = await _gateway.serviceEnabled();
        if (_disposed) return _cancelled;
        // Native service recovery may also change authorization.
        access = await _gateway.checkAccess();
        if (_disposed) return _cancelled;
        final failure = _accessFailure(access);
        if (failure != null) return failure;
      }
      if (!enabled) {
        return const LocationResult(LocationOutcome.serviceDisabled);
      }
      _reading = true;
      _readCancellation = null;
      final LocationFix fix;
      try {
        fix = await Future.any<LocationFix>([
          _gateway.readFix(timeout: _readTimeout),
          _disposedResult.future.then<LocationFix>(
            (_) => throw StateError('Coordinator disposed'),
          ),
        ]).timeout(_readTimeout);
      } catch (_) {
        await _cancelRead();
        return _disposed
            ? _cancelled
            : const LocationResult(LocationOutcome.failed);
      } finally {
        _reading = false;
      }
      if (_disposed) return _cancelled;
      return _acceptable(fix)
          ? LocationResult(LocationOutcome.ready, fix: fix)
          : const LocationResult(LocationOutcome.poorFix);
    } catch (_) {
      return _disposed
          ? _cancelled
          : const LocationResult(LocationOutcome.failed);
    }
  }

  LocationResult? _accessFailure(LocationAccess access) => switch (access) {
    LocationAccess.granted => null,
    LocationAccess.denied => const LocationResult(
      LocationOutcome.permissionNeeded,
    ),
    LocationAccess.blocked => const LocationResult(LocationOutcome.blocked),
    LocationAccess.restricted => const LocationResult(
      LocationOutcome.restricted,
    ),
  };

  bool _acceptable(LocationFix fix) {
    final age = _now().difference(fix.capturedAt);
    return fix.latitude.isFinite &&
        fix.latitude >= -90 &&
        fix.latitude <= 90 &&
        fix.longitude.isFinite &&
        fix.longitude >= -180 &&
        fix.longitude <= 180 &&
        fix.accuracyMeters.isFinite &&
        fix.accuracyMeters >= 0 &&
        fix.accuracyMeters <= _maxAccuracyMeters &&
        !age.isNegative &&
        age <= _maxAge;
  }

  Future<bool> openSettings() {
    if (_disposed) return Future.value(false);
    final launch = _settingsLaunch;
    if (launch != null) return launch;
    // Do not overlap another native interaction with an active attempt.
    if (_active != null) return Future.value(false);
    final shared = _launchSettings().whenComplete(() => _settingsLaunch = null);
    _settingsLaunch = shared;
    return shared;
  }

  Future<bool> _launchSettings() async {
    try {
      final launched = await _gateway.openAppSettings();
      if (_disposed) return false;
      _settingsPending = launched;
      return launched;
    } catch (_) {
      _settingsPending = false;
      return false;
    }
  }

  Future<LocationResult?> onResumed() async {
    if (_disposed) return null;
    // Some adapters finish launching Settings after the resume event arrives.
    final launch = _settingsLaunch;
    if (launch != null) await launch;
    if (_disposed || !_settingsPending) return null;
    _settingsPending = false;
    return locate();
  }

  Future<void> _cancelRead() => _readCancellation ??= _performCancellation();

  Future<void> _performCancellation() async {
    try {
      await _gateway.cancelRead();
    } catch (_) {
      // Cancellation is best effort; no successful fix can escape after disposal.
    }
  }

  Future<void> dispose() {
    final disposal = _disposal;
    if (disposal != null) return disposal;
    _disposed = true;
    _settingsPending = false;
    _disposedResult.complete(_cancelled);
    return _disposal = _reading ? _cancelRead() : Future.value();
  }
}
