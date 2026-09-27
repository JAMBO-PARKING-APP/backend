import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parking_officer_app/features/parking/models/zone_model.dart';
import 'package:parking_officer_app/features/parking/providers/non_app_user_session_provider.dart';
import 'package:parking_officer_app/features/parking/screens/non_app_user_session_screen.dart';

class CreateGuestSessionScreen extends StatelessWidget {
  const CreateGuestSessionScreen({super.key, this.initialPlate, this.zoneId});

  final String? initialPlate;
  final String? zoneId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NonAppUserSessionProvider(),
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Create Guest Session')),
          body: GuestSessionForm(
            initialPlate: initialPlate,
            initialZoneId: zoneId,
            onSessionCreated: (session) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      NonAppUserSessionScreen(initialSession: session),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class GuestSessionForm extends StatefulWidget {
  const GuestSessionForm({
    super.key,
    this.initialPlate,
    this.initialZoneId,
    required this.onSessionCreated,
  });

  final String? initialPlate;
  final String? initialZoneId;
  final ValueChanged<Map<String, dynamic>> onSessionCreated;

  @override
  State<GuestSessionForm> createState() => _GuestSessionFormState();
}

class _GuestSessionFormState extends State<GuestSessionForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _plateController;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  Zone? _selectedZone;
  double _durationHours = 1;

  @override
  void initState() {
    super.initState();
    _plateController = TextEditingController(
      text: widget.initialPlate?.toUpperCase() ?? '',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<NonAppUserSessionProvider>().loadZones();
    });
  }

  @override
  void dispose() {
    _plateController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NonAppUserSessionProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingZones && provider.zones.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.zones.isNotEmpty && _selectedZone == null) {
          _selectedZone = provider.zones.firstWhere(
            (zone) => zone.id == widget.initialZoneId,
            orElse: () => provider.zones.first,
          );
          _durationHours = _durationOptions(_selectedZone!).first;
        }

        return Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Enter the driver and vehicle details to start a parking session.',
                style: TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 20),
              TextFormField(
                key: const Key('guest_license_plate'),
                controller: _plateController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'License plate',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.directions_car),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Enter a license plate'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('guest_driver_name'),
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Driver name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Enter the driver name'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('guest_driver_phone'),
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Driver phone (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 14),
              if (provider.zones.isEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'No parking zones are available. Check your connection and try again.',
                      style: TextStyle(color: Colors.red),
                    ),
                    TextButton.icon(
                      onPressed: provider.isLoadingZones
                          ? null
                          : provider.loadZones,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                )
              else ...[
                DropdownButtonFormField<Zone>(
                  key: ValueKey('guest_zone_${_selectedZone?.id ?? 'unset'}'),
                  initialValue: _selectedZone,
                  decoration: const InputDecoration(
                    labelText: 'Parking zone',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  items: provider.zones
                      .map(
                        (zone) => DropdownMenuItem(
                          value: zone,
                          child: Text(
                            '${zone.name} (${zone.availableSlots} spaces)',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (zone) {
                    if (zone == null) return;
                    setState(() {
                      _selectedZone = zone;
                      _durationHours = _durationOptions(zone).first;
                    });
                  },
                  validator: (zone) =>
                      zone == null ? 'Select a parking zone' : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<double>(
                  key: ValueKey('guest_duration_$_durationHours'),
                  initialValue: _durationHours,
                  decoration: const InputDecoration(
                    labelText: 'Parking duration',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.schedule),
                  ),
                  items: _durationOptions(_selectedZone!)
                      .map(
                        (hours) => DropdownMenuItem(
                          value: hours,
                          child: Text(hours == 1 ? '1 hour' : '$hours hours'),
                        ),
                      )
                      .toList(),
                  onChanged: (hours) {
                    if (hours != null) setState(() => _durationHours = hours);
                  },
                ),
                if (_selectedZone!.hourlyRate > 0) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Estimated total: UGX ${_formatAmount(_selectedZone!.hourlyRate * _durationHours)}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ],
              if (provider.error != null) ...[
                const SizedBox(height: 12),
                Text(
                  provider.error!,
                  key: const Key('guest_session_error'),
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  key: const Key('create_guest_session'),
                  onPressed: provider.isSubmitting || _selectedZone == null
                      ? null
                      : () => _submit(provider),
                  icon: provider.isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    provider.isSubmitting ? 'Creating session…' : 'Continue',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submit(NonAppUserSessionProvider provider) async {
    if (!_formKey.currentState!.validate() || _selectedZone == null) return;
    final created = await provider.createSession(
      licensePlate: _plateController.text,
      driverName: _nameController.text,
      driverPhone: _phoneController.text,
      zoneId: _selectedZone!.id,
      durationHours: _durationHours,
    );
    if (created && mounted) {
      widget.onSessionCreated(provider.session!);
    }
  }

  List<double> _durationOptions(Zone zone) {
    final maxHours = zone.maxDurationHours > 0 ? zone.maxDurationHours : 24;
    final options = [
      1.0,
      2.0,
      3.0,
      4.0,
      8.0,
      12.0,
      24.0,
    ].where((hours) => hours <= maxHours).toList();
    return options.isEmpty ? [1.0] : options;
  }

  String _formatAmount(double amount) => amount.toStringAsFixed(2);
}
