import 'dart:io';
import 'dart:math';

///根据`pubspec.yaml`文件中声明的合法Uri，生成一棵资源路径树，
///记录Uri之间的关系以及各自所持有的文件。
class ResourceTree {
  final List<Uri> validUri;

  ResourceNode? _header;

  ResourceNode? get header => _header;

  ResourceTree(this.validUri) {
    for (var uri in validUri) {
      _header ??= ResourceNode(uri);
      _header?.insert(ResourceNode(uri));
    }
    _header = _header?.header;
  }

  ///传一个[uri]，以此`uri`为根节点,封闭一棵受此`uri`管理的子树
  ResourceNode manage(Uri uri) {
    final node = ResourceNode(uri, isVirtual: true);
    _header?.copy().insert(node);
    return node.copy().._parent = null;
  }
}

/// 资源结点
/// - [insert] : 插入一个资源结点，根据资源路径[uri]确定结点间关系，构成一棵双向树
/// - [header] : 资源树头结点
/// - [isVirtual] : 该结点是否实际绑定一个资源文件声明，如果为`false`，则说明该`uri`不包含在[ResourceTree]的`validUri`参数之中
class ResourceNode {
  final Uri uri;

  final List<ResourceNode> children = [];

  late final List<String> pathSegments = uri.path.split('/');

  late final List<String> pathSegmentsNonEmpty =
      uri.path.split('/').where((e) => e.isNotEmpty).toList();

  late final formatPath = pathSegmentsNonEmpty.join('/');

  bool _isVirtual;

  ResourceNode? _parent;

  ResourceNode get header => _parent == null ? this : _parent!.header;

  String get path => uri.path;

  String get scheme => uri.scheme;

  ResourceNode? get parent => _parent;

  bool get isVirtual => _isVirtual;

  ResourceNode(this.uri, {bool isVirtual = false}) : _isVirtual = isVirtual;

  ///插入一个结点,返回根节点
  ResourceNode? insert(ResourceNode node) {
    header._insert(node);
    return header;
  }

  void _insert(ResourceNode node) {
    if (node.isEqual(this)) {
      _isVirtual = node.isVirtual && isVirtual;
      node._parent = _parent;
      node.children.clear();
      node.children.addAll(children);
    }
    if (node.isParent(this)) {
      _parent = node;
    }
    if (node.isChild(this)) {
      _addChild(node);
    }
    if (node.isBrother(this)) {
      _unionNode(node);
    }
  }

  ///判断两个结点是否相等
  bool isEqual(ResourceNode node) => formatPath == node.formatPath;

  ///当前节点是传入结点的父结点
  bool isParent(ResourceNode node) =>
      node.path.startsWith(path) &&
      node.pathSegmentsNonEmpty.length > pathSegmentsNonEmpty.length;

  ///当前节点是传入结点的子结点
  bool isChild(ResourceNode node) => node.isParent(this);

  ///两节点互为兄弟结点
  bool isBrother(ResourceNode node) =>
      !isParent(node) && !isChild(node) && !isEqual(node);

  void _addChild(ResourceNode node) {
    for (var e in children.toList()) {
      if (e.isChild(node)) {
        children.remove(e);
        e._parent = node;
        node.children.add(e);
      }

      if (e.isParent(node)) {
        e._insert(node);
        return;
      }

      if (e.isEqual(node)) {
        e._isVirtual = node.isVirtual && isVirtual;
        node._parent = e._parent;
        node.children.clear();
        node.children.addAll(e.children);
        return;
      }
    }

    children.add(node);
    node._parent = this;
    return;
  }

  void _unionNode(ResourceNode node) {
    assert(_parent == null && node._parent == null);
    List<String> seg = pathSegments;
    List<String> seg1 = node.pathSegments;
    List<String> out = [];
    int index = min(seg.length, seg1.length);
    for (int i = 0; i < index; i++) {
      if (seg[i] == seg1[i]) {
        out.add(seg[i]);
      }
    }
    final String path = out.join('/');
    Uri uri = Uri(path: path, scheme: scheme);
    final virtual = ResourceNode(uri, isVirtual: true);
    _parent = virtual;
    node._parent = virtual;
    virtual.children.addAll([this, node]);
  }

  ///深拷贝当前[ResourceNode]及其子树,直接引用当前结点的亲结点
  ResourceNode copy() {
    final node = ResourceNode(uri, isVirtual: _isVirtual);
    node._parent = _parent;
    for (var e in children) {
      node.children.add(e.copy());
    }
    return node;
  }

  ///获取被当前结点及其子结点所管理的所有文件
  List<File> getManagedFile() {
    List<File> files = [];
    for (var e in children) {
      files.addAll(e.getManagedFile());
    }
    if (_isVirtual) {
      return files;
    }
    final file = File(uri.path);
    final dir = Directory(uri.path);
    if (file.existsSync()) {
      files.add(file);
    }
    if (dir.existsSync()) {
      List<FileSystemEntity> entities = dir.listSync();
      for (var e in entities) {
        final file = File(e.path);
        if (file.existsSync()) {
          files.add(file);
        }
      }
    }
    return files;
  }
}
