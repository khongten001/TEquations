# Installation

**Short Version**

You just need to import the content of this folder and add the file `mXparser.dll` in the project's references. That's all!

**Long version**

Here's a step by step installation guide that's good for Visual Studio:

 1. Create a new empty project called `TestEquation` (for example a C# Console Application).
 2. Save everything, just in case.
 3. In the solution explorer: right click on References > Add Reference > Browse > Select `mXparser.dll` > Click Ok
 4. Now follow these steps: Project > Add existing item > Select `Equation.cs` and `Fraction.cs` > Click Add
 5. Type on the head of the file `using EquationSolver;` and you're now ready for the next section!
# Generic usage

The `Equation` class is a generic equation solver that takes the expression (as string) in input. Please note that an expression must be properly written otherwise an exception will be raised (for example `2*x` is good but `2x` not). Let's see an example where we try to solve `f(x) = e^x-2x^2`:

``` c#
try {
    Equation e = new Equation("exp(x)-2*x^2");
    (double x0, double res, List<double> g) = e.SolveEquation(Algorithm.Newton, new List<double> { 1.3, 1.0e-10, 20, 1 }, true);

    Console.WriteLine("Solution [x0] = " + x0.ToString());
    Console.WriteLine("Residual [f(x0)] = " + res.ToString());

    Console.WriteLine("\nResuduals list:");
    foreach (var val in g)
        Console.WriteLine(val);

    Console.ReadKey();
} catch (Exception e) {
    Console.WriteLine(e.Message);
}

/* 
====== OUTPUT ======

Solution [x0] = 1,48796206549818
Residual [f(x0)] = 5,32907051820075E-15

Resuduals list:
1,3
1,48899590911958
1,48796191425372
1,48796206549817
1,48796206549818
*/
```

Please note that the syntax above can also be replaced by the following (... but I prefer the previous way).

```c#
Equation e = new Equation("exp(x)-2*x^2");
var s = ValueTuple.Create(e.SolveEquation(Algorithm.Newton, new List<double> { 1.3, 1.0e-10, 20 }, true));

Console.WriteLine("Solution [x0] = " + s.Item1.Item1.ToString());
Console.WriteLine("Residual [f(x0)] = " + s.Item1.Item2.ToString());

Console.WriteLine("\nResuduals list:");
foreach (var val in s.Item1.Item3)
    Console.WriteLine(val);
```	

This library implements some root finding algorithms (and maybe more in the future) and each of them need some input numbers to run. Considering again the example `f(x) = e^x-2x^2` let's see which algorithms we can use:

 - Newton's method.
   ```c#
   e.SolveEquation(Algorithm.Newton, new List<double> { 1.3, 1.0e-10, 20 }, true);
   ```
     - First parameter: the algorithm type `Newton`
     - Second parameter: an array containing: the initial guess, the tolerance and the max. number of iterations
     - Third parameter: true or false if you want to generate a table with the x0 calculated during the calculation process
     
  - Newton's method with multiplicity.
    ```c#
    e.SolveEquation(Algorithm.NewtonWithMultiplicity, new List<double> { 1.3, 1.0e-10, 20, 1 }, true);
    ```
     - First parameter: the algorithm type `NewtonWithMultiplicity`
     - Second parameter: an array containing: the initial guess, the tolerance, the max. number of iterations and the multiplicity
     - Third parameter: see above
     
  - Newton's method with multiplicity.
    ```c#
    e.SolveEquation(Algorithm.Secant, new List<double> { 1, 2, 1.0e-10, 20 }, true)
    ```
     - First parameter: the algorithm type `Secant`
     - Second parameter: an array containing: the lower bound, the upper bound, the tolerance and the max. number of iterations
     - Third parameter: see above

# Specific usage

Coming soon...
