import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class PlaceholderLoginScreen extends StatelessWidget {
  const PlaceholderLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        title: const Text(
          'Login (Placeholder)',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.deepNavy,
        elevation: 0,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.login_rounded,
                size: 64,
                color: AppColors.brightMint,
              ),
              SizedBox(height: 16),
              Text(
                'Login Target Screen',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Returning users are navigated here after splash.',
                style: TextStyle(
                  color: AppColors.paleSky,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
