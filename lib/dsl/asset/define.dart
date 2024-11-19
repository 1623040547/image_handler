import 'asset.dart';

typedef PatternType = List<List<String>>;

typedef ArrayType = List<String>;

abstract class AssetDefineImpl<E extends AssetResource>
    extends DataDefineProc<E> {
  DartFile? targetFile;

  ClassDeclaration? declaration;

  final Map<ClassMember, String> mappingMemberToName = {};

  final Map<String, ClassMember> mappingNameToMember = {};

  final Map<String, ClassMember> mappingPathToMember = {};

  final Map<ClassMember, String> mappingMemberToPath = {};

  final Map<PatternType, ClassMember> mappingPatternsToMember = {};

  final Map<ArrayType, ClassMember> mappingArraysToMember = {};

  final StringBuffer codeBuffer = StringBuffer();

  AssetConfig get config => resource.config;

  Set<AssetSource> get sources => resource.sources;
}

class AssetDefineProc<E extends AssetResource> extends AssetDefineImpl<E> {
  AssetDefineProc();

  List<DartFile> targetFiles = [];

  ClassDeclaration? meta;

  String get projPath => resource.projPath;

  String get defineClassName => config.className;

  String get defineClassPath => config.classDefinePath;

  String get defaultBaseName => config.baseName;

  String get defaultBasePath => config.baseNamePath;

  String get metaClassName => config.metaClassName;

  bool get needMeta => config.needMeta;

  bool get permitMetaClass => config.permitMetaClass;

  String get metaClassPatternName => config.metaClassPatternName;

  String get metaClassArrayName => config.metaClassArrayName;

  String get metaClassSource => config.metaClassSource;

  final Map<String, TopLevelVariableDeclaration> mappingNameToConstArray = {};

  @override
  void build() {
    resource.set(this);
    handleClassDefine();
    final unit = declaration!.parent as CompilationUnit;
    final grammar = AssetGrammar(
      fileString: targetFile!.fileString,
      className: defineClassName,
      baseName: defaultBaseName,
      basePath: defaultBasePath,
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
        targetFile = file;
        break;
      }
    }
    if (declaration == null) {
      _handleClassDefineCreate();
      for (var file in targetFiles) {
        if (_handleClassDeclaration(file.latestFileString)) {
          targetFile = file;
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
      File(targetFile!.filePath).writeAsStringSync(DartFormatter().format("""
       ${targetFile!.latestFileString}\n
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
        targetFile!.fileString,
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
      if (resource.pathIsTarget(node.value)) {
        mappingPathToMember[node.value] = member;
        mappingMemberToPath[member] = node.value;
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
      if (isDirect && resource.pathIsTarget(path)) {
        mappingPathToMember[path] = member;
        mappingMemberToPath[member] = path;
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
