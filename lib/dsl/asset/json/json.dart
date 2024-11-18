import 'package:resource_handler/dsl/asset/asset.dart';

part 'json.g.dart';

@JsonSerializable()
class JsonConfig extends AssetConfig {
  JsonConfig({
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

  static JsonConfig fromJson(Map<String, dynamic> json) =>
      _$JsonConfigFromJson(json);

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

class JsonSource extends AssetSource {
  File file;

  JsonSource({
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

class JsonResource extends AssetResource {
  JsonResource(super.projPath, super.config);

  static JsonResource build(
      String sourceFolder, String projPath, String configName) {
    final config =
        json.decode(File('$configPath/$configName').readAsStringSync());
    return AssetResource.build(
      sourceFolder: sourceFolder,
      resource: JsonResource(
        projPath,
        JsonConfig.fromJson(config),
      ),
    );
  }

  @override
  AssetSource archive(File f) =>
      JsonSource(name: f.uri.jsonName, tailFix: f.uri.jsonType, file: f);

  @override
  bool pathIsTarget(String path) {
    final name = Uri.parse(path).pathSegments.last;
    final isImage = ['json'].contains(
      name.split('.').last,
    );
    final isHidden = name.startsWith('.');
    return isImage && !isHidden;
  }

  @override
  List<String> get bindings => [config.binding];
}

extension on Uri {
  String get jsonName => pathSegments.last.split('.').first;

  String get jsonType => pathSegments.last.split('.').last;
}
