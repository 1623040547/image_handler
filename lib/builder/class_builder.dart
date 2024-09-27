import 'package:resource_handler/builder/builder.dart';

///使用[config]中的[basePath]，[className]，[basePathName]信息，
///构建一个资源管理类的基本框架。
///```dart
///class className {
///   const String basePathName = 'basePath';
///}
/// ```
class ClassBuilder extends Builder {
  String get basePath => config.basePath;

  String get className => config.className;

  String get basePathName => config.basePathName;

  String _sourceCode = "";

  String get sourceCode => '$_sourceCode}';

  ClassBuilder(super.config) {
    _sourceCode = """
    class $className {
        const String $basePathName = '$basePath';
    """;
  }

  void append(String source) {
    _sourceCode += source;
  }
}
