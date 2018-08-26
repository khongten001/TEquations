unit UEquationTypes;

interface

uses
  SysUtils, ParseExpr, Complex;

// TEquation types

type
  TEquationError = class(Exception);

type
  TResult = record
    Solution: double;
    Residual: double;
    GuessesList: array of double;
  end;

type
  TAlgorithm = (Newton = 0, NewtonWithMultiplicity = 1, Secant = 2);

type
  IEquation = interface
    ['{B5477C50-96CE-496A-8658-8D8240237EA9}']
    function ElapsedMilliseconds: Int64;
    function EvaluateOn(const FPoint: double): double;
    function SolveEquation(Algoritm: TAlgorithm;
                           AInputList: array of double;
                           AGuessList: boolean = false): TResult;
  end;

type
  TAlgoritmCode = reference to function(const APoints: array of double;
                                        AGuess: boolean): TResult;

// TPolynomial types

type
  TPolyException = class(Exception);

type
  ArrOfDouble = array of double;

type
  TPolyResult = array of TComplex;

type
  TPolyAlgorithm = (Laguerre = 0, Bairstrow = 1);

type
  TPolyCode = reference to function(const APoints: array of double): TPolyResult;

type
  IPolyBase = interface
    ['{F04E0939-8122-4ACB-A296-3BBA1FC0B7DB}']
    function GetSolutions: TPolyResult;
    function EvaluateOn(Point: double): double;
  end;

implementation

end.
