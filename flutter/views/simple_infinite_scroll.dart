import 'package:flutter/material.dart';

enum InfiniteListViewStatus { LOADING, STABLE }
abstract class SimpleInfiniteScroll  {
  final ScrollController scrollController = new ScrollController();
  int nextPage = 1;
  InfiniteListViewStatus loadMoreStatus = InfiniteListViewStatus.STABLE;
  List<dynamic> items = [];

  void disposeScrollControllers() {
    scrollController.dispose();
  }

  void loadNextPage({int page = 1}) async {
    print("Ere");
  }

  Future<Null> _handleRefreshListView() async {
    items = [];
  }

  bool onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      if (scrollController.position.maxScrollExtent > scrollController.offset &&
          scrollController.position.maxScrollExtent - scrollController.offset <=
              100) {
        if (loadMoreStatus != null &&
            loadMoreStatus == InfiniteListViewStatus.STABLE) {
          loadMoreStatus = InfiniteListViewStatus.LOADING;
          this.loadNextPage(page: this.nextPage);
        }
      }
    }
    return true;
  }
}