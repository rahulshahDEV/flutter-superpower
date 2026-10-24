import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:permission_eval/location_coordinator.dart';
import 'package:permission_eval/location_gateway.dart';

final instant = DateTime.utc(2026, 1, 1);
LocationFix fix({
  double lat = 27,
  double lon = 85,
  double accuracy = 10,
  DateTime? capturedAt,
}) => LocationFix(
  latitude: lat,
  longitude: lon,
  accuracyMeters: accuracy,
  capturedAt: capturedAt ?? instant,
);

class Gateway implements LocationGateway {
  final calls = <String>[];
  LocationAccess access = LocationAccess.granted;
  LocationAccess requestedAccess = LocationAccess.granted;
  bool enabled = true;
  bool requestedService = true;
  bool settingsLaunch = true;
  LocationFix value = fix();
  Completer<LocationFix>? pendingRead;
  Completer<LocationAccess>? pendingPermission;
  bool failRead = false;
  Duration? timeout;

  @override
  Future<LocationAccess> checkAccess() async {
    calls.add('check');
    return access;
  }

  @override
  Future<LocationAccess> requestAccess() async {
    calls.add('permission');
    return pendingPermission?.future ?? requestedAccess;
  }

  @override
  Future<bool> serviceEnabled() async {
    calls.add('service');
    return enabled;
  }

  @override
  Future<bool> requestService() async {
    calls.add('enable');
    return requestedService;
  }

  @override
  Future<bool> openAppSettings() async {
    calls.add('settings');
    return settingsLaunch;
  }

  @override
  Future<LocationFix> readFix({required Duration timeout}) async {
    calls.add('read');
    this.timeout = timeout;
    if (failRead) throw StateError('read failed');
    return pendingRead?.future ?? value;
  }

  @override
  Future<void> cancelRead() async {
    calls.add('cancel');
  }
}

LocationCoordinator coordinator(
  Gateway gateway, {
  Duration timeout = const Duration(seconds: 1),
}) => LocationCoordinator(
  gateway,
  now: () => instant,
  maxAge: const Duration(minutes: 1),
  maxAccuracyMeters: 25,
  readTimeout: timeout,
);

Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  test('passive missing access and service never prompt', () async {
    final g = Gateway()..access = LocationAccess.denied;
    final c = coordinator(g);
    expect((await c.locate()).outcome, LocationOutcome.permissionNeeded);
    expect(g.calls, ['check']);
    g.access = LocationAccess.granted;
    g.enabled = false;
    expect((await c.locate()).outcome, LocationOutcome.serviceDisabled);
    expect(g.calls, ['check', 'check', 'service']);
    await c.dispose();
  });

  for (final access in [
    LocationAccess.denied,
    LocationAccess.blocked,
    LocationAccess.restricted,
  ]) {
    test('interactive preserves requested $access', () async {
      final g = Gateway()
        ..access = LocationAccess.denied
        ..requestedAccess = access;
      final c = coordinator(g);
      final expected = {
        LocationAccess.denied: LocationOutcome.denied,
        LocationAccess.blocked: LocationOutcome.blocked,
        LocationAccess.restricted: LocationOutcome.restricted,
      }[access];
      expect((await c.locate(interactive: true)).outcome, expected);
      expect(g.calls, ['check', 'permission']);
      await c.dispose();
    });
  }

  for (final access in [LocationAccess.blocked, LocationAccess.restricted]) {
    test('$access does not prompt or open settings', () async {
      final g = Gateway()..access = access;
      final c = coordinator(g);
      await c.locate(interactive: true);
      expect(g.calls, ['check']);
      await c.dispose();
    });
  }

  test('interactive enables service once and reads once', () async {
    final g = Gateway()
      ..access = LocationAccess.denied
      ..enabled = false;
    final c = coordinator(g);
    final result = await c.locate(interactive: true);
    expect(result.outcome, LocationOutcome.ready);
    expect(result.fix, same(g.value));
    expect(g.calls, ['check', 'permission', 'service', 'enable', 'read']);
    expect(g.timeout, const Duration(seconds: 1));
    await c.dispose();
    expect(g.calls.contains('cancel'), false);
  });

  test('service request refusal remains serviceDisabled', () async {
    final g = Gateway()
      ..enabled = false
      ..requestedService = false;
    final c = coordinator(g);
    expect(
      (await c.locate(interactive: true)).outcome,
      LocationOutcome.serviceDisabled,
    );
    expect(g.calls, ['check', 'service', 'enable']);
    await c.dispose();
  });

  test('concurrent callers share the active attempt and read', () async {
    final g = Gateway()..pendingRead = Completer<LocationFix>();
    final c = coordinator(g);
    final first = c.locate();
    final second = c.locate(interactive: true);
    expect(identical(first, second), true);
    await flush();
    expect(g.calls, ['check', 'service', 'read']);
    g.pendingRead!.complete(fix());
    expect(await first, same(await second));
    await c.dispose();
  });

  test(
    'permission dialog resume does nothing; settings return rechecks once',
    () async {
      final g = Gateway()
        ..access = LocationAccess.denied
        ..pendingPermission = Completer<LocationAccess>();
      final c = coordinator(g);
      final attempt = c.locate(interactive: true);
      await flush();
      expect(await c.onResumed(), isNull);
      g.pendingPermission!.complete(LocationAccess.denied);
      expect((await attempt).outcome, LocationOutcome.denied);
      expect(await c.openSettings(), true);
      expect(g.calls, ['check', 'permission', 'settings']);
      expect((await c.onResumed())!.outcome, LocationOutcome.permissionNeeded);
      expect(await c.onResumed(), isNull);
      expect(g.calls, ['check', 'permission', 'settings', 'check']);
      await c.dispose();
    },
  );

  test('failed settings launch does not schedule a recheck', () async {
    final g = Gateway()..settingsLaunch = false;
    final c = coordinator(g);
    expect(await c.openSettings(), false);
    expect(await c.onResumed(), isNull);
    expect(g.calls, ['settings']);
    await c.dispose();
  });

  final invalid = <String, LocationFix>{
    'old': fix(capturedAt: instant.subtract(const Duration(seconds: 61))),
    'future': fix(capturedAt: instant.add(const Duration(seconds: 1))),
    'nan latitude': fix(lat: double.nan),
    'infinite latitude': fix(lat: double.infinity),
    'latitude range': fix(lat: -91),
    'longitude range': fix(lon: 181),
    'nan longitude': fix(lon: double.nan),
    'infinite accuracy': fix(accuracy: double.infinity),
    'nan accuracy': fix(accuracy: double.nan),
    'negative accuracy': fix(accuracy: -1),
    'poor accuracy': fix(accuracy: 26),
  };
  for (final entry in invalid.entries) {
    test('rejects ${entry.key} without exposing the fix', () async {
      final g = Gateway()..value = entry.value;
      final c = coordinator(g);
      final result = await c.locate();
      expect(result.outcome, LocationOutcome.poorFix);
      expect(result.fix, isNull);
      expect(g.calls.where((call) => call == 'read').length, 1);
      await c.dispose();
    });
  }

  test(
    'inclusive age, coordinate and accuracy boundaries are accepted',
    () async {
      final g = Gateway()
        ..value = fix(
          lat: -90,
          lon: 180,
          accuracy: 25,
          capturedAt: instant.subtract(const Duration(minutes: 1)),
        );
      final c = coordinator(g);
      expect((await c.locate()).outcome, LocationOutcome.ready);
      await c.dispose();
    },
  );

  test('acquisition failure cancels native work', () async {
    final g = Gateway()..failRead = true;
    final c = coordinator(g);
    expect((await c.locate()).outcome, LocationOutcome.failed);
    expect(g.calls, ['check', 'service', 'read', 'cancel']);
    await c.dispose();
    expect(g.calls.where((call) => call == 'cancel').length, 1);
  });

  test('timeout cancels work and ignores late success', () async {
    final g = Gateway()..pendingRead = Completer<LocationFix>();
    final c = coordinator(g, timeout: const Duration(milliseconds: 5));
    expect((await c.locate()).outcome, LocationOutcome.failed);
    expect(g.calls.last, 'cancel');
    g.pendingRead!.complete(fix());
    await flush();
    await c.dispose();
    expect(g.calls.where((call) => call == 'cancel').length, 1);
  });

  test(
    'dispose cancels read, resolves callers and rejects all new work',
    () async {
      final g = Gateway()..pendingRead = Completer<LocationFix>();
      final c = coordinator(g);
      final result = c.locate();
      await flush();
      await c.dispose();
      expect((await result).outcome, LocationOutcome.cancelled);
      final calls = List<String>.of(g.calls);
      expect(calls.last, 'cancel');
      expect(
        (await c.locate(interactive: true)).outcome,
        LocationOutcome.cancelled,
      );
      expect(await c.openSettings(), false);
      expect(await c.onResumed(), isNull);
      g.pendingRead!.complete(fix());
      await flush();
      await c.dispose();
      expect(g.calls, calls);
    },
  );

  test('dispose during permission cannot proceed to service or read', () async {
    final g = Gateway()
      ..access = LocationAccess.denied
      ..pendingPermission = Completer<LocationAccess>();
    final c = coordinator(g);
    final result = c.locate(interactive: true);
    await flush();
    await c.dispose();
    expect((await result).outcome, LocationOutcome.cancelled);
    g.pendingPermission!.complete(LocationAccess.granted);
    await flush();
    expect(g.calls, ['check', 'permission']);
  });
}
