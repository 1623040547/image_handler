abstract class ResourceHandler<E> {
  E? _resource;

  E get resource {
    assert(_resource != null, 'Run exec() before call this method.');
    return _resource!;
  }

  ResourceHandler? _front;

  ResourceHandler? _next;

  ResourceHandler get header => _front == null ? this : _front!.header;

  void build();

  ResourceHandler link(ResourceHandler handler) {
    _next = handler;
    _front = handler;
    return handler;
  }

  ///始终从头节点开始执行
  E exec(E resource) {
    header._exec(resource);
    return header.resource;
  }

  void _exec(E resource) {
    _resource = resource;
    build();
    _next?._exec(resource);
  }
}
