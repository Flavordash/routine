import 'package:flutter/material.dart';
import '../widgets/common/error_boundary.dart';

class LazyLoader<T> {
  T? _instance;
  final T Function() _factory;
  
  LazyLoader(this._factory);
  
  T get instance {
    _instance ??= _factory();
    return _instance!;
  }
  
  void dispose() {
    _instance = null;
  }
  
  bool get isLoaded => _instance != null;
}

class LazyWidget extends StatefulWidget {
  const LazyWidget({
    super.key,
    required this.builder,
    this.placeholder,
    this.errorWidget,
    this.preload = false,
  });

  final Widget Function() builder;
  final Widget? placeholder;
  final Widget Function(Object error)? errorWidget;
  final bool preload;

  @override
  State<LazyWidget> createState() => _LazyWidgetState();
}

class _LazyWidgetState extends State<LazyWidget> {
  Widget? _cachedWidget;
  Object? _error;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.preload) {
      _loadWidget();
    }
  }

  Future<void> _loadWidget() async {
    if (_cachedWidget != null || _isLoading) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Add small delay to simulate async loading and prevent UI blocking
      await Future.delayed(const Duration(milliseconds: 1));
      
      final widget = this.widget.builder();
      
      if (mounted) {
        setState(() {
          _cachedWidget = widget;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorWidget?.call(_error!) ??
          ErrorBoundary(
            errorMessage: 'Failed to load widget',
            child: Container(),
          );
    }

    if (_cachedWidget != null) {
      return _cachedWidget!;
    }

    if (!_isLoading) {
      // Start loading when widget becomes visible
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadWidget();
      });
    }

    return widget.placeholder ?? const LoadingWidget();
  }
}

class LazyFutureBuilder<T> extends StatelessWidget {
  const LazyFutureBuilder({
    super.key,
    required this.future,
    required this.builder,
    this.placeholder,
    this.errorBuilder,
  });

  final Future<T> Function() future;
  final Widget Function(BuildContext context, T data) builder;
  final Widget? placeholder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return errorBuilder?.call(context, snapshot.error ?? 'Unknown error') ??
              ErrorBoundary(
                errorMessage: 'Failed to load data',
                child: Container(),
              );
        }

        if (snapshot.hasData) {
          return builder(context, snapshot.data!);
        }

        return placeholder ?? const LoadingWidget();
      },
    );
  }
}

// Lazy loading for dialogs
class LazyDialog {
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget Function() builder,
    Widget? loadingWidget,
    bool barrierDismissible = true,
    Color? barrierColor,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      builder: (context) => LazyWidget(
        builder: builder,
        placeholder: loadingWidget ?? const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: LoadingWidget(message: 'Loading...'),
          ),
        ),
      ),
    );
  }
}

// Lazy loading for page routes
class LazyPageRoute<T> extends PageRouteBuilder<T> {
  LazyPageRoute({
    required Widget Function() builder,
    Widget? placeholder,
    RouteSettings? settings,
    Duration transitionDuration = const Duration(milliseconds: 300),
  }) : super(
          settings: settings,
          transitionDuration: transitionDuration,
          pageBuilder: (context, animation, _) => LazyWidget(
            builder: builder,
            placeholder: placeholder ?? const Scaffold(
              body: LoadingWidget(),
            ),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
}

// Memory-efficient image loading
class LazyImage extends StatefulWidget {
  const LazyImage({
    super.key,
    required this.imageProvider,
    this.placeholder,
    this.errorWidget,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  final ImageProvider imageProvider;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  State<LazyImage> createState() => _LazyImageState();
}

class _LazyImageState extends State<LazyImage> {
  bool _isLoading = true;
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Image(
        image: widget.imageProvider,
        fit: widget.fit,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _isLoading) {
                setState(() => _isLoading = false);
              }
            });
            return child;
          }

          return widget.placeholder ?? 
              const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _hasError = true;
              });
            }
          });

          return widget.errorWidget ?? 
              const Center(
                child: Icon(
                  Icons.error_outline,
                  color: Colors.red,
                ),
              );
        },
      ),
    );
  }
}

// Lazy list loading with pagination
class LazyListView<T> extends StatefulWidget {
  const LazyListView({
    super.key,
    required this.itemBuilder,
    required this.loadMore,
    this.initialItems = const [],
    this.hasMore = true,
    this.loadingWidget,
    this.errorWidget,
    this.emptyWidget,
    this.itemCount,
    this.scrollController,
    this.physics,
    this.padding,
  });

  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Future<List<T>> Function(int page) loadMore;
  final List<T> initialItems;
  final bool hasMore;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final Widget? emptyWidget;
  final int? itemCount;
  final ScrollController? scrollController;
  final ScrollPhysics? physics;
  final EdgeInsets? padding;

  @override
  State<LazyListView<T>> createState() => _LazyListViewState<T>();
}

class _LazyListViewState<T> extends State<LazyListView<T>> {
  late ScrollController _scrollController;
  List<T> _items = [];
  bool _isLoading = false;
  bool _hasError = false;
  bool _hasMore = true;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_onScroll);
    _items = List.from(widget.initialItems);
    _hasMore = widget.hasMore;
    
    if (_items.isEmpty && _hasMore) {
      _loadMore();
    }
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final newItems = await widget.loadMore(_currentPage);
      
      if (mounted) {
        setState(() {
          _items.addAll(newItems);
          _currentPage++;
          _isLoading = false;
          _hasMore = newItems.isNotEmpty;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty && !_isLoading) {
      return widget.emptyWidget ?? 
          const Center(child: Text('No items available'));
    }

    return ListView.builder(
      controller: _scrollController,
      physics: widget.physics,
      padding: widget.padding,
      itemCount: _items.length + (_hasMore || _isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _items.length) {
          if (_hasError) {
            return widget.errorWidget ??
                Center(
                  child: Column(
                    children: [
                      const Text('Failed to load more items'),
                      ElevatedButton(
                        onPressed: _loadMore,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
          }
          
          return widget.loadingWidget ??
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
        }

        return widget.itemBuilder(context, _items[index], index);
      },
    );
  }
}