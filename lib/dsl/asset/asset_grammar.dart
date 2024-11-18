import 'asset.dart';

/// class [className] {
///
/// static const String [baseName] = '[basePath]';
///
/// static const String `name` = '[baseName]/`fullName`.png';
///
/// @[metaClassName](\
///   [metaClassPatternName]': [['iconSunSign', '.png']],\
///   [metaClassArrayName]': horoscopeTypeList ,\
/// )\
/// static String getByName(String name) => '[baseName]/$name.svg';
///
/// }
///
/// const horoscopeTypeList = [
///   '1',
///   '2',
///   '3',
/// ];
///
/// ///optional
/// class [metaClassName] {
///   final List<List<String>> [metaClassPatternName];
///
///   final List<String> [metaClassArrayName];
///
///   const ImageMeta({this.[metaClassPatternName] = const [], this.[metaClassArrayName] = const []});
/// }
///
class AssetGrammar {
  final String fileString;

  final String className;

  final String baseName;

  final String basePath;

  final String metaClassName;

  final String metaClassPatternName;

  final String metaClassArrayName;

  final bool permitMetaClass;

  final bool permitConstStringLiteral;

  AssetGrammar({
    required this.fileString,
    required this.className,
    required this.baseName,
    required this.basePath,
    required this.metaClassName,
    required this.permitMetaClass,
    required this.permitConstStringLiteral,
    required this.metaClassPatternName,
    required this.metaClassArrayName,
  });

  void compilationUnitRule(CompilationUnit target) {
    for (var member in target.declarations) {
      assert(
          member is ClassDeclaration || member is TopLevelVariableDeclaration);

      if (member is ClassDeclaration) {
        final name = member.name.toString();
        assert(name == className || name == metaClassName);
        if (name == className) {
          classDeclarationRule(member);
        }
        if (name == metaClassName) {
          assert(permitMetaClass);
        }
      }

      if (member is TopLevelVariableDeclaration) {
        assert(permitConstStringLiteral);
        assert(member.variables.variables.isNotEmpty);
        final initializer = member.variables.variables.first.initializer;
        assert(member.variables.variables.first.initializer is ListLiteral);
        listLiteralRule(initializer as ListLiteral);
      }
    }
  }

  void classDeclarationRule(ClassDeclaration target) {
    for (var member in target.members) {
      assert(member is FieldDeclaration || member is MethodDeclaration);
      dynamic flag;
      TestFile.fromString(
        fileString,
        node: member,
        visit: (node, _, controller) {
          if (node is SimpleStringLiteral) {
            flag = node.value;
            assert(Uri.tryParse(flag) != null);
            controller.stop();
          }
          if (node is StringInterpolation) {
            flag = node;
            controller.stop();
          }
        },
      );
      assert(flag != null);

      if (member is FieldDeclaration) {
        assert(member.isStatic);
        assert(member.fields.variables.isNotEmpty);
        final name = member.fields.variables.first.name.toString();
        assert((name != baseName && flag != basePath) ||
            (name == baseName && flag == basePath));
      }

      if (member is MethodDeclaration) {
        assert(member.isStatic);
      }

      for (var element in member.metadata) {
        annotationRule(element);
      }
    }
  }

  void listLiteralRule(ListLiteral target) {
    assert(target.elements.isNotEmpty);
    for (var outer in target.elements) {
      assert(outer is SimpleStringLiteral || outer is ListLiteral);
      if (outer is ListLiteral) {
        assert(outer.elements.isNotEmpty);
        for (var inner in outer.elements) {
          assert(inner is SimpleStringLiteral && inner.value.isNotEmpty);
        }
      }
      if (outer is SimpleStringLiteral) {
        assert(outer.value.isNotEmpty);
      }
    }
  }

  void annotationRule(Annotation annotation) {
    if (annotation.name.name != metaClassName) {
      return;
    }
    for (var expression in annotation.arguments?.arguments ?? []) {
      assert(expression is NamedExpression);
      final label = (expression as NamedExpression).name.label.name;
      assert(label == metaClassPatternName || label == metaClassArrayName);
      final innerExpression = expression.expression;
      assert(innerExpression is SimpleIdentifier ||
          innerExpression is ListLiteral);
      if (innerExpression is ListLiteral) {
        listLiteralRule(innerExpression);
      }
    }
  }
}
