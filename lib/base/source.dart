import 'dart:io';

import 'package:resource_handler/base/resource.dart';

abstract class DataSourceProc<E extends BaseResource>
    extends ResourceHandler<E> {}

///文件类型的数据源处理
abstract class FileDataSourceProc<E extends BaseResource>
    extends DataSourceProc<E> {
  ///数据来源所在的根目录
  final String rootFolder;

  FileDataSourceProc(this.rootFolder);

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
