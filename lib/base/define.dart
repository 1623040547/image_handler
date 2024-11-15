import 'package:analyzer_query/proj_path/dart_file.dart';
import 'package:analyzer_query/proj_path/package.dart';

import 'resource.dart';

abstract class DataDefineProc<E> extends ResourceHandler<E> {
  DataDefineProc(this.projPath);

  final String projPath;

  late final ProjectDart projDart =
      ProjectDart(PackageConfig.fromProj(projPath));
}
