unit EquationSolverPlot;

interface

uses
  System.SysUtils, System.Classes, FMX.Types, FMX.Controls, UEquation,
  UEquationTypes, Polynomial, Fraction, System.Types, UITypes, FMX.Graphics;

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
  TAction = procedure(Sender: TObject) of object;

type
  TEquationSolverPlot = class(TControl)
  strict private
    FType: TEquationType;
    //Equation
    FEqOpt: TEquationOptions;
    //Polynomial
    FPolynomial: TPolynomialType;
    FPolyOpt: TPolynomialOptions;
    //Generic
    FColor, FDotColor: TAlphaColor;
    FDots: boolean;
    FSolved: boolean;
    FBorder: boolean;
    FLineFill: TStrokeBrush;
    FTransparent: boolean;
    FEvaluation: double;
    FZoomInOut: TAction;
    FEquationSolved: TAction;
    FPolynomialSolver: TAction;
    xmax, xmin, ymax, ymin: integer;
    procedure SetDots(Value: boolean);
    procedure SetDotColor(const Value: TAlphaColor);
    procedure SetBorder(Value: boolean);
    procedure SetTransparent(Value: boolean);
    procedure SetColor(const Value: TAlphaColor);
    function ScreenToLog(ScreenPoint: TPointF): TPointF;
    function LogToScreen(LogPoint: TPointF): TPointF;
  protected
    procedure Paint; override;
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
    procedure ZoomIn;
    procedure ZoomOut;
  published
    property Align;
    property Anchors;
    property ClipChildren;
    property ClipParent;
    property EquationColor: TAlphaColor read FColor write SetColor stored true;
    property DotColor: TAlphaColor read FDotColor write SetDotColor stored true;
    property Cursor;
    property Enabled;
    property Kind: TEquationType read FType write FType default etEquation;
    property EquationOpt: TEquationOptions read FEqOpt write FEqOpt;
    property PolynomialOpt: TPolynomialOptions read FPolyOpt write FPolyOpt;
    property Locked;
    property Height;
    property HitTest;
    property PlotBorder: boolean read FBorder write SetBorder default true;
    property Opacity;
    property Margins;
    property Dots: boolean read FDots write SetDots;
    property Position;
    property Size;
    property Scale;
    property RotationAngle;
    property RotationCenter;
    property Transparent: boolean read FTransparent write SetTransparent default false;
    property Visible;
    property Width;
    property OnEquationSolved: TAction read FEquationSolved write FEquationSolved;
    property OnPolySolved: TAction read FPolynomialSolver write FPolynomialSolver;
    property OnZoom: TAction read FZoomInOut write FZoomInOut;
    property OnClick;
    property OnDblClick;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseWheel;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnPainting;
    property OnPaint;
    property OnResize;
    property OnResized;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AlbertoComp.', [TEquationSolverPlot]);
end;

constructor TEquationSolverPlot.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FType := etEquation;
  FPolynomial := ptQuadratic;
  FLineFill := TStrokeBrush.Create(TBrushKind.Solid, $FF000000);

  FEqOpt := TEquationOptions.Create;
  FPolyOpt := TPolynomialOptions.Create;
  FEvaluation := 0;

  FTransparent := false;
  FBorder := true;
  FSolved := false;
  FDots := false;

  xmax := 5;
  ymax := 5;
  xmin := -5;
  ymin := -5;
end;

destructor TEquationSolverPlot.Destroy;
begin
  FEqOpt.Free;
  FPolyOpt.Free;
  FLineFill.Free;
  inherited;
end;

function TEquationSolverPlot.EvaluateOn(Point: double): double;
begin
  if FType = etEquation then
    Result := (TEquation.Create(FEqOpt.Equation) as IEquation).EvaluateOn(Point)
  else
    Result := 0;
end;

procedure TEquationSolverPlot.Paint;
var
  i: integer;
  distX, distY: single;
  logx, logy: double;
  Equation: IEquation;
  Poly: IPolyBase;
  CurrPoint, PrevPoint, assex, assey, Points: TPointF;
  MidPointS, MidPointC: TPointF;
begin
  //Setup
  Canvas.Stroke.Assign(FLineFill);

  if not FTransparent then
    Canvas.ClearRect(ClipRect, TAlphaColorRec.White);

  distX := (Width/2) / xmax;
  distY := (Height/2) / ymax;

  //Draw the grid
  Canvas.Stroke.Color := TAlphaColorRec.Silver;
  PrevPoint := TPointF.Create(distX, 0);
  CurrPoint := TPointF.Create(0, distY);

  for i := xmin to xmax do
   begin
    if (i = 0) then
     continue;

    Canvas.DrawLine(PrevPoint, TPointF.Create(PrevPoint.X, Height), 1);
    Canvas.DrawLine(CurrPoint, TPointF.Create(Width, CurrPoint.Y), 1);
    PrevPoint.X := PrevPoint.X + distX;
    CurrPoint.Y := CurrPoint.Y + distY;
   end;

  //Draw X and Y axes
  Canvas.Stroke.Color := TAlphaColorRec.Black;
  Canvas.Stroke.Thickness := 2;

  assex.X := 0; assex.Y := Height/2;
  assey.X := Width;  assey.Y := Height/2;
  Canvas.DrawLine(assex, assey, 1);
  assex.X := Width/2; assex.Y := 0;
  assey.X := Width/2; assey.Y := Height;
  Canvas.DrawLine(assex, assey, 1);
  Canvas.Stroke.Thickness := 1;

  //Draw the borders
  if FBorder then
    begin
      Canvas.DrawLine(TPointF.Create(0, 0), TPointF.Create(0, Height), 1);
      Canvas.DrawLine(TPointF.Create(Width, 0), TPointF.Create(Width, Height), 1);
      Canvas.DrawLine(TPointF.Create(0, Height), TPointF.Create(Width, Height), 1);
      Canvas.DrawLine(TPointF.Create(0, 0), TPointF.Create(Width, 0), 1);
    end;

  //Draw dots
  MidPointS := TPointF.Create( -3, (Height / 2) - 3);
  MidPointC := TPointF.Create((Width / 2) - 3, -3);

  for i := xmin to xmax + 1 do
   begin
     if (i = 0) then
      continue;

     if FDots then
       begin
         Canvas.Fill.Color := FDotColor;
         Canvas.FillEllipse(TRectF.Create(MidPointS, 6, 6), 1);
         Canvas.FillEllipse(TRectF.Create(MidPointC, 6, 6), 1);

         MidPointS.X := MidPointS.X + distX;
         MidPointC.Y := MidPointC.Y + distY;
       end;
   end;

  //Draw the function
  if FSolved then
    begin
      Canvas.Stroke.Color := FColor;
      PrevPoint := TPointF.Create(0, 0);
      logy := 0;

      if FType = etEquation then
        Equation := TEquation.Create(FEqOpt.Equation)
      else
        begin
          case FPolyOpt.PolyType of
            ptQuadratic: begin
                           Poly := TQuadratic.Create(FPolyOpt.a, FPolyOpt.b, FPolyOpt.c);
                         end;
            ptCubic:     begin
                           Poly := TCubic.Create(FPolyOpt.a, FPolyOpt.b, FPolyOpt.c, FPolyOpt.d);
                         end;
            ptQuartic:   begin
                           Poly := TQuartic.Create(FPolyOpt.a, FPolyOpt.b, FPolyOpt.c, FPolyOpt.d, FPolyOpt.e);
                         end;
          end;
        end;

      for i := 0 to Round(Width) do
        begin
          logx := ScreenToLog(TPointF.Create(i, 0)).X;

          if FType = etEquation then
            logy := Equation.EvaluateOn(logx)
          else
            case FPolyOpt.PolyType of
              ptQuadratic: begin
                             logy := (Poly as TQuadratic).EvaluateOn(logx);
                           end;
              ptCubic:     begin
                             logy := (Poly as TCubic).EvaluateOn(logx);
                           end;
              ptQuartic:   begin
                             logy := (Poly as TQuartic).EvaluateOn(logx);
                           end;
            end;

          Points := TPointF.Create(logx, logy);
          CurrPoint := TPointF.Create(i, LogToScreen(Points).Y);

          if (CurrPoint.Y >= 0) and (CurrPoint.Y <= Height) then
            Canvas.DrawLine(CurrPoint, PrevPoint, 1);
          PrevPoint := CurrPoint;
        end;
    end;
end;

function TEquationSolverPlot.ScreenToLog(ScreenPoint: TPointF): TPointF;
begin
  Result.X := xmin + (ScreenPoint.X / Width) * (xmax - xmin);
  Result.Y := ymin + (ymax - ymin) * (Height - ScreenPoint.Y) / Height;
end;

function TEquationSolverPlot.LogToScreen(LogPoint: TPointF): TPointF;
begin
  Result.X := round(Width * (LogPoint.X - xmin) / (xmax - xmin));
  Result.Y := round(Height - Height * (LogPoint.Y - ymin) / (ymax - ymin));
end;

procedure TEquationSolverPlot.SetBorder(Value: boolean);
begin
  FBorder := Value;
  Repaint;
end;

procedure TEquationSolverPlot.SetColor(const Value: TAlphaColor);
begin
  if FColor <> Value then
  begin
    FColor := Value;
    Repaint;
  end;
end;

procedure TEquationSolverPlot.SetDotColor(const Value: TAlphaColor);
begin
  if FColor <> Value then
  begin
    FDotColor := Value;
    Repaint;
  end;
end;

procedure TEquationSolverPlot.SetDots(Value: boolean);
begin
  FDots := Value;
  Repaint;
end;

procedure TEquationSolverPlot.SetEquationOptions(const AEquation: string;
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

function TEquationSolverPlot.SolveEquation: TSolution;
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

  FSolved := true;
  Repaint;

  if Assigned(FEquationSolved) then
    FPolynomialSolver(Self);
end;

procedure TEquationSolverPlot.SetPolynomial(const APoints: array of double);
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

procedure TEquationSolverPlot.SetTransparent(Value: boolean);
begin
  FTransparent := Value;
  Repaint;
end;

function TEquationSolverPlot.SolvePolynomial: TSolutions;
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

  FSolved := true;
  Repaint;

  if Assigned(FPolynomialSolver) then
    FPolynomialSolver(Self);
end;

procedure TEquationSolverPlot.ZoomIn;
begin
  if (xmax > 1) then
    begin
      xmax := xmax - 1;
      ymax := ymax - 1;
      xmin := xmin + 1;
      ymin := ymin + 1;
      Repaint;

      if Assigned(FZoomInOut) then
        FZoomInOut(Self);
    end;
end;

procedure TEquationSolverPlot.ZoomOut;
begin
  if (xmax <= 20) then
    begin
     xmax := xmax + 1;
     ymax := ymax + 1;
     xmin := xmin - 1;
     ymin := ymin - 1;
     Repaint;

     if Assigned(FZoomInOut) then
       FZoomInOut(Self);
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
