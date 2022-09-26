import 'model.dart';

class Unifier {
  List<MultiEquation> unify(List<MultiEquation> system,
      Set<Constructor> constructors, Set<Variable> variables) {
    List<MultiEquation> resultingSystem = [];
    while (system.length > 0) {
      MultiEquation current = system[_chooseEquation(system)];
      if (current.rightSide.isEmpty) {
        resultingSystem.add(current);
        system.remove(current);
        continue;
      }
      Constructor generalPart =
          Constructor.generalPart(current.rightSide, constructors, variables);
      Set<MultiEquation> border =
          Constructor.border(current.rightSide, constructors, variables);
      MultiEquation modified = MultiEquation(current.leftSide, {generalPart});
      resultingSystem.add(modified);
      border.forEach((element) {
        system.add(element);
      });
      system.remove(current);
      system = MultiEquation.compactify(system);
    }
    return resultingSystem;
  }

  int _chooseEquation(List<MultiEquation> system) {
    int result = -1;
    for (int i = 0; i < system.length; i++) {
      bool fit = true;
      if (system[i].rightSide.isEmpty) {
        continue;
      }
      for (int j = 0; j < system.length; j++) {
        if (j == i) {
          continue;
        }
        bool anyPresent = false;
        system[i].leftSide.forEach((element) {
          anyPresent = anyPresent ||
              _isVariablePresentInMultiEquation(element, system[j]);
        });
        if (anyPresent) {
          fit = false;
          break;
        }
      }
      if (fit) {
        return i;
      }
    }
    if (result == -1) {
      for (int i = 0; i < system.length; i++) {
        bool fit = true;
        for (int j = 0; j < system.length; j++) {
          if (j == i) {
            continue;
          }
          bool anyPresent = false;
          system[i].leftSide.forEach((element) {
            anyPresent = anyPresent ||
                _isVariablePresentInMultiEquation(element, system[j]);
          });
          if (anyPresent) {
            fit = false;
            break;
          }
        }
        if (fit) {
          return i;
        }
      }
    }

    if (result == -1) {
      throw Exception("Unification failed");
    }
    return result;
  }

  bool _isVariablePresentInMultiEquation(Variable v, MultiEquation me) {
    return _isVariablePresentInSet(v, me.leftSide) ||
        _isVariablePresentInSet(v, me.rightSide);
  }

  bool _isVariablePresentInSet(Variable v, Set<Term> terms) {
    bool present = false;
    terms.forEach((element) {
      if (element is Variable) {
        present = present || v == element;
      } else if (element is Constructor) {
        if (element.args != null) {
          present =
              present || _isVariablePresentInSet(v, element.args!.toSet());
        }
      }
    });
    return present;
  }
}
