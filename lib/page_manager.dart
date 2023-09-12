// Flutter imports:
import 'package:flutter/material.dart';

import 'package:permission_handler/permission_handler.dart'
    as permission_handler;

import 'page_args.dart';
import 'page_names.dart';

class PageManager {
  static final PageManager _instance = PageManager._constructor();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  PageNames? currentPage;

  factory PageManager() {
    return _instance;
  }

  PageNames? getPageNameEnum(String? pageName) {
    try {
      return PageNames.values.where((x) => x.toString() == pageName).single;
    } catch (e) {
      throw Exception(e);
    }
  }

  PageManager._constructor();

  PageRoute? getRoute(RouteSettings settings) {
    PageArgs? arguments;

    if (settings.arguments != null) {
      arguments = settings.arguments as PageArgs;
    }

    PageNames? page = getPageNameEnum(settings.name);

    currentPage = page;
    switch (page) {
      default:
        return throw Exception("No existe página con este PageName");
    }
  }

  PageRoute _changeAnimation({
    required Widget page,
    bool shouldChangeAnimation = true,
    Duration duration = const Duration(milliseconds: 200),
  }) {
    return shouldChangeAnimation
        ? PageRouteBuilder(
            transitionDuration: duration,
            transitionsBuilder: (BuildContext context,
                Animation<double> animation,
                Animation<double> secAnimation,
                Widget child) {
              animation = CurvedAnimation(
                  parent: animation, curve: Curves.fastLinearToSlowEaseIn);
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              );
            },
            pageBuilder: (BuildContext context, Animation<double> animation,
                Animation<double> secAnimation) {
              return page;
            },
          )
        : MaterialPageRoute(builder: (context) => page);
  }

  goBack({PageArgs? args, PageNames? specificPage}) {
    if (specificPage != null) {
      navigatorKey.currentState!
          .popAndPushNamed(specificPage.toString(), arguments: args);
    } else {
      Navigator.pop(navigatorKey.currentState!.overlay!.context, args);
    }
  }

  _goPage(String pageName,
      {PageArgs? args,
      Function(PageArgs? args)? actionBack,
      bool makeRootPage = false,
      int? tabIndex}) {
    if (!makeRootPage) {
      return navigatorKey.currentState
          ?.pushNamed(pageName, arguments: args)
          .then((value) {
        if (actionBack != null) actionBack(value as PageArgs?);
      });
    } else {
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        pageName,
        (route) => false,
        arguments: args,
      );
    }
  }
}
