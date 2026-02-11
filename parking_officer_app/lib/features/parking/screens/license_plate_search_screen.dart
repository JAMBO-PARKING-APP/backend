import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parking_officer_app/features/parking/providers/vehicle_search_provider.dart';

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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                  return const CircularProgressIndicator();
                }

                if (provider.searchError != null) {
                  return Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        provider.searchError ?? 'Not found',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.red),
                      ),
                    ],
                  );
                }

                if (provider.currentVehicle == null) {
                  return SizedBox.fromSize(
                    size: Size.fromHeight(
                      MediaQuery.of(context).size.height * 0.4,
                    ),
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
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Owner Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Owner Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildDetailRow('Name', vehicle.ownerName),
                const SizedBox(height: 12),
                _buildDetailRow('Phone', vehicle.ownerPhone),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Violations & Session Card
        Card(
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
                const SizedBox(height: 16),
                if (vehicle.activeSession != null) ...[
                  Divider(color: Colors.grey.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  const Text(
                    'Active Parking Session',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('Zone', vehicle.activeSession!.zone),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Started',
                    _formatDateTime(vehicle.activeSession!.startedAt),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Planned End',
                    _formatDateTime(vehicle.activeSession!.plannedEnd),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Estimated Cost',
                    'UGX ${vehicle.activeSession!.estimatedCost.toStringAsFixed(2)}',
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.end,
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
