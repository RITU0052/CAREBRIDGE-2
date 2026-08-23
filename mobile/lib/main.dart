import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_provider.dart';
import 'widgets/app_theme.dart';
import 'screens/landing_page_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CareBridgeApp());
}

class CareBridgeApp extends StatelessWidget {
  const CareBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..loadSession()),
      ],
      child: MaterialApp(
        title: 'CareBridge AI — Modern Healthcare Platform',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const LandingPageScreen(),
      ),
    );
  }
}
