import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ErrorHandler {
  // Check if device has internet
  static Future<bool> hasInternet() async {
    final result = await Connectivity().checkConnectivity();
    return result.first != ConnectivityResult.none;
  }

  // Show a snackbar with consistent styling
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () =>
              ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline,
                color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF1B6B3A),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Parse Supabase/network errors into readable messages
  static String parseError(dynamic error) {
    final message = error.toString();

    if (message.contains('SocketException') ||
        message.contains('NetworkException') ||
        message.contains('Failed host lookup')) {
      return 'No internet connection. Please check your network.';
    }
    if (message.contains('TimeoutException')) {
      return 'Request timed out. Please try again.';
    }
    if (message.contains('JWT')) {
      return 'Session expired. Please log in again.';
    }
    if (message.contains('duplicate key')) {
      return 'This record already exists.';
    }
    if (message.contains('violates row-level security')) {
      return 'You don\'t have permission to do this.';
    }

    return 'Something went wrong. Please try again.';
  }
}