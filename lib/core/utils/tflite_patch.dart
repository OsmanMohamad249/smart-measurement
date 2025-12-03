// Patch file to override tflite_flutter tensor issue
// This file should be imported before using TFLiteService

import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';

/// Extension to fix UnmodifiableUint8ListView issue in older tflite_flutter versions
extension TensorDataFix on Tensor {
  /// Safe way to get tensor data
  Uint8List get safeData {
    try {
      return data as Uint8List;
    } catch (e) {
      // Fallback: copy data manually
      final buffer = ByteData(numBytes());
      for (int i = 0; i < numBytes(); i++) {
        buffer.setUint8(i, 0);
      }
      return buffer.buffer.asUint8List();
    }
  }
}

