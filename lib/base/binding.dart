import 'dart:io';
import 'dart:math';

import 'package:analyzer_query/proj_path/yaml_file.dart';
import 'package:resource_handler/base/resource.dart';

abstract class DataBindingProc<E> extends ResourceHandler<E> {}

///Yaml类型的数据绑定处理
abstract class YamlDataBindingProc<E> extends DataBindingProc<E> {
  ///数据来源所在的根目录
  late final String yamlPath;

  late final Map<String, dynamic> yamlMap;

  YamlDataBindingProc(this.yamlPath) {
    try {
      final map = YamlFile(yamlPath).yamlMap;
      yamlMap = map;
    } catch (e) {
      yamlMap = {};
    }
  }

  handleYamlMap();

  void insertYaml(String preDepthPattern, int depth, List<String> content) {
    final lines = File(yamlPath).readAsLinesSync().toList();
    const String spacer = '  ';
    int index = lines.indexWhere((e) {
      final tmp = max(0, depth - 1);
      if (e.trim().startsWith('#')) {
        return false;
      }
      if (tmp == 0) {
        return e.split('').firstOrNull != ' ' && e.contains(preDepthPattern);
      }
      return e.startsWith(spacer * tmp) && e.contains(preDepthPattern);
    });
    if (preDepthPattern.isEmpty) {
      index = lines.length - 1;
    } else if (index == -1) {
      return;
    }
    for (var slice in content) {
      lines.insert(index + 1, '${spacer * depth}$slice');
      index += 1;
    }
    File(yamlPath).writeAsStringSync(lines.join('\n'));
    yamlMap.clear();
    yamlMap.addAll(YamlFile(yamlPath).yamlMap);
  }
}
