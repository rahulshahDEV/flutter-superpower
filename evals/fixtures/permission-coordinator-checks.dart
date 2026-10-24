import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:permission_eval/location_coordinator.dart';
import 'package:permission_eval/location_gateway.dart';

class _Gateway implements LocationGateway {
  LocationAccess access = LocationAccess.granted;
  LocationAccess requestedAccess = LocationAccess.granted;
  bool enabled = true;
  bool resolved = true;
  bool settingsLaunched = true;
  int requests = 0;
  int resolutions = 0;
  int reads = 0;
  int cancels = 0;
  int settings = 0;
  Object? readError;
  Completer<LocationAccess>? permission;
  Completer<LocationFix>? position;
  final startedRead = Completer<void>();
  LocationFix fix = _fix();

  @override
  Future<LocationAccess> checkAccess() async => access;
  @override
  Future<LocationAccess> requestAccess() {
    requests++;
    return (permission?.future ?? Future.value(requestedAccess)).then((value) {
      access = value;
      return value;
    });
  }

  @override
  Future<bool> serviceEnabled() async => enabled;
  @override
  Future<bool> requestService() async {
    resolutions++;
    enabled = resolved;
    return resolved;
  }

  @override
  Future<bool> openAppSettings() async {
    settings++;
    return settingsLaunched;
  }

  @override
  Future<LocationFix> readFix({required Duration timeout}) {
    reads++;
    if (!startedRead.isCompleted) startedRead.complete();
    if (readError case final error?) return Future.error(error);
    return position?.future ?? Future.value(fix);
  }

  @override
  Future<void> cancelRead() async => cancels++;
}

final _epoch = DateTime.utc(2026, 1, 1, 12);
LocationFix _fix({
  double latitude = 1,
  double longitude = 2,
  double accuracy = 4,
  DateTime? time,
}) => LocationFix(
  latitude: latitude,
  longitude: longitude,
  accuracyMeters: accuracy,
  capturedAt: time ?? _epoch,
);

void main() {
  late _Gateway gateway;
  late DateTime clock;
  late LocationCoordinator coordinator;
  setUp(() {
    gateway = _Gateway();
    clock = _epoch;
    coordinator = LocationCoordinator(
      gateway,
      now: () => clock,
      maxAge: const Duration(seconds: 10),
      maxAccuracyMeters: 20,
      readTimeout: const Duration(milliseconds: 100),
    );
  });
  tearDown(() => coordinator.dispose());

  test('passive denial performs no interactive work', () async {
    gateway.access = LocationAccess.denied;
    final result = await coordinator.locate();
    expect(
      result.outcome,
      anyOf(LocationOutcome.permissionNeeded, LocationOutcome.denied),
    );
    expect(
      [gateway.requests, gateway.resolutions, gateway.reads, gateway.settings],
      [0, 0, 0, 0],
    );
  });
  test('blocked and restricted grants preserve their outcomes', () async {
    gateway.access = LocationAccess.blocked;
    expect(
      (await coordinator.locate(interactive: true)).outcome,
      LocationOutcome.blocked,
    );
    gateway.access = LocationAccess.restricted;
    expect(
      (await coordinator.locate(interactive: true)).outcome,
      LocationOutcome.restricted,
    );
    expect(gateway.settings, 0);
    expect(gateway.reads, 0);
  });
  test(
    'service disabled is distinct and passive does not resolve it',
    () async {
      gateway.enabled = false;
      expect(
        (await coordinator.locate()).outcome,
        LocationOutcome.serviceDisabled,
      );
      expect([gateway.resolutions, gateway.reads], [0, 0]);
    },
  );
  test('cancelled service resolution stops acquisition', () async {
    gateway.enabled = false;
    gateway.resolved = false;
    expect(
      (await coordinator.locate(interactive: true)).outcome,
      LocationOutcome.serviceDisabled,
    );
    expect(gateway.resolutions, 1);
    expect(gateway.reads, 0);
  });
  test(
    'simultaneous interactive requests and prompt resume share one attempt',
    () async {
      gateway.access = LocationAccess.denied;
      gateway.permission = Completer<LocationAccess>();
      final first = coordinator.locate(interactive: true);
      final second = coordinator.locate(interactive: true);
      final resume = coordinator.onResumed();
      gateway.permission!.complete(LocationAccess.granted);
      expect((await first).outcome, LocationOutcome.ready);
      expect((await second).outcome, LocationOutcome.ready);
      await resume;
      expect(gateway.requests, 1);
      expect(gateway.reads, 1);
    },
  );
  test(
    'Settings launch does not imply grant and return only rechecks once',
    () async {
      gateway.access = LocationAccess.denied;
      expect(await coordinator.openSettings(), isTrue);
      expect(gateway.reads, 0);
      await Future.wait([coordinator.onResumed(), coordinator.onResumed()]);
      expect(gateway.requests, 0);
      expect(gateway.settings, 1);
      expect(gateway.reads, 0);
      expect(await coordinator.onResumed(), isNull);
    },
  );
  test('Settings return with grant resumes one passive read', () async {
    gateway.access = LocationAccess.blocked;
    await coordinator.openSettings();
    gateway.access = LocationAccess.granted;
    final result = await coordinator.onResumed();
    expect(result?.outcome, LocationOutcome.ready);
    await coordinator.onResumed();
    expect([gateway.requests, gateway.settings, gateway.reads], [0, 1, 1]);
  });
  test('unsuccessful Settings launch does not schedule recovery', () async {
    gateway.settingsLaunched = false;
    expect(await coordinator.openSettings(), isFalse);
    expect(await coordinator.onResumed(), isNull);
    expect(gateway.reads, 0);
  });
  test(
    'permission denial after request remains denial rather than generic failure',
    () async {
      gateway.access = LocationAccess.denied;
      gateway.requestedAccess = LocationAccess.denied;
      expect(
        (await coordinator.locate(interactive: true)).outcome,
        LocationOutcome.denied,
      );
      expect(gateway.reads, 0);
    },
  );
  test(
    'quality rejects invalid coordinates accuracy and stale fixes',
    () async {
      for (final fix in [
        _fix(latitude: double.nan),
        _fix(longitude: double.infinity),
        _fix(latitude: 91),
        _fix(longitude: -181),
        _fix(accuracy: double.nan),
        _fix(accuracy: -1),
        _fix(accuracy: 100),
        _fix(time: _epoch.subtract(const Duration(seconds: 11))),
      ]) {
        gateway.fix = fix;
        expect((await coordinator.locate()).outcome, LocationOutcome.poorFix);
      }
    },
  );
  test(
    'freshness is evaluated when a delayed position actually arrives',
    () async {
      gateway.position = Completer<LocationFix>();
      final result = coordinator.locate();
      await gateway.startedRead.future;
      clock = _epoch.add(const Duration(minutes: 1));
      gateway.position!.complete(_fix());
      expect((await result).outcome, LocationOutcome.poorFix);
    },
  );
  test('acquisition errors and timeout clean up pending native read', () async {
    gateway.readError = TimeoutException('unavailable');
    expect((await coordinator.locate()).outcome, LocationOutcome.failed);
    expect(gateway.cancels, greaterThan(0));
  });
  test('dispose suppresses late success and prevents new work', () async {
    gateway.position = Completer<LocationFix>();
    final result = coordinator.locate();
    await gateway.startedRead.future;
    await coordinator.dispose().timeout(const Duration(seconds: 1));
    gateway.position!.complete(_fix());
    expect((await result).outcome, LocationOutcome.cancelled);
    expect(gateway.cancels, greaterThan(0));
    final reads = gateway.reads;
    expect(
      (await coordinator.locate(interactive: true)).outcome,
      LocationOutcome.cancelled,
    );
    expect(gateway.reads, reads);
  });
  test(
    'dispose while permission is pending prevents later position acquisition',
    () async {
      gateway.access = LocationAccess.denied;
      gateway.permission = Completer<LocationAccess>();
      final result = coordinator.locate(interactive: true);
      await Future<void>.delayed(Duration.zero);
      await coordinator.dispose().timeout(const Duration(seconds: 1));
      gateway.permission!.complete(LocationAccess.granted);
      expect((await result).outcome, LocationOutcome.cancelled);
      expect(gateway.reads, 0);
    },
  );
}
