unit UEquation;

interface

uses
  Classes, ParseExpr, UEquationTypes, Generics.Collections, StrUtils, Polynomial,
  Complex, Math;

//Generic - Equations
type
  TEquation = class(TInterfacedObject, IEquation)
    strict private
      Fx: double;
      FIndex: integer;
      FParser: TExpressionParser;
      FAlgorithm: TDictionary<TAlgorithm, TAlgoritmCode>;
    protected
      procedure Init(); virtual;
    public
      constructor Create(const AEquation: string);
      destructor Destroy; override;
      function EvaluateOn(const FPoint: double): double;
      function EvalDerivative(FPoint: double): double;
      function SolveEquation(Algoritm: TAlgorithm;
                             AInputList: array of double;
                             AGuessList: boolean = false): TResult;
  end;

//Specific - Polynomials of 2nd, 3rd and 4th degree
type
  TPolyBase = class abstract
    private
      FPoly, FDerivative: TPolynomial;
      FDegree: integer;
    protected
      property GetPoly: TPolynomial read FPoly;
    public
      constructor Create(const coeff: array of double);
      function GetSolutions: TPolyResult; virtual; abstract;
      property GetDerivative: TPolynomial read FDerivative;
      property GetDegree: integer read FDegree;
  end;

  TQuadratic = class(TPolyBase)
    private
      Fa, Fb, Fc: double;
    public
      constructor Create(a, b, c: double);
      function GetSolutions: TPolyResult; override;
      function GetDiscriminant: double;
  end;

  TCubic = class(TPolyBase)
    private
      Fa, Fb, Fc, Fd: double;
    public
      constructor Create(a, b, c, d: double);
      function GetSolutions: TPolyResult; override;
      function GetDiscriminant: double;
  end;

  TQuartic = class(TPolyBase)
    private
      Fa, Fb, Fc, Fd, Fe: double;
    public
      constructor Create(a, b, c, d, e: double);
      function GetSolutions: TPolyResult; override;
      function GetDiscriminant: double;
  end;

  TPolyEquation = class(TPolyBase)
    private
      FAlgorithm: TDictionary<TPolyAlgorithm, TPolyCode>;
      FMethod: TPolyAlgorithm;
      procedure Init();
    public
      constructor Create(const coeff: array of double; AMethod: TPolyAlgorithm);
      destructor Destroy; override;
      function GetSolutions: TPolyResult; override;
  end;

implementation

{ TEquation }

constructor TEquation.Create(const AEquation: string);
begin
  //Setup the container
  FAlgorithm := TDictionary<TAlgorithm, TAlgoritmCode>.Create;
  Init();

  //Setup the parser
  FParser := TCstyleParser.Create;
  FParser.Optimize := true;
  FParser.DefineVariable('x', @Fx);
  FParser.DecimSeparator := '.';
  FIndex := FParser.AddExpression(AEquation);
  Fx := 0;
end;

destructor TEquation.Destroy;
begin
  FParser.Free;
  FAlgorithm.Free;
  inherited;
end;

function TEquation.EvaluateOn(const FPoint: double): double;
begin
  Result := FParser.AsFloat[FIndex];
end;

function TEquation.EvalDerivative(FPoint: double): double;
  const h = 1.0e-10;
begin
  Fx := FPoint + h;
  Result := FParser.AsFloat[FIndex];
  Fx := FPoint;
  Result := (Result - FParser.AsFloat[FIndex])/h;
end;

function TEquation.SolveEquation(Algoritm: TAlgorithm;
                                 AInputList: array of double;
                                 AGuessList: boolean): TResult;
begin
  Result := FAlgorithm.Items[Algoritm](AInputList, AGuessList);
end;

procedure TEquation.Init;
begin
  //Newton method
  FAlgorithm.Add(TAlgorithm.Newton,
                 function(const APoints: array of double;
                          AGuess: boolean): TResult
                 var n, n_max: integer;
                     diff, toll, der: double;
                 begin
                   if Length(APoints) <> 3 then
                     TEquationError.Create('The Points array must contain 3 parameters: the initial guess, the tolerance and the max. number of iterations');

                   //Points setup
                   Result.Solution := APoints[0];
                   toll := APoints[1];
                   n_max := Trunc(APoints[2]);

                   if AGuess then
                     begin
                       SetLength(Result.GuessesList, n_max);
                       Result.GuessesList[0] := Result.Solution;
                     end;

                   //Algorithm
                   n := 0;
                   diff := APoints[1] + 1;

                    while (diff >= toll) and (n < n_max) do
                      begin
                        der := EvalDerivative(Result.Solution);
                        if der = 0 then
                          raise TEquationError.Create('Found a f''(x) = 0');

                        Fx := Result.Solution;
                        diff := -FParser.AsFloat[0]/der;
                        Result.Solution := Result.Solution + diff;

                        if AGuess then
                          Result.GuessesList[n+1] := Result.Solution;

                        diff := abs(diff);
                        Inc(n);
                      end;

                   Result.Residual := FParser.AsFloat[0];
                   if AGuess then
                     SetLength(Result.GuessesList, n);
                 end);

  //Newton with multiplicity known method
  FAlgorithm.Add(TAlgorithm.NewtonWithMultiplicity,
                 function(const APoints: array of double;
                          AGuess: boolean): TResult
                 var n, n_max, r: integer;
                     diff, toll, der: double;
                 begin
                   if Length(APoints) <> 4 then
                     TEquationError.Create('The Points array must contain 4 parameters: the initial guess, the tolerance, the max. number of iterations and the multiplicity');

                   //Points setup
                   Result.Solution := APoints[0];
                   toll := APoints[1];
                   n_max := Trunc(APoints[2]);
                   r := Trunc(APoints[3]);

                   if AGuess then
                     begin
                       SetLength(Result.GuessesList, n_max);
                       Result.GuessesList[0] := Result.Solution;
                     end;

                   //Algorithm
                   n := 0;
                   diff := APoints[1] + 1;

                    while (diff >= toll) and (n < n_max) do
                      begin
                        der := EvalDerivative(Result.Solution);
                        if der = 0 then
                          raise TEquationError.Create('Found a f''(x) = 0');

                        Fx := Result.Solution;
                        diff := -r*(FParser.AsFloat[0]/der);
                        Result.Solution := Result.Solution + diff;

                        if AGuess then
                          Result.GuessesList[n+1] := Result.Solution;

                        diff := abs(diff);
                        Inc(n);
                      end;

                   Result.Residual := FParser.AsFloat[0];
                   if AGuess then
                     SetLength(Result.GuessesList, n);
                 end);

  //Secant
  FAlgorithm.Add(TAlgorithm.Secant,
                 function(const APoints: array of double;
                          AGuess: boolean): TResult
                 var n, n_max: integer;
                     diff, toll, den, xold, fold, fnew: double;
                 begin
                   if Length(APoints) <> 4 then
                     TEquationError.Create('The Points array must contain 4 parameters: the first guess, the second guess, the tolerance and the max. number of iterations');

                   n := 1;
                   xold := APoints[0];
                   Result.Solution := APoints[1];
                   toll := APoints[2];
                   n_max := Trunc(APoints[3]);

                   if AGuess then
                     begin
                       SetLength(Result.GuessesList, n_max);
                       Result.GuessesList[0] := Result.Solution;
                     end;

                   Fx := xold;
                   fold := FParser.AsFloat[0];
                   Fx := Result.Solution;
                   fnew := FParser.AsFloat[0];
                   diff := toll + 1;

                   while (diff >= toll) and (n < n_max) do
                     begin
                       den := fnew - fold;
                       if den = 0 then
                          raise TEquationError.Create('Denominator = 0');

                       diff := -(fnew*(Result.Solution - xold))/den;
                       xold := Result.Solution;
                       fold := fnew;
                       Result.Solution := Result.Solution + diff;
                       diff := abs(diff);
                       Inc(n);

                       if AGuess then
                          Result.GuessesList[n+1] := Result.Solution;

                       Fx := Result.Solution;
                       fnew := FParser.AsFloat[0];
                     end;

                   Result.Residual := FParser.AsFloat[0];
                   if AGuess then
                     SetLength(Result.GuessesList, n);
                 end);

end;

{ TPolyBase }

constructor TPolyBase.Create(const coeff: array of double);
begin
  inherited Create;

  FPoly := TPolynomial.Create(coeff);
  FDerivative := FPoly.GetDerivative;
  FDegree := FPoly.Degree;

  if FPoly.Coeff[FDegree] = 0 then
    raise TPolyException.Create('Highest power coefficient cannot be zero.');
end;

{ TQuadratic }

constructor TQuadratic.Create(a, b, c: double);
begin
  inherited Create([a, b, c]);

  Fa := c;
  Fb := b;
  Fc := a;
end;

function TQuadratic.GetDiscriminant: double;
begin
  Result := Fb*Fb - 4*Fa*Fc;
end;

function TQuadratic.GetSolutions: TPolyResult;
var delta: double;
begin

  delta := GetDiscriminant;
  SetLength(Result, 2);

  if (delta >= 0) then
   begin
     Result[0] := TComplex.Create( ((-Fb + sqrt(delta))/(2*Fa)), 0 );
     Result[1] := TComplex.Create( ((-Fb - sqrt(delta))/(2*Fa)), 0 );
   end
  else
   begin
     Result[0] := TComplex.Create( -Fb/(2*Fa) , (sqrt(abs(delta)))/(2*Fa) );
     Result[1] := TComplex.Create( -Fb/(2*Fa) , -(sqrt(abs(delta)))/(2*Fa) );
   end;

end;

{ TCubic }

constructor TCubic.Create(a, b, c, d: double);
begin
  inherited Create([a, b, c, d]);

  Fa := d;
  Fb := c;
  Fc := b;
  Fd := a;
end;

function TCubic.GetDiscriminant: double;
begin
  Result := Fc*Fc*Fb*Fb - 4*Fd*Fb*Fb*Fb - 4*Fc*Fc*Fc*Fa + 18*Fa*Fb*Fc*Fd - 27*Fd*Fd*Fa*Fa;
end;

function TCubic.GetSolutions: TPolyResult;
var a_over_3, q, q_cube, r, theta, sqrt_q: double;
    s, t, sqrt_d, term1, delta: double;
    a, b, c: double;

 function cbrt(const val: double): double;
  begin
    if (val >= 0) then
      Result := power(val, 1/3)
    else
      Result := -power(val*-1, 1/3)
  end;

const
 TWO_PI = 2*Pi;
 FOUR_PI = 4*Pi;

begin

   a := Fb/Fa;
   b := Fc/Fa;
   c := Fd/Fa;
   q := (3*b - a*a) / 9.0;
   r := (9*a*b - 27*c - 2*a*a*a) / 54.0;

   a_over_3 := a/3;
   q_cube := q*q*q;
   delta := q_cube + (r*r);
   SetLength(Result, 3);

     if (delta < 0) then
      begin

       theta := arccos(r/sqrt(-q_cube));
       sqrt_q := sqrt(-q);

       Result[0] := TComplex.Create( (sqrt_q*2*cos(theta/3) - a_over_3) , 0 );
       Result[1] := TComplex.Create( (sqrt_q*2*cos((theta+TWO_PI)/3) - a_over_3) , 0 );
       Result[2] := TComplex.Create( (sqrt_q*2*cos((theta+FOUR_PI)/3) - a_over_3) , 0 );

      end
     else
      begin

       if (delta > 0) then
        begin

         sqrt_d := sqrt(delta);
         s := cbrt(r+sqrt_d);
         t := cbrt(r-sqrt_d);
         term1 := a_over_3 + ((s+t)/2);

         Result[0] := TComplex.Create( ((s+t) - a_over_3) , 0 );
         Result[1] := TComplex.Create( (-term1) , (sqrt(3)*(-t+s)/2) );
         Result[2] := TComplex.Create( (-term1) , -Result[1].ImagPart );

        end
       else
        begin

         Result[0] := TComplex.Create( (2*cbrt(r) - a_over_3) , 0 );
         Result[1] := TComplex.Create( (cbrt(r) - a_over_3) , 0 );
         Result[2] := TComplex.Create( (cbrt(r) - a_over_3) , 0 );

        end;

      end;

end;

{ TQuartic }

constructor TQuartic.Create(a, b, c, d, e: double);
begin
  inherited Create([a, b, c, d, e]);

  Fa := e;
  Fb := d;
  Fc := c;
  Fd := b;
  Fe := a;
end;

function TQuartic.GetDiscriminant: double;
var k, phi, rho: double;
begin
  k := Fb*Fb*Fc*Fc*Fd*Fd - 4.0*Fd*Fd*Fd*Fb*Fb*Fb - 4.0*Fd*Fd*Fc*Fc*Fc*Fa +
       18.0*Fd*Fd*Fd*Fc*Fb*Fa - 27.0*Fd*Fd*Fd*Fd*Fa*Fa + 256.0*Fe*Fe*Fe*Fa*Fa*Fa;
  phi := Fe*(-4.0*Fc*Fc*Fc*Fb*Fb + 18.0*Fd*Fc*Fb*Fb*Fb + 16.0*Fc*Fc*Fc*Fc*Fa -
         80.0*Fd*Fc*Fc*Fb*Fa - 6.0*Fd*Fd*Fb*Fb*Fa + 144.0*Fd*Fd*Fa*Fa*Fc);
  rho := Fe*Fe*(-27*Fb*Fb*Fb*Fb + 144*Fc*Fb*Fb*Fa - 128*Fc*Fc*Fa*Fa - 192*Fd*Fb*Fa*Fa);

  Result := k + phi + rho;
end;

function TQuartic.GetSolutions: TPolyResult;
var a, b, c, d, e: TComplex;
    Q1, Q2, Q3, Q4, Q5, Q6, Q7, temp: TComplex;
begin

   a := TComplex.Create( Fa, 0 );
   b := TComplex.Create( Fb/Fa, 0 );
   c := TComplex.Create( Fc/Fa, 0 );
   d := TComplex.Create( Fd/Fa, 0 );
   e := TComplex.Create( Fe/Fa, 0 );

   Q1 := c * c - 3.0 * b * d + 12.0 * e;
   Q2 := 2.0 * c * c * c - 9.0 * b * c * d + 27.0 * d * d + 27.0 * b * b * e - 72.0 * c * e;
   Q3 := 8.0 * b * c - 16.0 * d - 2.0 * b * b * b;
   Q4 := 3.0 * b * b - 8.0 * c;

   temp := Q2 * Q2 / 4.0 - Q1 * Q1 * Q1;
   Q5 := TComplex.power( temp.Sqrt + Q2 / 2.0 , 1.0/3.0);
   Q6 := (Q1 / Q5 + Q5) / 3.0;
   temp := Q4 / 12.0 + Q6;
   Q7 := temp.Sqrt * 2.0;

   SetLength(Result, 4);
   temp := (4.0 * Q4 / 6.0 - 4.0 * Q6 - Q3 / Q7);
   Result[0] :=  ((-b - Q7 - temp.Sqrt) / 4.0);
   Result[1] :=  ((-b - Q7 + temp.Sqrt) / 4.0);
   temp := (4.0 * Q4 / 6.0 - 4.0 * Q6 + Q3 / Q7);
   Result[2] :=  ((-b + Q7 - temp.Sqrt) / 4.0);
   Result[3] :=  ((-b + Q7 + temp.Sqrt) / 4.0);

end;

{ TPolyEquation }

constructor TPolyEquation.Create(const coeff: array of double; AMethod: TPolyAlgorithm);
begin
  inherited Create(coeff);
  FAlgorithm := TDictionary<TPolyAlgorithm, TPolyCode>.Create;
  FMethod := AMethod;
  Init();
end;

destructor TPolyEquation.Destroy;
begin
  FAlgorithm.Free;
  inherited;
end;

function TPolyEquation.GetSolutions: TPolyResult;
begin
  Result := FAlgorithm.Items[FMethod](GetPoly.ToArray);
end;

procedure TPolyEquation.Init;
begin

  //Laguerre
  FAlgorithm.Add(TPolyAlgorithm.Laguerre,
                 function(const APoints: array of double): TPolyResult
                 begin
                   //Work in progress
                   SetLength(Result, 0);
                 end);

  //Bairstrow
  FAlgorithm.Add(TPolyAlgorithm.Bairstrow,
                 function(const APoints: array of double): TPolyResult
                 begin
                   //Work in progress
                   SetLength(Result, 0);
                 end);

end;

end.
