import 'package:analyzer_query/proj_path/yaml_file.dart';
import 'package:resource_handler/base/resource.dart';

abstract class DataBindingPorc<E> extends ResourceHandler<E> {}

abstract class YamlDataBindingProc<E> extends DataBindingPorc<E> {
  ///数据来源所在的根目录
  final String filePath;

  late final Map<String, dynamic> yamlMap;

  YamlDataBindingProc(this.filePath) {
    yamlMap = YamlFile(filePath).yamlMap;
  }
}
