import 'dart:io';

import 'package:analyzer_query/mini/log.dart';
import 'package:analyzer_query/proj_path/dart_file.dart';
import 'package:analyzer_query/tester.dart';
import 'package:resource_handler/common/grammar/grammar_1.dart';
import 'package:resource_handler/dsl/asset/data.dart';

import '../../base/base.dart';

typedef PatternType = List<List<String>>;

typedef ArrayType = List<String>;

///图片处理运行起点与处理全流程共享变量存储
class AssetResource {
  AssetResource(this.projPath);

  final String projPath;

  late DartFile defineFile;

  late ClassDeclaration declaration;

  List<String> get bindings => [];

  //ImageHandlerConfig
  String get className => "";

  String get metaClassName => "";

  bool get permitMetaClass => true;

  String get classDefinePath => "";

  String get baseName => "";

  String get baseNamePath => "";

  bool get needMeta => true;

  String get metaClassPatternName => "";

  String get metaClassArrayName => "";

  String get metaClassSource => "";

  bool get isOverwrite => false;

  bool get cleanUndefineAsset => true;

  bool get cleanNoCitedAssetDefine => true;

  AssetSource archive(File f) => AssetSource(name: '', tailFix: '');

  bool isValid(File f) => true;

  bool isTarget(String path) => true;

  ///外部图片源
  final Set<AssetSource> sources = {};

  ///项目图片源
  final Set<AssetSource> assetSources = {};

  ///需要增加在class中的代码
  StringBuffer codeBuffer = StringBuffer();

  ///通过语法检查后获取的有效数据
  final Map<ClassMember, String> mappingMemberToName = {};

  final Map<String, ClassMember> mappingNameToMember = {};

  final Map<String, ClassMember> mappingPathToMember = {};

  final Map<PatternType, ClassMember> mappingPatternsToMember = {};

  final Map<ArrayType, ClassMember> mappingArraysToMember = {};
}

class AssetSourceProc<E extends AssetResource> extends FileDataSourceProc<E> {
  AssetSourceProc(super.rootFolder);

  Set<AssetSource> get sources => resource.sources;

  @override
  build() {
    recursive(fileGetter: (f) {
      ///忽略隐藏文件与非指定格式照片
      if (!resource.isValid(f)) {
        return;
      }
      sources.add(resource.archive(f));
    });
  }
}

class AssetBindingProc<E extends AssetResource> extends YamlDataBindingProc<E> {
  AssetBindingProc(super.yamlPath);

  static const String keywordFlutter = "flutter";

  static const String keywordAsset = "assets";

  List<String> get bindings => resource.bindings;

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

class AssetDestinationProc<E extends AssetResource>
    extends DataDestinationProc<E> {
  List<String> get bindings => resource.bindings;

  String get projPath => resource.projPath;

  Set<AssetSource> get assetSources => resource.assetSources;

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
        if (file.existsSync() && resource.isValid(file)) {
          assetSources.add(resource.archive(file));
        }
      });
    }
  }
}

class AssetDefineProc<E extends AssetResource> extends DataDefineProc<E> {
  AssetDefineProc(super.projPath);

  List<DartFile> targetFiles = [];

  ClassDeclaration? declaration;

  ClassDeclaration? meta;

  DartFile? target;

  String get defineClassName => resource.className;

  String get defineClassPath => resource.classDefinePath;

  String get defaultBaseName => resource.baseName;

  String get defaultBasePath => resource.baseNamePath;

  String get metaClassName => resource.metaClassName;

  bool get needMeta => resource.needMeta;

  bool get permitMetaClass => resource.permitMetaClass;

  String get metaClassPatternName => resource.metaClassPatternName;

  String get metaClassArrayName => resource.metaClassArrayName;

  String get metaClassSource => resource.metaClassSource;

  final Map<String, TopLevelVariableDeclaration> mappingNameToConstArray = {};

  Map<ClassMember, String> get mappingMemberToName =>
      resource.mappingMemberToName;

  Map<String, ClassMember> get mappingNameToMember =>
      resource.mappingNameToMember;

  Map<String, ClassMember> get mappingPathToMember =>
      resource.mappingPathToMember;

  Map<PatternType, ClassMember> get mappingPatternsToMember =>
      resource.mappingPatternsToMember;

  Map<ArrayType, ClassMember> get mappingArraysToMember =>
      resource.mappingArraysToMember;

  StringBuffer get codeBuffer => resource.codeBuffer;

  @override
  void build() {
    handleClassDefine();
    final unit = declaration!.parent as CompilationUnit;
    resource.defineFile = target!;
    resource.declaration = declaration!;
    final grammar = Grammar1(
      fileString: target!.fileString,
      className: defineClassName,
      defaultBaseName: defaultBaseName,
      defaultBasePath: defaultBasePath,
      metaClassName: metaClassName,
      permitMetaClass: permitMetaClass,
      permitConstStringLiteral: permitMetaClass,
      metaClassPatternName: metaClassPatternName,
      metaClassArrayName: metaClassArrayName,
    );
    grammar.compilationUnitRule(unit);
    dataFromClassDefine();
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
      _handleClassDefineCreate();
      for (var file in targetFiles) {
        if (_handleClassDeclaration(file.latestFileString)) {
          target = file;
          break;
        }
      }
    }
    _handleClassMetaDefineCreate();
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
        if (node is ClassDeclaration && node.name.toString() == metaClassName) {
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
  void _handleClassDefineCreate() {
    final file = File('$projPath/$defineClassPath');
    if (file.existsSync()) {
      file.deleteSync();
    }
    file.createSync(recursive: true);
    file.writeAsStringSync(DartFormatter().format("""
      class $defineClassName {
        static const String $defaultBaseName = '$defaultBasePath';
      }
      
      ${needMeta ? metaClassSource : ""}
      """));
    projDart.acceptPack = (pack) => pack.isMainProj;
    projDart.acceptDartFile = (f) => f.filePath == file.path;
    projDart.acceptDartString = (s) => true;
    targetFiles.clear();
    targetFiles.addAll(projDart.flush());
  }

  ///处理[_imageMetaName],如果项目中不存在,则在指定位置创建
  void _handleClassMetaDefineCreate() {
    if (needMeta && meta == null) {
      File(target!.filePath).writeAsStringSync(DartFormatter().format("""
       ${target!.latestFileString}\n
       $metaClassSource
       """));
    }
  }

  ///从[defineClassName]定义中获取数据
  void dataFromClassDefine() {
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
      if (resource.isTarget(node.value)) {
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
      if (isDirect && resource.isTarget(path)) {
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
      if (e.name.name != metaClassName) {
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
        if (name == metaClassPatternName) {
          mappingPatternsToMember[list] = member;
        } else if (name == metaClassArrayName) {
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

class AssetCitePorc<E extends AssetResource> extends DataCiteProc<E> {
  AssetCitePorc(super.projPath);

  final List<AssetSource> undefineAssetSources = [];

  final List<ClassMember> citedMember = [];

  final List<ClassMember> discardMember = [];

  Set<AssetSource> get sources => resource.sources;

  Set<AssetSource> get assetSources => resource.assetSources;

  bool get isOverwrite => resource.isOverwrite;

  bool get cleanUndefine => resource.cleanUndefineAsset;

  bool get cleanNoCite => resource.cleanNoCitedAssetDefine;

  String get defineBaseName => resource.baseName;

  StringBuffer get codeBuffer => resource.codeBuffer;

  String get baseNamePath => resource.baseNamePath;

  String get className => resource.className;

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
                s.fullName == source.fullName &&
                !undefineAssetSources.contains(s),
          )
          .isNotEmpty;
      if (isDuplicate && !isOverwrite) {
        sources.remove(source);
        analyzerLog('Duplicate Source: ${source.fullName}');
      } else if (source.isValid()) {
        source.shrink();
      } else {
        sources.remove(source);
        analyzerLog('Invalid Source\'s Name: ${source.fullName}');
      }
    }
  }

  void writeSource() {
    for (var source in sources) {
      codeBuffer.writeln("""
        static const String  ${source.name} = '\$$defineBaseName/${source.fullName}';
      """);
      source.moveTo('$projPath/$baseNamePath');
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

  bool _pathInclude(AssetSource source) {
    for (var path in mappingPathToMember.keys) {
      if (Uri.parse(path).pathSegments.last == source.fullName) {
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
  bool _patternInclude(AssetSource source) {
    final name = source.fullName;
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

  bool _arrayInclude(AssetSource source) {
    final name = source.fullName;
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
