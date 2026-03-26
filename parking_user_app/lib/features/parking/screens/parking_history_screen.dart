import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:parking_user_app/features/parking/providers/parking_provider.dart';
import 'package:parking_user_app/features/settings/providers/settings_provider.dart';
import 'package:parking_user_app/core/utils/currency_formatter.dart';
import 'package:parking_user_app/core/app_theme.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:parking_user_app/core/constants.dart';

class ParkingHistoryScreen extends StatefulWidget {
  const ParkingHistoryScreen({super.key});

  @override
  State<ParkingHistoryScreen> createState() => _ParkingHistoryScreenState();
}

class _ParkingHistoryScreenState extends State<ParkingHistoryScreen> {
  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    await context.read<ParkingProvider>().fetchSessions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Parking History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: AppTheme.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<ParkingProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 80,
                    color: Colors.grey.shade200,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No parking history yet',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              itemCount: provider.sessions.length,
              padding: const EdgeInsets.all(20),
              itemBuilder: (context, index) {
                final session = provider.sessions[index];
                final dateStr = DateFormat(
                  'MMM dd, yyyy',
                ).format(session.startTime);
                final timeStr = DateFormat('HH:mm').format(session.startTime);

                return InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Session details coming soon')),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.directions_car_filled_rounded,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                session.zoneName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$dateStr • $timeStr',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Consumer<SettingsProvider>(
                              builder: (context, settings, _) => Text(
                                CurrencyFormatter.formatCurrency(
                                  session.totalCost,
                                  settings.countryConfig,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                session.vehiclePlate,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                final baseUrl = AppConstants.baseUrl;
                                final domain = baseUrl.substring(0, baseUrl.indexOf('/api/'));
                                final url = Uri.parse('$domain/api/parking/invoice/${session.id}/');
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url, mode: LaunchMode.externalApplication);
                                }
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.download_rounded, size: 14, color: AppTheme.primaryColor),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Invoice',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
