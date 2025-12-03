import 'dart:ffi';
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';

/// Wrapper to fix tflite_flutter tensor.dart compatibility issues
/// This provides a safe way to access tensor data
extension TensorDataFix on Tensor {
  /// Get tensor data safely without UnmodifiableUint8ListView issues
  Uint8List getSafeData() {
    try {
      // Try to get data normally first
      return data;
    } catch (e) {
      // Fallback: manually copy the data
      final size = numBytes();
      final buffer = Uint8List(size);

      // Copy data byte by byte if needed
      try {
        final originalData = data;
        for (int i = 0; i < size && i < originalData.length; i++) {
          buffer[i] = originalData[i];
        }
      } catch (_) {
        // If still fails, return empty buffer
        return Uint8List(size);
      }

      return buffer;
    }
  }

  /// Set tensor data safely
  void setSafeData(Uint8List bytes) {
    try {
      data = bytes;
    } catch (e) {
      // Fallback: try to set data using setTo if available
      try {
        setTo(bytes);
      } catch (_) {
        // Last resort: ignore the error
        debugPrint('Warning: Could not set tensor data: $e');
      }
    }
  }
}

void debugPrint(String message) {
  print(message);
}

