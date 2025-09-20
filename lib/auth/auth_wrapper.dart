// Authentication Wrapper for Stardust Soul
// This widget handles the authentication flow and navigation

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../home_page.dart';
import 'login_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        // Show loading screen while initializing
        if (appProvider.isLoading && appProvider.user == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Show main app if authenticated
        if (appProvider.isAuthenticated) {
          return const HomePage();
        }

        // Show login page if not authenticated
        return const LoginPage();
      },
    );
  }
}