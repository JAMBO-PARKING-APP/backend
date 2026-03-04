import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parking_officer_app/core/app_theme.dart';
import 'package:parking_officer_app/features/parking/models/zone_model.dart';

class ViolationWizardScreen extends StatefulWidget {
  final String licensePlate;
  final Zone? zone;
  final String? sessionId;

  const ViolationWizardScreen({
    super.key,
    required this.licensePlate,
    this.zone,
    this.sessionId,
  });

  @override
  State<ViolationWizardScreen> createState() => _ViolationWizardScreenState();
}

class _ViolationWizardScreenState extends State<ViolationWizardScreen> {
  int _currentStep = 0;
  final List<File> _evidence = [];
  String _violationType = 'no_payment';
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  final Map<String, String> _violationTypes = {
    'expired': 'Expired Parking',
    'no_payment': 'No Payment',
    'wrong_zone': 'Wrong Zone',
    'disabled_spot': 'Disabled Spot Violation',
    'overdue_parking': 'Overdue Parking',
  };

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _evidence.add(File(pickedFile.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _evidence.removeAt(index);
    });
  }

  Future<void> _submitViolation() async {
    if (_evidence.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least one evidence photo is required.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Logic for submission via OfficerService will go here
      // For now, simulating success
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Icon(
            Icons.check_circle,
            color: AppTheme.successColor,
            size: 64,
          ),
          content: const Text(
            'Violation issued successfully. The user has been notified and the fine has been deducted from their wallet.',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Pop dialog
                Navigator.pop(context); // Pop wizard
              },
              child: const Text('FINISH'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to issue violation: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FINE ISSUANCE'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 3,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppTheme.accentColor,
            ),
          ),
        ),
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: IndexedStack(
                    index: _currentStep,
                    children: [
                      _buildEvidenceStep(),
                      _buildDetailsStep(),
                      _buildReviewStep(),
                    ],
                  ),
                ),
                _buildNavigationButtons(),
              ],
            ),
    );
  }

  Widget _buildEvidenceStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'STEP 1: CAPTURE EVIDENCE',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ensure the license plate and vehicle position are clearly visible.',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _evidence.length + 1,
              itemBuilder: (context, index) {
                if (index == _evidence.length) {
                  return _buildAddImageButton();
                }
                return _buildEvidenceThumbnail(index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddImageButton() {
    return InkWell(
      onTap: () => _pickImage(ImageSource.camera),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.2),
            width: 2,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo_rounded,
              color: AppTheme.primaryColor,
              size: 32,
            ),
            SizedBox(height: 8),
            Text(
              'CAPTURE',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvidenceThumbnail(int index) {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(_evidence[index], fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'STEP 2: VIOLATION DETAILS',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'VEHICLE PLATE',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.licensePlate,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'VIOLATION TYPE',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _violationType,
                isExpanded: true,
                items: _violationTypes.entries.map((e) {
                  return DropdownMenuItem(value: e.key, child: Text(e.value));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _violationType = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'OFFICER NOTES',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Enter specific details about the violation...',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'STEP 3: FINAL REVIEW',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          _buildReviewRow('Vehicle Plate', widget.licensePlate),
          _buildReviewRow('Violation', _violationTypes[_violationType]!),
          _buildReviewRow('Zone', widget.zone?.name ?? 'Detecting...'),
          _buildReviewRow('Evidence', '${_evidence.length} Photo(s)'),
          const Divider(height: 48),
          const Text(
            'CONFIRMATION',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'By submitting this, a fine will be instantly issued to the vehicle owner. Ensure all details are correct.',
            style: TextStyle(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                child: const Text('BACK'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                if (_currentStep < 2) {
                  setState(() => _currentStep++);
                } else {
                  _submitViolation();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentStep == 2
                    ? AppTheme.errorColor
                    : AppTheme.primaryColor,
              ),
              child: Text(_currentStep == 2 ? 'ISSUE FINE' : 'CONTINUE'),
            ),
          ),
        ],
      ),
    );
  }
}
