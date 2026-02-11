import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:parking_officer_app/features/violations/providers/enforcement_provider.dart';
import 'package:parking_officer_app/features/violations/screens/camera_screen.dart';
import 'package:parking_officer_app/core/app_theme.dart';

class ViolationFormScreen extends StatefulWidget {
  final String vehiclePlate;
  final String? vehicleId;
  final String? zoneId;
  final String? sessionId;

  const ViolationFormScreen({
    super.key,
    required this.vehiclePlate,
    this.vehicleId,
    this.zoneId,
    this.sessionId,
  });

  @override
  State<ViolationFormScreen> createState() => _ViolationFormScreenState();
}

class _ViolationFormScreenState extends State<ViolationFormScreen> {
  final _descriptionController = TextEditingController();
  final _fineAmountController = TextEditingController();
  String _selectedType = 'expired';
  List<File> _evidence = [];
  bool _isLocating = false;
  Position? _currentPosition;

  final List<Map<String, dynamic>> _violationTypes = [
    {'value': 'expired', 'label': 'Expired Parking', 'fine': 20000.0},
    {'value': 'no_payment', 'label': 'No Payment', 'fine': 50000.0},
    {'value': 'wrong_zone', 'label': 'Wrong Zone', 'fine': 30000.0},
    {'value': 'disabled_spot', 'label': 'Disabled Spot', 'fine': 100000.0},
  ];

  @override
  void initState() {
    super.initState();
    _fineAmountController.text = _violationTypes[0]['fine'].toString();
    _getLocation();
  }

  Future<void> _getLocation() async {
    setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        _currentPosition = await Geolocator.getCurrentPosition();
      }
    } catch (_) {}
    setState(() => _isLocating = false);
  }

  void _submit() async {
    if (_descriptionController.text.isEmpty || _currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please provide description and ensure location is active',
          ),
        ),
      );
      return;
    }

    final success = await context.read<EnforcementProvider>().issueViolation(
      vehicleId:
          widget.vehicleId ?? widget.vehiclePlate, // Fallback if ID missing
      zoneId: widget.zoneId ?? '0',
      type: _selectedType,
      description: _descriptionController.text,
      fineAmount: double.parse(_fineAmountController.text),
      lat: _currentPosition!.latitude,
      lng: _currentPosition!.longitude,
      evidence: _evidence,
      sessionId: widget.sessionId,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Violation issued successfully')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Issue Violation')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildVehicleHeader(),
            const SizedBox(height: 24),
            const Text(
              'Violation Type',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            DropdownButtonFormField<String>(
              value: _selectedType,
              items: _violationTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type['value'],
                  child: Text(type['label']),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedType = val;
                    _fineAmountController.text = _violationTypes
                        .firstWhere((t) => t['value'] == val)['fine']
                        .toString();
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Fine Amount (UGX)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _fineAmountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(prefixText: 'UGX '),
            ),
            const SizedBox(height: 16),
            const Text(
              'Description',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Describe the violation...',
              ),
            ),
            const SizedBox(height: 24),
            _buildEvidenceSection(),
            const SizedBox(height: 32),
            Consumer<EnforcementProvider>(
              builder: (context, ep, _) {
                return ElevatedButton(
                  onPressed: ep.isProcessing || _isLocating ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorColor,
                  ),
                  child: ep.isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'ISSUE FINE',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            'VEHICLE PLATE',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Text(
            widget.vehiclePlate,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Evidence Photos',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Spacer(),
            Icon(Icons.camera_alt, size: 16, color: Colors.grey),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _evidence.length + 1,
            itemBuilder: (context, index) {
              if (index == _evidence.length) {
                return _buildAddPhotoButton();
              }
              return _buildPhotoItem(index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddPhotoButton() {
    return InkWell(
      onTap: () async {
        final File? image = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CameraScreen()),
        );
        if (image != null) {
          setState(() {
            _evidence.add(image);
          });
        }
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey[400]!,
            style: BorderStyle.solid,
          ),
        ),
        child: const Icon(Icons.add_a_photo, color: Colors.grey),
      ),
    );
  }

  Widget _buildPhotoItem(int index) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: DecorationImage(
          image: FileImage(_evidence[index]),
          fit: BoxFit.cover,
        ),
      ),
      child: Align(
        alignment: Alignment.topRight,
        child: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 20),
          onPressed: () => setState(() => _evidence.removeAt(index)),
        ),
      ),
    );
  }
}
