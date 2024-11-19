import 'asset.dart';

abstract class AssetCiteProcImpl<E extends AssetResource>
    extends DataCiteProc<E> {
  String get projPath => resource.projPath;

  Set<AssetSource> get sources => resource.sources;

  Set<AssetSource> get assetSources => resource.assetSources;

  Map<String, ClassMember> get mappingNameToMember =>
      resource.mappingNameToMember;

  Map<ClassMember, String> get mappingMemberToName =>
      resource.mappingMemberToName;

  Map<String, ClassMember> get mappingPathToMember =>
      resource.mappingPathToMember;

  Map<ClassMember, String> get mappingMemberToPath =>
      resource.mappingMemberToPath;

  Map<List<List<String>>, ClassMember> get mappingPatternsToMember =>
      resource.mappingPatternsToMember;

  Map<List<String>, ClassMember> get mappingArraysToMember =>
      resource.mappingArraysToMember;

  ClassDeclaration get declaration => resource.declaration;

  DartFile get file => resource.targetFile;

  StringBuffer get codeBuffer => resource.codeBuffer;

  AssetConfig get config => resource.config;

  Function() get removeNoResourceBindings => resource.removeNoResourceBindings;
}

class AssetCiteProc<E extends AssetResource> extends AssetCiteProcImpl<E> {
  AssetCiteProc();

  final List<AssetSource> undefineAssetSources = [];

  final List<ClassMember> citedMember = [];

  final List<ClassMember> discardMember = [];

  bool get isOverwrite => config.needOverwrite;

  bool get cleanUndefine => config.cleanUndefineAsset;

  bool get cleanNoCite => config.cleanNoCitedAssetDefine;

  String get defineBaseName => config.baseName;

  String get baseNamePath => config.baseNamePath;

  String get className => config.className;

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

    removeNoResourceBindings.call();
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
          final member = mappingNameToMember[name]!;
          checkCitedResourceExist(member);
          citedMember.add(member);
        }
        if (node is PrefixedIdentifier && node.prefix.toString() == className) {
          final name = node.identifier.toString();
          final member = mappingNameToMember[name]!;
          checkCitedResourceExist(member);
          citedMember.add(member);
        }
      });
    }

    citedMember.add(mappingNameToMember[defineBaseName]!);
  }

  void checkCitedResourceExist(ClassMember member) {
    final path = '$projPath/${mappingMemberToPath[member]!}';
    if (!File(path).existsSync()) {
      final name = mappingMemberToName[member];
      analyzerLog('[Error] resource `$name` is missing. path: \n$path\n');
    }
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
        analyzerLog('remove no cite: ${mappingMemberToName[member]}');
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
        analyzerLog('remove no define: ${source.name}');
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
      } else if (!source.sourceIsValid()) {
        sources.remove(source);
        analyzerLog('Invalid Source\'s Name: ${source.fullName}');
      }
    }
  }

  void writeSource() {
    for (var source in sources) {
      if (mappingNameToMember.keys.contains(source.name)) {
        analyzerLog('Already define: ${source.name}');
      } else {
        codeBuffer.writeln("""
        static const String  ${source.name} = '\$$defineBaseName/${source.fullName}';
      """);
      }
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
      if (path == '$baseNamePath/${source.fullName}') {
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
