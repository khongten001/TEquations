unit EquationSolver;

interface

uses
  System.SysUtils, System.Classes, UEquation, UEquationTypes, Polynomial, Fraction;

type
  TEquationType = (etPolynomial, etEquation);

//Equation types
type
  TSolverType = (sNewton, sSecant);

type
  TSolution = record
    Solution: double;
    Residual: double;
    GuessesList: array of double;
  end;

type
  TEquationOptions = class(TPersistent)
    strict private
      FEquation: string;
      FPoint, Fa, Fb: double;
      FMaxSteps: integer;
      FTolerance: double;
      FSolver: TSolverType;
      FGuessList: boolean;
    public
      constructor Create;
      procedure Assign(Source: TPersistent); override;
    published
      property Equation: string read FEquation write FEquation;
      property Guess: double read FPoint write FPoint;
      property a: double read Fa write Fa;
      property b: double read Fb write Fb;
      property MaxSteps: integer read FMaxSteps write FMaxSteps default 20;
      property Tolerance: double read FTolerance write FTolerance;
      property Method: TSolverType read Fsolver write Fsolver default sNewton;
      property GuessesList: boolean read FGuessList write FGuessList;
  end;

//Polynomial types
type
  TPolynomialType = (ptQuadratic, ptCubic, ptQuartic);

type
  TComplex = record
    strict private
      FRealPart, FImagPart: double;
      FRealFraction, FImagFraction: TFraction;
    public
      constructor Create(real, imag: double);
      property RealPart: double read FRealPart write FRealPart;
      property ImagPart: double read FImagPart write FImagPart;
      property RealFraction: TFraction read FRealFraction write FRealFraction;
      property ImagFraction: TFraction read FImagFraction write FImagFraction;
  end;

type
  TSolutions = record
    Solutions: array of TComplex;
    Discriminant: double;
  end;

type
  TPolynomialOptions = class(TPersistent)
    strict private
      Fa, Fb, Fc, Fd, Fe: double;
      FPolyType: TPolynomialType;
    public
      constructor Create;
      procedure Assign(Source: TPersistent); override;
    published
      property PolyType: TPolynomialType read FPolyType write FPolyType default ptQuadratic;
      property a: double read Fa write Fa;
      property b: double read Fb write Fb;
      property c: double read Fc write Fc;
      property d: double read Fd write Fd;
      property e: double read Fe write Fe;
  end;

//Main component
type
  TEquationSolver = class(TComponent)
  strict private
    FType: TEquationType;
    //Equation
    FEqOpt: TEquationOptions;
    //Polynomial
    FPolynomial: TPolynomialType;
    FPolyOpt: TPolynomialOptions;
    //Generic
    FEvaluation: double;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function EvaluateOn(Point: double): double;
    //Equation methods
    procedure SetEquationOptions(const AEquation: string; FMethod: TSolverType; const Points: array of double);
    function SolveEquation: TSolution;
    //Polynomial methods
    procedure SetPolynomial(const APoints: array of double);
    function SolvePolynomial: TSolutions;
  published
    property Kind: TEquationType read FType write FType default etEquation;
    property EquationOpt: TEquationOptions read FEqOpt write FEqOpt;
    property PolynomialOpt: TPolynomialOptions read FPolyOpt write FPolyOpt;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AlbertoComp.', [TEquationSolver]);
end;

{ TEquationSolver }

constructor TEquationSolver.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FType := etEquation;
  FPolynomial := ptQuadratic;

  FEqOpt := TEquationOptions.Create;
  FPolyOpt := TPolynomialOptions.Create;
  FEvaluation := 0;
end;

destructor TEquationSolver.Destroy;
begin
  FEqOpt.Free;
  FPolyOpt.Free;

  inherited;
end;

function TEquationSolver.EvaluateOn(Point: double): double;
begin
  if FType = etEquation then
    Result := (TEquation.Create(FEqOpt.Equation) as IEquation).EvaluateOn(Point)
  else
    Result := 0;
end;

procedure TEquationSolver.SetEquationOptions(const AEquation: string;
FMethod: TSolverType; const Points: array of double);
begin
  FType := etEquation;
  FEqOpt.Equation := AEquation;

  case FMethod of
    sNewton: begin
               FEqOpt.Method := FMethod;
               FEqOpt.Guess := Points[0];
               FEqOpt.Tolerance := Points[1];
               FEqOpt.MaxSteps := Trunc(Points[2]);
             end;
    sSecant: begin
               FEqOpt.Method := FMethod;
               FEqOpt.a := Points[0];
               FEqOpt.b := Points[1];
               FEqOpt.Tolerance := Points[2];
               FEqOpt.MaxSteps := Trunc(Points[3]);
             end
  end;
end;

function TEquationSolver.SolveEquation: TSolution;
var
  Equation: IEquation;
  tmp: TResult;
  i: Integer;
begin
  if not(FType = etEquation) then
    raise Exception.Create('You haven''t set up the equation type! Current type is: etPolynomial');

  Equation := TEquation.Create(FEqOpt.Equation);

  case FEqOpt.Method of
    sNewton: begin
               tmp :=  Equation.SolveEquation(TAlgorithm.Newton,
                                              [FEqOpt.Guess, FEqOpt.Tolerance, FEqOpt.MaxSteps],
                                              FEqOpt.GuessesList);
             end;
    sSecant: begin
               tmp :=  Equation.SolveEquation(TAlgorithm.Secant,
                                              [FEqOpt.a, FEqOpt.b, FEqOpt.Tolerance, FEqOpt.MaxSteps],
                                              FEqOpt.GuessesList);
             end;
  end;

  Result.Solution := tmp.Solution;
  Result.Residual := tmp.Residual;

  if FEqOpt.GuessesList then
    begin
      SetLength(Result.GuessesList, Length(tmp.GuessesList));
      for i := Low(tmp.GuessesList) to High(tmp.GuessesList) do
        Result.GuessesList[i] := tmp.GuessesList[i];
    end;
end;

procedure TEquationSolver.SetPolynomial(const APoints: array of double);
begin
  FType := etPolynomial;

  case Length(APoints) of
    3: begin
         FPolyOpt.PolyType := ptQuadratic;
         FPolyOpt.a := APoints[0];
         FPolyOpt.b := APoints[1];
         FPolyOpt.c := APoints[2];
       end;
    4: begin
         FPolyOpt.PolyType := ptQuadratic;
         FPolyOpt.a := APoints[0];
         FPolyOpt.b := APoints[1];
         FPolyOpt.c := APoints[2];
         FPolyOpt.d := APoints[3];
       end;
    5: begin
         FPolyOpt.PolyType := ptQuadratic;
         FPolyOpt.a := APoints[0];
         FPolyOpt.b := APoints[1];
         FPolyOpt.c := APoints[2];
         FPolyOpt.d := APoints[3];
         FPolyOpt.e := APoints[4];
       end;
  end;
end;

function TEquationSolver.SolvePolynomial: TSolutions;
var
  Poly: IPolyBase;
  tmp: TPolyResult;
  i: integer;
begin
  if not(FType = etPolynomial) then
    raise Exception.Create('You haven''t set up the polynomial type! Current type is: etEquation');

  case FPolyOpt.PolyType of
    ptQuadratic: begin
                   SetLength(Result.Solutions, 2);
                   Poly := TQuadratic.Create(FPolyOpt.a, FPolyOpt.b, FPolyOpt.c);
                   Result.Discriminant := (Poly as TQuadratic).GetDiscriminant;
                 end;
    ptCubic:     begin
                   SetLength(Result.Solutions, 3);
                   Poly := TCubic.Create(FPolyOpt.a, FPolyOpt.b, FPolyOpt.c, FPolyOpt.d);
                   Result.Discriminant := (Poly as TCubic).GetDiscriminant;
                 end;
    ptQuartic:   begin
                   SetLength(Result.Solutions, 4);
                   Poly := TQuartic.Create(FPolyOpt.a, FPolyOpt.b, FPolyOpt.c, FPolyOpt.d, FPolyOpt.e);
                   Result.Discriminant := (Poly as TQuartic).GetDiscriminant;
                 end;
  end;

  tmp := Poly.GetSolutions;
  for i := Low(tmp) to High(tmp) do
    begin
      Result.Solutions[i].RealPart := tmp[i].RealPart;
      Result.Solutions[i].ImagPart := tmp[i].ImagPart;
      Result.Solutions[i].RealFraction := tmp[i].RealPartFraction;
      Result.Solutions[i].ImagFraction := tmp[i].ImagPartFraction;
    end;
end;

{ TComplex }

constructor TComplex.Create(real, imag: double);
begin
  FRealPart := real;
  FImagPart := imag;
  FRealFraction := TFraction.Create(real);
  FImagFraction := TFraction.Create(imag);
end;

{ TEquationOptions }

procedure TEquationOptions.Assign(Source: TPersistent);
var
  ASource: TEquationOptions;
begin
  if Source is TEquationOptions then
    begin
      ASource := TEquationOptions(Source);
      FEquation := ASource.FEquation;
      FPoint := ASource.FPoint;
      Fa := ASource.Fa;
      Fb := ASource.Fb;
      FMaxSteps := ASource.FMaxSteps;
      FTolerance := ASource.FTolerance;
      FSolver := ASource.FSolver;
    end
  else
    begin
      inherited Assign(Source);
    end;
end;

constructor TEquationOptions.Create;
begin
  FEquation := 'x';
  FPoint := 0;
  MaxSteps := 20;
  FTolerance := 1.0e-10;
  FSolver := sNewton;
  FGuessList := false;
end;

{ TPolynomialOptions }

procedure TPolynomialOptions.Assign(Source: TPersistent);
var
  ASource: TPolynomialOptions;
begin
  if Source is TPolynomialOptions then
    begin
      ASource := TPolynomialOptions(Source);
      FPolyType := ASource.FPolyType;
      Fa := ASource.Fa;
      Fb := ASource.Fb;
      Fc := ASource.Fc;
      Fd := ASource.Fd;
      Fe := ASource.Fe;
    end
  else
    begin
      inherited Assign(Source);
    end;
end;

constructor TPolynomialOptions.Create;
begin
  FPolyType := ptQuadratic;
  Fa := 0;
  Fb := 0;
  Fc := 0;
  Fd := 0;
  Fe := 0;
end;

end.
