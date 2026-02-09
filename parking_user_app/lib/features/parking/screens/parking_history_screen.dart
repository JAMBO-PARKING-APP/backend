import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:parking_user_app/features/parking/providers/parking_provider.dart';

class ParkingHistoryScreen extends StatefulWidget {
  const ParkingHistoryScreen({super.key});

  @override
  State<ParkingHistoryScreen> createState() => _ParkingHistoryScreenState();
}

class _ParkingHistoryScreenState extends State<ParkingHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ParkingProvider>().fetchSessions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Parking History')),
      body: Consumer<ParkingProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.sessions.isEmpty) {
            return const Center(child: Text('No history found'));
          }
          return ListView.builder(
            itemCount: provider.sessions.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final session = provider.sessions[index];
              final dateStr = DateFormat(
                'MMM dd, HH:mm',
              ).format(session.startTime);
              return Card(
                child: ListTile(
                  title: Text(session.zoneName),
                  subtitle: Text('${session.vehiclePlate} • $dateStr'),
                  trailing: Text(
                    'UGX ${session.totalCost.toInt()}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
