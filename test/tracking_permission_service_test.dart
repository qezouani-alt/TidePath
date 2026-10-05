import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fishing/services/tracking_permission_service.dart';

void main() {
  test(
    'requests undetermined ATT only while active and records authorization',
    () async {
      var requests = 0;
      var status = PermissionStatus.denied;
      final service = TrackingPermissionService(
        supported: true,
        status: () async => status,
        waitForActive: () async => true,
        request: () async {
          requests++;
          return status = PermissionStatus.granted;
        },
      );
      await service.requestOnLaunch();
      await service.requestOnLaunch();
      expect(requests, 1);
      expect(service.authorized, isTrue);
    },
  );
  test('denied or restricted ATT does not prompt again', () async {
    for (final status in [
      PermissionStatus.permanentlyDenied,
      PermissionStatus.restricted,
    ]) {
      var requests = 0;
      final service = TrackingPermissionService(
        supported: true,
        status: () async => status,
        request: () async {
          requests++;
          return PermissionStatus.granted;
        },
      );
      await service.requestOnLaunch();
      expect(requests, 0);
      expect(service.authorized, isFalse);
    }
  });
  test('inactive app does not attempt to show ATT', () async {
    var requests = 0;
    final service = TrackingPermissionService(
      supported: true,
      status: () async => PermissionStatus.denied,
      waitForActive: () async => false,
      request: () async {
        requests++;
        return PermissionStatus.granted;
      },
    );
    await service.requestOnLaunch();
    expect(requests, 0);
  });
}
