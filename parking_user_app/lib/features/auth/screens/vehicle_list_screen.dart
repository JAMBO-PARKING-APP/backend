import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parking_user_app/features/auth/providers/vehicle_provider.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VehicleProvider>().fetchVehicles();
    });
  }

  void _showAddVehicleDialog() {
    final licenseController = TextEditingController();
    final makeController = TextEditingController();
    final modelController = TextEditingController();
    final colorController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Vehicle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: licenseController,
              decoration: const InputDecoration(labelText: 'License Plate'),
            ),
            TextField(
              controller: makeController,
              decoration: const InputDecoration(
                labelText: 'Make (e.g. Toyota)',
              ),
            ),
            TextField(
              controller: modelController,
              decoration: const InputDecoration(
                labelText: 'Model (e.g. Camry)',
              ),
            ),
            TextField(
              controller: colorController,
              decoration: const InputDecoration(labelText: 'Color'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await context.read<VehicleProvider>().addVehicle(
                licensePlate: licenseController.text,
                make: makeController.text,
                model: modelController.text,
                color: colorController.text,
              );
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'Vehicle added!' : 'Failed to add vehicle',
                    ),
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Vehicles')),
      body: Consumer<VehicleProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.vehicles.isEmpty) {
            return const Center(child: Text('No vehicles added yet.'));
          }

          return ListView.builder(
            itemCount: provider.vehicles.length,
            itemBuilder: (context, index) {
              final vehicle = provider.vehicles[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.directions_car),
                  title: Text(vehicle.licensePlate),
                  subtitle: Text(
                    '${vehicle.color} ${vehicle.make} ${vehicle.model}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Vehicle'),
                          content: const Text(
                            'Are you sure you want to remove this vehicle?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('No'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Yes'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true && mounted) {
                        await provider.removeVehicle(vehicle.id);
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddVehicleDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
