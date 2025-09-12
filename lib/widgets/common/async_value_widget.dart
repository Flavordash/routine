import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_constants.dart';
import '../../constants/text_styles.dart';
import 'error_boundary.dart';

class AsyncValueWidget<T> extends StatelessWidget {
  const AsyncValueWidget({
    super.key,
    required this.value,
    required this.data,
    this.loading,
    this.error,
    this.emptyMessage,
    this.emptyIcon,
    this.emptyAction,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget? loading;
  final Widget Function(Object error, StackTrace stackTrace)? error;
  final String? emptyMessage;
  final IconData? emptyIcon;
  final Widget? emptyAction;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: (d) {
        // Check if data is empty for collections
        if (d is List && d.isEmpty) {
          return EmptyStateWidget(
            title: emptyMessage ?? 'No data available',
            icon: emptyIcon,
            action: emptyAction,
          );
        }
        return data(d);
      },
      loading: () => loading ?? const LoadingWidget(),
      error: (err, stack) =>
          error?.call(err, stack) ??
          ErrorBoundary(
            errorMessage: 'Something went wrong',
            child: Container(),
          ),
    );
  }
}

class AsyncValueSliverWidget<T> extends StatelessWidget {
  const AsyncValueSliverWidget({
    super.key,
    required this.value,
    required this.data,
    this.loading,
    this.error,
    this.emptyMessage,
    this.emptyIcon,
    this.emptyAction,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget? loading;
  final Widget Function(Object error, StackTrace stackTrace)? error;
  final String? emptyMessage;
  final IconData? emptyIcon;
  final Widget? emptyAction;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: (d) {
        // Check if data is empty for collections
        if (d is List && d.isEmpty) {
          return SliverFillRemaining(
            child: EmptyStateWidget(
              title: emptyMessage ?? 'No data available',
              icon: emptyIcon,
              action: emptyAction,
            ),
          );
        }
        return data(d);
      },
      loading: () => loading ?? const SliverFillRemaining(child: LoadingWidget()),
      error: (err, stack) =>
          error?.call(err, stack) ??
          SliverFillRemaining(
            child: ErrorBoundary(
              errorMessage: 'Something went wrong',
              child: Container(),
            ),
          ),
    );
  }
}

class LoadingButton extends StatelessWidget {
  const LoadingButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.style,
    this.loadingColor,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final ButtonStyle? style;
  final Color? loadingColor;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: style,
      child: isLoading
          ? SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  loadingColor ?? Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            )
          : child,
    );
  }
}

class LoadingIconButton extends StatelessWidget {
  const LoadingIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.isLoading = false,
    this.loadingSize = 16.0,
    this.color,
    this.tooltip,
  });

  final VoidCallback? onPressed;
  final Widget icon;
  final bool isLoading;
  final double loadingSize;
  final Color? color;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: isLoading ? null : onPressed,
      color: color,
      tooltip: tooltip,
      icon: isLoading
          ? SizedBox(
              height: loadingSize,
              width: loadingSize,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  color ?? Theme.of(context).colorScheme.onSurface,
                ),
              ),
            )
          : icon,
    );
  }
}

class RefreshableAsyncValue<T> extends StatelessWidget {
  const RefreshableAsyncValue({
    super.key,
    required this.value,
    required this.onRefresh,
    required this.child,
  });

  final AsyncValue<T> value;
  final Future<void> Function() onRefresh;
  final Widget Function(T data) child;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: AsyncValueWidget<T>(
        value: value,
        data: child,
        loading: const LoadingWidget(message: 'Loading...'),
      ),
    );
  }
}

class PaginatedLoadingWidget extends StatelessWidget {
  const PaginatedLoadingWidget({
    super.key,
    this.message = 'Loading more...',
    this.height = 80.0,
  });

  final String message;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: AppConstants.iconM,
            height: AppConstants.iconM,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            message,
            style: AppTextStyles.caption.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class ErrorRetryWidget extends StatelessWidget {
  const ErrorRetryWidget({
    super.key,
    required this.onRetry,
    this.message = 'Something went wrong',
    this.buttonText = 'Retry',
  });

  final VoidCallback onRetry;
  final String message;
  final String buttonText;

  @override
  Widget build(BuildContext context) {
    return Center(
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
            message,
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingL),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(buttonText),
          ),
        ],
      ),
    );
  }
}

class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader({
    super.key,
    this.height = 20.0,
    this.width = double.infinity,
    this.borderRadius,
  });

  final double height;
  final double width;
  final BorderRadius? borderRadius;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(AppConstants.radiusS),
            color: Theme.of(context).colorScheme.onSurface.withValues(
              alpha: 0.1 + (_animation.value * 0.15),
            ),
          ),
        );
      },
    );
  }
}

class SkeletonList extends StatelessWidget {
  const SkeletonList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 80.0,
    this.separatorHeight = 8.0,
  });

  final int itemCount;
  final double itemHeight;
  final double separatorHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: separatorHeight),
          child: SkeletonLoader(height: itemHeight),
        ),
      ),
    );
  }
}

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonLoader(
              height: 16,
              width: MediaQuery.of(context).size.width * 0.6,
            ),
            const SizedBox(height: AppConstants.spacingS),
            const SkeletonLoader(height: 12),
            const SizedBox(height: AppConstants.spacingS),
            SkeletonLoader(
              height: 12,
              width: MediaQuery.of(context).size.width * 0.4,
            ),
          ],
        ),
      ),
    );
  }
}