import 'package:flutter_test/flutter_test.dart';
import 'package:parking_officer_app/features/parking/models/zone_model.dart';
import 'package:parking_officer_app/features/parking/providers/non_app_user_session_provider.dart';
import 'package:parking_officer_app/features/parking/services/vehicle_search_service.dart';
import 'package:parking_officer_app/features/parking/services/zone_service.dart';

void main() {
  group('NonAppUserSessionProvider', () {
    late _FakeSessionService sessionService;
    late NonAppUserSessionProvider provider;

    setUp(() {
      sessionService = _FakeSessionService();
      provider = NonAppUserSessionProvider(
        sessionService: sessionService,
        zoneService: _FakeZoneService(),
      );
    });

    test('creates a guest session and retains the returned summary', () async {
      final created = await provider.createSession(
        licensePlate: 'ab123cd',
        driverName: 'Test Driver',
        driverPhone: '0712345678',
        zoneId: 'zone-1',
        durationHours: 2,
      );

      expect(created, isTrue);
      expect(sessionService.lastPlate, 'AB123CD');
      expect(sessionService.lastZoneId, 'zone-1');
      expect(provider.session?['id'], 'session-1');
      expect(provider.session?['estimated_cost'], '2000.00');
      expect(provider.error, isNull);
    });

    test('initiates and confirms payment for the created session', () async {
      await provider.createSession(
        licensePlate: 'AB123CD',
        driverName: 'Test Driver',
        driverPhone: '0712345678',
        zoneId: 'zone-1',
        durationHours: 1,
      );

      expect(await provider.initiatePayment('0712345678'), isTrue);
      expect(provider.paymentUrl, 'https://payments.example/checkout');

      expect(await provider.confirmPayment(), isTrue);
      expect(provider.isPaymentConfirmed, isTrue);
      expect(provider.session?['status'], 'active');
      expect(provider.session?['payment_status'], 'completed');
    });
  });
}

class _FakeSessionService extends VehicleSearchService {
  String? lastPlate;
  String? lastZoneId;

  @override
  Future<Map<String, dynamic>> createGuestSession({
    required String licensePlate,
    required String driverName,
    required String driverPhone,
    required String zoneId,
    required double durationHours,
  }) async {
    lastPlate = licensePlate;
    lastZoneId = zoneId;
    return {
      'success': true,
      'session_id': 'session-1',
      'amount_due': 2000,
      'session': {
        'id': 'session-1',
        'license_plate': licensePlate,
        'driver_name': driverName,
        'driver_phone': driverPhone,
        'zone_name': 'Test Zone',
        'estimated_cost': '2000.00',
        'status': 'active',
      },
    };
  }

  @override
  Future<Map<String, dynamic>> initiateGuestPayment({
    required String sessionId,
    required String phoneNumber,
  }) async => {
    'success': true,
    'payment_url': 'https://payments.example/checkout',
  };

  @override
  Future<Map<String, dynamic>> confirmGuestSessionPayment(
    String sessionId,
  ) async => {
    'success': true,
    'session_status': 'active',
    'payment_status': 'completed',
  };
}

class _FakeZoneService extends ZoneService {
  @override
  Future<List<Zone>> getZones() async => [
    Zone(
      id: 'zone-1',
      name: 'Test Zone',
      code: 'TZ',
      latitude: 0,
      longitude: 0,
      totalSlots: 10,
      availableSlots: 5,
      occupiedSlots: 5,
      hourlyRate: 1000,
    ),
  ];
}
