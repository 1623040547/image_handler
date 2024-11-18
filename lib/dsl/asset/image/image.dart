import 'dart:typed_data';
import 'package:image/image.dart';
import 'package:resource_handler/dsl/asset/asset.dart';

part 'image.g.dart';

@JsonSerializable()
class ImageConfig extends AssetConfig {
  ImageConfig({
    required super.binding,
    required super.className,
    required super.metaClassName,
    required super.classDefinePath,
    required super.baseName,
    required super.permitMetaClass,
    required super.needMeta,
    required super.needOverwrite,
    required super.cleanUndefineAsset,
    required super.cleanNoCitedAssetDefine,
    required super.needBinding,
  });

  static ImageConfig fromJson(Map<String, dynamic> json) =>
      _$ImageConfigFromJson(json);

  @override
  String get baseNamePath =>
      binding.split('/').where((e) => e.isNotEmpty).join('/');

  @override
  List<String> get bindings =>
      [binding, '$baseNamePath/2.0x/', '$baseNamePath/3.0x/'];

  @override
  String get metaClassArrayName => "citeArray";

  @override
  String get metaClassPatternName => "patterns";

  @override
  String get metaClassSource => """
///部分图片没有直接使用字符串常量索引，通过注解提供两种间接表示图片名称的方式，
///- [$metaClassPatternName]用于表示图片一定包含的字符常量片段的数组，
///该字段一般用于含有索引的图片组，
///例如某一特征为['iconSunSign', '.png']，则其对应的正则表达式为['iconSunSign*.png']
///- [$metaClassArrayName]用于表示对一个定义于本文件的常量列表的引用
///该字段一般用于关联性较强的字符串类型的图片组，
///当声明[$metaClassArrayName]之后，会在图片自动化时寻找到相应的常量数组并提取其中的字符串常量
class $metaClassName {
  final List<List<String>> $metaClassPatternName;
  final List<String> $metaClassArrayName;

  const $metaClassName({
    this.$metaClassPatternName = const [],
    this.$metaClassArrayName = const [],
  });
}
""";
}

class ImageSource extends AssetSource {
  File? imageX1;

  File? imageX2;

  File? imageX3;

  bool get allImage => imageX1 != null && imageX2 != null && imageX3 != null;

  String get fullImageName => '$name.$tailFix';

  ImageSource({
    required super.name,
    required super.tailFix,
    this.imageX1,
    this.imageX2,
    this.imageX3,
  });

  @override
  void delete() {
    imageX1?.deleteSync();
    imageX2?.deleteSync();
    imageX3?.deleteSync();
  }

  @override
  void moveTo(String path) {
    shrinkImage();
    if (imageX1 != null) {
      _moveTo(imageX1!, path);
    }
    if (imageX2 != null) {
      _moveTo(imageX2!, '$path${Platform.pathSeparator}2.0x');
    }
    if (imageX3 != null) {
      _moveTo(imageX3!, '$path${Platform.pathSeparator}3.0x');
    }
  }

  @override
  bool sourceIsValid() {
    try {
      DartFormatter formatter = DartFormatter(indent: 0);
      formatter.format("""const String $name = '$name.$tailFix'; """);
      return true;
    } catch (e) {
      analyzerLog('Image name is invalid: $name');
      return false;
    }
  }

  ///图片缩放
  void shrinkImage() {
    File? img = imageX3 ?? imageX2 ?? imageX1;
    if (allImage || img == null) {
      return;
    }
    String dir = img.parent.path + Platform.pathSeparator;

    ///重命名3倍图
    imageX3 = img.renameSync('$dir$name@3x.$tailFix');
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
    imageX2 = File('$dir$name@2x.$tailFix');
    imageX2!
        .writeAsBytesSync(encodeNamedImage(imageX2!.path, image2x)!.toList());
    analyzerLog('Get x2 image from $name');

    ///获取1倍图
    Image image1x = copyResize(image3x,
        width: image3x.width ~/ 3, height: image3x.height ~/ 3);
    imageX1 = File('$dir$name.$tailFix');
    imageX1!
        .writeAsBytesSync(encodeNamedImage(imageX1!.path, image1x)!.toList());
    analyzerLog('Get x1 image from $name');
  }

  _moveTo(File f, String assetPath) {
    final String newPath = assetPath + Platform.pathSeparator + fullImageName;
    f.copySync(newPath).createSync();
    f.deleteSync();
  }
}

class ImageResource extends AssetResource {
  static final Map<String, ImageSource> _sourceMap = {};

  ImageResource(super.projPath, super.config);

  static ImageResource build(
      String sourceFolder, String projPath, String configName) {
    final config =
        json.decode(File('$configPath/$configName').readAsStringSync());
    return AssetResource.build(
      sourceFolder: sourceFolder,
      resource: ImageResource(
        projPath,
        ImageConfig.fromJson(config),
      ),
    );
  }

  @override
  AssetSource archive(File f) {
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
        name: imageName,
        tailFix: tailFix,
        imageX1: f.uri.isX1 ? f : null,
        imageX2: f.uri.isX2 ? f : null,
        imageX3: f.uri.isX3 ? f : null,
      );
    }
    return _sourceMap[fullImageName]!;
  }

  @override
  bool pathIsTarget(String path) {
    final name = Uri.parse(path).pathSegments.last;
    final isImage = ['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(
      name.split('.').last,
    );
    final isHidden = name.startsWith('.');
    return isImage && !isHidden;
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
