import 'dart:math';

import 'package:analyzer_query/mini/log.dart';

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
}

class ResourceNode {
  final Uri uri;

  final List<ResourceNode> children = [];

  bool _isVirtual;

  ResourceNode? _parent;

  ResourceNode get header => _parent == null ? this : _parent!.header;

  String get path => uri.path;

  String get scheme => uri.scheme;

  ResourceNode? get parent => _parent;

  List<String> get pathSegments => uri.path.split('/');

  bool get isVirtual => _isVirtual;

  ResourceNode(this.uri, {bool isVirtual = false}) : _isVirtual = isVirtual;

  ///插入一个结点,返回根节点
  ResourceNode? insert(ResourceNode node) {
    header._insert(node);
    return header;
  }

  void _insert(ResourceNode node) {
    if (node.isEqual(this)) {
      analyzerLog('${node.path} is equal: $path');
      _isVirtual = false;
    }
    if (node.isParent(this)) {
      analyzerLog('${node.path} is parent: $path');
      _parent = node;
    }
    if (node.isChild(this)) {
      analyzerLog('${node.path} is child: $path');
      _addChild(node);
    }
    if (node.isBrother(this)) {
      analyzerLog('${node.path} is brother: $path');
      _unionNode(node);
      analyzerLog('virtual parent is: ${node.parent?.path}');
    }
  }

  bool isEqual(ResourceNode node) => node.path == path;

  ///当前节点是传入结点的父结点
  bool isParent(ResourceNode node) =>
      node.path.startsWith(path) &&
      node.pathSegments.length > pathSegments.length;

  ///当前节点是传入结点的子结点
  bool isChild(ResourceNode node) => node.isParent(this);

  ///两节点互为兄弟结点
  bool isBrother(ResourceNode node) =>
      !isParent(node) && !isChild(node) && !isEqual(node);

  void _addChild(ResourceNode node) {
    ResourceNode? nonBrother;
    for (var e in children) {
      if (!e.isBrother(node)) {
        nonBrother = e;
        break;
      }
    }

    if (nonBrother == null) {
      children.add(node);
      node._parent = this;
      return;
    }

    if (nonBrother.isChild(node)) {
      children.remove(nonBrother);
      children.add(node);
      node._parent = this;
      node.children.add(nonBrother);
      nonBrother._parent = node;
    }

    if (nonBrother.isParent(node)) {
      nonBrother._insert(node);
    }

    if (nonBrother.isEqual(node)) {
      nonBrother._isVirtual = false;
    }
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
}
