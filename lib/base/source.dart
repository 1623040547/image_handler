import 'dart:io';

import 'package:resource_handler/base/resource.dart';

abstract class DataSourcePorc<E> extends ResourceHandler<E> {}

abstract class FileDataSourcePorc<E> extends DataSourcePorc<E> {
  ///数据来源所在的根目录
  final String rootFolder;

  FileDataSourcePorc(this.rootFolder);

  ///递归根目录，每搜索到一个[File]或[Directory]，便触发一次[fileGetter]或[folderGetter]回调
  recursive({
    Function(File)? fileGetter,
    Function(Directory)? folderGetter,
  }) {
    final root = Directory(rootFolder);
    if (!root.existsSync()) {
      return;
    }
    folderGetter?.call(root);
    root.listSync(recursive: true).forEach((entity) {
      final file = File(entity.path);
      final folder = Directory(entity.path);
      if (file.existsSync()) {
        fileGetter?.call(file);
      }
      if (folder.existsSync()) {
        folderGetter?.call(folder);
      }
    });
  }
}
