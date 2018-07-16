# Installation

**Short Version**

You just need to import the content of this folder and add `UEquation` to the uses clause. That's all!

**Long version**

Here's a step by step installation guide. I am creating a new VCL project just as example but the steps are the same for any other project type.

 1. Download this folder `Source` (I'd recommend to place it in the same folder as your main project)
 2. File > New > VCL Forms Application. Save the newly created project.
 3. Project > Add to project > Reach the `Source` folder > Open `Parser` and import the four .pas files
 4. Project > Add to project > Reach the `Source` folder > Import the five .pas files
 5. In the main unit add `UEquation` to the uses and you're done!

# Generic usage

The `Equation` class is a generic equation solver that takes the expression (as string) in input. Please note that an expression must be properly written otherwise an exception will be raised (for example `2*x` is good but `2x` not). Let's see an example where we try to solve `f(x) = e^x-2x^2`:

``` delphi
procedure Test;
var
  AEquation: IEquation;
  AResult: TResult;
  i: integer;
begin

  AEquation := TEquation.Create('exp(x)-2*x^2');
  try
    AResult := AEquation.SolveEquation(TAlgorithm.Newton, [1.3, 1.0e-10, 20], true);
    //read below to understand the meaning of the input parameters of solveEquation()

    Writeln('Solution [x0] = ' + AResult.Solution.ToString);
    Writeln('Residual [f(x0)] = ' + AResult.Residual.ToString);

    Writeln(sLineBreak + 'Residuals list:');
    for i := Low(AResult.GuessesList) to High(AResult.GuessesList) do
      Writeln(AResult.GuessesList[i].ToString);

  except
    on E : Exception do
     Writeln(E.Message);
  end;
  
end;

(* 
====== OUTPUT ======

Solution [x0] = 1,48796206549818
Residual [f(x0)] = -8,17124146124115E-14

Residuals list:
1,3
1,4889957706899
1,48796191447505
1,48796206549823
*)
```

Please note that here I've used the interface `AEquation: IEquation` to gain the reference counting mechanism and the automatic memory managment of the object. It's also possible to declare `AEquation: TEquation` but now of course you have to use the classic `try ... finally` block! 

  - The interface type `IEquation` offers the methods `SolveEquation` and `EvaluateOn`
  - The non interface type `TEquation` offers the methods `SolveEquation`, `EvaluateOn` and `EvalDerivative`

This library implements some root finding algorithms (and maybe more in the future) and each of them need some input numbers to run. Considering again the example `f(x) = e^x-2x^2` let's see which algorithms we can use:

 - Newton's method.
   ```delphi
   AEquation.SolveEquation(TAlgorithm.Newton, [1.3, 1.0e-10, 20], true)
   ```
     - First parameter: the algorithm type `Newton`
     - Second parameter: an array containing: the initial guess, the tolerance and the max. number of iterations
     - Third parameter: true or false if you want to generate a table with the x0 calculated during the calculation process
     
  - Newton's method with multiplicity.
    ```delphi
    AEquation.SolveEquation(TAlgorithm.NewtonWithMultiplicity, [1.3, 1.0e-10, 20, 1], true)
    ```
     - First parameter: the algorithm type `NewtonWithMultiplicity`
     - Second parameter: an array containing: the initial guess, the tolerance, the max. number of iterations and the multiplicity
     - Third parameter: see above
     
  - Newton's method with multiplicity.
    ```delphi
    AResult := AEquation.SolveEquation(TAlgorithm.Secant, [1, 2, 1.0e-10, 20], true);
    ```
     - First parameter: the algorithm type `Secant`
     - Second parameter: an array containing: the lower bound, the upper bound, the tolerance and the max. number of iterations
     - Third parameter: see above

# Specific usage

The `Equation` class is general purpose and it uses root finding algorithms (they may not converge to a solution) that produce an approximation of the solution. If you have to deal with polynomials you can use `Equation` but it would be better if you used one of the following classes:

 - `Quadratic`: second degree polynomials solver
 - `Cubic`: third degree polynomials solver
 - `Quartic`: fourth degree polynomials solver
 - `PolyEquation`: generic polynomials solver
 
 Let's see an example with a cubic equation (3rd degree polynomial): 
 
 ```delphi
procedure Test;
var
  AEquation: TPolyBase;
  AResult: TPolyResult;
  i: integer;
begin

  AEquation := TCubic.Create(5, -3, 1, 2);
  try
    AResult := AEquation.GetSolutions(); 
  
    for i := Low(AResult) to High(AResult) do
      Writeln(AResult[i].ToString);
  finally
    AEquation.Free;
  end;

end;
 
(*
====== OUTPUT ======
   
-1,93877822138267 + 0i
0,719389110691337 + 0,878607528100661i
0,719389110691337 - 0,878607528100661i
*)
 ```
 
You can also use an the interface `IPolyBase` and I really suggest that to you because it will make your code shorter and more readable. An equivalent implementation of the code seen above would be the following:

```delphi
procedure Test;
var
  AEquation: IPolyBase;
  AResult: TPolyResult;
  i: integer;
begin

  AEquation := TCubic.Create(5, -3, 1, 2);
  AResult := AEquation.GetSolutions();

  for i := Low(AResult) to High(AResult) do
    Writeln(AResult[i].ToString);
    
end.
```
 
The `TPolyResult` variable is a vector of `Complex` so the result is in the format `realPart + imagPart`; the usage of the other classes is identical. Please note that the parameters in input start from the coefficient with the **lower** degree so `2x^3 + x^2 - 3x + 5` is `TCubic.Create(5, -3, 1, 2)` (the reverse order). Another way:

```delphi
AEquation := TEquation.Create('2*x^3+x^2-3*x+5');
AResult := AEquation.SolveEquation(TAlgorithm.Secant, [-2, -1.5, 1.0e-10, 20], true);
```

There's also the `PolyEquation` class that finds every root, real and complex, of a given polynomial (whose degree should be equal or greater than 1). This root finding algorithm gives you an approximation of the solutions; of course it can be used with polynomials of degree 2, 3 and 4 as well but my recommendation is:

  - Use `Quadratic`, `Cubic`, `Quartic` for 2nd, 3rd and 4th degree polynomials (you won't have an approximation of the solutions)
  - Use `PolyEquation` for polynomials with a degree equal or higher than 5 (you'll get an approximation of the solutions)
  
Of course, if you wish, you can use the `Equation` as you've seen above and use a generic root finding algorithm. The usage is exactly the same as the other polynomial classes but with the exception that you have an extra parameter: the algorithm that has to be used to find the roots.

```delphi
//f(x) = x^5 - 2x^3 + x^2 - 3x + 5
AEquation := TPolyEquation.Create([5, -3, 1, -2, 0, 1], TPolyAlgorithm.Laguerre);
try
  AResult := AEquation.GetSolutions;

  for i := Low(AResult) to High(AResult) do
    Writeln(AResult[i].ToString);
finally
  AEquation.Free;
end;
```

The algorithms supported in this class are Laguerre and Bairstrow but you can create new ones just adding members to the algorithm container inside the class (which is a `TDictionary`).

# Notes

I have added a `Fraction` class that may be useful if you have to deal with fractions as input/output. Please note that the algorithms will output an **approximated fractional representation**, which means this:

```delphi
s := TFraction.Create( sqrt(3) );
Writeln(s.ToString);

// OUTPUT: 191861/110771
```

The square root of 3 is an irrational number and it cannot be represented as fraction but here we get that `sqrt(3) = 191861/110771`!  The reason is that the algorithm computes the square root of 3, it takes the first 10 decimal digits (1.*73205080757*) and then it calculates the fractional value of 1.73205080757.

I'll repeat it: keep in mind that this class gives an approximated fractional representation. Anyway this class can be useful in some cases:

```delphi
try
  s := TFraction.Create(5.675);
  //OUTPUT: 227/40
  Writeln(s.ToString);

  t := TFraction.Create('24/62');
  //OUTPUT: 24/62
  Writeln(t.ToString);
  t.Reduce;
  //OUTPUT: 12/31
  Writeln(t.ToString);
  //OUTPUT: 0.38709677419...
  Writeln(t.ToDouble.ToString);
except
  on E : Exception do
    Writeln(E.Message);
end;
```

You can also execute common operations between fraction objects such as:

```delphi
try
  s := TFraction.Create(5.675);
  s.Inverse;

  t := TFraction.Create('1/3');
  s.Negate;

  u := s + t;
  u.Reduce;

  Writeln(u.ToString);
  //OUTPUT: 107/681

except
  on E : Exception do
    Writeln(E.Message);
end;
```
