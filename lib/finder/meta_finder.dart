import 'package:analyzer_query/proj_path/dart_file.dart';
import 'package:analyzer_query/tester.dart';
import 'package:resource_handler/finder/finder.dart';


class MetaFinder extends Finder {
  bool get isValid => config.meta != null;

  String get className => config.meta!.className;

  final List<DartFile> classDefine = [];

  final List<DartFile> classRef = [];

  MetaFinder(super.config) : assert(config.meta != null) {
    final files = rootDart.flush();
    rootDart.acceptPack = (pack) => pack.isMainProj;
    rootDart.acceptDartString = (f) => f.contains(className);
    for (var file in files) {
      TestFile.fromString(
        file.fileString,
        breathVisit: true,
        visit: (node, token, controller) {
          if (node is ClassDeclaration && node.name.toString() == className) {
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
  }
}
