import 'dart:io';
import 'dart:typed_data';

import 'package:analyzer_query/mini/log.dart';
import 'package:analyzer_query/tester.dart';
import 'package:image/image.dart';

class ImageSource {
  static final Map<String, ImageSource> _sourceMap = {};

  String imageName = '';

  File? imageX1;

  File? imageX2;

  File? imageX3;

  String tailFix = '';

  bool get allImage => imageX1 != null && imageX2 != null && imageX3 != null;

  String get fullImageName => '$imageName.$tailFix';

  ImageSource({
    required this.imageName,
    required this.tailFix,
    this.imageX1,
    this.imageX2,
    this.imageX3,
  });

  ///图片缩放
  void shrinkImage() {
    File? img = imageX3 ?? imageX2 ?? imageX1;
    if (allImage || img == null) {
      return;
    }
    String dir = img.parent.path + Platform.pathSeparator;

    ///重命名3倍图
    imageX3 = img.renameSync('$dir$imageName@3x.$tailFix');
    Uint8List data = imageX3!.readAsBytesSync();
    if (data.isEmpty) {
      analyzerLog('$fullImageName: Data is Empty');
      return;
    }
    Image? image3x = decodeImage(data);
    analyzerLog('Set x3 image from ${img.parent.path}');

    ///获取2倍图
    Image image2x = copyResize(image3x!,
        width: image3x.width ~/ 1.5, height: image3x.height ~/ 1.5);
    imageX2 = File('$dir$imageName@2x.$tailFix');
    imageX2!
        .writeAsBytesSync(encodeNamedImage(imageX2!.path, image2x)!.toList());
    analyzerLog('Get x2 image from $imageName');

    ///获取1倍图
    Image image1x = copyResize(image3x,
        width: image3x.width ~/ 3, height: image3x.height ~/ 3);
    imageX1 = File('$dir$imageName.$tailFix');
    imageX1!
        .writeAsBytesSync(encodeNamedImage(imageX1!.path, image1x)!.toList());
    analyzerLog('Get x1 image from $imageName');
  }

  ///图片转移
  void moveTo(String assetPath) {
    if (!isValid()) {
      return;
    }
    if (imageX1 != null) {
      _moveTo(imageX1!, assetPath);
    }
    if (imageX2 != null) {
      _moveTo(imageX2!, '$assetPath${Platform.pathSeparator}2.0x');
    }
    if (imageX3 != null) {
      _moveTo(imageX3!, '$assetPath${Platform.pathSeparator}3.0x');
    }
  }

  _moveTo(File f, String assetPath) {
    final String newPath = assetPath + Platform.pathSeparator + fullImageName;
    f.copySync(newPath).createSync();
    f.deleteSync();
  }

  void delete() {
    imageX1?.deleteSync();
    imageX2?.deleteSync();
    imageX3?.deleteSync();
  }

  ///检查命名合法性
  bool isValid() {
    try {
      DartFormatter formatter = DartFormatter(indent: 0);
      formatter.format("""const String $imageName = '$imageName.$tailFix'; """);
      return true;
    } catch (e) {
      analyzerLog('Image name is invalid: $imageName');
      return false;
    }
  }

  static bool isImage(String filePath) =>
      ['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(
        Uri.parse(filePath).pathSegments.last.split('.').last,
      ) &&
      !Uri.parse(filePath).pathSegments.last.startsWith('.');

  static ImageSource archive(File f) {
    String imageName = f.uri.imageName;
    String tailFix = f.uri.imageType;
    final fullImageName = '$imageName.$tailFix';
    final source = _sourceMap[fullImageName];
    if (source != null) {
      source.imageX1 = f.uri.isX1 ? f : source.imageX1;
      source.imageX2 = f.uri.isX2 ? f : source.imageX2;
      source.imageX3 = f.uri.isX3 ? f : source.imageX3;
    } else {
      _sourceMap[fullImageName] = ImageSource(
        imageName: imageName,
        tailFix: tailFix,
        imageX1: f.uri.isX1 ? f : null,
        imageX2: f.uri.isX2 ? f : null,
        imageX3: f.uri.isX3 ? f : null,
      );
    }
    return _sourceMap[fullImageName]!;
  }
}

extension on Uri {
  String get imageName => pathSegments.last.split('.').first.split('@').first;

  String get imageType => pathSegments.last.split('.').last;

  bool get isX1 => !isX2 && !isX3;

  bool get isX2 =>
      pathSegments.contains('2.0x') ||
      pathSegments.last.toLowerCase().contains('@2x');

  bool get isX3 =>
      pathSegments.contains('3.0x') ||
      pathSegments.last.toLowerCase().contains('@3x');
}
