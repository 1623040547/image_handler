import 'package:resource_handler/base/base.dart';

import 'data.dart';

class ImageResource {
  static ImageResource build(String rootFolder) => ImageSourcePorc(rootFolder)
      .link(ImageBindingPorc())
      .link(ImageDestinationPorc())
      .link(ImageDefinePorc())
      .link(ImageCitePorc())
      .exec(ImageResource());

  ///外部图片源
  final List<ImageSource> sources = [];

  ///项目图片源
  final List<ImageSource> assetSources = [];
}

class ImageSourcePorc<E extends ImageResource> extends FileDataSourcePorc<E> {
  ImageSourcePorc(super.rootFolder);

  @override
  build() {
    recursive(fileGetter: (f) {
      final image = ImageSource.archive(f);
      if (image != null) {
        resource.sources.add(image);
      }
    });
  }
}

class ImageBindingPorc<E extends ImageResource> extends DataBindingPorc<E> {
  @override
  void build() {
    // TODO: implement build
  }
}

class ImageDestinationPorc<ImageResource>
    extends DataDestinationPorc<ImageResource> {
  @override
  void build() {
    // TODO: implement build
  }
}

class ImageDefinePorc<E extends ImageResource> extends DataDefinePorc<E> {
  @override
  void build() {
    // TODO: implement build
  }
}

class ImageCitePorc<E extends ImageResource> extends DataCitePorc<E> {
  @override
  void build() {
    // TODO: implement build
  }
}
