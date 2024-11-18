import 'package:analyzer_query/proj_path/dart_file.dart';
import 'package:analyzer_query/proj_path/package.dart';

import 'resource.dart';

abstract class DataDefineProc<E extends BaseResource>
    extends ResourceHandler<E> {
  DataDefineProc();

  late final ProjectDart projDart =
      ProjectDart(PackageConfig.fromProj(resource.projPath));
}
