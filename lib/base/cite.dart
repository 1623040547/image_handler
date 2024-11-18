import 'package:analyzer_query/proj_path/dart_file.dart';
import 'package:analyzer_query/proj_path/package.dart';

import 'resource.dart';

abstract class DataCiteProc<E extends BaseResource> extends ResourceHandler<E> {
  late final ProjectDart projDart =
      ProjectDart(PackageConfig.fromProj(resource.projPath));

  DataCiteProc();
}
