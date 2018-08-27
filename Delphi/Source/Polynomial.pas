unit Polynomial;

interface

uses
 UEquationTypes, System.Math;

type
 TPolynomial = record
   private
     FPoly: array of double;
     FDegree: integer;
     function GetCoeff(Index: integer): double;
   public
     constructor Create(values: array of double);
     procedure Negate();
     function EvaluateOn(x: double): double;
     function GetDerivative: TPolynomial;
     function ToArray: ArrOfDouble;
     property Degree: integer read Fdegree;
     property Coeff[Index: integer]: double read GetCoeff;
 end;

implementation

{ TPolynomial }

constructor TPolynomial.Create(values: array of double);
var i, len: integer;
begin
  len := Length(values);
  if (len = 0) then
    raise TPolyException.Create('There must be at least one coefficient!');

  FDegree := len - 1;
  SetLength(FPoly, len);

  for i := Low(values) to High(values) do
    FPoly[i] := values[i];
end;

function TPolynomial.EvaluateOn(x: double): double;
begin
  Result := Poly(x, FPoly);
end;

function TPolynomial.GetCoeff(Index: integer): double;
begin
  if ((Index < 0) or (Index > Length(FPoly)-1)) then
    raise TPolyException.Create('Out of bounds.');
  Result := FPoly[Index];
end;

function TPolynomial.GetDerivative: TPolynomial;
var x: array of double;
    i: integer;
begin
  if (FDegree = 0) then
   begin
     Result := TPolynomial.Create([0])
   end
  else
   begin
     SetLength(x, Length(FPoly)-1);
     for i := Length(x)-1 downto 0 do
       x[i] := FPoly[i+1]*(i+1);

     Result := TPolynomial.Create(x);
   end;
end;

procedure TPolynomial.Negate;
var i: integer;
begin
  for i := Low(FPoly) to High(FPoly) do
    FPoly[i] := FPoly[i]*-1;
end;

function TPolynomial.ToArray: ArrOfDouble;
var i: integer;
begin
  SetLength(Result, Length(FPoly));
  for i := Low(FPoly) to High(FPoly) do
    Result[i] := FPoly[i];
end;

end.
