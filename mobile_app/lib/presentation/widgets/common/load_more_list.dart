import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';

/// A ListView that fires [onLoadMore] when the user scrolls near the bottom.
/// Shows a spinner at the bottom while [isLoadingMore] is true.
class LoadMoreList extends StatefulWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final Widget Function(BuildContext, int)? separatorBuilder;
  final Future<void> Function() onLoadMore;
  final bool isLoadingMore;
  final bool hasMore;
  final EdgeInsetsGeometry padding;
  final ScrollController? controller;

  const LoadMoreList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.separatorBuilder,
    required this.onLoadMore,
    required this.isLoadingMore,
    required this.hasMore,
    this.padding = const EdgeInsets.all(16),
    this.controller,
  });

  @override
  State<LoadMoreList> createState() => _LoadMoreListState();
}

class _LoadMoreListState extends State<LoadMoreList> {
  late final ScrollController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = widget.controller ?? ScrollController();
    _ctrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_ctrl.hasClients) return;
    final threshold = _ctrl.position.maxScrollExtent - 200;
    if (_ctrl.offset >= threshold &&
        widget.hasMore &&
        !widget.isLoadingMore) {
      widget.onLoadMore();
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalCount =
        widget.itemCount + (widget.isLoadingMore || widget.hasMore ? 1 : 0);

    if (widget.separatorBuilder != null) {
      return ListView.separated(
        controller: _ctrl,
        padding: widget.padding,
        itemCount: totalCount,
        separatorBuilder: (ctx, i) =>
            i < widget.itemCount ? widget.separatorBuilder!(ctx, i) : const SizedBox.shrink(),
        itemBuilder: (ctx, i) {
          if (i >= widget.itemCount) return _BottomLoader(hasMore: widget.hasMore);
          return widget.itemBuilder(ctx, i);
        },
      );
    }

    return ListView.builder(
      controller: _ctrl,
      padding: widget.padding,
      itemCount: totalCount,
      itemBuilder: (ctx, i) {
        if (i >= widget.itemCount) return _BottomLoader(hasMore: widget.hasMore);
        return widget.itemBuilder(ctx, i);
      },
    );
  }
}

class _BottomLoader extends StatelessWidget {
  final bool hasMore;
  const _BottomLoader({required this.hasMore});

  @override
  Widget build(BuildContext context) {
    if (!hasMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text('All caught up!',
              style: TextStyle(color: AppColors.textHint, fontSize: 13)),
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(
          child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}
