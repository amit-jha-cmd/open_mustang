import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';

class ServiceMethodVisitor extends SimpleElementVisitor {
  ServiceMethodVisitor({
    required this.overrides,
    required this.imports,
  });

  List<String> overrides;
  List<String> imports;

  @override
  visitMethodElement(MethodElement element) {
    List<ElementAnnotation> annotations = element.declaration.metadata;
    if (annotations.isNotEmpty) {
      DartType type = annotations.first.computeConstantValue()!.type!;
      String annotationImport = type.element?.location?.encoding ?? '';
      annotationImport = annotationImport.split(';').first;
      imports.add("import '$annotationImport';");
      String methodName = '${element.displayName}(';
      if (element.parameters.isNotEmpty) {
        element.parameters.toList().forEach((parameter) {
          String import = parameter.type.element?.location?.encoding ?? '';
          if (parameter.declaration.isOptional) {
            methodName =
                '$methodName${parameter.displayName}: ${parameter.displayName}, ';
          } else {
            methodName = '$methodName${parameter.displayName}, ';
          }
          import = import.split(';').first;
          if (import.contains('wrench_flutter_common')) {
            imports.add(
                "import 'package:wrench_flutter_common/flutter_common.dart';");
          } else {
            List<String> importSplit = import.split('/');
            importSplit.remove('lib');
            import = importSplit.join('/');
            imports.add("import '$import';");
          }
        });
      }
      methodName = '$methodName)';
      String declaration = element.declaration.toString();
      declaration = declaration.split('*').join('');
      Map<String, String> methodsWithDeclaration = {};
      methodsWithDeclaration.addEntries([MapEntry(declaration, methodName)]);
      List<MapEntry<String, String>> methods =
          methodsWithDeclaration.entries.toList();
      for (MapEntry<String, String> method in methods) {
        overrides.add('''
      @override
      ${method.key}  ${element.isAsynchronous ? "async" : ""} {
        try {
          if(${type.getDisplayString(withNullability: false)}Hook().preHook()) {
            return super.${method.value};
          }
          return ${type.getDisplayString(withNullability: false)}Hook().postHook();
        } catch (e, stackTrace) {
          return ${type.getDisplayString(withNullability: false)}Hook().onException(e, stackTrace,);
        }
      }
      ''');
      }
    }
    return super.visitMethodElement(element);
  }
}
