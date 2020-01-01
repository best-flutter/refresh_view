library refresh_view;


import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class Page<T> {
  int page;
  int pages;
  List<T> data;

  Page({this.page = 1, this.pages, this.data})
      : assert(page != null),
        assert(pages != null);

  bool isFirstPage() {
    return page <= 1;
  }

  bool isLastPage() {
    return page >= pages;
  }
}

enum RequestDataType { Initialize, Refresh, LoadMore }

typedef Future RequestData(RequestDataType type, int position);
typedef Widget StateListItemBuilder<T>(BuildContext context, T data, int index);

Widget _buildHeader(BuildContext context) {
  return new WaterDropHeader();
}

Widget _buildFooter(BuildContext context) {
  return new CustomFooter(
    builder: (BuildContext context, LoadStatus mode) {
      Widget body;
      if (mode == LoadStatus.idle) {
        body = Text("pull up load");
      } else if (mode == LoadStatus.loading) {
        body = CupertinoActivityIndicator();
      } else if (mode == LoadStatus.failed) {
        body = Text("Load Failed!Click retry!");
      } else if (mode == LoadStatus.canLoading) {
        body = Text("release to load more");
      } else {
        body = Text("No more Data");
      }
      return Container(
        height: 55.0,
        child: Center(child: body),
      );
    },
  );
}

class StateListView<T> extends StatefulWidget {
  static WidgetBuilder _globalHeaderBuilder = _buildHeader;
  static WidgetBuilder _globalFooterBuilder = _buildFooter;

  static void setGlobalHeaderBuilder(WidgetBuilder widgetBuilder) {
    _globalHeaderBuilder = widgetBuilder;
  }

  static void setGlobalFooterBuilder(WidgetBuilder widgetBuilder) {
    _globalFooterBuilder = widgetBuilder;
  }

  final RequestData requestData;
  final double itemExtent;
  final StateListItemBuilder<T> itemBuilder;
  final WidgetBuilder footerBuilder;
  final WidgetBuilder headerBuilder;

  StateListView(
      {this.requestData,
        this.itemBuilder,
        this.itemExtent,
        this.footerBuilder,
        this.headerBuilder});

  @override
  _StateListViewState<T> createState() => _StateListViewState<T>();
}

class _StateListViewState<T> extends State<StateListView> {
  RefreshController _refreshController =
  new RefreshController(initialRefresh: false);

  bool _footer = false;

  List<T> data = [];

  void requestData(RequestDataType type) async {
    var data = await widget.requestData(type, this.data.length);

    setState(() {
      if (type != RequestDataType.LoadMore) {
        this.data.clear();
      }
      if (data is List) {
        this.data = data;
      } else {
        Page page = data;
        if (page.isLastPage()) {
          _footer = false;
        } else {
          _footer = true;
        }
        this.data.addAll(data.data);
      }

      if (type == RequestDataType.LoadMore) {
        _refreshController.loadComplete();
      } else {
        _refreshController.refreshCompleted();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    requestData(RequestDataType.Initialize);
  }

  @override
  Widget build(BuildContext context) {
    WidgetBuilder headerBuilder =
        widget.headerBuilder ?? StateListView._globalHeaderBuilder;
    Widget footer;
    if (_footer) {
      WidgetBuilder footerBuilder =
          widget.footerBuilder ?? StateListView._globalFooterBuilder;
      footer = footerBuilder(context);
    }

    return SmartRefresher(
      enablePullDown: true,
      enablePullUp: _footer,
      controller: _refreshController,
      onRefresh: () {
        this.requestData(RequestDataType.Refresh);
      },
      onLoading: () {
        this.requestData(RequestDataType.LoadMore);
      },
      header: headerBuilder(context),
      footer: footer,
      child: ListView.builder(
        itemBuilder: (c, i) {
          return widget.itemBuilder(c, data[i], i);
        },
        itemExtent: widget.itemExtent,
        itemCount: data.length,
      ),
    );
  }
}
