// Flutter imports:
import 'package:flutter/material.dart';

class ModalBottomSheetPictureSourceComponent {
  BuildContext context;
  Function? onTakePictureFromCameraButtonTap;
  Function? onTakePictureFromGaleryButtonTap;

  ModalBottomSheetPictureSourceComponent({
    required this.context,
    this.onTakePictureFromCameraButtonTap,
    this.onTakePictureFromGaleryButtonTap,
  });

  Future<dynamic> show() {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 130,
        padding: const EdgeInsets.all(15),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(15),
          ),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  Navigator.pop(context);
                  await onTakePictureFromCameraButtonTap?.call();
                },
                child: const Card(
                  color: Colors.white,
                  elevation: 2,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.camera_alt,
                          color: Colors.blue,
                        ),
                        SizedBox(height: 3),
                        Text(
                          "Camera",
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.2,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  onTakePictureFromGaleryButtonTap?.call();
                },
                child: const Card(
                  color: Colors.white,
                  elevation: 2,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.perm_media,
                          color: Colors.blue,
                        ),
                        SizedBox(height: 3),
                        Text(
                          "Gallery",
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.2,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
