import 'asset.dart';

abstract class AssetDestinationImpl<E extends AssetResource>
    extends DataDestinationProc<E> {
  final Set<AssetSource> assetSources = {};

  String get projPath => resource.projPath;

  List<String> get bindings => resource.config.bindings;
}

class AssetDestinationProc<E extends AssetResource>
    extends AssetDestinationImpl<E> {
  @override
  void build() {
    resource.set(this);
    for (var bindingPath in bindings) {
      final path = '$projPath/$bindingPath';
      final directory = Directory(path);
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }
      directory.listSync().forEach((f) {
        final file = File(f.path);
        if (file.existsSync() && resource.pathIsTarget(file.path)) {
          assetSources.add(resource.archive(file));
        }
      });
    }
  }
}
