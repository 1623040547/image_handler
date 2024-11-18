import 'package:resource_handler/dsl/asset/asset.dart';

part 'svg.g.dart';

@JsonSerializable()
class SvgConfig extends AssetConfig {
  SvgConfig({
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

  static SvgConfig fromJson(Map<String, dynamic> json) =>
      _$SvgConfigFromJson(json);

  @override
  String get baseNamePath =>
      binding.split('/').where((e) => e.isNotEmpty).join('/');

  @override
  List<String> get bindings => [binding];

  @override
  String get metaClassArrayName => "";

  @override
  String get metaClassPatternName => "";

  @override
  String get metaClassSource => "";
}

class SvgSource extends AssetSource {
  File file;

  SvgSource({
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

class SvgResource extends AssetResource {
  SvgResource(super.projPath, super.config);

  static SvgResource build(
      String sourceFolder, String projPath, String configName) {
    final config =
        json.decode(File('$configPath/$configName').readAsStringSync());
    return AssetResource.build(
      sourceFolder: sourceFolder,
      resource: SvgResource(
        projPath,
        JsonConfig.fromJson(config),
      ),
    );
  }

  @override
  AssetSource archive(File f) =>
      SvgSource(name: f.uri.svgName, tailFix: f.uri.svgType, file: f);

  @override
  bool pathIsTarget(String path) {
    final name = Uri.parse(path).pathSegments.last;
    final isImage = ['svg'].contains(
      name.split('.').last,
    );
    final isHidden = name.startsWith('.');
    return isImage && !isHidden;
  }
}

extension on Uri {
  String get svgName => pathSegments.last.split('.').first;

  String get svgType => pathSegments.last.split('.').last;
}
