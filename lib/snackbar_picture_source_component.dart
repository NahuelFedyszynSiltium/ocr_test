import 'package:flutter/material.dart';

class SnackBarPictureSourceComponent {
  static SnackBar build(context, onTakePictureFromCameraButtonTap,
      onTakePictureFromGaleryButtonTap) {
    return SnackBar(
      dismissDirection: DismissDirection.down,
      duration: const Duration(seconds: 5),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      content: Container(
        alignment: Alignment.center,
        height: 100,
        width: MediaQuery.of(context).size.width,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox.shrink(),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () async {
                    await onTakePictureFromCameraButtonTap();
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        "images/icon_photo.png",
                        color: Colors.black,
                        scale: 2.5,
                      ),
                      const SizedBox(width: 15),
                      const Text(
                        "Take a picture",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.normal,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    onTakePictureFromGaleryButtonTap();
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset(
                          "images/icon_picture.png",
                          color: Colors.black,
                          scale: 2.5,
                        ),
                        const SizedBox(width: 15),
                        const Text(
                          "Open gallery",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.normal,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
