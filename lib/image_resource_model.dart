import 'dart:io';

class ImageResourceModel {
  int? imageId;
  String? fileName;
  String? extension;
  String? base64;
  String? imageUrl;
  File? file;

  //USO INTERNO
  int position = 0;

  ImageResourceModel({
    this.imageId,
    this.fileName,
    this.extension,
    this.base64,
    this.imageUrl,
    this.file,
    this.position = 0,
  });
}
