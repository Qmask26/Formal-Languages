import 'model.dart';

class Parser {
  Set<Constructor> extactConstructors(String input) {
    Set<Constructor> constructors = {};
    input
        .substring(input.indexOf("=") + 1)
        .trim()
        .split(",")
        .forEach((element) {
      String symbol = element.substring(0, element.indexOf("(")).trim();
      int arity = int.parse(
          element.substring(element.indexOf("(") + 1, element.indexOf(")")));

      constructors.add(Constructor(symbol, arity));
    });
    return constructors;
  }

  Set<Variable> extractVariables(String input) {
    Set<Variable> variables = {};
    input.substring(input.indexOf("=") + 1).split(",").forEach((element) {
      String symbol = element.trim();

      variables.add(Variable(symbol));
    });
    variables.add(Variable("x0"));
    return variables;
  }

  Constructor parseConstructor(
      String input, Set<Constructor> constructors, Set<Variable> variables) {
    if (input.indexOf("(") == -1) {
      throw Exception("Icnorrect input");
    }
    String cut = input.substring(input.indexOf(":") + 2).trim();
    Constructor constructor = Constructor(cut[0],
        constructors.firstWhere((element) => element.symbol == cut[0]).arity);

    List<Term> args = _parseTerms(
        input.substring(input.indexOf("(") + 1, input.lastIndexOf(")")).trim(),
        constructors,
        variables);
    constructor.attachArgs(args);
    return constructor;
  }

  List<Term> _parseTerms(
      String input, Set<Constructor> constructors, Set<Variable> variables) {
    List<Term> args = [];
    if (input.length <= 1) {
      args.add(variables.firstWhere((element) => element.symbol == input[0]));
    } else {
      for (int i = 0; i < input.length;) {
        if (constructors
            .any((element) => element.symbol.compareTo(input[i]) == 0)) {
          Constructor current = Constructor(
              input[i],
              constructors
                  .firstWhere(
                      (element) => element.symbol.compareTo(input[i]) == 0)
                  .arity);

          if (current.arity > 0) {
            int endOfConstructorsArgs = _endOfConstructorArgs(input, i + 1);
            current.attachArgs(_parseTerms(
                input.substring(i + 2, endOfConstructorsArgs),
                constructors,
                variables));

            args.add(current);
            i = endOfConstructorsArgs;
            continue;
          } else {
            args.add(current);
          }
        } else if (variables
            .any((element) => element.symbol.compareTo(input[i]) == 0)) {
          args.add(variables.firstWhere(
              (element) => element.symbol.compareTo(input[i]) == 0));
        }
        i++;
      }
    }
    return args;
  }

  int _endOfConstructorArgs(String constructor, int start) {
    int balance = 1;
    start++;
    for (int i = start; i < constructor.length; i++) {
      if (constructor[i] == "(") {
        balance++;
      } else if (constructor[i] == ")") {
        balance--;
      }
      if (balance == 0) {
        return i;
      }
    }
    return -1;
  }
}
