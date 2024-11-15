import 'package:analyzer_query/proj_path/dart_file.dart';
import 'package:analyzer_query/proj_path/package.dart';

import 'resource.dart';

abstract class DataCitePorc<E> extends ResourceHandler<E> {
  final String projPath;

  late final ProjectDart projDart =
      ProjectDart(PackageConfig.fromProj(projPath));

  DataCitePorc(this.projPath);
}
