import 'dart:io';

import 'package:analyzer_query/mini/log.dart';
import 'package:analyzer_query/proj_path/dart_file.dart';
import 'package:analyzer_query/tester.dart';
import 'package:resource_handler/base/base.dart';

import 'data.dart';

void main() {
  ImageResource.build(
    "/Users/mac/StudioProjects/resource_handler/test/1",
    "/Users/mac/StudioProjects/my_healer",
  );
  // TestFile.fromFile(
  //         "/Users/mac/StudioProjects/my_healer/lib/common/images.dart")
  //     .showNodeDict();
}

///声明代码的语法规则，被[ImageDefinePorc]使用
class ImageHandleGrammar {
  final String fileString;

  ImageHandleGrammar(this.fileString);

  String get className => ImageHandlerConfig.instance.className;

  String get defaultBaseName => ImageHandlerConfig.instance.defaultBaseName;

  String get defineBasePath => ImageHandlerConfig.instance.binding
      .split('/')
      .where((e) => e.isNotEmpty)
      .join('/');

  void compilationUnitRule(CompilationUnit target) {
    for (var member in target.declarations) {
      assert(
          member is ClassDeclaration || member is TopLevelVariableDeclaration);

      if (member is ClassDeclaration) {
        final name = member.name.toString();
        assert(name == className || name == _imageMetaName);
        if (name == className) {
          classDeclarationRule(member);
        }
      }

      if (member is TopLevelVariableDeclaration) {
        assert(member.variables.variables.isNotEmpty);
        final initializer = member.variables.variables.first.initializer;
        assert(member.variables.variables.first.initializer is ListLiteral);
        listLiteralRule(initializer as ListLiteral);
      }
    }
  }

  void classDeclarationRule(ClassDeclaration target) {
    for (var member in target.members) {
      assert(member is FieldDeclaration || member is MethodDeclaration);
      dynamic flag;
      TestFile.fromString(
        fileString,
        node: member,
        visit: (node, _, controller) {
          if (node is SimpleStringLiteral) {
            flag = node.value;
            assert(Uri.tryParse(flag) != null);
            controller.stop();
          }
          if (node is StringInterpolation) {
            flag = node;
            controller.stop();
          }
        },
      );
      assert(flag != null);

      if (member is FieldDeclaration) {
        assert(member.fields.variables.isNotEmpty);
        final name = member.fields.variables.first.name.toString();
        assert(name != defaultBaseName ||
            (name == defaultBaseName && flag == defineBasePath));
      }

      for (var element in member.metadata) {
        annotationRule(element);
      }
    }
  }

  void listLiteralRule(ListLiteral target) {
    for (var outer in target.elements) {
      assert(outer is SimpleStringLiteral || outer is ListLiteral);
      if (outer is ListLiteral) {
        for (var inner in outer.elements) {
          assert(inner is SimpleStringLiteral);
        }
      }
    }
  }

  void annotationRule(Annotation annotation) {
    if (annotation.name.name != _imageMetaName) {
      return;
    }
    for (var expression in annotation.arguments?.arguments ?? []) {
      assert(expression is NamedExpression);
      final label = (expression as NamedExpression).name.label.name;
      assert(label == _imageMetaPatterns || label == _imageMetaCiteArray);
      final innerExpression = expression.expression;
      assert(innerExpression is SimpleIdentifier ||
          innerExpression is ListLiteral);
      if (innerExpression is ListLiteral) {
        listLiteralRule(innerExpression);
      }
    }
  }
}

///图片处理运行的全局配置
class ImageHandlerConfig {
  ImageHandlerConfig._();

  static ImageHandlerConfig? _instance;

  static ImageHandlerConfig get instance =>
      _instance ??= ImageHandlerConfig._();

  List<String> get bindings => [binding, bindingX2, bindingX3];

  final String className = "ImageNames";

  final String defaultClassDefinePath = "lib/common/images.dart";

  final String defaultBaseName = "imageBasePath";

  final String binding = 'lib/resources/images/';

  final String bindingX2 = 'lib/resources/images/2.0x/';

  final String bindingX3 = 'lib/resources/images/3.0x/';

  final bool isOverWrite = false;

  final bool needImageMeta = true;
}

///图片处理运行起点与处理全流程共享变量存储
class ImageResource {
  ImageResource(this.projPath);

  static ImageResource build(String sourceFolder, String projPath) =>
      ImageSourcePorc(sourceFolder)
          .link(ImageBindingPorc('$projPath/pubspec.yaml'))
          .link(ImageDestinationPorc())
          .link(ImageDefinePorc(projPath))
          .link(ImageCitePorc())
          .exec(ImageResource(projPath));

  final String projPath;

  ///外部图片源
  final Set<ImageSource> sources = {};

  ///项目图片源
  final Set<ImageSource> assetSources = {};

  ///需要增加在class中的代码
  StringBuffer codeBuffer = StringBuffer();

  ///通过语法检查后获取的有效数据
  final Map<String, TopLevelVariableDeclaration> mappingNameToConstArray = {};

  final Map<ClassMember, String> mappingMemberToName = {};

  final Map<String, ClassMember> mappingNameToMember = {};

  final Map<String, ClassMember> mappingPathToMember = {};

  final Map<List<List<String>>, ClassMember> mappingPatternsToMember = {};

  final Map<List<String>, ClassMember> mappingArraysToMember = {};
}

///数据源处理
class ImageSourcePorc<E extends ImageResource> extends FileDataSourcePorc<E> {
  ImageSourcePorc(super.rootFolder);

  @override
  build() {
    recursive(fileGetter: (f) {
      ///忽略隐藏文件与非指定格式照片
      if (!isValid(f)) {
        return;
      }
      final image = ImageSource.archive(f);
      resource.sources.add(image);
    });
  }

  @override
  bool isValid(File f) => ImageSource.isImage(f.path);
}

///数据绑定处理
class ImageBindingPorc<E extends ImageResource> extends YamlDataBindingProc<E> {
  ImageBindingPorc(super.yamlPath);

  static const String keywordFlutter = "flutter";

  static const String keywordAsset = "assets";

  List<String> get bindings => ImageHandlerConfig.instance.bindings;

  @override
  void build() {
    handleYamlMap();
  }

  @override
  handleYamlMap() {
    if (!yamlMap.containsKey(keywordFlutter)) {
      insertYaml('', 0, ['$keywordFlutter:']);
    }
    assert(yamlFlutter == null || yamlFlutter is Map);
    if (yamlFlutter == null ||
        !(yamlFlutter as Map).containsKey(keywordAsset)) {
      insertYaml('$keywordFlutter:', 1, ['$keywordAsset:']);
    }
    assert(yamlAsset == null || yamlAsset is List);
    final List<String> assets =
        (yamlAsset as List?)?.map((e) => e.toString()).toList() ?? [];
    for (var bind in bindings) {
      if (!assets.contains(bind)) {
        insertYaml('$keywordAsset:', 2, ['- $bind']);
      }
    }
  }

  get yamlFlutter => yamlMap[keywordFlutter];

  get yamlAsset => yamlFlutter[keywordAsset];
}

///数据源写入目标处理
class ImageDestinationPorc<E extends ImageResource>
    extends DataDestinationPorc<E> {
  List<String> get bindings => ImageHandlerConfig.instance.bindings;

  bool get isOverwrite => ImageHandlerConfig.instance.isOverWrite;

  bool isValid(File f) => ImageSource.isImage(f.path);

  String get projPath => resource.projPath;

  Set<ImageSource> get sources => resource.sources;

  Set<ImageSource> get assetSources => resource.assetSources;

  @override
  void build() {
    for (var bindingPath in bindings) {
      final path = '$projPath/$bindingPath';
      final directory = Directory(path);
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }
      directory.list().forEach((f) {
        final file = File(f.path);
        if (file.existsSync() && isValid(file)) {
          final image = ImageSource.archive(file);
          assetSources.add(image);
        }
      });
    }
    handleOverwrite();
  }

  void handleOverwrite() {
    for (var source in sources.toSet()) {
      bool isDuplicate = assetSources
          .where((s) => s.fullImageName == source.fullImageName)
          .isNotEmpty;
      if (isDuplicate && !isOverwrite) {
        sources.remove(source);
        analyzerLog('Duplicate Image: ${source.fullImageName}');
      } else if (source.isValid()) {
        source.shrinkImage();
      } else {
        sources.remove(source);
        analyzerLog('Invalid Image\'s Name: ${source.fullImageName}');
      }
    }
  }
}

///声明代码处理
class ImageDefinePorc<E extends ImageResource> extends DataDefinePorc<E> {
  ImageDefinePorc(super.projPath);

  List<DartFile> targetFiles = [];

  ClassDeclaration? declaration;

  ClassDeclaration? meta;

  DartFile? target;

  String get defineClassName => ImageHandlerConfig.instance.className;

  String get defineClassPath =>
      ImageHandlerConfig.instance.defaultClassDefinePath;

  String get defineBaseName => ImageHandlerConfig.instance.defaultBaseName;

  String get defineBasePath => ImageHandlerConfig.instance.binding
      .split('/')
      .where((e) => e.isNotEmpty)
      .join('/');

  bool get needMeta => ImageHandlerConfig.instance.needImageMeta;

  Map<String, TopLevelVariableDeclaration> get mappingNameToConstArray =>
      resource.mappingNameToConstArray;

  Map<ClassMember, String> get mappingMemberToName =>
      resource.mappingMemberToName;

  Map<String, ClassMember> get mappingNameToMember =>
      resource.mappingNameToMember;

  Map<String, ClassMember> get mappingPathToMember =>
      resource.mappingPathToMember;

  Map<List<List<String>>, ClassMember> get mappingPatternsToMember =>
      resource.mappingPatternsToMember;

  Map<List<String>, ClassMember> get mappingArraysToMember =>
      resource.mappingArraysToMember;

  StringBuffer get codeBuffer => resource.codeBuffer;

  @override
  void build() {
    handleClassDefine();
    final unit = declaration!.parent as CompilationUnit;
    ImageHandleGrammar(target!.fileString).compilationUnitRule(unit);
    dataFromImageDefine();
  }

  ///处理[defineClassName],如果项目中不存在,则在指定位置创建
  void handleClassDefine() {
    projDart.acceptPack = (pack) => pack.isMainProj;
    projDart.acceptDartString = (fs) => fs.contains(defineClassName);
    final list = projDart.flush();
    targetFiles.clear();
    targetFiles.addAll(list);
    for (var file in targetFiles) {
      if (_handleClassDeclaration(file.fileString)) {
        target = file;
        break;
      }
    }
    if (declaration == null) {
      _handleImageDefineCreate();
      for (var file in targetFiles) {
        if (_handleClassDeclaration(file.latestFileString)) {
          target = file;
          break;
        }
      }
    }
    _handleImageMetaDefineCreate();
  }

  ///处理[ClassDeclaration]
  bool _handleClassDeclaration(String fileString) {
    bool isTarget = false;
    TestFile.fromString(
      fileString,
      breathVisit: true,
      visit: (node, token, controller) {
        if (node is ClassDeclaration &&
            node.name.toString() == defineClassName) {
          isTarget = true;
          declaration = node;
        }
        if (node is ClassDeclaration &&
            node.name.toString() == _imageMetaName) {
          meta = node;
        }
        if (controller.depth == 3) {
          controller.stop();
        }
      },
    );
    return isTarget;
  }

  ///在指定位置创建[defineClassName]
  void _handleImageDefineCreate() {
    final file = File('$projPath/$defineClassPath');
    if (file.existsSync()) {
      file.deleteSync();
    }
    file.createSync(recursive: true);
    file.writeAsStringSync(DartFormatter().format("""
      class $defineClassName {
        static const String $defineBaseName = '$defineBasePath';
      }
      
      ${needMeta ? _imageMetaSource : ""}
      """));
    projDart.acceptPack = (pack) => pack.isMainProj;
    projDart.acceptDartFile = (f) => f.filePath == file.path;
    projDart.acceptDartString = (s) => true;
    targetFiles.clear();
    targetFiles.addAll(projDart.flush());
  }

  ///处理[_imageMetaName],如果项目中不存在,则在指定位置创建
  void _handleImageMetaDefineCreate() {
    if (needMeta && meta == null) {
      File(target!.filePath).writeAsStringSync(DartFormatter().format("""
       ${target!.latestFileString}\n
       $_imageMetaSource
       """));
    }
  }

  ///从[defineClassName]定义中获取数据
  void dataFromImageDefine() {
    final unit = declaration!.parent as CompilationUnit;
    for (var member in unit.declarations) {
      if (member is TopLevelVariableDeclaration) {
        final name = member.variables.variables.first.name.toString();
        mappingNameToConstArray[name] = member;
      }
    }
    for (var member in declaration!.members) {
      String? name;
      if (member is FieldDeclaration) {
        assert(member.fields.variables.isNotEmpty);
        name = member.fields.variables.first.name.toString();
      }
      if (member is MethodDeclaration) {
        name = member.name.toString();
      }
      TestFile.fromString(
        target!.fileString,
        node: member,
        visit: (node, token, controller) {
          if (node is StringInterpolation) {
            _dataFromStringDefine(node, member);
            mappingMemberToName[member] = name!;
            mappingNameToMember[name] = member;
          }
          if (node is SimpleStringLiteral) {
            _dataFromStringDefine(node, member);
            mappingMemberToName[member] = name!;
            mappingNameToMember[name] = member;
          }
        },
      );
    }
    if (!mappingNameToMember.keys.contains(defineBaseName)) {
      codeBuffer.writeln("""
      static const String  $defineBaseName = '$defineBasePath';
      """);
    }
  }

  ///从[StringInterpolation]与[SimpleStringLiteral]中获取数据
  void _dataFromStringDefine(AstNode node, ClassMember member) {
    if (node is SimpleStringLiteral) {
      if (ImageSource.isImage(node.value)) {
        mappingPathToMember[node.value] = member;
      }
    }

    if (node is StringInterpolation) {
      String path = "";
      bool isDirect = true;
      for (var e in node.elements) {
        if (e is InterpolationString) {
          path += e.value;
        } else if (e is InterpolationExpression &&
            e.expression is SimpleIdentifier) {
          final name = (e.expression as SimpleIdentifier).token.toString();
          if (name == defineBaseName) {
            path += defineBasePath;
          } else {
            _dataFromAnnotationDefine(member);
            isDirect = false;
            break;
          }
        } else {
          _dataFromAnnotationDefine(member);
          isDirect = false;
          break;
        }
      }
      if (isDirect && ImageSource.isImage(path)) {
        mappingPathToMember[path] = member;
      }
    }
  }

  ///从[Annotation]中获取数据
  void _dataFromAnnotationDefine(ClassMember member) {
    if (!needMeta) {
      return;
    }
    for (var e in member.metadata) {
      if (e.name.name != _imageMetaName) {
        continue;
      }
      e.arguments?.arguments.forEach((expression) {
        final target = expression as NamedExpression;
        final name = target.name.label.name;
        final targetExpression = target.expression;
        final List<List<String>> list;
        if (targetExpression is SimpleIdentifier) {
          final citeNode = mappingNameToConstArray[targetExpression.name]!;
          final variables = citeNode.variables.variables;
          list =
              _dataFromStringList(variables.first.initializer as ListLiteral);
        } else if (targetExpression is ListLiteral) {
          list = _dataFromStringList(targetExpression);
        } else {
          list = [];
        }
        if (name == _imageMetaPatterns) {
          mappingPatternsToMember[list] = member;
        } else if (name == _imageMetaCiteArray) {
          mappingArraysToMember[list.first] = member;
        }
      });
    }
  }

  ///从[ListLiteral]中获取数据
  List<List<String>> _dataFromStringList(ListLiteral list) {
    final List<List<String>> result = [];
    final List<String> line = [];
    for (var element in list.elements) {
      if (element is StringLiteral && element.stringValue != null) {
        line.add(element.stringValue!);
      } else if (element is ListLiteral) {
        result.add(_dataFromStringList(element).firstOrNull ?? []);
      }
    }
    if (line.isNotEmpty) {
      result.add(line);
    }
    return result;
  }
}

///声明引用处理：
/// code define -> asset
/// use code define  -> code define
class ImageCitePorc<E extends ImageResource> extends DataCitePorc<E> {
  @override
  void build() {}
}

///代码段定义，被[ImageDefinePorc]使用
const String _imageMetaName = "ImageMeta";

const String _imageMetaPatterns = "patterns";

const String _imageMetaCiteArray = "citeArray";

const String _imageMetaSource = """
///部分图片没有直接使用字符串常量索引，通过注解提供两种间接表示图片名称的方式，
///- [$_imageMetaPatterns]用于表示图片一定包含的字符常量片段的数组，
///该字段一般用于含有索引的图片组，
///例如某一特征为['iconSunSign', '.png']，则其对应的正则表达式为['iconSunSign*.png']
///- [$_imageMetaCiteArray]用于表示对一个定义于本文件的常量列表的引用
///该字段一般用于关联性较强的字符串类型的图片组，
///当声明[$_imageMetaCiteArray]之后，会在图片自动化时寻找到相应的常量数组并提取其中的字符串常量
class $_imageMetaName {
  final List<List<String>> $_imageMetaPatterns;
  final List<String> $_imageMetaCiteArray;

  const $_imageMetaName({
    this.$_imageMetaPatterns = const [],
    this.$_imageMetaCiteArray = const [],
  });
}
""";
