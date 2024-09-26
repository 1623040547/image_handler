import 'dart:convert';

import 'package:analyzer_query/mini/log.dart';

ResourceConfig get defaultResourceConfig => ResourceConfig._fromJson({});

List<ResourceConfig> readResourceConfig(String jsonString) {
  List<ResourceConfig> config = [];
  for (var e in json.decode(jsonString)) {
    config.add(ResourceConfig._fromJson(json.decode(json.encode(e))));
  }
  return config;
}

class ResourceConfig {
  ResourceConfig._();

  late final String configName;

  late final String basePathName;

  late final String basePath;

  late final String className;

  late final ResourceMeta? meta;

  late final ResourceStrategy? strategy;

  late final ImageStrategy? imageStrategy;

  static ResourceConfig _fromJson(Map<String, dynamic> json) {
    final model = ResourceConfig._();
    model.configName = json["configName"] ?? "image";
    model.basePathName = json["basePathName"] ?? "imageBasePath";
    model.basePath = json["basePath"] ?? "lib/resources/images";
    model.className = json["className"] ?? "ImageNames";

    if (json["meta"] != null) {
      model.meta = ResourceMeta._fromJson(json["meta"]);
    } else {
      model.meta = null;
    }

    if (json["strategy"] != null) {
      model.strategy = ResourceStrategy._fromJson(json["strategy"]);
    } else {
      model.strategy = null;
    }

    if (json["imageStrategy"] != null) {
      model.imageStrategy = ImageStrategy._fromJson(json["imageStrategy"]);
    } else {
      model.imageStrategy = null;
    }

    return model;
  }

  @override
  String toString() {
    return """
className: $className,
configName: $configName,
basePathName: $basePathName,
basePath: $basePath,
    """;
  }
}

class ResourceMeta {
  ResourceMeta._();

  late final String className;

  late final List<ResourceMetaParam> params;

  static ResourceMeta _fromJson(Map<String, dynamic> json) {
    final model = ResourceMeta._();
    model.className = json["className"] ?? ["ImageMeta"];
    final param = json["params"];
    if (param is List) {
      model.params = param.map((e) => ResourceMetaParam._fromJson(e)).toList();
    } else {
      model.params = [];
    }
    return model;
  }
}

class ResourceMetaParam {
  ResourceMetaParam._();

  late final String name;

  late final String type;

  static ResourceMetaParam _fromJson(Map<String, dynamic> json) {
    final model = ResourceMetaParam._();
    if (json["name"] == null) {
      analyzerLog("ResourceMetaParam _fromJson: `name` is empty.");
    }
    if (json["type"] == null) {
      analyzerLog("ResourceMetaParam _fromJson: `type` is empty.");
    }
    model.name = json["name"]!;
    model.type = json["type"]!;
    return model;
  }
}

class ResourceStrategy {
  ResourceStrategy._();

  bool needCopy = false;

  bool needOverride = false;

  bool removeNoCiteSource = false;

  bool removeNoCiteStr = false;

  static ResourceStrategy _fromJson(Map<String, dynamic> json) {
    final model = ResourceStrategy._();
    model.needCopy = json["needCopy"] ?? model.needCopy;
    model.needOverride = json["needOverride"] ?? model.needOverride;
    model.removeNoCiteSource =
        json["removeNoCiteSource"] ?? model.removeNoCiteSource;
    model.removeNoCiteStr = json["removeNoCiteStr"] ?? model.removeNoCiteStr;
    return model;
  }
}

class ImageStrategy {
  ImageStrategy._();

  int size = 3;

  String endWithPattern = "";

  String containPattern = "";

  String startWithPattern = "";

  static ImageStrategy _fromJson(Map<String, dynamic> json) {
    final model = ImageStrategy._();
    model.size = json["size"] ?? model.size;
    model.startWithPattern = json["startWithPattern"] ?? model.startWithPattern;
    model.endWithPattern = json["endWithPattern"] ?? model.endWithPattern;
    model.containPattern = json["containPattern"] ?? model.containPattern;
    return model;
  }
}
