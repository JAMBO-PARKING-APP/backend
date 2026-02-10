import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/parking_session_model.dart';
import '../../../core/app_theme.dart';

class QRCodeViewScreen extends StatelessWidget {
  final ParkingSession session;

  const QRCodeViewScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final qrData = session.qrCodeData ?? "INVALID_SESSION";

    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            "Parking Pass",
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Show this to the parking officer",
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16),
          ),
          const Spacer(),
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 280.0,
                    gapless: false,
                    foregroundColor: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    session.vehiclePlate,
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    session.zoneName,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.access_time, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  "Expires at: ${session.endTime?.hour.toString().padLeft(2, '0')}:${session.endTime?.minute.toString().padLeft(2, '0')}",
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
