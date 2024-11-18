import 'asset.dart';

abstract class AssetConfig {
  final String binding;

  final String className;

  final String metaClassName;

  final String classDefinePath;

  final String baseName;

  final bool permitMetaClass;

  final bool needMeta;

  final bool needOverwrite;

  final bool cleanUndefineAsset;

  final bool cleanNoCitedAssetDefine;

  final bool needBinding;

  AssetConfig({
    required this.binding,
    required this.className,
    required this.metaClassName,
    required this.classDefinePath,
    required this.baseName,
    required this.permitMetaClass,
    required this.needMeta,
    required this.needOverwrite,
    required this.cleanUndefineAsset,
    required this.cleanNoCitedAssetDefine,
    required this.needBinding,
  });

  String get metaClassPatternName;

  String get metaClassArrayName;

  String get metaClassSource;

  String get baseNamePath;

  List<String> get bindings;
}

///图片处理运行起点与处理全流程共享变量存储
abstract class AssetResource extends BaseResource {
  AssetResource(
    super.projPath,
    this.config,
  );

  static E build<E extends AssetResource>({
    required String sourceFolder,
    required E resource,
  }) {
    return AssetSourceProc<E>(sourceFolder)
        .link(AssetBindingProc<E>())
        .link(AssetDestinationProc<E>())
        .link(AssetDefineProc<E>())
        .link(AssetCiteProc<E>())
        .exec(resource);
  }

  AssetSource archive(File f);

  bool pathIsTarget(String path);

  final AssetConfig config;

  Set<AssetSource> get sources => get<AssetSourceImpl>().sources;

  Set<AssetSource> get assetSources => get<AssetDestinationImpl>().assetSources;

  Map<ClassMember, String> get mappingMemberToName =>
      get<AssetDefineImpl>().mappingMemberToName;

  Map<String, ClassMember> get mappingNameToMember =>
      get<AssetDefineImpl>().mappingNameToMember;

  Map<String, ClassMember> get mappingPathToMember =>
      get<AssetDefineImpl>().mappingPathToMember;

  Map<ClassMember, String> get mappingMemberToPath =>
      get<AssetDefineImpl>().mappingMemberToPath;

  Map<PatternType, ClassMember> get mappingPatternsToMember =>
      get<AssetDefineImpl>().mappingPatternsToMember;

  Map<ArrayType, ClassMember> get mappingArraysToMember =>
      get<AssetDefineImpl>().mappingArraysToMember;

  StringBuffer get codeBuffer => get<AssetDefineImpl>().codeBuffer;

  ClassDeclaration get declaration => get<AssetDefineImpl>().declaration!;

  DartFile get targetFile => get<AssetDefineImpl>().targetFile!;
}
