import 'package:resource_handler/dsl/asset/asset.dart';

part 'media.g.dart';

@JsonSerializable()
class MediaConfig extends AssetConfig {
  MediaConfig({
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

  static MediaConfig fromJson(Map<String, dynamic> json) =>
      _$MediaConfigFromJson(json);

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

class MediaSource extends AssetSource {
  File file;

  MediaSource({
    required super.name,
    required super.tailFix,
    required this.file,
  });

  @override
  void delete() {
    file.deleteSync();
  }

  @override
  void moveTo(String path) {
    final String newPath = path + Platform.pathSeparator + fullName;
    file.copySync(newPath).createSync();
    file.deleteSync();
  }

  @override
  bool sourceIsValid() {
    try {
      DartFormatter formatter = DartFormatter(indent: 0);
      formatter.format("""const String $name = '$name.$tailFix'; """);
      return true;
    } catch (e) {
      analyzerLog('Name is invalid: $name');
      return false;
    }
  }
}

class MediaResource extends AssetResource {
  MediaResource(super.projPath, super.config);

  static MediaResource build(
      String sourceFolder, String projPath, String configName) {
    final config =
        json.decode(File('$configPath/$configName').readAsStringSync());
    return AssetResource.build(
      sourceFolder: sourceFolder,
      resource: MediaResource(
        projPath,
        MediaConfig.fromJson(config),
      ),
    );
  }

  @override
  AssetSource archive(File f) =>
      MediaSource(name: f.uri.mediaName, tailFix: f.uri.mediaType, file: f);

  @override
  bool pathIsTarget(String path) {
    final name = Uri.parse(path).pathSegments.last;
    final isMedia = ['mp3', 'mp4'].contains(
      name.split('.').last,
    );
    final isHidden = name.startsWith('.');
    return isMedia && !isHidden;
  }

  @override
  List<String> get bindings => [config.binding];
}

extension on Uri {
  String get mediaName => pathSegments.last.split('.').first;

  String get mediaType => pathSegments.last.split('.').last;
}