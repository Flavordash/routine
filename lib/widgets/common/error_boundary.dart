import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../constants/text_styles.dart';
import '../../utils/logger.dart';

// Error Boundary Widget
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final Widget? fallback;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorMessage,
    this.onRetry,
    this.fallback,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool hasError = false;
  Object? error;

  @override
  Widget build(BuildContext context) {
    if (hasError) {
      return widget.fallback ?? _buildErrorWidget();
    }

    return ErrorBoundaryInherited(
      onError: _handleError,
      child: widget.child,
    );
  }

  void _handleError(Object error, [StackTrace? stackTrace]) {
    // Log the error with context
    Logger.instance.error('ErrorBoundary caught error: $error');
    if (stackTrace != null) {
      Logger.instance.error('Stack trace: $stackTrace');
    }

    // Report error for analytics (in production)
    _reportError(error, stackTrace);

    setState(() {
      hasError = true;
      this.error = error;
    });
  }

  void _reportError(Object error, StackTrace? stackTrace) {
    // This is where you'd integrate with crash analytics like Firebase Crashlytics
    // For now, we'll just use our logger
    Logger.instance.error('Error reported to analytics: ${error.runtimeType} - $error');
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: AppConstants.iconXL * 2,
            color: Colors.red[300],
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            'Oops! Something went wrong',
            style: AppTextStyles.h3,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingS),
          if (widget.errorMessage != null)
            Text(
              widget.errorMessage!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: AppConstants.spacingS),
              child: Text(
                error.toString(),
                style: AppTextStyles.caption.copyWith(
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const SizedBox(height: AppConstants.spacingL),
          if (widget.onRetry != null)
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  hasError = false;
                  error = null;
                });
                widget.onRetry!();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingL,
                  vertical: AppConstants.spacingM,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Inherited Widget for Error Boundary
class ErrorBoundaryInherited extends InheritedWidget {
  final Function(Object) onError;

  const ErrorBoundaryInherited({
    super.key,
    required this.onError,
    required super.child,
  });

  static ErrorBoundaryInherited? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ErrorBoundaryInherited>();
  }

  @override
  bool updateShouldNotify(ErrorBoundaryInherited oldWidget) {
    return onError != oldWidget.onError;
  }
}

// Loading State Widget
class LoadingWidget extends StatelessWidget {
  final String? message;
  final double? size;

  const LoadingWidget({
    super.key,
    this.message,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size ?? AppConstants.iconXL,
            height: size ?? AppConstants.iconXL,
            child: const CircularProgressIndicator(),
          ),
          if (message != null) ...[
            const SizedBox(height: AppConstants.spacingM),
            Text(
              message!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

// Empty State Widget
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? action;

  const EmptyStateWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon ?? Icons.inbox_outlined,
            size: AppConstants.iconXL * 2,
            color: Colors.grey[300],
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            title,
            style: AppTextStyles.h3,
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppConstants.spacingS),
            Text(
              subtitle!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: AppConstants.spacingL),
            action!,
          ],
        ],
      ),
    );
  }
}