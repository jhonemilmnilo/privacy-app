import 'package:flutter/material.dart';
import 'views/home/home_screen.dart';
import 'views/overlay/overlay_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PrivacyApp());
}

/// Dedicated background entry point for the overlay window.
/// flutter_overlay_window looks for @pragma("vm:entry-point") overlayMain()
@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OverlayEntryPoint(),
    ),
  );
}

class PrivacyApp extends StatelessWidget {
  const PrivacyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Privacy Screen',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0F19),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          secondary: Color(0xFF38BDF8),
          surface: Color(0xFF131B2E),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
