class Term {
  String _symbol;
  String get symbol => _symbol;
  Term(this._symbol);
}

class Constructor extends Term {
  int _arity;
  List<Term>? _args;

  Constructor(String symbol, this._arity) : super(symbol);

  @override
  String toString() {
    String args = "";
    if (_args == null || _args!.length == 0) {
      args = "-";
    } else {
      args = "${_args![0].toString()}";
      for (int i = 1; i < _args!.length; i++) {
        args = "$args, ${_args![i].toString()}";
      }
    }
    return "${super._symbol}($args)";
  }

  int get arity => _arity;
  List<Term>? get args => _args;

  void attachArgs(List<Term> args) {
    _args = args;
  }

  static Constructor generalPart(Set<Term> rightSide,
      Set<Constructor> constructors, Set<Variable> variables) {
    String symbol = rightSide.first.symbol;
    for (Term term in rightSide) {
      if (term.symbol != symbol || term is! Constructor) {
        throw Exception("Сouldn't find the general part");
      }
    }
    return _generalPart(rightSide, constructors, variables) as Constructor;
  }

  static Term _generalPart(
      Set<Term> terms, Set<Constructor> constructors, Set<Variable> variables) {
    String? symbol;
    Term? applicant;
    for (Term term in terms) {
      if (term is Constructor) {
        if (symbol == null) {
          symbol = term.symbol;
        } else if (term.symbol != symbol) {
          throw Exception("Сouldn't find the general part");
        }
      } else {
        applicant =
            variables.firstWhere((element) => element.symbol == term.symbol);
      }
    }
    if (applicant == null) {
      applicant = Constructor(
          terms.first.symbol,
          constructors
              .firstWhere((element) => element.symbol == terms.first.symbol)
              .arity);

      List<Term> args = [];
      for (int i = 0; i < (applicant as Constructor).arity; i++) {
        Set<Term> constructorsArgs = {};
        for (Term term in terms) {
          constructorsArgs.add((term as Constructor).args![i]);
        }
        args.add(_generalPart(constructorsArgs, constructors, variables));
      }
      applicant.attachArgs(args);
    }

    return applicant;
  }

  static Set<MultiEquation> border(
      Set<Term> terms, Set<Constructor> constructors, Set<Variable> variables) {
    return MultiEquation.compactify(
            _border(terms, constructors, variables).toList())
        .toSet();
  }

  static Set<MultiEquation> _border(
      Set<Term> terms, Set<Constructor> constructors, Set<Variable> variables) {
    Term? applicant;
    Set<MultiEquation> result = {};
    MultiEquation currentEquation = MultiEquation({}, {});
    for (Term term in terms) {
      if (term is Constructor) {
        currentEquation.addToRightSide(term);
      } else if (term is Variable) {
        applicant = variables.firstWhere((element) => element == term);
        currentEquation.addToLeftSide(term);
      }
    }
    result.add(currentEquation);
    if (applicant == null) {
      applicant = Constructor(
          terms.first.symbol,
          constructors
              .firstWhere((element) => element.symbol == terms.first.symbol)
              .arity);

      Set<MultiEquation> args = {};
      for (int i = 0; i < (applicant as Constructor).arity; i++) {
        Set<Term> constructorsArgs = {};
        for (Term term in terms) {
          constructorsArgs.add((term as Constructor).args![i]);
          currentEquation.addToRightSide(term);
        }
        args.addAll(_border(constructorsArgs, constructors, variables));
      }

      result.addAll(args);
    }

    return result;
  }

  bool operator ==(Object b) {
    if (b is! Constructor) {
      return false;
    }
    if (this.args == null) {
      return b.args == null;
    }
    if (b.args == null) {
      return false;
    }
    bool isEqual = true;
    this.args!.forEach((elementA) {
      isEqual = isEqual && b.args!.any((elementB) => elementB == elementA);
    });
    return this.symbol == b.symbol && isEqual;
  }
}

class Variable extends Term {
  Variable(String symbol) : super(symbol);
  @override
  String toString() {
    return super.symbol;
  }

  @override
  bool operator ==(Object b) {
    return b is Variable && this.symbol == b.symbol;
  }
}

class MultiEquation {
  Set<Variable> _leftSide;
  Set<Constructor> _rightSide;

  MultiEquation(this._leftSide, this._rightSide);

  void addToLeftSide(Variable x) {
    _leftSide.add(x);
  }

  void addToRightSide(Constructor x) {
    _rightSide.add(x);
  }

  Set<Variable> get leftSide => _leftSide;
  Set<Constructor> get rightSide => _rightSide;

  @override
  String toString() {
    return "$leftSide = $rightSide";
  }

  static List<MultiEquation> compactify(List<MultiEquation> system) {
    List<MultiEquation> tmpList = system;
    int i = 0;
    while (i < tmpList.length) {
      bool changed = false;
      for (int j = 0; j < tmpList.length; j++) {
        if (i != j) {
          if (tmpList[i].canMergeWith(tmpList[j])) {
            changed = true;
            var merged = tmpList[i].mergeWith(tmpList[j]);
            tmpList.add(merged);
            if (i > j) {
              tmpList.removeAt(i);
              tmpList.removeAt(j);
            } else {
              tmpList.removeAt(j);
              tmpList.removeAt(i);
            }
            break;
          }
        }
      }
      if (!changed) {
        i++;
      } else {
        i = 0;
      }
    }
    i = 0;
    while (i < tmpList.length) {
      if (tmpList[i].leftSide.isEmpty) {
        tmpList.removeAt(i);
        i = 0;
      } else {
        i++;
      }
    }
    return tmpList;
  }

  bool _equalTo(MultiEquation b) {
    bool equal = true;
    bool left = true;
    bool right = true;
    this.leftSide.forEach((elementA) {
      bool have = false;
      b.leftSide.forEach((elementB) {
        have = have || (elementA == elementB);
      });
      left = left && have;
    });

    this.rightSide.forEach((elementA) {
      bool have = false;
      b.rightSide.forEach((elementB) {
        have = have || (elementA == elementB);
      });
      right = right && have;
    });

    return (right && left);
  }

  bool operator ==(Object b) {
    if (b is! MultiEquation) {
      return false;
    }
    return this._equalTo(b);
  }

  MultiEquation mergeWith(MultiEquation b) {
    Set<Variable> leftSide = {};
    Set<Constructor> rightSide = {};

    this.leftSide.forEach((element) {
      leftSide.add(element);
    });
    this.rightSide.forEach((element) {
      rightSide.add(element);
    });

    b.leftSide.forEach((element) {
      leftSide.add(element);
    });
    b.rightSide.forEach((element) {
      rightSide.add(element);
    });

    return MultiEquation(leftSide, rightSide);
  }

  bool canMergeWith(MultiEquation b) {
    bool isLeftSidesEqual = false;
    bool isRightSidesEqual = false;
    this.leftSide.forEach((elementA) {
      b.leftSide.forEach((elementB) {
        if (elementA == elementB) {
          isLeftSidesEqual = true;
        }
      });
    });

    this.rightSide.forEach((elementA) {
      b.rightSide.forEach((elementB) {
        if (elementA == elementB) {
          isRightSidesEqual = true;
        }
      });
    });
    return isLeftSidesEqual || isRightSidesEqual;
  }
}
