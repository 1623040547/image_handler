import 'asset.dart';

class AssetBindingProc<E extends AssetResource> extends YamlDataBindingProc<E> {
  AssetBindingProc();

  final String keywordFlutter = "flutter";

  final String keywordAsset = "assets";

  List<String> get bindings => resource.config.bindings;

  @override
  void build() {
    handleYamlMap();
  }

  @override
  handleYamlMap() {
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
    assert(yamlAsset == null || yamlAsset is List);
    final List<String> assets =
        (yamlAsset as List?)?.map((e) => e.toString()).toList() ?? [];
    for (var bind in bindings) {
      if (!assets.contains(bind)) {
        insertYaml('$keywordAsset:', 2, ['- $bind']);
      }
    }
  }

  get yamlFlutter => yamlMap[keywordFlutter];

  get yamlAsset => yamlFlutter[keywordAsset];
}
