import 'dart:io';

import 'package:analyzer_query/proj_path/package.dart';
import 'package:resource_handler/config.dart';
import 'package:resource_handler/resource_tree/resource_tree.dart';
import 'package:resource_handler/resource_tree/yaml_parse.dart';

void main() {
  // configDartTest();
  // yamlParseDartTest();
  resourceTreeDartTest();
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

void yamlParseDartTest() {
  for (var element
      in YamlParser(r"C:\Users\16230\StudioProjects\my_healer\pubspec.yaml")
          .validUri) {
    print(element.path);
  }
}

void resourceTreeDartTest() {
  final uri =
      YamlParser(r"C:\Users\16230\StudioProjects\my_healer\pubspec.yaml")
          .validUri;
  final tree = ResourceTree(uri);
  print(tree);
}
