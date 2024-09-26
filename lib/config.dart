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

  ///设置名称，表明本次配置是针对那一类资源。
  ///例如,`image`、`lottie`、`font`。
  late final String configName;

  ///资源文件的基路径，即所有同级资源文件的公共路径
  late final String basePath;

  ///资源管理类的类名
  late final String className;

  ///资源管理类中基路径的定义
  late final String basePathName;

  ///资源注解定义，注解用于处理一些非直接引用的资源对象
  late final ResourceMeta? meta;

  ///资源控制策略
  late final ResourceStrategy strategy;

  ///图片资源控制策略
  late final ImageStrategy imageStrategy;

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
      model.strategy = ResourceStrategy._fromJson({});
    }

    if (json["imageStrategy"] != null) {
      model.imageStrategy = ImageStrategy._fromJson(json["imageStrategy"]);
    } else {
      model.imageStrategy = ImageStrategy._fromJson({});
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
    model.className = json["className"] ?? "ImageMeta";
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

  bool disable = false;

  bool needCopy = false;

  bool needOverride = true;

  bool removeNoCiteSource = true;

  bool removeNoCiteStr = true;

  static ResourceStrategy _fromJson(Map<String, dynamic> json) {
    final model = ResourceStrategy._();
    model.disable = json["disable"] ?? model.disable;
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

  bool disable = false;

  int size = 3;

  String sizeFolder = "{num}.0x";

  String endWithPattern = "@{num}x";

  String containPattern = "";

  String startWithPattern = "";

  static ImageStrategy _fromJson(Map<String, dynamic> json) {
    final model = ImageStrategy._();
    model.disable = json["disable"] ?? model.disable;
    model.size = json["size"] ?? model.size;
    model.startWithPattern = json["startWithPattern"] ?? model.startWithPattern;
    model.endWithPattern = json["endWithPattern"] ?? model.endWithPattern;
    model.containPattern = json["containPattern"] ?? model.containPattern;
    return model;
  }
}
