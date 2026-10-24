import 'dart:async';

import 'location_gateway.dart';

/// Coordinates foreground location work without owning any UI or lifecycle hooks.
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
      throw ArgumentError('Invalid location policy');
    }
  }

  final LocationGateway _gateway;
  final DateTime Function() _now;
  final Duration _maxAge;
  final double _maxAccuracyMeters;
  final Duration _readTimeout;
  Completer<LocationResult>? _attempt;
  Completer<LocationFix>? _read;
  Timer? _readTimer;
  Future<void>? _cancellation;
  bool _ownsRead = false;
  bool _disposed = false;
  bool _launchingSettings = false;
  bool _awaitingSettingsReturn = false;

  Future<LocationResult> locate({bool interactive = false}) {
    if (_disposed) {
      return Future.value(const LocationResult(LocationOutcome.cancelled));
    }
    final existing = _attempt;
    if (existing != null) return existing.future;
    final attempt = Completer<LocationResult>();
    _attempt = attempt;
    unawaited(_execute(attempt, interactive));
    return attempt.future;
  }

  Future<void> _execute(
    Completer<LocationResult> attempt,
    bool interactive,
  ) async {
    LocationResult result;
    try {
      result = await _locate(interactive);
    } catch (_) {
      result = LocationResult(
        _disposed ? LocationOutcome.cancelled : LocationOutcome.failed,
      );
    }
    if (!attempt.isCompleted) {
      attempt.complete(
        _disposed ? const LocationResult(LocationOutcome.cancelled) : result,
      );
    }
    if (identical(_attempt, attempt)) _attempt = null;
  }

  Future<LocationResult> _locate(bool interactive) async {
    var access = await _gateway.checkAccess();
    if (_disposed) return const LocationResult(LocationOutcome.cancelled);
    if (access == LocationAccess.denied && interactive) {
      access = await _gateway.requestAccess();
      if (_disposed) return const LocationResult(LocationOutcome.cancelled);
    }
    switch (access) {
      case LocationAccess.denied:
        return LocationResult(
          interactive
              ? LocationOutcome.denied
              : LocationOutcome.permissionNeeded,
        );
      case LocationAccess.blocked:
        return const LocationResult(LocationOutcome.blocked);
      case LocationAccess.restricted:
        return const LocationResult(LocationOutcome.restricted);
      case LocationAccess.granted:
        break;
    }
    var enabled = await _gateway.serviceEnabled();
    if (_disposed) return const LocationResult(LocationOutcome.cancelled);
    if (!enabled && interactive) {
      enabled = await _gateway.requestService();
      if (_disposed) return const LocationResult(LocationOutcome.cancelled);
    }
    if (!enabled) return const LocationResult(LocationOutcome.serviceDisabled);

    final pending = Completer<LocationFix>();
    _read = pending;
    _ownsRead = true;
    _readTimer = Timer(_readTimeout, () {
      if (!pending.isCompleted) {
        pending.completeError(TimeoutException('Location'));
      }
    });
    try {
      // Attach both handlers so late native completions remain harmless.
      _gateway
          .readFix(timeout: _readTimeout)
          .then(
            (fix) {
              if (!pending.isCompleted) pending.complete(fix);
            },
            onError: (Object error, StackTrace stack) {
              if (!pending.isCompleted) pending.completeError(error, stack);
            },
          );
      final fix = await pending.future;
      _ownsRead = false;
      if (_disposed) return const LocationResult(LocationOutcome.cancelled);
      return _valid(fix)
          ? LocationResult(LocationOutcome.ready, fix: fix)
          : const LocationResult(LocationOutcome.poorFix);
    } catch (_) {
      await _cancelOwnedRead();
      return LocationResult(
        _disposed ? LocationOutcome.cancelled : LocationOutcome.failed,
      );
    } finally {
      _readTimer?.cancel();
      _readTimer = null;
      _read = null;
    }
  }

  bool _valid(LocationFix fix) {
    final age = _now().difference(fix.capturedAt);
    return !age.isNegative &&
        age <= _maxAge &&
        fix.latitude.isFinite &&
        fix.latitude >= -90 &&
        fix.latitude <= 90 &&
        fix.longitude.isFinite &&
        fix.longitude >= -180 &&
        fix.longitude <= 180 &&
        fix.accuracyMeters.isFinite &&
        fix.accuracyMeters >= 0 &&
        fix.accuracyMeters <= _maxAccuracyMeters;
  }

  Future<bool> openSettings() async {
    if (_disposed || _launchingSettings || _attempt != null) return false;
    _launchingSettings = true;
    try {
      final launched = await _gateway.openAppSettings();
      if (_disposed) return false;
      _awaitingSettingsReturn = launched;
      return launched;
    } catch (_) {
      return false;
    } finally {
      _launchingSettings = false;
    }
  }

  Future<LocationResult?> onResumed() async {
    if (_disposed || !_awaitingSettingsReturn) return null;
    _awaitingSettingsReturn = false;
    return locate();
  }

  Future<void> _cancelOwnedRead() {
    if (!_ownsRead) return _cancellation ?? Future.value();
    _ownsRead = false;
    return _cancellation = _cancelNative();
  }

  Future<void> _cancelNative() async {
    try {
      await _gateway.cancelRead();
    } catch (_) {
      // Cancellation is best effort; its failure cannot restore stale work.
    }
  }

  Future<void> dispose() async {
    if (!_disposed) {
      _disposed = true;
      _awaitingSettingsReturn = false;
      _readTimer?.cancel();
      final read = _read;
      if (read != null && !read.isCompleted) {
        read.completeError(StateError('Disposed'));
      }
      final attempt = _attempt;
      if (attempt != null && !attempt.isCompleted) {
        attempt.complete(const LocationResult(LocationOutcome.cancelled));
      }
    }
    await _cancelOwnedRead();
  }
}
