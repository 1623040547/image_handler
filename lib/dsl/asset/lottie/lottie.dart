import 'package:resource_handler/dsl/asset/asset.dart';

part 'lottie.g.dart';

@JsonSerializable()
class LottieConfig extends AssetConfig {
  LottieConfig({
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

  static LottieConfig fromJson(Map<String, dynamic> json) =>
      _$LottieConfigFromJson(json);

  @override
  String get baseNamePath =>
      binding.split('/').where((e) => e.isNotEmpty).join('/');

  @override
  String get metaClassArrayName => "";

  @override
  String get metaClassPatternName => "";

  @override
  String get metaClassSource => "";
}

class LottieSource extends AssetSource {
  final File dataJson;

  late final Directory lottieFolder;

  Directory? imageFolder;

  final List<File> images = [];

  String get folderName => lottieFolder.uri.folderName;

  @override
  String get fullName => '$folderName/data.json';

  LottieSource({
    required super.name,
    required super.tailFix,
    required this.dataJson,
  }) {
    lottieFolder = dataJson.parent;
    name = folderName;
    tailFix = '';
    lottieFolder.listSync().forEach((folder) {
      if (folder is Directory && folder.uri.folderName == 'images') {
        imageFolder = folder;
      }
    });

    imageFolder?.listSync().forEach((file) {
      final isImage = ['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(
        file.uri.imageType,
      );
      if (file is File && isImage) {
        images.add(file);
      }
    });
  }

  @override
  void delete() {
    if (lottieFolder.existsSync()) {
      lottieFolder.deleteSync(recursive: true);
    }
  }

  @override
  void moveTo(String path) {
    final String newFolderPath = '$path/$folderName';

    final String newJsonPath = '$newFolderPath/data.json';

    final String newImageFolderPath = '$newFolderPath/images';

    if (Directory(newFolderPath).existsSync()) {
      Directory(newFolderPath).deleteSync(recursive: true);
    }
    Directory(newFolderPath).createSync();

    dataJson.copySync(newJsonPath).createSync();

    if (images.isNotEmpty) {
      Directory(newImageFolderPath).createSync();
      for (var f in images) {
        final String newImagePath =
            '$newImageFolderPath/${f.uri.pathSegments.last}';
        f.copySync(newImagePath).createSync();
      }
    }

    if (lottieFolder.existsSync()) {
      lottieFolder.deleteSync(recursive: true);
    }
  }

  @override
  bool sourceIsValid() {
    try {
      DartFormatter formatter = DartFormatter(indent: 0);
      formatter.format("""const String $folderName = '$folderName'; """);
      return true;
    } catch (e) {
      analyzerLog('Name is invalid: $folderName');
      return false;
    }
  }
}

class LottieResource extends AssetResource {
  LottieResource(super.projPath, super.config);

  static LottieResource build(
      String sourceFolder, String projPath, String configName) {
    final config =
        json.decode(File('$configPath/$configName').readAsStringSync());
    return AssetResource.build(
      sourceFolder: sourceFolder,
      resource: LottieResource(
        projPath,
        LottieConfig.fromJson(config),
      ),
    );
  }

  @override
  AssetSource archive(File f) =>
      LottieSource(name: '', tailFix: '', dataJson: f);

  @override
  bool pathIsTarget(String path) {
    final name = Uri.parse(path).pathSegments.last;
    return name == 'data.json';
  }

  @override
  List<String> get bindings {
    final List<String> result = [];
    for (var source in sources) {
      source = source as LottieSource;
      result.add('${config.baseNamePath}/${source.folderName}/data.json');
      if (source.imageFolder != null) {
        result.add('${config.baseNamePath}/${source.folderName}/images/');
      }
    }
    return result;
  }
}

extension on Uri {
  String get folderName => pathSegments.where((e) => e.isNotEmpty).last;

  String get imageType => pathSegments.last.split('.').last;
}
