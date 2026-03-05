import 'package:flutter/material.dart';
import 'core/theme/app_colors.dart';
import 'features/auth/presentation/screens/login_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const RecipeApp());
}

class RecipeApp extends StatelessWidget {
  const RecipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
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
      home: const LoginScreen(),
    );
  }
}