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
    for (var file in files) {
      TestFile.fromString(
        file.fileString,
        breathVisit: true,
        visit: (node, token, controller) {
          if (node is ClassDeclaration &&
              node.name.toString() == config.className) {
            classDefine.add(file);
            controller.stop();
          }
          if (controller.depth > 2) {
            classRef.add(file);
            controller.stop();
          }
        },
      );
    }
    assert(classDefine.length == 1, 'Class define just permit 1');
  }
}
