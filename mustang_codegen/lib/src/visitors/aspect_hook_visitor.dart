import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:mustang_codegen/src/codegen_constants.dart';
import 'package:mustang_core/mustang_core.dart';
import 'package:source_gen/source_gen.dart';

/// Visits all the methods for the aspect and generates appropriate hooks.
/// It is used by [AppAspectGenerator] to find method annotated with
/// @invoke in user written aspect
class AspectHookVisitor extends SimpleElementVisitor {
  const AspectHookVisitor(
    this.invokeHooks,
  );

  final List<MethodElement> invokeHooks;

  @override
  visitMethodElement(MethodElement element) {
    // if there are no annotations skip this method
    if (element.metadata.isNotEmpty) {
      final DartObject? invokeAnnotationObject =
          TypeChecker.fromRuntime(Invoke).firstAnnotationOfExact(element);
      _validation(element, invokeHooks, invokeAnnotationObject);
      if (invokeAnnotationObject != null) {
        invokeHooks.add(element);
      }
    }

    super.visitMethodElement(element);
  }

  void _validation(
    MethodElement element,
    List<MethodElement> invokeHooks,
    DartObject? type,
  ) {
    if (!element.returnType.isDartAsyncFuture) {
      throw InvalidGenerationSourceError(
        '''Error: All aspects must be async and return a Future
  example:
    @invoke 
    Future<void> run() async {
      print('sample aspect');
    }''',
        todo: 'use Future<T> as return type',
        element: element,
      );
    }

    if (invokeHooks.length > 1) {
      throw InvalidGenerationSourceError(
        'Error: Only 1 @${CodeGenConstants.invoke} annotation allowed per aspect. ${invokeHooks.length} Found: ${invokeHooks.join(', ')}',
        todo: 'Use @${CodeGenConstants.invoke} for only 1 method',
        element: element,
      );
    }
  }
}