import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

///选择木马布局
class CarouselLayout extends StatefulWidget {
  CarouselLayout({
    Key key,
    this.children,
    this.childWidth = 60,
    this.childHeight = 60,
    this.deviationRatio = 0.2,
    this.minScale = 0.8,
    this.isAuto = false,
    this.autoSweepAngle = 0.2,
  }) : super(key: key);

  //所有的子控件
  final List<Widget> children;

  //每个子控件的宽
  final double childWidth;

  //每个子控件的高
  final double childHeight;

  //偏移X系数  0-1
  final double deviationRatio;

  //最小缩放比 子控件的滑动时最小比例
  final double minScale;

  //是否自动
  final bool isAuto;

  //自动(每时间间隔)旋转角度
  final double autoSweepAngle;

  @override
  State<StatefulWidget> createState() => CarouselState();
}

class CarouselState extends State<CarouselLayout>
    with TickerProviderStateMixin {
  List<Point> currentList = [];

  //滑动系数
  final slipRatio = 0.5;

  //开始角度
  double startAngle = 270;

  //旋转角度
  double rotateAngle = 0.0;

  //按下时X坐标
  double downX = 0.0;

  //按下时的角度
  double downAngle = 0.0;

  Size size;

  //半径
  double radius = 0.0;

  Timer _rotateTimer;

  AnimationController _controller;

  AnimationController moveController;

  Animation<double> animation;

  double velocityX;

  @override
  void didUpdateWidget(covariant CarouselLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    _startRotateTimer();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (mounted)
        setState(() {
          _startRotateTimer();
        });
    });

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    animation = new Tween<double>(begin: 1, end: 0).animate(animation)
      ..addListener(() {
        //当前速度
        var velocity = animation.value * -velocityX;
        var offsetX = velocity * 5 / (2 * pi * radius);
        rotateAngle += offsetX;
        setState(() => {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _startRotateTimer();
        }
      });
  }

  @override
  void dispose() {
    super.dispose();
    _cancelRotateTimer();
    _controller?.dispose();
  }

  ///开始自动旋转计时器
  _startRotateTimer() {
    _cancelRotateTimer();
    if (!this.widget.isAuto) {
      return;
    }
    if (_rotateTimer == null) {
      _rotateTimer = new Timer.periodic(new Duration(milliseconds: 5), (timer) {
        rotateAngle += this.widget.autoSweepAngle;
        rotateAngle %= 360; // 取个模 防止sweepAngle爆表
        setState(() {});
      });
    }
  }

  ///取消自动旋转计时器
  _cancelRotateTimer() {
    _rotateTimer?.cancel();
    _rotateTimer = null;
  }

  ///子控件集
  _childList({Size size = Size.zero}) {
    //所有的子布局
    List<Widget> childList = [];
    //清空之前的数据
    currentList?.clear();
    if (this.widget.children?.isNotEmpty ?? false) {
      //子控件数量
      int count = this.widget.children.length;
      //平均角度
      double averageAngle = 360 / count;
      //半径
      radius = size.width / 2 - this.widget.childWidth / 2;
      for (int i = 0; i < count; i++) {
        double angle = (startAngle - averageAngle * i + rotateAngle) * pi / 180;
        var sinValue = sin(angle);
        var cosValue = cos(angle);
        var coordinateX = size.width / 2 - radius * cosValue;
        var coordinateY = size.height / 2 -
            radius * sinValue * sin(pi / (1 + this.widget.deviationRatio));
        var minScale = min(this.widget.minScale, 0.99);
        var scale = ((1 - minScale) / 2 * (1 - sin(angle)) + minScale);
        var child = Positioned(
          width: this.widget.childWidth * scale,
          height: this.widget.childHeight * scale,
          left: coordinateX - this.widget.childWidth * scale / 2,
          top: coordinateY - this.widget.childHeight * scale / 2,
          child: GestureDetector(
            child: this.widget.children[i],
            onTap: () {},
          ),
        );
        currentList.add(Point(
          i,
          coordinateX,
          coordinateY,
          coordinateX - this.widget.childWidth * scale / 2,
          coordinateY - this.widget.childHeight * scale / 2,
          coordinateX + this.widget.childWidth * scale / 2,
          coordinateY + this.widget.childHeight * scale / 2,
          scale,
          child,
          angle,
        ));
      }
      currentList.sort((a, b) {
        return a.scale.compareTo(b.scale);
      });
      currentList.forEach((item) {
        childList.add(item.child);
      });
    }
    return childList;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (
      BuildContext context,
      BoxConstraints constraints,
    ) {
      size = constraints.biggest;
      return GestureDetector(
        ///滑动按下
        onHorizontalDragDown: (DragDownDetails details) {
          _cancelRotateTimer(); //取消自动移动
          _controller?.stop();
        },

        ///滑动开始
        onHorizontalDragStart: (DragStartDetails details) {
          downAngle = rotateAngle;
          downX = details.globalPosition.dx;
        },

        ///滑动中
        onHorizontalDragUpdate: (DragUpdateDetails details) {
          var updateX = details.globalPosition.dx;
          rotateAngle = xToAngle(downX - updateX) + downAngle;
          if (mounted) setState(() {});
        },

        ///滑动结束
        onHorizontalDragEnd: (DragEndDetails details) {
          //每秒像素x数
          velocityX = details.velocity.pixelsPerSecond.dx;
          _controller.reset();
          _controller.forward();
        },

        ///滑动取消
        onHorizontalDragCancel: () {
          _startRotateTimer();
        },
        behavior:HitTestBehavior.opaque,
        child: CustomPaint(
          size: constraints.biggest,
          child: Stack(
            children: _childList(size: constraints.biggest),
          ),
        ),
      );
    });
  }

  double xToAngle(double offsetX) {
    return offsetX * slipRatio;
  }
}


class Point {
  Point(
    this.index,
    this.x,
    this.y,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.scale,
    this.child,
    this.angle,
  );

  double x;
  double y;
  double left;
  double top;
  double right;
  double bottom;
  double scale;
  int index;
  Widget child;
  double angle;

  @override
  String toString() {
    StringBuffer valueBuffer = new StringBuffer();
    valueBuffer
      ..write("x=$x ")
      ..write("y=$y ")
      ..write("left=$left ")
      ..write("top=$top ")
      ..write("right=$right ")
      ..write("bottom=$bottom ")
      ..write("scale=$scale ")
      ..write("index=$index ")
      ..write("angle=$angle ");
    return valueBuffer.toString();
  }
}
class LoopViewWidget extends AnimatedWidget{
  @override
  Widget build(BuildContext context) {
    throw UnimplementedError();
  }


}