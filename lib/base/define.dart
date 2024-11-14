import 'package:analyzer_query/proj_path/dart_file.dart';
import 'package:analyzer_query/proj_path/package.dart';

import 'resource.dart';

abstract class DataDefinePorc<E> extends ResourceHandler<E> {
  DataDefinePorc(this.projPath);

  final String projPath;

  late final ProjectDart projDart =
      ProjectDart(PackageConfig.fromProj(projPath));
}
