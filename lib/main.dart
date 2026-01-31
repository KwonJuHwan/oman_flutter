import 'package:flutter/material.dart';
import 'core/theme/app_colors.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'package:device_preview/device_preview.dart'; 
import 'package:flutter/foundation.dart';

void main() {
  runApp(
    DevicePreview(
      enabled: !kReleaseMode, 
      builder: (context) => const RecipeApp(), 
    ),
  );
}

class RecipeApp extends StatelessWidget {
  const RecipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: DevicePreview.locale(context), 
      builder: DevicePreview.appBuilder,
      
      debugShowCheckedModeBanner: false,
      title: 'Recipe App',
      theme: ThemeData(
        fontFamily: 'Pretendard',
        textTheme: const TextTheme(
        bodyLarge: TextStyle(letterSpacing: -0.5), 
        bodyMedium: TextStyle(letterSpacing: -0.5),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        primarySwatch: Colors.orange,
      ),
      home: const HomeScreen(),
    );
  }
}