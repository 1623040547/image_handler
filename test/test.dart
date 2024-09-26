import 'dart:io';

import 'package:analyzer_query/proj_path/package.dart';
import 'package:resource_handler/config.dart';

void main() {
  configDartTest();
}

void configDartTest() {
  print(defaultResourceConfig);
  List<ResourceConfig> config = readResourceConfig(File(
          '${mainProj.projPath}/dev_plugin/resource_handler/test/test_config.json')
      .readAsStringSync());
  for (var e in config) {
    print(e);
  }
}
