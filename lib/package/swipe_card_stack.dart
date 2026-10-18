import 'dart:math' as Math;
import 'package:flutter/widgets.dart';

enum SwiperPosition { None, Left, Right, Up, Down }

enum StackFrom { None, Top, Left, Right, Bottom }

class SwiperItem {
  Widget Function(SwiperPosition, double progress) builder;

  SwiperItem({required this.builder});
}

class SwipeCardStack extends StatefulWidget {
  final List<SwiperItem> children;
  final int maxAngle;
  final int threshold;
  final StackFrom stackFrom;
  final int visibleCount;
  final int translationInterval;
  final double scaleInterval;
  final Duration animationDuration;
  final int historyCount;
  final void Function(int, SwiperPosition) onSwipe;
  final void Function(int, SwiperPosition) onRewind;
  final void Function() onEnd;
  final void Function(double progress, SwiperPosition position)? onDragProgress;
  final EdgeInsetsGeometry padding;

  SwipeCardStack(
      {Key? key,
      required this.children,
      this.maxAngle = 35,
      this.threshold = 30,
      this.stackFrom = StackFrom.None,
      this.visibleCount = 2,
      this.translationInterval = 0,
      this.scaleInterval = 0,
      this.animationDuration = const Duration(milliseconds: 200),
      this.historyCount = 1,
      required this.onEnd,
      required this.onSwipe,
      required this.onRewind,
      this.onDragProgress,
      this.padding = const EdgeInsets.symmetric(vertical: 20, horizontal: 25)})
      : assert(maxAngle >= 0 && maxAngle <= 360),
        assert(threshold >= 1 && threshold <= 100),
        assert(visibleCount >= 2),
        assert(translationInterval >= 0),
        assert(scaleInterval >= 0),
        assert(historyCount >= 0),
        super(key: key);

  SwipeCardStackState createState() => SwipeCardStackState();
}

class SwipeCardStackState extends State<SwipeCardStack>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  Animation<double>? _animationX;
  Animation<double>? _animationY;
  Animation<double>? _animationAngle;

  double _left = 0;
  double _top = 0;
  double _angle = 0;
  double _maxAngle = 0;
  double _progress = 0;
  double _centerSlow = 1;
  SwiperPosition _currentItemPosition = SwiperPosition.None;
  final List<Map<String, dynamic>> _history = [];
  late List<SwiperItem> _deck;

  final Map<StackFrom, Alignment> _alignment = {
    StackFrom.Left: Alignment.centerLeft,
    StackFrom.Top: Alignment.topCenter,
    StackFrom.Right: Alignment.centerRight,
    StackFrom.Bottom: Alignment.bottomCenter,
    StackFrom.None: Alignment.center
  };

  bool _isTop = false;
  bool _isLeft = false;

  int _animationType = 0;

  BoxConstraints? _baseContainerConstraints;

  int get currentIndex => _deck.length - 1;

  @override
  void initState() {
    _deck = List<SwiperItem>.from(widget.children);
    if (widget.maxAngle > 0) _maxAngle = widget.maxAngle * (Math.pi / 180);

    _animationController =
        AnimationController(duration: widget.animationDuration, vsync: this);

    _animationController.addListener(() {
      if (_animationController.status == AnimationStatus.forward) {
        if (_animationX != null) _left = _animationX!.value;
        if (_animationY != null) _top = _animationY!.value;
        if (_animationType != 1 && _animationAngle != null) {
          _angle = _animationAngle!.value;
        }
        _updateProgressFromDrag();
        setState(() {});
      }
    });

    _animationController.addStatusListener((AnimationStatus animationStatus) {
      if (animationStatus == AnimationStatus.completed) {
        if (_animationType != 3 && _animationType != 0) {
          if (widget.historyCount > 0 && _deck.isNotEmpty) {
            _history.add({
              "item": _deck[_deck.length - 1],
              "position": _currentItemPosition,
              "left": _left,
              "top": _top,
              "angle": _angle
            });
            if (_history.length > widget.historyCount) _history.removeAt(0);
          }
        } else if (_animationType == 3) {
          widget.onRewind(
              _deck.length - 1, _history[_history.length - 1]["position"]);
          _history.removeAt(_history.length - 1);
        }

        if (_animationType != 0 && _animationType != 3) {
          if (_deck.isNotEmpty) {
            _deck.removeAt(_deck.length - 1);
          }
          widget.onSwipe(_deck.length, _currentItemPosition);
          if (_deck.isEmpty) widget.onEnd();
        }

        _left = 0;
        _top = 0;
        _angle = 0;
        _progress = 0;
        _currentItemPosition = SwiperPosition.None;
        _animationType = 0;
        setState(() {});
        _animationController.reset();
      }
    });
    super.initState();
  }

  @override
  void didUpdateWidget(SwipeCardStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncDeckFromWidget();
  }

  void _syncDeckFromWidget() {
    if (widget.children.length > _deck.length) {
      _deck.addAll(widget.children.sublist(_deck.length));
    } else if (widget.children.length < _deck.length) {
      _deck = List<SwiperItem>.from(widget.children);
    }
  }

  void _updateProgressFromDrag() {
    if (_baseContainerConstraints == null) return;
    final maxDim = Math.max(
      _baseContainerConstraints!.maxWidth,
      _baseContainerConstraints!.maxHeight,
    );
    if (_top.abs() > _left.abs() * 2) {
      _progress = (100 / maxDim) * _top.abs();
      _currentItemPosition = (_top.toInt() == 0)
          ? SwiperPosition.None
          : (_top < 0)
              ? SwiperPosition.Up
              : SwiperPosition.Down;
    } else {
      _progress = (100 / maxDim) * _left.abs();
      _currentItemPosition = (_left.toInt() == 0)
          ? SwiperPosition.None
          : (_left < 0)
              ? SwiperPosition.Left
              : SwiperPosition.Right;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      _baseContainerConstraints = constraints;
      if (_deck.isEmpty) return Container();

      return Container(
        padding: widget.padding,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return Stack(
              fit: StackFit.expand,
              children: _deck
                  .asMap()
                  .map((int index, _) {
                    return MapEntry(index, _item(constraints, index));
                  })
                  .values
                  .toList(),
            );
          },
        ),
      );
    });
  }

  Widget _item(BoxConstraints constraints, int index) {
    if (index != _deck.length - 1) {
      double scaleReduced =
          (widget.scaleInterval * (_deck.length - index));
      scaleReduced -= ((widget.scaleInterval * 2) / 100) * _progress;
      final double scale = 1 - scaleReduced;

      double positionReduced =
          ((widget.translationInterval * (_deck.length - index - 1)))
              .toDouble();
      positionReduced -= (widget.translationInterval / 100) * _progress;
      final double position = positionReduced * -1;

      return Visibility(
        visible: (_deck.length - index) <= widget.visibleCount,
        child: Positioned(
            top: widget.stackFrom == StackFrom.Top ? position : null,
            left: widget.stackFrom == StackFrom.Left ? position : null,
            right: widget.stackFrom == StackFrom.Right ? position : null,
            bottom: widget.stackFrom == StackFrom.Bottom ? position : null,
            child: Transform.scale(
                scale: scale,
                alignment: _alignment[widget.stackFrom],
                child: Container(
                    constraints: constraints,
                    child: _deck[index].builder(SwiperPosition.None, 0)))),
      );
    }

    if (widget.maxAngle > 0 &&
        _animationController.status != AnimationStatus.forward) {
      _angle = ((_maxAngle / 100) * _progress) * _centerSlow;
      _angle = _angle *
          ((_isTop && _isLeft)
              ? 1
              : (!_isTop && !_isLeft)
                  ? 1
                  : -1);
    }

    return Positioned(
      left: _left,
      top: _top,
      child: GestureDetector(
          child: Transform.rotate(
            angle: _angle,
            child: Container(
                constraints: constraints,
                child: _deck[index].builder(_currentItemPosition, _progress)),
          ),
          onPanStart: (DragStartDetails dragStartDetails) {
            RenderBox getBox = context.findRenderObject() as RenderBox;
            var local = getBox.globalToLocal(dragStartDetails.globalPosition);

            _isLeft = local.dx < getBox.size.width / 2;
            _isTop = local.dy < getBox.size.height / 2;

            double halfHeight = getBox.size.height / 2;
            _centerSlow = ((halfHeight - local.dy) * (1 / halfHeight)).abs();
          },
          onPanUpdate: (DragUpdateDetails dragUpdateDetails) {
            _left += dragUpdateDetails.delta.dx;
            _top += dragUpdateDetails.delta.dy;
            _updateProgressFromDrag();
            widget.onDragProgress?.call(_progress, _currentItemPosition);
            setState(() {});
          },
          onPanEnd: _onPandEnd),
    );
  }

  void _onPandEnd(_) {
    setState(() {});
    if (_progress < widget.threshold) {
      _goFirstPosition();
    } else {
      _animationType = 1;
      if (_left.abs() * 2 > _top.abs() && _baseContainerConstraints != null) {
        _animationX = Tween<double>(
                begin: _left,
                end: _baseContainerConstraints!.maxWidth * (_left < 0 ? -1 : 1))
            .animate(_animationController);
        _animationY = Tween<double>(begin: _top, end: _top + _top)
            .animate(_animationController);
      } else {
        if (_baseContainerConstraints != null) {
          _animationX = Tween<double>(begin: _left, end: _left + _left)
              .animate(_animationController);
          _animationY = Tween<double>(
                  begin: _top,
                  end: _baseContainerConstraints!.maxHeight *
                      (_top < 0 ? -1 : 1))
              .animate(_animationController);
        }
      }
      _animationController.forward();
    }
  }

  void _goFirstPosition() {
    _animationX =
        Tween<double>(begin: _left, end: 0.0).animate(_animationController);
    _animationY =
        Tween<double>(begin: _top, end: 0.0).animate(_animationController);
    if (widget.maxAngle > 0) {
      _animationAngle =
          Tween<double>(begin: _angle, end: 0.0).animate(_animationController);
    }
    _animationController.forward();
  }

  void swipeLeft() {
    if (_deck.isNotEmpty &&
        _animationController.status != AnimationStatus.forward &&
        _baseContainerConstraints != null) {
      _animationType = 2;
      _animationX =
          Tween<double>(begin: 0, end: _baseContainerConstraints!.maxWidth * -1)
              .animate(_animationController);
      _animationY = Tween<double>(
              begin: 0, end: (_baseContainerConstraints!.maxHeight / 2) * -1)
          .animate(_animationController);
      if (widget.maxAngle > 0) {
        _animationAngle = Tween<double>(begin: 0, end: _maxAngle * 0.7)
            .animate(_animationController);
      }
      _animationController.forward();
    }
  }

  void swipeRight() {
    if (_deck.isNotEmpty &&
        _animationController.status != AnimationStatus.forward &&
        _baseContainerConstraints != null) {
      _animationType = 2;
      _animationX =
          Tween<double>(begin: 0, end: _baseContainerConstraints!.maxWidth)
              .animate(_animationController);
      _animationY = Tween<double>(
              begin: 0, end: (_baseContainerConstraints!.maxHeight / 2) * -1)
          .animate(_animationController);
      if (widget.maxAngle > 0) {
        _animationAngle = Tween<double>(begin: 0, end: (_maxAngle * 0.7) * -1)
            .animate(_animationController);
      }
      _animationController.forward();
    }
  }

  void swipeUp() {
    if (_deck.isNotEmpty &&
        _animationController.status != AnimationStatus.forward &&
        _baseContainerConstraints != null) {
      _animationType = 2;
      _animationX =
          Tween<double>(begin: 0, end: 30).animate(_animationController);
      _animationY = Tween<double>(
              begin: 0, end: _baseContainerConstraints!.maxHeight * -1)
          .animate(_animationController);
      if (widget.maxAngle > 0) {
        _animationAngle = Tween<double>(begin: 0, end: (_maxAngle * 0.2) * -1)
            .animate(_animationController);
      }
      _animationController.forward();
    }
  }

  void swipeDown() {
    if (_deck.isNotEmpty &&
        _animationController.status != AnimationStatus.forward &&
        _baseContainerConstraints != null) {
      _animationType = 2;
      _animationX =
          Tween<double>(begin: 0, end: 30).animate(_animationController);
      _animationY =
          Tween<double>(begin: 0, end: _baseContainerConstraints!.maxHeight)
              .animate(_animationController);
      if (widget.maxAngle > 0) {
        _animationAngle = Tween<double>(begin: 0, end: (_maxAngle * 0.2) * -1)
            .animate(_animationController);
      }
      _animationController.forward();
    }
  }

  void rewind() {
    if (_history.isNotEmpty &&
        _animationController.status != AnimationStatus.forward) {
      _animationType = 3;
      final lastHistory = _history[_history.length - 1];
      _deck.add(lastHistory["item"]);
      _animationX = Tween<double>(begin: lastHistory["left"], end: 0)
          .animate(_animationController);
      _animationY = Tween<double>(begin: lastHistory["top"], end: 0)
          .animate(_animationController);
      if (widget.maxAngle > 0) {
        _animationAngle = Tween<double>(begin: lastHistory["angle"], end: 0)
            .animate(_animationController);
      }
      _animationController.forward();
    }
  }

  void clearHistory() => _history.clear();

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
