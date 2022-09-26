import 'dart:io';

import 'src/parser.dart';
import 'src/model.dart';
import 'src/unifier.dart';

void main(List<String> arguments) {
  if (arguments.length == 0) {
    return;
  }
  File input = new File("tests/${arguments[0]}");
  List<String> inputContent = input.readAsLinesSync();

  Parser parser = Parser();
  Unifier unifier = Unifier();

  Set<Constructor> constructors = (parser.extactConstructors(inputContent[0]));

  Set<Variable> variables = (parser.extractVariables(inputContent[1]));

  Constructor firstTerm =
      parser.parseConstructor(inputContent[2], constructors, variables);

  Constructor secondTerm =
      parser.parseConstructor(inputContent[3], constructors, variables);

  List<MultiEquation> equationsSystem = [];

  equationsSystem.add(MultiEquation(
      <Variable>{variables.firstWhere((element) => element.symbol == "x0")},
      <Constructor>{firstTerm, secondTerm}));

  for (Variable variable in variables) {
    if (variable.symbol == 'x0') {
      continue;
    }
    equationsSystem.add(MultiEquation(<Variable>{variable}, <Constructor>{}));
  }
  print("Input data: {");
  equationsSystem.forEach(
    (element) {
      print("   $element");
    },
  );
  print("}");
  print("Result: {");
  try {
    unifier.unify(equationsSystem, constructors, variables).forEach((element) {
      print("   $element");
    });
    print("}");
  } catch (_) {
    print("   Unification failed");
    print("}");
  }
}
