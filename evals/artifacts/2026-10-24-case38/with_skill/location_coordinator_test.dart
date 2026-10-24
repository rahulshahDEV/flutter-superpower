import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:permission_eval/location_coordinator.dart';
import 'package:permission_eval/location_gateway.dart';

final clock = DateTime.utc(2026, 10, 24, 12);
LocationFix fix({
  double latitude = 27,
  double longitude = 85,
  double accuracy = 10,
  Duration age = Duration.zero,
}) => LocationFix(
  latitude: latitude,
  longitude: longitude,
  accuracyMeters: accuracy,
  capturedAt: clock.subtract(age),
);

final class FakeGateway implements LocationGateway {
  LocationAccess access = LocationAccess.granted;
  LocationAccess requestedAccess = LocationAccess.granted;
  bool enabled = true;
  bool serviceAccepted = true;
  bool settingsLaunched = true;
  bool serviceActuallyEnabled = true;
  bool readFails = false;
  bool cancellationFails = false;
  Completer<LocationAccess>? permission;
  Completer<LocationFix>? reading;
  Completer<bool>? settings;
  LocationFix sample = fix();
  final calls = <String>[];
  Duration? timeout;

  @override
  Future<LocationAccess> checkAccess() async {
    calls.add('checkAccess');
    return access;
  }

  @override
  Future<LocationAccess> requestAccess() async {
    calls.add('requestAccess');
    return access = await (permission?.future ?? Future.value(requestedAccess));
  }

  @override
  Future<bool> serviceEnabled() async {
    calls.add('serviceEnabled');
    return enabled;
  }

  @override
  Future<bool> requestService() async {
    calls.add('requestService');
    enabled = serviceActuallyEnabled;
    return serviceAccepted;
  }

  @override
  Future<bool> openAppSettings() async {
    calls.add('openSettings');
    return settings?.future ?? Future.value(settingsLaunched);
  }

  @override
  Future<LocationFix> readFix({required Duration timeout}) async {
    calls.add('readFix');
    this.timeout = timeout;
    if (readFails) throw StateError('Provider unavailable');
    return reading?.future ?? Future.value(sample);
  }

  @override
  Future<void> cancelRead() async {
    calls.add('cancelRead');
    if (cancellationFails) throw StateError('Cancellation unavailable');
  }

  int count(String call) => calls.where((item) => item == call).length;
}

LocationCoordinator coordinator(FakeGateway gateway) => LocationCoordinator(
  gateway,
  now: () => clock,
  maxAge: const Duration(minutes: 1),
  maxAccuracyMeters: 50,
  readTimeout: const Duration(seconds: 5),
);

void main() {
  late FakeGateway gateway;
  late LocationCoordinator subject;
  setUp(() {
    gateway = FakeGateway();
    subject = coordinator(gateway);
  });
  tearDown(() => subject.dispose());

  test('passive denial does not prompt or read', () async {
    gateway.access = LocationAccess.denied;
    expect((await subject.locate()).outcome, LocationOutcome.permissionNeeded);
    expect(gateway.calls, ['checkAccess']);
  });

  for (final access in [LocationAccess.blocked, LocationAccess.restricted]) {
    test('$access is preserved without request or Settings', () async {
      gateway.access = access;
      final expected = access == LocationAccess.blocked
          ? LocationOutcome.blocked
          : LocationOutcome.restricted;
      expect((await subject.locate(interactive: true)).outcome, expected);
      expect(gateway.calls, ['checkAccess']);
    });
  }

  for (final access in [
    LocationAccess.denied,
    LocationAccess.blocked,
    LocationAccess.restricted,
  ]) {
    test('request result $access stays specific', () async {
      gateway.access = LocationAccess.denied;
      gateway.requestedAccess = access;
      final expected = switch (access) {
        LocationAccess.denied => LocationOutcome.denied,
        LocationAccess.blocked => LocationOutcome.blocked,
        _ => LocationOutcome.restricted,
      };
      expect((await subject.locate(interactive: true)).outcome, expected);
      expect(gateway.calls, ['checkAccess', 'requestAccess']);
    });
  }

  test('passive service check never enables services', () async {
    gateway.enabled = false;
    expect((await subject.locate()).outcome, LocationOutcome.serviceDisabled);
    expect(gateway.calls, ['checkAccess', 'serviceEnabled']);
  });

  test(
    'interactive grant and service recovery acquire once after recheck',
    () async {
      gateway.access = LocationAccess.denied;
      gateway.enabled = false;
      final result = await subject.locate(interactive: true);
      expect(result.outcome, LocationOutcome.ready);
      expect(result.fix, same(gateway.sample));
      expect(gateway.calls, [
        'checkAccess',
        'requestAccess',
        'serviceEnabled',
        'requestService',
        'serviceEnabled',
        'checkAccess',
        'readFix',
      ]);
      expect(gateway.timeout, const Duration(seconds: 5));
    },
  );

  test(
    'cancelled service recovery stays serviceDisabled without read',
    () async {
      gateway.enabled = false;
      gateway.serviceAccepted = false;
      expect(
        (await subject.locate(interactive: true)).outcome,
        LocationOutcome.serviceDisabled,
      );
      expect(gateway.count('requestService'), 1);
      expect(gateway.count('readFix'), 0);
    },
  );

  test('accepted service launch does not imply enabled service', () async {
    gateway.enabled = false;
    gateway.serviceActuallyEnabled = false;
    expect(
      (await subject.locate(interactive: true)).outcome,
      LocationOutcome.serviceDisabled,
    );
    expect(gateway.count('readFix'), 0);
  });

  test(
    'concurrent callers share attempt; prompt resume does nothing',
    () async {
      gateway.access = LocationAccess.denied;
      gateway.permission = Completer<LocationAccess>();
      final first = subject.locate(interactive: true);
      final second = subject.locate(interactive: true);
      expect(second, same(first));
      expect(await subject.onResumed(), isNull);
      gateway.permission!.complete(LocationAccess.granted);
      expect((await first).outcome, LocationOutcome.ready);
      expect(gateway.count('requestAccess'), 1);
      expect(gateway.count('readFix'), 1);
    },
  );

  test(
    'Settings launch is not grant; return rechecks once passively',
    () async {
      gateway.access = LocationAccess.blocked;
      expect(await subject.openSettings(), isTrue);
      expect(gateway.calls, ['openSettings']);
      expect((await subject.onResumed())?.outcome, LocationOutcome.blocked);
      expect(await subject.onResumed(), isNull);
      expect(gateway.calls, ['openSettings', 'checkAccess']);
    },
  );

  test('Settings grant allows one fresh fix on return', () async {
    gateway.access = LocationAccess.denied;
    await subject.openSettings();
    gateway.access = LocationAccess.granted;
    expect((await subject.onResumed())?.outcome, LocationOutcome.ready);
    expect(await subject.onResumed(), isNull);
    expect(gateway.count('requestAccess'), 0);
    expect(gateway.count('readFix'), 1);
  });

  test('failed Settings launch does not register resume', () async {
    gateway.settingsLaunched = false;
    expect(await subject.openSettings(), isFalse);
    expect(await subject.onResumed(), isNull);
    expect(gateway.calls, ['openSettings']);
  });

  test('concurrent Settings launches are shared', () async {
    gateway.settings = Completer<bool>();
    final first = subject.openSettings();
    final second = subject.openSettings();
    expect(second, same(first));
    gateway.settings!.complete(true);
    expect(await first, isTrue);
    expect(gateway.count('openSettings'), 1);
  });

  test(
    'early duplicate Settings resume waits for launch and rechecks once',
    () async {
      final launch = Completer<bool>();
      gateway.settings = launch;
      final opening = subject.openSettings();
      final firstResume = subject.onResumed();
      final secondResume = subject.onResumed();
      launch.complete(true);
      expect(await opening, isTrue);
      expect((await firstResume)?.outcome, LocationOutcome.ready);
      expect(await secondResume, isNull);
      expect(gateway.count('readFix'), 1);
      expect(gateway.count('checkAccess'), 1);
    },
  );

  final invalidFixes = <String, LocationFix>{
    'stale': fix(age: const Duration(minutes: 2)),
    'future timestamp': fix(age: const Duration(seconds: -1)),
    'latitude above range': fix(latitude: 91),
    'latitude below range': fix(latitude: -91),
    'longitude above range': fix(longitude: 181),
    'longitude below range': fix(longitude: -181),
    'NaN latitude': fix(latitude: double.nan),
    'infinite longitude': fix(longitude: double.infinity),
    'negative accuracy': fix(accuracy: -1),
    'NaN accuracy': fix(accuracy: double.nan),
    'infinite accuracy': fix(accuracy: double.infinity),
    'poor accuracy': fix(accuracy: 51),
  };
  for (final entry in invalidFixes.entries) {
    test('rejects ${entry.key}', () async {
      gateway.sample = entry.value;
      final result = await subject.locate();
      expect(result.outcome, LocationOutcome.poorFix);
      expect(result.fix, isNull);
      expect(gateway.count('readFix'), 1);
    });
  }

  test('policy boundaries are inclusive', () async {
    gateway.sample = fix(
      latitude: -90,
      longitude: 180,
      accuracy: 50,
      age: const Duration(minutes: 1),
    );
    expect((await subject.locate()).outcome, LocationOutcome.ready);
  });

  test('provider failure cancels native read, and retry works', () async {
    gateway.readFails = true;
    expect((await subject.locate()).outcome, LocationOutcome.failed);
    expect(gateway.count('cancelRead'), 1);
    gateway.readFails = false;
    expect((await subject.locate()).outcome, LocationOutcome.ready);
    expect(gateway.count('readFix'), 2);
  });

  testWidgets('deadline cancels pending native read and ignores late fix', (
    tester,
  ) async {
    gateway.reading = Completer<LocationFix>();
    final attempt = subject.locate();
    await tester.pump();
    expect(gateway.count('readFix'), 1);
    await tester.pump(const Duration(seconds: 5));
    expect((await attempt).outcome, LocationOutcome.failed);
    expect(gateway.count('cancelRead'), 1);
    gateway.reading!.complete(fix());
    await tester.pump();
  });

  test(
    'dispose cancels once, settles pending call, rejects late success',
    () async {
      gateway.reading = Completer<LocationFix>();
      final attempt = subject.locate();
      await Future<void>.delayed(Duration.zero);
      await subject.dispose();
      expect((await attempt).outcome, LocationOutcome.cancelled);
      expect(gateway.count('cancelRead'), 1);
      gateway.reading!.complete(fix());
      await Future<void>.delayed(Duration.zero);
      expect(
        (await subject.locate(interactive: true)).outcome,
        LocationOutcome.cancelled,
      );
      expect(await subject.openSettings(), isFalse);
      expect(await subject.onResumed(), isNull);
      expect(gateway.count('readFix'), 1);
    },
  );

  test(
    'dispose during permission prevents native read and settles callers',
    () async {
      gateway.access = LocationAccess.denied;
      gateway.permission = Completer<LocationAccess>();
      final attempt = subject.locate(interactive: true);
      // Drain status-check continuations to enter the permission request.
      await Future<void>.delayed(Duration.zero);
      await subject.dispose();
      expect((await attempt).outcome, LocationOutcome.cancelled);
      gateway.permission!.complete(LocationAccess.granted);
      await Future<void>.delayed(Duration.zero);
      expect(gateway.count('readFix'), 0);
      expect(gateway.count('serviceEnabled'), 0);
    },
  );

  test('cancellation error never becomes stale success', () async {
    gateway.readFails = true;
    gateway.cancellationFails = true;
    expect((await subject.locate()).outcome, LocationOutcome.failed);
    expect(gateway.count('cancelRead'), 1);
  });
}
