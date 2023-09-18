import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_painter/image_painter.dart';
import 'package:ocr_test/image_resource_model.dart';
import 'package:ocr_test/image_upload_component.dart';
import 'package:ocr_test/loading_popup.dart';

class MlKitTestPage extends StatefulWidget {
  const MlKitTestPage({super.key});

  @override
  State<MlKitTestPage> createState() => _MlKitTestPageState();
}

class _MlKitTestPageState extends State<MlKitTestPage> {
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final _imageKey = GlobalKey<ImagePainterState>();

  String _processedText = "Texto capturado";

  File? _file;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ImageUploadComponent(
                editImageAfterPick: true,
                compressImage: false,
                saveFileCallback: (file) async {
                  await _imageUploadCallback(file);
                },
                child: (onTap) => GestureDetector(
                  onTap: () => onTap(),
                  child: Container(
                    height: 50,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                    ),
                    child: const Center(
                      child: Text("Get Image"),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  // child: _text(),
                  child: Visibility(
                    visible: _file != null,
                    child: ImagePainter.file(
                      _file ?? File(""),
                      key: _imageKey,
                      scalable: true,
                      height: MediaQuery.of(context).size.height * .7,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _text() {
    return Text(
      _processedText,
      textAlign: TextAlign.left,
    );
  }

  Future<void> _imageUploadCallback(File? file) async {
    await _imageUploadLoading(file);
  }

  Future<void> _imageUploadLoading(File? file) async {
    if (file != null) {
      await LoadingPopup(
        context: context,
        onLoading: _processImage(file),
        onError: (err) {
          _onProcessImageError(err);
        },
        onResult: (data) {
          _onProcessImageSuccess(data);
        },
      ).show();
    }
  }

  Future<RecognizedText> _processImage(File? file) async {
    if (file != null) {
      InputImage inputImage = InputImage.fromFile(file);
      _file = file;
      // ImagePainter.file(file, key: _imageKey);
      // Uint8List? byteArray = await _imageKey.currentState?.exportImage();
      // if (byteArray != null) {
      //   _file = File.fromRawPath(byteArray);
      // }
      return await textRecognizer.processImage(inputImage);
    } else {
      throw Exception("File is null");
    }
  }

  void _onProcessImageError(err) {
    showToast(
        context: context,
        message: "Ocurrió un error al intentar procesar la imágen");
  }

  void _onProcessImageSuccess(RecognizedText recognizedText) {
    setState(() {
      _processedText = recognizedText.text;
    });
  }
}

void showToast({
  required BuildContext context,
  required String message,
  Duration duration = const Duration(seconds: 2),
  EdgeInsets padding = const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
  Color? color,
  BorderRadius? borderRadius,
  double fontSize = 14,
}) {
  SnackBar snackBar = SnackBar(
    behavior: SnackBarBehavior.floating,
    elevation: 0,
    padding: const EdgeInsets.only(bottom: 40),
    duration: duration,
    backgroundColor: Colors.transparent,
    content: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: color ??
                  const Color.fromARGB(255, 126, 126, 126).withOpacity(0.7),
              borderRadius: borderRadius ?? BorderRadius.circular(25),
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: fontSize),
              maxLines: null,
            ),
          ),
        ),
      ],
    ),
  );
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
