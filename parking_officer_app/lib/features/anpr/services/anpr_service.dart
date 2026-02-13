import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class AnprService {
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );
  bool _isBusy = false;

  Future<String?> processImage(InputImage inputImage) async {
    if (_isBusy) return null;
    _isBusy = true;

    try {
      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );

      // Simple heuristic for license plates:
      // Look for blocks of text that match common patterns (e.g. UBA 123A)
      // For now, return the first plausible block

      for (TextBlock block in recognizedText.blocks) {
        final text = block.text.trim();
        if (_isValidPlate(text)) {
          return text;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error processing image for ANPR: $e');
      return null;
    } finally {
      _isBusy = false;
    }
  }

  bool _isValidPlate(String text) {
    // Basic validation for Uganda plates (Uxx 000x)
    // Adjust regex as needed for local context
    // This is a simplified check
    final RegExp uandaPlateRegex = RegExp(r'^U[A-Z]{2}\s?\d{3}[A-Z]$');
    return uandaPlateRegex.hasMatch(text.toUpperCase()) ||
        text.length > 5 && text.length < 9;
  }

  void dispose() {
    _textRecognizer.close();
  }
}
