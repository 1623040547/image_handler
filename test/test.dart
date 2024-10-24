import 'dart:io';
import 'package:analyzer_query/proj_path/package.dart';
import 'package:resource_handler/config.dart';
import 'package:resource_handler/finder/class_finder.dart';
import 'package:resource_handler/tools/resource_tree/resource_tree.dart';
import 'package:resource_handler/tools/resource_tree/yaml_parse.dart';

Future<void> main() async {
  // configDartTest();
  await yamlParseDartTest();
  // resourceTreeDartTest();
  // classFinderDartTest();
}

void configDartTest() {
  print(defaultResourceConfig);
  List<ResourceConfig> config = readResourceConfig(
      File('${mainProj.projPath}/test/test_config.json').readAsStringSync());
  for (var e in config) {
    print(e);
  }
}

Future<void> yamlParseDartTest() async {
  // final doc = loadYamlDocument("${rootProj.projPath}/pubspec.yaml");
  // for (var element
  //     in YamlParser("${rootProj.projPath}/pubspec.yaml").validUri) {
  //   print(element.path);
  // }
  // print(modifiable);
  // final doc = loadYamlDocument(test_);
  // var settings =loadYaml( test_);
  // var map = settings.valueMap;
  // map.remove("sentry");
  // settings.save();

  // print(map);
  // doc.contents;
  // print(doc.span.text);
  // final map = doc.contents.value as YamlMap;
  // for(var key in map.nodes.keys) {
  //    key = key as YamlNode;
  //    print(key);
  // }
  // for (var element in map.nodes.values) {
  //   final s = element.span;
  //   s.start.offset;
  //   s.end.offset;
  //   final text = s.text;
  //   print(s.text + '\n\n');
  // }
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
