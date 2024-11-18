import 'asset.dart';

abstract class AssetSourceImpl<E extends AssetResource>
    extends FileDataSourceProc<E> {
  final Set<AssetSource> sources = {};

  AssetSourceImpl(super.rootFolder);
}

class AssetSourceProc<E extends AssetResource> extends AssetSourceImpl<E> {
  AssetSourceProc(super.rootFolder);

  @override
  build() {
    resource.set(this);
    recursive(fileGetter: (f) {
      ///忽略隐藏文件与非指定格式照片
      if (!resource.pathIsTarget(f.path)) {
        return;
      }
      sources.add(resource.archive(f));
    });
  }
}
