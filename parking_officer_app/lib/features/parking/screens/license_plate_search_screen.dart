import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parking_officer_app/core/app_theme.dart';
import 'package:parking_officer_app/core/localizations.dart';
import 'package:parking_officer_app/features/parking/providers/vehicle_search_provider.dart';
import 'package:parking_officer_app/features/parking/providers/zone_provider.dart';
import 'package:parking_officer_app/features/parking/providers/non_app_user_session_provider.dart';
import 'package:parking_officer_app/features/parking/screens/create_guest_session_screen.dart';

class LicensePlateSearchScreen extends StatefulWidget {
  const LicensePlateSearchScreen({super.key});

  @override
  State<LicensePlateSearchScreen> createState() =>
      _LicensePlateSearchScreenState();
}

class _LicensePlateSearchScreenState extends State<LicensePlateSearchScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final plate = _searchController.text.trim();
    if (plate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a license plate')),
      );
      return;
    }

    context.read<VehicleSearchProvider>().searchVehicle(plate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Vehicle'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search Input
            TextField(
              controller: _searchController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'Enter license plate',
                prefixIcon: const Icon(Icons.search),
                // Custom borders removed to inherit global theme
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<VehicleSearchProvider>().clearSearch();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _performSearch(),
            ),
            const SizedBox(height: 16),

            // Search Button
            ElevatedButton.icon(
              onPressed: _performSearch,
              icon: const Icon(Icons.search),
              label: const Text('SEARCH'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 32),

            // Results
            Consumer<VehicleSearchProvider>(
              builder: (context, provider, _) {
                if (provider.isSearching) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.searchError != null) {
                  final plateText = _searchController.text.trim().toUpperCase();
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor.withValues(alpha: 0.05),
                          border: Border.all(
                            color: AppTheme.errorColor.withValues(alpha: 0.2),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.errorColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.directions_car_filled_rounded,
                                color: AppTheme.errorColor,
                                size: 48,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'License Plate Not Found',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Plate "$plateText" is not registered in the system.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChangeNotifierProvider(
                                        create: (_) => NonAppUserSessionProvider(),
                                        child: CreateGuestSessionScreen(
                                          initialPlate: plateText,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.add_circle_outline_rounded),
                                label: const Text('Create Guest Session'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                if (provider.currentVehicle == null) {
                  return SizedBox(
                    height: MediaQuery.of(context).size.height * 0.4,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.directions_car,
                            size: 64,
                            color: Colors.grey.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          const Text('Search vehicle by license plate'),
                        ],
                      ),
                    ),
                  );
                }

                final vehicle = provider.currentVehicle!;
                return _buildVehicleDetails(context, vehicle);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleDetails(BuildContext context, dynamic vehicle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Vehicle Card
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vehicle Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildDetailRow('License Plate', vehicle.licensePlate),
                const SizedBox(height: 12),
                _buildDetailRow('Make', vehicle.make),
                const SizedBox(height: 12),
                _buildDetailRow('Model', vehicle.model),
                const SizedBox(height: 12),
                _buildDetailRow('Color', vehicle.color),
                const SizedBox(height: 24),
                _buildDetailRow(
                  AppLocalizations.of(context).owner,
                  vehicle.ownerName,
                  Icons.person_outline_rounded,
                ),
                _buildDetailRow(
                  AppLocalizations.of(context).phone,
                  vehicle.ownerPhone,
                  Icons.phone_outlined,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Status Card
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Unpaid Violations'),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: vehicle.unpaidViolations > 0
                            ? Colors.red.withValues(alpha: 0.2)
                            : Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${vehicle.unpaidViolations}',
                        style: TextStyle(
                          color: vehicle.unpaidViolations > 0
                              ? Colors.red
                              : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (vehicle.status == 'overdue' || vehicle.status == 'expired')
                  _buildOverstayWarning(context, vehicle),
                const SizedBox(height: 16),
                if (vehicle.activeSession != null)
                  _buildActiveSessionCard(vehicle.activeSession!)
                else if (vehicle.status == 'no_active_session' || vehicle.status == 'expired')
                  _buildNoActiveSessionState(context, vehicle),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverstayWarning(BuildContext context, dynamic vehicle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timer_off_rounded, color: Colors.red),
              const SizedBox(width: 12),
              Text(
                'Overstay Detected',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Overdue By', '${vehicle.overdueDurationMinutes} mins'),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Suggested Fine', style: TextStyle(color: Colors.grey)),
              Text(
                'UGX ${vehicle.suggestedFine.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Fine is calculated from the time session ended until now.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSessionCard(dynamic session) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_parking_rounded, color: Colors.blue),
              const SizedBox(width: 12),
              Text(
                'Active Parking Session',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDetailRow('Zone', session.zone),
          const SizedBox(height: 12),
          _buildDetailRow('Started At', _formatDateTime(session.startedAt)),
          const SizedBox(height: 12),
          _buildDetailRow('Planned End', _formatDateTime(session.plannedEnd)),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Amount Due', style: TextStyle(color: Colors.grey)),
              Text(
                'UGX ${session.amountDue.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoActiveSessionState(BuildContext context, dynamic vehicle) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppTheme.errorColor,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).noActiveSession,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.errorColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This vehicle is currently parked without an active session.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], height: 1.4),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showStartSessionDialog(context, vehicle),
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: const Text('START OFFICIAL SESSION'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStartSessionDialog(BuildContext context, dynamic vehicle) {
    double duration = 1.0;
    final zones = context.read<ZoneProvider>().zones;
    if (zones.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No active zones found')));
      return;
    }

    String selectedZoneId = zones.first.id;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('Start Official Session'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assigning session to ${vehicle.licensePlate}',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 24),
              const Text(
                'Select Zone',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedZoneId,
                isExpanded: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                items: zones
                    .map(
                      (z) => DropdownMenuItem(value: z.id, child: Text(z.name)),
                    )
                    .toList(),
                onChanged: (val) => setDialogState(() => selectedZoneId = val!),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Duration',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${duration.toStringAsFixed(1)}h',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Slider(
                value: duration,
                min: 0.25,
                max: 8.0,
                divisions: 31,
                activeColor: AppTheme.primaryColor,
                onChanged: (val) => setDialogState(() => duration = val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () async {
                final success = await context
                    .read<VehicleSearchProvider>()
                    .startSession(vehicle.id, selectedZoneId, duration);
                if (context.mounted) {
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Session started successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    context.read<VehicleSearchProvider>().searchVehicle(
                      vehicle.licensePlate,
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error starting session'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('START SESSION'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, [IconData? icon]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
          ],
          Text(label, style: const TextStyle(color: Colors.grey)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
