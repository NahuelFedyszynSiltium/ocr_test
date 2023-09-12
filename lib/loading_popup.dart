import 'package:flutter/material.dart';
import 'futuristic.dart';

class LoadingPopup {
  final BuildContext context;
  final Color backgroundColor;
  final Future onLoading;
  Function? onResult;
  Function? onError;

  LoadingPopup({
    required this.context,
    required this.onLoading,
    this.onResult,
    this.onError,
    this.backgroundColor = const Color(0x80707070),
  });

  final double radius = 20;

  Future show() {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return _dialog();
        });
  }

  _dialog() {
    return Futuristic(
      autoStart: true,
      futureBuilder: () => onLoading,
      busyBuilder: (context) => body(),
      onData: (data) {
        Navigator.pop(context);
        onResult!(data);
      },
      onError: (error, retry) {
        Navigator.pop(context);
        onError!(error);
      },
    );
  }

  body() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.5),
            Colors.black.withOpacity(0.5)
          ],
        ),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
