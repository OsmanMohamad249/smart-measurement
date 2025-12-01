import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/calibration/presentation/screens/smart_calibration_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: SmartMeasurementApp(),
    ),
  );
}

/// Main application widget for the Smart Measurement App.
class SmartMeasurementApp extends StatelessWidget {
  const SmartMeasurementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Measurement',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const SmartCalibrationScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
