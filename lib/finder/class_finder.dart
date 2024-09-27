import 'package:analyzer_query/mini/log.dart';
import 'package:analyzer_query/proj_path/dart_file.dart';
import 'package:analyzer_query/tester.dart';
import 'package:resource_handler/finder/finder.dart';

class ClassFinder extends Finder {
  final List<DartFile> classDefine = [];

  final List<DartFile> classRef = [];

  ClassFinder(super.config) {
    rootDart.acceptPack = (pack) => pack.isMainProj;
    rootDart.acceptDartString = (f) => f.contains(config.className);
    final files = rootDart.flush();
    // for (var e in files) {
    TestFile.fromString(files[1].fileString, breathVisit: true,
        visit: (node, token, controller) {
      analyzerLog(token.id);
      if (node is ClassDeclaration) {
        analyzerLog(node.name);
      }
      if (node is ClassDeclaration &&
          node.name.toString() == config.className) {
        classDefine.add(files.first);
        controller.stop();
      }
    });
    // }
  }
}
