class AssetSource {
  String name = '';

  String tailFix = '';

  AssetSource({
    required this.name,
    required this.tailFix,
  });

  String get fullName => '$name.$tailFix';

  void moveTo(String path) {}

  void delete() {}

  void shrink(){}

  bool isValid() => true;
}
