import 'package:analyzer_query/proj_path/package.dart';

String get configPath => ProjectCollection.instance.projPackages
    .expand((e) => e.packages)
    .firstWhere((e) => e.name == 'resource_handler')
    .projPath;

abstract class BaseResource {
  final String projPath;

  BaseResource(this.projPath);

  final Set<dynamic> _impls = {};

  void set(dynamic impl) {
    _impls.add(impl);
  }

  E get<E>() {
    for (var element in _impls) {
      if (element is E) {
        return element;
      }
    }
    throw Exception('no such element.');
  }
}

abstract class ResourceHandler<E extends BaseResource> {
  late final E resource;

  ResourceHandler? _front;

  ResourceHandler? _next;

  ResourceHandler get header => _front == null ? this : _front!.header;

  void build();

  ResourceHandler<E> link(ResourceHandler<E> handler) {
    _next = handler;
    handler._front = this;
    return handler;
  }

  ///始终从头节点开始执行
  E exec(E resource) {
    header._exec(resource);
    return header.resource as E;
  }

  void _exec(BaseResource resource) {
    this.resource = resource as E;
    build();
    _next?._exec(resource);
  }
}
