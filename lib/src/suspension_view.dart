import 'package:azlistview/src/az_common.dart';
import 'package:azlistview/src/event_bus.dart';
import 'package:flutter/material.dart';
import 'dart:async';

/// on all sus section callback(map: Used to scroll the list to the specified tag location).
typedef void OnSusSectionCallBack(Map<String, int> map);

///Suspension Widget.Currently only supports fixed height items!
class SuspensionView extends StatefulWidget {
  /// with  ISuspensionBean Data
  final List<ISuspensionBean> data;

  /// content widget(must contain ListView).
  final Widget contentWidget;

  /// suspension widget.
  final Widget suspensionWidget;

  /// ListView ScrollController.
  final ScrollController controller;

  /// suspension widget Height.
  final int suspensionHeight;

  /// item Height.
  final int itemHeight;

  /// on sus tag change callback.
  final ValueChanged<String> onSusTagChanged;

  /// on sus section callback.
  final OnSusSectionCallBack onSusSectionInited;

  final AzListViewHeader header;

  SuspensionView({
    Key key,
    @required this.data,
    @required this.contentWidget,
    @required this.suspensionWidget,
    @required this.controller,
    this.suspensionHeight = 40,
    this.itemHeight = 50,
    this.onSusTagChanged,
    this.onSusSectionInited,
    this.header,
  })  : assert(contentWidget != null),
        assert(controller != null),
        super(key: key);

  @override
  _SuspensionWidgetState createState() => new _SuspensionWidgetState();
}

class _SuspensionWidgetState extends State<SuspensionView> {
  int _suspensionTop = 0;
  int _lastIndex;
  int _suSectionListLength;

  List<int> _suspensionSectionList = new List();
  Map<String, int> _suspensionSectionMap = new Map();
  int _headerHeight=0;
  StreamSubscription<double> _subscription;

  @override
  void initState() {
    super.initState();
    _suspensionTop=0;
    _headerHeight =0;
    widget.controller.addListener(() {
      int offset = widget.controller.offset.toInt();
      int _index = _getIndex(offset);
      if (_index != -1 && _lastIndex != _index) {
        _lastIndex = _index;
        if (widget.onSusTagChanged != null) {
          widget.onSusTagChanged(_suspensionSectionMap.keys.toList()[_index]);
        }
      }
    });
    _subscription = EventBus.getInstance().on<double>().listen((event) {
      _headerHeight = event.toInt();
      _suspensionTop = -_headerHeight;
      setState(() {});
    });
  }

  @override
  dispose() {
    super.dispose();
    _subscription.cancel();
  }

  int _getIndex(int offset) {
    if (widget.header != null && offset < _headerHeight) {
      if (_suspensionTop != -_headerHeight && widget.suspensionWidget != null) {
        setState(() {
          _suspensionTop = -_headerHeight;
        });
      }
      return 0;
    }
    for (int i = 0; i < _suSectionListLength - 1; i++) {
      int space = _suspensionSectionList[i + 1] - offset;
      if (space > 0 && space < widget.suspensionHeight) {
        space = space - widget.suspensionHeight;
      } else {
        space = 0;
      }
      if (_suspensionTop != space && widget.suspensionWidget != null) {
        setState(() {
          _suspensionTop = space;
        });
      }
      int a = _suspensionSectionList[i];
      int b = _suspensionSectionList[i + 1];
      if (offset >= a && offset < b) {
        return i;
      }
      if (offset >= _suspensionSectionList[_suSectionListLength - 1]) {
        return _suSectionListLength - 1;
      }
    }
    return -1;
  }

  void _init() {
    _suspensionSectionMap.clear();
    int offset = 0;
    String tag;
    if (widget.header != null) {
      _suspensionSectionMap[widget.header.tag] = 0;
      offset = _headerHeight;
    }
    widget.data?.forEach((v) {
      if (tag != v.getSuspensionTag()) {
        tag = v.getSuspensionTag();
        _suspensionSectionMap.putIfAbsent(tag, () => offset);
        offset = offset + widget.suspensionHeight + widget.itemHeight;
      } else {
        offset = offset + widget.itemHeight;
      }
    });
    _suspensionSectionList
      ..clear()
      ..addAll(_suspensionSectionMap.values);
    _suSectionListLength = _suspensionSectionList.length;
    if (widget.onSusSectionInited != null) {
      widget.onSusSectionInited(_suspensionSectionMap);
    }
  }

  @override
  Widget build(BuildContext context) {
    _init();
    var children = <Widget>[
      widget.contentWidget,
    ];
    if (widget.suspensionWidget != null) {
      children.add(Positioned(
        ///-0.1修复部分手机丢失精度问题
        top: _suspensionTop.toDouble() - 0.1,
        left: 0.0,
        right: 0.0,
        child: widget.suspensionWidget,
      ));
    }
    return Stack(children: children);
  }
}
