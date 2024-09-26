import 'dart:io';

import 'package:analyzer_query/proj_path/yaml_file.dart';

class YamlParser {
  final String filePath;

  late final String projectPath;

  final List<Uri> validUri = [];

  YamlParser(this.filePath) {
    final map = YamlFile(filePath).yamlMap;
    projectPath = File(filePath).parent.path;
    _recursive(map);
  }

  void _recursive(Map<String, dynamic> map) {
    map.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        _recursive(value);
      }
      if (value is List) {
        for (var e in value) {
          if (e is Map<String, dynamic>) {
            _recursive(e);
          }
          _uriParse(e);
        }
      }
      _uriParse(value);
    });
  }

  void _uriParse(value) {
    if (value is String) {
      final uri = Uri.tryParse(value);
      if (uri != null) {
        final path = projectPath + Platform.pathSeparator + uri.path;
        if (File(path).existsSync() || Directory(path).existsSync()) {
          validUri.add(Uri.parse(path));
        }
      }
    }
  }
}
