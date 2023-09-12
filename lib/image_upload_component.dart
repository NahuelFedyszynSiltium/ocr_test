// Dart imports:
// ignore_for_file: use_build_context_synchronously

import 'dart:developer';
import 'dart:io';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:camera/camera.dart';
import 'package:collection/collection.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_cropper/image_cropper.dart';

// Project imports:
import 'loading_popup.dart';
import 'modal_bottom_sheet_picture_source_component.dart';

import 'package:permission_handler/permission_handler.dart'
    as permission_handler;

import 'page_manager.dart';
import 'permission_status_enum.dart';

class ImageUploadComponent extends StatefulWidget {
  final Widget Function(Function) child;
  final Future Function(File?)? saveFileCallback;
  final bool isEditable;
  final double height;
  final double width;
  final double cropRatio;
  final bool lockAspectRatio;
  final bool editImageAfterPick;
  final CustomCropperOptions? customCropperOptions;
  final bool enableGallery;
  final bool enableCamera;
  final bool compressImage;
  final int compressingHeight;
  final int compressingWidth;

  const ImageUploadComponent({
    Key? key,
    required this.child,
    required this.saveFileCallback,
    this.height = 110,
    this.width = 350,
    this.cropRatio = 1,
    this.lockAspectRatio = false,
    this.isEditable = true,
    this.editImageAfterPick = true,
    this.customCropperOptions,
    this.enableCamera = true,
    this.enableGallery = true,
    this.compressImage = true,
    this.compressingHeight = 480,
    this.compressingWidth = 640,
  }) : super(key: key);

  @override
  ImageUploadComponentState createState() => ImageUploadComponentState();
}

class ImageUploadComponentState extends State<ImageUploadComponent> {
  @override
  Widget build(BuildContext context) {
    return widget.child(onTap);
  }

  bool activeSnackBar = false;

  onTap() {
    if (!widget.enableCamera && !widget.enableGallery) {
      throw Exception("Error. Camera and Gallery cannot be both false");
    } else if (widget.enableCamera && !widget.enableGallery) {
      getImageFromCamera();
    } else if (!widget.enableCamera && widget.enableGallery) {
      getImageFromGallery();
    } else {
      ModalBottomSheetPictureSourceComponent(
              context: context,
              onTakePictureFromCameraButtonTap: getImageFromCamera,
              onTakePictureFromGaleryButtonTap: getImageFromGallery)
          .show();
    }
  }

  Future getImageFromGallery() async {
    PermissionStatusEnum? permission = await checkStoragePermissionsGalery();
    switch (permission) {
      case PermissionStatusEnum.granted:
        try {
          await LoadingPopup(
            context: context,
            onLoading: getImageFromGalleryLoading(),
            onResult: (file) async {
              if (file != null) {
                saveFilePicked(file.path);
              }
            },
            onError: (error) => {},
          ).show();
        } catch (ex) {
          debugPrint(ex.toString());
        }
        break;
      case PermissionStatusEnum.permanentlyDenied:
        log("permanentlyDenied");
        break;
      case PermissionStatusEnum.denied:
      default:
    }
  }

  Future<File?> getImageFromGalleryLoading() async {
    File? file;
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.image, allowCompression: false);
    if (result != null) {
      file = File(result.files.single.path!);
    } else {
      debugPrint("Image selection cancelled");
      file = null;
    }

    if (file != null) {
      if (widget.editImageAfterPick) {
        File? temp = await cropImage(file.path);
        if (temp != null) {
          file = temp;
        }
      }
    }
    return file;
  }

  Future<PermissionStatusEnum?> checkStoragePermissionsGalery() async {
    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    if (Platform.isIOS) {
      Map<permission_handler.Permission, permission_handler.PermissionStatus>
          statuses = await [
        permission_handler.Permission.photos,
      ].request();
      return PermissionStatusEnum.values.firstWhereOrNull((element) =>
          element.name == statuses[permission_handler.Permission.photos]!.name);
    } else {
      if (deviceInfo.version.sdkInt >= 33) {
        Map<permission_handler.Permission, permission_handler.PermissionStatus>
            statuses = await [
          permission_handler.Permission.photos,
        ].request();
        return PermissionStatusEnum.values.firstWhereOrNull((element) =>
            element.name ==
            statuses[permission_handler.Permission.photos]!.name);
      } else {
        Map<permission_handler.Permission, permission_handler.PermissionStatus>
            statuses = await [
          permission_handler.Permission.storage,
        ].request();
        return PermissionStatusEnum.values.firstWhereOrNull((element) =>
            element.name ==
            statuses[permission_handler.Permission.storage]!.name);
      }
    }
  }

  getImageFromCamera() async {
    PermissionStatusEnum? permission = await checkCameraPermissions();
    switch (permission) {
      case PermissionStatusEnum.granted:
        await LoadingPopup(
          context: context,
          onLoading: getCameras(),
          onResult: (data) => openViewer(data),
          onError: (error) => {},
        ).show();
        break;
      case PermissionStatusEnum.permanentlyDenied:
        log("permanentlyDenied");
        break;
      case PermissionStatusEnum.denied:
      default:
    }
  }

  Future<PermissionStatusEnum?> checkCameraPermissions() async {
    Map<permission_handler.Permission, permission_handler.PermissionStatus>
        statuses = await [
      permission_handler.Permission.camera,
    ].request();

    return PermissionStatusEnum.values.firstWhereOrNull((element) =>
        element.name == statuses[permission_handler.Permission.camera]!.name);
  }

  getCameras() async {
    WidgetsFlutterBinding.ensureInitialized();
    final cameras = await availableCameras();
    return cameras;
  }

  openViewer(List<CameraDescription> cameras) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TakePictureScreen(cameras, (image) async {
          saveFilePicked(await previewImage(image));
        }),
      ),
    );
  }

  Future<String> previewImage(String imagePath) async {
    if (widget.editImageAfterPick) {
      File? temp = await cropImage(imagePath);
      if (temp != null) {
        imagePath = temp.path;
      }
    }
    return imagePath;
  }

  Future<Uint8List> compressImage(Uint8List list) async {
    var result = await FlutterImageCompress.compressWithList(
      list,
      minHeight: widget.compressingHeight,
      minWidth: widget.compressingWidth,
      quality: 20,
    );
    return result;
  }

  Future saveFilePicked(String path) async {
    File? file = File(path);
    if (widget.compressImage) {
      var outImage = await compressImage(file.readAsBytesSync());
      file.writeAsBytesSync(outImage);
    }

    await widget.saveFileCallback?.call(file);
  }

  Future<File?> cropImage(String? path) async {
    CustomCropperOptions customOptions =
        widget.customCropperOptions ?? CustomCropperOptions();
    customOptions.aspectRatio =
        CropAspectRatio(ratioX: widget.cropRatio, ratioY: 1);

    customOptions.uiSettings ??= [
      AndroidUiSettings(
        statusBarColor: Colors.blue,
        toolbarTitle: "",
        toolbarColor: Colors.blue,
        lockAspectRatio: widget.lockAspectRatio,
        toolbarWidgetColor: Colors.white,
        initAspectRatio: CropAspectRatioPreset.ratio16x9,
      ),
      IOSUiSettings(
        title: "",
      ),
    ];
    if (path != null) {
      try {
        CroppedFile? temp = await ImageCropper().cropImage(
          sourcePath: path,
          aspectRatio: customOptions.aspectRatio,
          compressFormat: customOptions.compressFormat,
          compressQuality: customOptions.compressQuality,
          cropStyle: customOptions.cropStyle,
          uiSettings: customOptions.uiSettings,
          maxHeight: customOptions.maxHeight,
          maxWidth: customOptions.maxWidth,
        );
        if (temp != null) {
          return File(temp.path);
        } else {
          throw Exception("Error al intentar recortar la imagen");
        }
      } catch (err) {
        throw Exception(err);
      }
    } else {
      throw Exception("Error al intentar recortar la imagen");
    }
  }
}

class TakePictureScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  final Future<void> Function(String)? onResult;
  const TakePictureScreen(this.cameras, this.onResult, {Key? key})
      : super(key: key);

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  CameraController? _controller;
  late Future<void> _initializeControllerFuture;
  CameraDescription? cameraDescription;

  @override
  void initState() {
    super.initState();
    _initCamera(widget.cameras.first);
  }

  void _initCamera(CameraDescription description) {
    _controller = CameraController(
      description,
      ResolutionPreset.max,
      enableAudio: false,
    );
    //TODO: SIEMPRE VERTICAL, SE PODRIA AGREGAR MAS OPCIONES EN UN FUTURO
    if (_controller != null) {
      try {
        _initializeControllerFuture = _controller!.initialize();
        // to notify the widgets that camera has been initialized and now camera preview can be done
        setState(() {});
      } catch (e) {
        Navigator.pop(context);
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeControllerFuture;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  takePicture() async {
    if (_controller != null) {
      return await _controller!.takePicture();
    }
  }

  FlashMode flashMode = FlashMode.off;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (_controller != null &&
              snapshot.connectionState == ConnectionState.done) {
            _controller!.lockCaptureOrientation(DeviceOrientation.portraitUp);
            flashMode == FlashMode.off
                ? _controller!.setFlashMode(FlashMode.off)
                : _controller!.setFlashMode(FlashMode.always);
            return Center(
              child: Column(
                children: [
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          color: Colors.black,
                        ),
                        CameraPreview(_controller!),
                        Positioned(
                          bottom: MediaQuery.of(context).size.height / 8,
                          child: Row(
                            children: [
                              FloatingActionButton(
                                  heroTag: "button flash",
                                  backgroundColor: Colors.transparent,
                                  elevation: 0,
                                  onPressed: () {
                                    setState(() {
                                      if (flashMode == FlashMode.off) {
                                        _controller!
                                            .setFlashMode(FlashMode.always);
                                        flashMode = FlashMode.always;
                                      } else {
                                        _controller!
                                            .setFlashMode(FlashMode.off);
                                        flashMode = FlashMode.off;
                                      }
                                    });
                                  },
                                  child: flashMode == FlashMode.off
                                      ? const Icon(Icons.flash_off)
                                      : const Icon(Icons.flash_on)),
                              const SizedBox(width: 20),
                              FloatingActionButton(
                                backgroundColor: Colors.blue,
                                heroTag: "button camera",
                                onPressed: () async {
                                  await LoadingPopup(
                                      context: context,
                                      onLoading: takePicture(),
                                      onResult: (image) async {
                                        if (widget.onResult != null) {
                                          await widget.onResult!(image.path);
                                        }
                                        if (context.mounted) {
                                          Navigator.pop(context, image.path);
                                        }
                                      },
                                      onError: (error) =>
                                          {Navigator.pop(context)}).show();
                                },
                                child: const Icon(Icons.camera_alt),
                              ),
                              const SizedBox(width: 20),
                              Visibility(
                                visible: widget.cameras.length > 1,
                                child: FloatingActionButton(
                                    heroTag: "button change camera",
                                    backgroundColor: Colors.transparent,
                                    elevation: 0,
                                    onPressed: () async {
                                      setState(() {
                                        // get current lens direction (front / rear)
                                        final lensDirection = _controller!
                                            .description.lensDirection;
                                        CameraDescription newDescription;
                                        if (lensDirection ==
                                            CameraLensDirection.front) {
                                          newDescription = widget.cameras
                                              .firstWhere((description) =>
                                                  description.lensDirection ==
                                                  CameraLensDirection.back);
                                        } else {
                                          newDescription = widget.cameras
                                              .firstWhere((description) =>
                                                  description.lensDirection ==
                                                  CameraLensDirection.front);
                                        }
                                        _initCamera(newDescription);
                                      });
                                    },
                                    child: Platform.isIOS
                                        ? const Icon(Icons.flip_camera_ios)
                                        : const Icon(
                                            Icons.flip_camera_android)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

class CustomCropperOptions {
  CropAspectRatio aspectRatio = const CropAspectRatio(ratioX: 1, ratioY: 1);
  ImageCompressFormat compressFormat = ImageCompressFormat.jpg;
  int compressQuality = 90;
  CropStyle cropStyle = CropStyle.rectangle;
  int? maxHeight;
  int? maxWidth;
  List<PlatformUiSettings>? uiSettings = [
    AndroidUiSettings(
      statusBarColor: Colors.blue,
      toolbarTitle: "",
      toolbarColor: Colors.blue,
      lockAspectRatio: true,
      toolbarWidgetColor: Colors.white,
    ),
    IOSUiSettings(
      title: "",
    ),
  ];

  CustomCropperOptions({
    this.aspectRatio = const CropAspectRatio(ratioX: 1, ratioY: 1),
    this.compressFormat = ImageCompressFormat.jpg,
    this.compressQuality = 90,
    this.cropStyle = CropStyle.rectangle,
    this.maxHeight,
    this.maxWidth,
    this.uiSettings,
  });
}
