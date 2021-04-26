import 'package:flutter/material.dart';
import 'package:my_flutter/page/clock_page.dart';
import 'package:my_flutter/page/floating_page.dart';
import 'package:my_flutter/page/home_page.dart';

///路由管理
class RouteHelper {
  ///主模块
  static const String homePage = 'home';

  ///悬浮按钮
  static const String floatPage = 'floating_btn';


  ///钟表
  static const String clockPage = 'clock';


  ///路由与页面绑定注册
  static Map<String, WidgetBuilder> routes = {
    homePage: (context) => HomePage(),
    floatPage: (context) => FloatingPage(),
    clockPage: (context) => ClockPage(),
  };
}
