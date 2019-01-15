import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:real_mobile/enums/load_more_status.dart';

class MyNotification extends Notification {
  final String title;

  const MyNotification({this.title});
}


class InfiniteListView extends StatefulWidget {
  final Function getData;
  final Function itemBuilder;
  Function dataAppendFromRes;
  Function getNextPageFromRes;
  Stream updateListStream;
  bool withHeader = false;

  Widget loadingWidgetBuilder = Text("Loading...");
  InfiniteListView({Key key,
    @required this.getData,
    @required this.itemBuilder,
    this.loadingWidgetBuilder,
    this.withHeader = false,
    updateListStream,
    dataAppendFromRes,
    getNextPageFromRes,

  }
      ) : super(key: key) {

    if (dataAppendFromRes == null) {
      this.dataAppendFromRes = defaultReturnValue;
    } else {
      this.dataAppendFromRes = dataAppendFromRes;
    }
    if (getNextPageFromRes == null) {
      this.getNextPageFromRes = defaultReturnValue;
    } else {
      this.getNextPageFromRes = getNextPageFromRes;
    }
    if (getNextPageFromRes != null) {
      this.updateListStream = updateListStream;
    }

  }

  dynamic defaultReturnValue (res) {
    return res;
  }
  @override
  State<StatefulWidget> createState() => InfiniteListViewState();
}

class InfiniteListViewState extends State<InfiniteListView>  with AutomaticKeepAliveClientMixin {
  StreamSubscription streamSubscription;
  List<dynamic> data = [];
  InfiniteListViewStatus loadMoreStatus = InfiniteListViewStatus.STABLE;
  final ScrollController scrollController = new ScrollController();
  final AsyncMemoizer _memoizer = AsyncMemoizer();
  int nextPage = 1;

  @override
  void initState() {
    super.initState();
    if (widget.updateListStream != null) {
      streamSubscription = widget.updateListStream.listen((item) => onUpdateListStream(item));
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    if (streamSubscription != null) {
      streamSubscription.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: this._memoizer.runOnce(() async {
        Map<String, dynamic> value = await widget.getData(page: nextPage);
        handleServerRes(value);
        return value;
      }),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return NotificationListener(
              onNotification: onNotification,
              child: RefreshIndicator(
                  color: Colors.red,
                  onRefresh: _handleRefresh,
                  child: new ListView.builder(
                      padding: EdgeInsets.only(top: 5.0),
                      controller: scrollController,
                      itemCount: widget.withHeader ? data.length + 1: data.length,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemBuilder: (BuildContext context, index) {
                        if (widget.withHeader && index == 0) {
                          return widget.itemBuilder(context, index, null, data.length);
                        } else {
                          return widget.itemBuilder(context, index, data[widget.withHeader ? index - 1: index], data.length);
                        }

                      })
              )
          );
        } else {
          return widget.loadingWidgetBuilder;
        }
      },
    );
  }

  void onUpdateListStream(dynamic obj) {
    resetListAndCallService();
  }

  void resetListAndCallService() {
    data.clear();
    loadMoreStatus = InfiniteListViewStatus.LOADING;
    nextPage = 1;
    widget.getData(page:nextPage).then((jsonRes) {
      loadMoreStatus = InfiniteListViewStatus.STABLE;
      handleServerRes(jsonRes);
    });
  }

  void handleServerRes (res) {
    setState(() {
      nextPage = widget.getNextPageFromRes(res);
      data.addAll(widget.dataAppendFromRes(res));
    });
  }

  Future<Null> _handleRefresh() async {
    resetListAndCallService();
  }

  bool onNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      if (scrollController.position.maxScrollExtent > scrollController.offset &&
          scrollController.position.maxScrollExtent - scrollController.offset <=
              50) {
        if (loadMoreStatus != null &&
            loadMoreStatus == InfiniteListViewStatus.STABLE) {
          loadMoreStatus = InfiniteListViewStatus.LOADING;
          widget.getData(page: nextPage).then((jsonRes) {
            loadMoreStatus = InfiniteListViewStatus.STABLE;
            handleServerRes(jsonRes);
          });
        }
      }
    }
    return true;
  }

  @override
  bool get wantKeepAlive => true;
}