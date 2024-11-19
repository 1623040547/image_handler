import 'asset.dart';

abstract class AssetDestinationImpl<E extends AssetResource>
    extends DataDestinationProc<E> {
  final Set<AssetSource> assetSources = {};

  String get projPath => resource.projPath;

  List<String> get bindings => resource.bindings;

  String get binding => resource.config.binding;
}

class AssetDestinationProc<E extends AssetResource>
    extends AssetDestinationImpl<E> {
  @override
  void build() {
    resource.set(this);
    final path = '$projPath/$binding';
    try {
      final directory = Directory(path);
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }
      directory.listSync(recursive: true).forEach((f) {
        final file = File(f.path);
        if (file.existsSync() && resource.pathIsTarget(file.path)) {
          assetSources.add(resource.archive(file));
        }
      });
    } catch (e) {
      analyzerLog('binding file: $binding');
    }
  }
}
