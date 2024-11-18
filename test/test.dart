import 'package:resource_handler/common/resources.dart';
import 'package:resource_handler/dsl/asset/asset.dart';
import 'package:resource_handler/dsl/asset/image/image.dart';
import 'package:resource_handler/dsl/asset/svg/svg.dart';

void main() {
  // JsonResource.build(
  //   '/Users/mac/StudioProjects/resource_handler/test',
  //   '/Users/mac/StudioProjects/resource_handler',
  //   ResourceNames.selfResource,
  // );

  // ImageResource.build(
  //   '/Users/mac/StudioProjects/resource_handler/test',
  //   '/Users/mac/StudioProjects/diviner',
  //   ResourceNames.image,
  // );

  // SvgResource.build(
  //   '/Users/mac/StudioProjects/resource_handler/test',
  //   '/Users/mac/StudioProjects/my_healer',
  //   ResourceNames.svg,
  // );

  LottieResource.build(
    '/Users/mac/StudioProjects/resource_handler/test',
    '/Users/mac/StudioProjects/diviner',
    ResourceNames.lottie,
  );
}
