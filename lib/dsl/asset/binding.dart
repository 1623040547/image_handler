import 'asset.dart';

abstract class AssetBindingProcImpl<E extends AssetResource>
    extends YamlDataBindingProc<E> {
  void removeNoResourceBindings();
}

class AssetBindingProc<E extends AssetResource>
    extends AssetBindingProcImpl<E> {
  AssetBindingProc();

  final String keywordFlutter = "flutter";

  final String keywordAsset = "assets";

  List<String> get bindings => resource.bindings;

  @override
  void build() {
    handleYamlMap();
  }

  @override
  handleYamlMap() {
    resource.set(this);
    if (!resource.config.needBinding) {
      return;
    }
    if (!yamlMap.containsKey(keywordFlutter)) {
      insertYaml('', 0, ['$keywordFlutter:']);
    }
    assert(yamlFlutter == null || yamlFlutter is Map);
    if (yamlFlutter == null ||
        !(yamlFlutter as Map).containsKey(keywordAsset)) {
      insertYaml('$keywordFlutter:', 1, ['$keywordAsset:']);
    }
    addBindings();
  }

  void addBindings() {
    assert(yamlAsset == null || yamlAsset is List);
    final List<String> assets =
        (yamlAsset as List?)?.map((e) => e.toString()).toList() ?? [];
    for (var bind in bindings) {
      if (!assets.contains(bind)) {
        insertYaml('$keywordAsset:', 2, ['- $bind']);
      }
    }
  }

  @override
  void removeNoResourceBindings() {
    if (!resource.config.needBinding) {
      return;
    }
    assert(yamlAsset == null || yamlAsset is List);
    final List<String> assets =
        (yamlAsset as List?)?.map((e) => e.toString()).toList() ?? [];
    for (var asset in assets) {
      _removeNoResourceBinding(asset);
    }
  }

  void _removeNoResourceBinding(String assetPath) {
    final path = '${resource.projPath}/$assetPath';
    bool needRemove = false;
    final type = FileSystemEntity.typeSync(path);
    switch (type) {
      case FileSystemEntityType.directory:
        final dir = Directory(path);
        needRemove =
            !dir.existsSync() || dir.listSync().whereType<File>().isEmpty;
        break;
      case FileSystemEntityType.file:
        needRemove = !File(path).existsSync();
        break;
      case FileSystemEntityType.link:
      case FileSystemEntityType.notFound:
      case FileSystemEntityType.pipe:
      case FileSystemEntityType.unixDomainSock:
        needRemove = true;
    }
    if (needRemove) {
      removeYaml('$keywordAsset:', 2, ['- $assetPath']);
      analyzerLog('remove no resource binding: - $assetPath');
    }
  }

  get yamlFlutter => yamlMap[keywordFlutter];

  get yamlAsset => yamlFlutter[keywordAsset];
}
