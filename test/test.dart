import 'dart:io';

import 'package:analyzer_query/proj_path/package.dart';
import 'package:resource_handler/config.dart';
import 'package:resource_handler/finder/class_finder.dart';
import 'package:resource_handler/resource_tree/resource_tree.dart';
import 'package:resource_handler/resource_tree/yaml_parse.dart';

void main() {
  // configDartTest();
  // yamlParseDartTest();
  // resourceTreeDartTest();
  classFinderDartTest();
}

void configDartTest() {
  print(defaultResourceConfig);
  List<ResourceConfig> config = readResourceConfig(
      File('${mainProj.projPath}/test/test_config.json').readAsStringSync());
  for (var e in config) {
    print(e);
  }
}

void yamlParseDartTest() {
  for (var element
      in YamlParser("${rootProj.projPath}/pubspec.yaml").validUri) {
    print(element.path);
  }
}

void resourceTreeDartTest() {
  final uri = YamlParser("${rootProj.projPath}/pubspec.yaml").validUri;
  final tree = ResourceTree(uri);
  ResourceNode? node = tree.header?.children.first.copy();
  ResourceNode node2 =
      tree.manage(Uri.parse("${rootProj.projPath}/lib/resources/"));
  final files = node2.getManagedFile();
  for (var element in files) {}
}

void classFinderDartTest() {
  List<ResourceConfig> config = readResourceConfig(
      File('${mainProj.projPath}/test/test_config.json').readAsStringSync());
  for (var e in config) {
    final finder = ClassFinder(e);
    print(finder);
  }
}
