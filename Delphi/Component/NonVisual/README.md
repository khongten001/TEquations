# Installation

 1. Download the source code of the library in this repo ([link](https://github.com/albertodev01/TEquations/tree/master/Delphi/Source))
 2. Download the content of this folder, including the images that are needed if you want to have a nice component icon in the IDE. **Note**: it's better if you move the content of the `Parser` folder in the main folder where you have all the files. At the end, your folder should look like this:
 
 <p align="center"><img src="https://github.com/albertodev01/TEquations/blob/master/Delphi/Component/NonVisual/github_images/filelist.png" /></p>
 <p align="center">Green = component files | Red = library files</p>
 
 3. Open Delphi and do File > New > Package. Name it and Save All. Now in the project manager: Right click on the project name > Add > Select the `.pas` files (**not** the images) > Click open
 4. Go on Project > Resources and Images > Add the bmp/png files > Give them the following names:
 
 <p align="center"><img src="https://github.com/albertodev01/TEquations/blob/master/Delphi/Component/NonVisual/github_images/pmanager.png" /></p>
 
 5. Click Ok. Now save all and in the project manager: Right click on the project name > Compile > Right click on the project name > Build > Right click on the project name > Install.
 6. Done!

# Usage

Let's do an example. Create a new VCL or FMX project, add a Button, add a Memo and drop the `EquationSolver` component (set its `Name` property to `Solver`, just to type less characters!).

**Equation.**
In this section I'll show you how to solve a simple equation such as `f(x) = x^5-3x+1`. Select the component in the Form Designer and do the following:

 1. Set the `Kind` property to `etEquation` (it's the default option)
 2. Expand `(TEquationOptions)` and use one of the following settings (it depends if you want to use Newton or Secant)
 
  <p align="center"><img src="https://github.com/albertodev01/TEquations/blob/master/Delphi/Component/NonVisual/github_images/methods.png" /></p>
  
  3. Double click the button and type the following code:

```delphi
procedure TForm1.Button1Click(Sender: TObject);
var
  tmp: TSolution;
  r: double;
begin
  tmp := Solver.SolveEquation;

  Memo1.Lines.Add('x0 = ' + tmp.Solution.ToString);
  Memo1.Lines.Add('f(x0) = ' + tmp.Residual.ToString + sLineBreak);

  for r in tmp.GuessesList do
    Memo1.Lines.Add(r.ToString);
end;
```

I have created a VCL project but as I have already said, you'll get the same result on FMX. This is what I get:

<p align="center"><img src="https://github.com/albertodev01/TEquations/blob/master/Delphi/Component/NonVisual/github_images/result.png" /></p>
 
**Polynomial.**
In this section I'll show you how to solve a simple polynomial equation such as `f(x) = -x^4 - 2x^3 + 3x + 6`. You could have used the *Equation* mode I have explained above but for polynomials, this mode is more accurate and it calculates all the solutions. Select the component in the Form Designer and do the following:

1. Set the `Kind` property to `etPolynomial` 
 2. Expand `(TPolynomialOptions)` and use one of the following settings
 
  <p align="center"><img src="https://github.com/albertodev01/TEquations/blob/master/Delphi/Component/NonVisual/github_images/polysettings.png" /></p>
  
  3. Double click the button and type the following code:

```delphi
var
  tmp: TSolutions;
  i: Integer;
begin
  tmp := Solver.SolvePolynomial;
  Memo1.Lines.Add('Discriminant = ' + tmp.Discriminant.ToString);
  Memo1.Lines.Add(sLineBreak);

  for i := Low(tmp.Solutions) to High(tmp.Solutions) do
    Memo1.Lines.Add(tmp.Solutions[i].RealPart.ToString + ' + ' +
                    tmp.Solutions[i].ImagPart.ToString + 'i')
```

Please note that the `a` property in the component is associated to the parameter with the lowest degree. In fact I have set `a` to 6 (x^0) and **not** `a` to -1 (x^4). I have created a FMX project but as I have already said, you'll get the same result on VCL. This is what I get:

<p align="center"><img src="https://github.com/albertodev01/TEquations/blob/master/Delphi/Component/NonVisual/github_images/resultpoly.png" /></p>
