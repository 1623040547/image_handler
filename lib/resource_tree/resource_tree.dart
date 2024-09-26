///根据`pubspec.yaml`文件中声明的合法Uri，生成一棵资源路径树，
///记录Uri之间的关系以及各自所持有的文件。
class ResourceTree {
  final List<Uri> validUri;

  ResourceTree(this.validUri);
}
