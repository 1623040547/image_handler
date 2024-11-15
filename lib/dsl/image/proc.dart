import 'dart:io';
import 'package:analyzer_query/mini/log.dart';
import 'package:analyzer_query/proj_path/dart_file.dart';
import 'package:analyzer_query/tester.dart';
import 'package:resource_handler/base/base.dart';

import 'data.dart';

void main() {
  // ImageResource.build(
  //   "/Users/mac/StudioProjects/resource_handler/test/1",
  //   "/Users/mac/StudioProjects/diviner",
  // );
  // TestFile.fromFile(
  //         "/Users/mac/StudioProjects/resource_handler/lib/dsl/image/proc.dart")
  //     .showNodeDict();
}

///声明代码的语法规则，被[ImageDefinePorc]使用
class ImageHandleGrammar {
  final String fileString;

  ImageHandleGrammar(this.fileString);

  String get className => ImageHandlerConfig.instance.className;

  String get defaultBaseName => ImageHandlerConfig.instance.defaultBaseName;

  String get defaultBasePath => ImageHandlerConfig.instance.defaultBasePath;

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
        assert(member.isStatic);
        assert(member.fields.variables.isNotEmpty);
        final name = member.fields.variables.first.name.toString();
        assert(name != defaultBaseName ||
            (name == defaultBaseName && flag == defaultBasePath));
      }

      if (member is MethodDeclaration) {
        assert(member.isStatic);
      }

      for (var element in member.metadata) {
        annotationRule(element);
      }
    }
  }

  void listLiteralRule(ListLiteral target) {
    assert(target.elements.isNotEmpty);
    for (var outer in target.elements) {
      assert(outer is SimpleStringLiteral || outer is ListLiteral);
      if (outer is ListLiteral) {
        assert(outer.elements.isNotEmpty);
        for (var inner in outer.elements) {
          assert(inner is SimpleStringLiteral && inner.value.isNotEmpty);
        }
      }
      if (outer is SimpleStringLiteral) {
        assert(outer.value.isNotEmpty);
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

  String get defaultBasePath =>
      binding.split('/').where((e) => e.isNotEmpty).join('/');

  String get bindingX2 => '$defaultBasePath/2.0x/';

  String get bindingX3 => '$defaultBasePath/3.0x/';

  final bool isOverWrite = false;

  final bool needImageMeta = true;

  ///清理没有被定义的图片
  final bool cleanUndefineImage = true;

  ///清理没有被引用的图片
  final bool cleanNoCitedImageDefine = true;
}

///图片处理运行起点与处理全流程共享变量存储
class ImageResource {
  ImageResource(this.projPath);

  static ImageResource build(String sourceFolder, String projPath) =>
      ImageSourcePorc(sourceFolder)
          .link(ImageBindingPorc('$projPath/pubspec.yaml'))
          .link(ImageDestinationPorc())
          .link(ImageDefinePorc(projPath))
          .link(ImageCitePorc(projPath))
          .exec(ImageResource(projPath));

  final String projPath;

  late DartFile defineFile;

  late ClassDeclaration declaration;

  ///外部图片源
  final Set<ImageSource> sources = {};

  ///项目图片源
  final Set<ImageSource> assetSources = {};

  ///需要增加在class中的代码
  StringBuffer codeBuffer = StringBuffer();

  ///通过语法检查后获取的有效数据
  final Map<ClassMember, String> mappingMemberToName = {};

  final Map<String, ClassMember> mappingNameToMember = {};

  final Map<String, ClassMember> mappingPathToMember = {};

  final Map<List<List<String>>, ClassMember> mappingPatternsToMember = {};

  final Map<List<String>, ClassMember> mappingArraysToMember = {};
}

///数据源处理
class ImageSourcePorc<E extends ImageResource> extends FileDataSourcePorc<E> {
  ImageSourcePorc(super.rootFolder);

  Set<ImageSource> get sources => resource.sources;

  @override
  build() {
    recursive(fileGetter: (f) {
      ///忽略隐藏文件与非指定格式照片
      if (!isValid(f)) {
        return;
      }
      final image = ImageSource.archive(f);
      sources.add(image);
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

  bool isValid(File f) => ImageSource.isImage(f.path);

  String get projPath => resource.projPath;

  Set<ImageSource> get assetSources => resource.assetSources;

  @override
  void build() {
    for (var bindingPath in bindings) {
      final path = '$projPath/$bindingPath';
      final directory = Directory(path);
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }
      directory.listSync().forEach((f) {
        final file = File(f.path);
        if (file.existsSync() && isValid(file)) {
          final image = ImageSource.archive(file);
          assetSources.add(image);
        }
      });
    }
    // handleOverwrite();
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

  String get defaultBaseName => ImageHandlerConfig.instance.defaultBaseName;

  String get defaultBasePath => ImageHandlerConfig.instance.defaultBasePath;

  bool get needMeta => ImageHandlerConfig.instance.needImageMeta;

  final Map<String, TopLevelVariableDeclaration> mappingNameToConstArray = {};

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
    resource.defineFile = target!;
    resource.declaration = declaration!;
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
        static const String $defaultBaseName = '$defaultBasePath';
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
    if (!mappingNameToMember.keys.contains(defaultBaseName)) {
      codeBuffer.writeln("""
      static const String  $defaultBaseName = '$defaultBasePath';
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
          if (name == defaultBaseName) {
            path += defaultBasePath;
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
  ImageCitePorc(super.projPath);

  final List<ImageSource> undefineAssetSources = [];

  final List<ClassMember> citedMember = [];

  final List<ClassMember> discardMember = [];

  Set<ImageSource> get sources => resource.sources;

  Set<ImageSource> get assetSources => resource.assetSources;

  bool get isOverwrite => ImageHandlerConfig.instance.isOverWrite;

  bool get cleanUndefine => ImageHandlerConfig.instance.cleanUndefineImage;

  bool get cleanNoCite => ImageHandlerConfig.instance.cleanNoCitedImageDefine;

  String get defineBaseName => ImageHandlerConfig.instance.defaultBaseName;

  StringBuffer get codeBuffer => resource.codeBuffer;

  String get binding => ImageHandlerConfig.instance.binding;

  String get className => ImageHandlerConfig.instance.className;

  DartFile get file => resource.defineFile;

  Map<String, ClassMember> get mappingNameToMember =>
      resource.mappingNameToMember;

  Map<ClassMember, String> get mappingMemberToName =>
      resource.mappingMemberToName;

  Map<String, ClassMember> get mappingPathToMember =>
      resource.mappingPathToMember;

  Map<List<List<String>>, ClassMember> get mappingPatternsToMember =>
      resource.mappingPatternsToMember;

  Map<List<String>, ClassMember> get mappingArraysToMember =>
      resource.mappingArraysToMember;

  ClassDeclaration get declaration => resource.declaration;

  @override
  void build() {
    ///处理声明是否引用
    handleCitedMember();

    ///移除没有引用的图片类成员
    removeNoCiteMember();

    ///移除没有声明的图片资源
    removeNoDefineAssetImage();

    ///处理图片命名冲突
    handleOverwrite();

    ///写入需要导入的资源文件
    writeSource();
  }

  ///因为内部成员只能是静态类，针对这些成员的引用只有一种格式
  ///即[className].[member]
  void handleCitedMember() {
    projDart.acceptPack = (pack) => pack.isMainProj;
    projDart.acceptDartString = (fs) => fs.contains(className);
    for (var f in projDart.flush()) {
      TestFile.fromString(f.fileString, visit: (node, token, controller) {
        ///寻找[MethodInvocation]&[PrefixedIdentifier]
        if (node is MethodInvocation && node.target?.toString() == className) {
          final name = node.methodName.toString();
          citedMember.add(mappingNameToMember[name]!);
        }
        if (node is PrefixedIdentifier && node.prefix.toString() == className) {
          final name = node.identifier.toString();
          citedMember.add(mappingNameToMember[name]!);
        }
      });
    }
    citedMember.add(mappingNameToMember[defineBaseName]!);
  }

  void removeNoCiteMember() {
    for (var member in mappingMemberToName.keys) {
      if (!citedMember.contains(member) && cleanNoCite) {
        final token = member.testToken(file);
        File(file.filePath).writeAsStringSync(
            file.latestFileString.substring(0, token.start) +
                ' ' * token.name.length +
                file.latestFileString.substring(member.end));
        discardMember.add(member);
      }
    }
  }

  void removeNoDefineAssetImage() {
    for (var source in assetSources) {
      if (_pathInclude(source) ||
          _arrayInclude(source) ||
          _patternInclude(source)) {
        continue;
      } else if (cleanUndefine) {
        source.delete();
        undefineAssetSources.add(source);
      }
    }
  }

  void handleOverwrite() {
    for (var source in sources.toSet()) {
      bool isDuplicate = assetSources
          .where(
            (s) =>
                s.fullImageName == source.fullImageName &&
                !undefineAssetSources.contains(s),
          )
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

  void writeSource() {
    for (var source in sources) {
      codeBuffer.writeln("""
        static const String  ${source.imageName} = '\$$defineBaseName/${source.fullImageName}';
      """);
      source.moveTo('$projPath/$binding');
    }

    final token = declaration.testToken(file);

    File(file.filePath).writeAsStringSync(
      DartFormatter().format(
        file.latestFileString.substring(0, token.end - 1) +
            codeBuffer.toString() +
            file.latestFileString.substring(token.end - 1),
      ),
    );
  }

  bool _pathInclude(ImageSource source) {
    for (var path in mappingPathToMember.keys) {
      if (Uri.parse(path).pathSegments.last == source.fullImageName) {
        final member = mappingPathToMember[path];
        return !discardMember.contains(member);
      }
    }
    return false;
  }

  ///pattern匹配具有三种格式
  ///A*
  ///A*B
  ///A*B1*BN*C
  bool _patternInclude(ImageSource source) {
    final name = source.fullImageName;
    bool isMatch = false;
    for (var patterns in mappingPatternsToMember.keys) {
      for (var pattern in patterns) {
        isMatch |= _patternMatch(pattern, name);
        if (isMatch) {
          final member = mappingPatternsToMember[patterns];
          isMatch = !discardMember.contains(member);
          break;
        }
      }
    }
    return isMatch;
  }

  bool _arrayInclude(ImageSource source) {
    final name = source.fullImageName;
    for (var array in mappingArraysToMember.keys) {
      for (var part in array) {
        if (name.toLowerCase().contains(part.toLowerCase())) {
          final member = mappingArraysToMember[array];
          return !discardMember.contains(member);
        }
      }
    }
    return false;
  }

  bool _patternMatch(List<String> pattern, String match) {
    final patternSlice = pattern.expand((e) => [...e.split(''), '']).toList();
    final matchSlice = match.split('');
    if (pattern.length > 1) {
      patternSlice.removeLast();
    }
    int ptr = 0;
    for (int i = 0; i < matchSlice.length; i++) {
      if (ptr > patternSlice.length - 1) {
        break;
      }
      if (patternSlice[ptr] == matchSlice[i]) {
        ptr += 1;
      } else if (patternSlice[ptr] == '') {
        if (ptr + 1 > patternSlice.length - 1) {
          ptr += 1;
          break;
        }
        if (patternSlice[ptr + 1] == matchSlice[i]) {
          ptr += 2;
        }
      } else {
        break;
      }
    }
    return ptr > patternSlice.length - 1;
  }
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
