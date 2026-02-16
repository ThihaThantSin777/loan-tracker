import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Utility class for handling and displaying errors
class ErrorHandler {
  /// Show a snackbar with error message
  static void showError(BuildContext context, String message, {String? errorCode}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.dangerColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show a snackbar with success message
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show a snackbar with warning message
  static void showWarning(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_outlined, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.warningColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Show an error dialog
  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? errorCode,
    VoidCallback? onRetry,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: AppTheme.dangerColor),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (errorCode != null) ...[
              const SizedBox(height: 12),
              Text(
                'Error code: $errorCode',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (onRetry != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  /// Show a network error dialog with retry option
  static Future<void> showNetworkError(BuildContext context, {VoidCallback? onRetry}) {
    return showErrorDialog(
      context,
      title: 'Connection Error',
      message: 'Unable to connect to the server. Please check your internet connection and try again.',
      errorCode: 'NETWORK_ERROR',
      onRetry: onRetry,
    );
  }

  /// Show a session expired dialog
  static Future<void> showSessionExpired(BuildContext context, {required VoidCallback onLogin}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: AppTheme.warningColor),
            SizedBox(width: 12),
            Text('Session Expired'),
          ],
        ),
        content: const Text(
          'Your session has expired. Please login again to continue.',
        ),
        actions: [
          ElevatedButton(
            onPressed: onLogin,
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  /// Handle API response and show appropriate error
  static bool handleResponse(
    BuildContext context,
    Map<String, dynamic> response, {
    String? successMessage,
    VoidCallback? onSuccess,
    VoidCallback? onRetry,
  }) {
    if (response['success'] == true) {
      if (successMessage != null) {
        showSuccess(context, successMessage);
      }
      onSuccess?.call();
      return true;
    } else {
      final errorCode = response['error_code'] as String?;
      final error = response['error'] as String? ?? 'Something went wrong';

      // Handle specific error codes
      if (errorCode == 'NETWORK_ERROR') {
        showNetworkError(context, onRetry: onRetry);
      } else if (errorCode == 'UNAUTHENTICATED') {
        showError(context, error, errorCode: errorCode);
        // Could trigger logout here
      } else if (errorCode == 'VALIDATION_ERROR' && response['errors'] != null) {
        // Format validation errors
        final errors = response['errors'] as Map<String, dynamic>;
        final firstError = errors.values.first;
        final errorMessage = firstError is List ? firstError.first : firstError.toString();
        showError(context, errorMessage, errorCode: errorCode);
      } else {
        showError(context, error, errorCode: errorCode);
      }
      return false;
    }
  }
}

/// A widget to display when an error occurs
class ErrorView extends StatelessWidget {
  final String message;
  final String? errorCode;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorView({
    super.key,
    required this.message,
    this.errorCode,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  factory ErrorView.network({VoidCallback? onRetry}) {
    return ErrorView(
      message: 'No internet connection.\nPlease check your network.',
      errorCode: 'NETWORK_ERROR',
      icon: Icons.wifi_off,
      onRetry: onRetry,
    );
  }

  factory ErrorView.server({VoidCallback? onRetry}) {
    return ErrorView(
      message: 'Server error.\nPlease try again later.',
      errorCode: 'SERVER_ERROR',
      icon: Icons.cloud_off,
      onRetry: onRetry,
    );
  }

  factory ErrorView.notFound({String? message}) {
    return ErrorView(
      message: message ?? 'The requested resource was not found.',
      errorCode: 'NOT_FOUND',
      icon: Icons.search_off,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            if (errorCode != null) ...[
              const SizedBox(height: 8),
              Text(
                'Error: $errorCode',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A widget to display when a list is empty
class EmptyView extends StatelessWidget {
  final String message;
  final IconData icon;
  final Widget? action;

  const EmptyView({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
