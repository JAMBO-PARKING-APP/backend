import 'package:flutter/foundation.dart';

class OfficerStatus {
  final String id;
  final String officerName;
  final String officerPhone;
  final bool isOnline;
  final DateTime? wentOnlineAt;
  final DateTime? wentOfflineAt;
  final String? zoneName;
  final double? latitude;
  final double? longitude;
  final DateTime updatedAt;

  OfficerStatus({
    required this.id,
    required this.officerName,
    required this.officerPhone,
    required this.isOnline,
    this.wentOnlineAt,
    this.wentOfflineAt,
    this.zoneName,
    this.latitude,
    this.longitude,
    required this.updatedAt,
  });

  factory OfficerStatus.fromJson(Map<String, dynamic> json) {
    try {
      return OfficerStatus(
        id: json['id']?.toString() ?? '',
        officerName: json['officer_name'] ?? '',
        officerPhone: json['officer_phone'] ?? '',
        isOnline: json['is_online'] ?? false,
        wentOnlineAt: json['went_online_at'] != null
            ? DateTime.tryParse(json['went_online_at'])
            : null,
        wentOfflineAt: json['went_offline_at'] != null
            ? DateTime.tryParse(json['went_offline_at'])
            : null,
        zoneName: json['zone_name'],
        latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
        longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
        updatedAt: json['updated_at'] != null 
            ? DateTime.tryParse(json['updated_at']) ?? DateTime.now()
            : DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error parsing OfficerStatus: $e');
      rethrow;
    }
  }
}
