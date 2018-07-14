# Installation

**Short Version**

You just need to import the content of this folder and type `#include Equation.h` in your program. That's all!

**Long version**

Visual Studio may not compile the files correctly because there isn't the `stdafx.h` header in my library. You have 2 ways to solve this:

 - Add `#include "stdafx.h"` where needed
 - Go on Project > Properties > Configuration properties > C/C++ > Precompiled Headers and set the **Not Using Precompiled Headers** option

Here's a step by step installation guide that's good for Visual Studio:

 1. Create a new empty project (for example a Windows Console Application).
 2. Save everything, just in case.
 3. Copy the contents (the h/cpp files and the Parser folder) in the project folder. In this way you have (in the same folder) the cpp file with the `main()` and the h/cpp files of the Equation library.
 4. Go on Project > Add Existing Items > Navigate to the project folder > Select everything (the Parser folder and the h/cpp files called Equation and Fraction) > Click Add
 5. Now you can type `#include "Equation.h"` and jump to the Usage section!

If you are not using Visual Studio you just need to be sure that you have a C++11 (C++14 or higher would be better) compiler and, once you've imported the content of the Source folder in your project, the only requirement is `#include "Equation.h"`.

# Generic usage

The `Equation` class is a generic equation solver that takes the expression (as string) in input. Please note that an expression must be properly written otherwise an exception will be raised (for example `2*x` is good but `2x` not). Let's see an example where we try to solve `f(x) = e^x-2x^2`:

``` c++
using namespace NA_Equation;
std::cout.precision(15);

try {

  Equation test{ std::move("exp(x)-2*x^2") };
  auto solution = test.solveEquation(Algorithm::Newton, { 1.3, 1.0e-10, 20 }, true);
  //read below to understand the meaning of the input parameters of solveEquation()

  std::cout << "Solution [x0] = " << std::get<0>(solution) << std::endl;
  std::cout << "Residual [f(x0)] = " << std::get<1>(solution) << std::endl;

  std::cout << "\nResiduals list:" << std::endl;
  std::vector<double> x = std::move(std::get<2>(solution));
  
  for (const auto& val : x) {
    std::cout << val << std::endl;
  }
	
} catch (const std::exception& err) {
  std::cerr << "Ops: " << err.what() << std::endl;
}

/* 
====== OUTPUT ======

Solution [x0] = 1.48796206549818
Residual [f(x0)] = 8.88178419700125e-16

Residuals list:
1.3
1.4889957706899
1.48796191447505
1.48796206549823
1.48796206549818
*/
```

Please note that if you have a C++17 compiler you can achieve the same result with less lines of code (I prefer this way).

```c++
Equation test{ std::move("exp(x)-2.1*x^2") };
//Structured bindings (auto + bracket initializer) were introduced in C++17
const auto& [x0, residual, list] = test.solveEquation(Algorithm::Newton, { 1.3, 1.0e-10, 20 }, true);

std::cout << "Solution [x0] = " << x0 << std::endl;
std::cout << "Residual [f(x0)] = " << residual << std::endl;

std::cout << "\nResiduals list:" << std::endl;
for (const auto& val : list) {
  std::cout << val << std::endl;
}
```	

This library implements some root finding algorithms (and maybe more in the future) and each of them need some input numbers to run. Considering again the example `f(x) = e^x-2x^2` let's see which algorithms we can use:

 - Newton's method.
   ```c++
   test.solveEquation(Algorithm::Newton, { 1.3, 1.0e-10, 20 }, true);
   ```
     - First parameter: the algorithm type `Newton`
     - Second parameter: an array containing: the initial guess, the tolerance and the max. number of iterations
     - Third parameter: true or false if you want to generate a table with the x0 calculated during the calculation process
     
  - Newton's method with multiplicity.
    ```c++
    test.solveEquation(Algorithm::NewtonWithMultiplicity, { 1.3, 1.0e-10, 20, 1 }, true);
    ```
     - First parameter: the algorithm type `NewtonWithMultiplicity`
     - Second parameter: an array containing: the initial guess, the tolerance, the max. number of iterations and the multiplicity
     - Third parameter: see above
     
  - Newton's method with multiplicity.
    ```c++
    test.solveEquation(Algorithm::Secant, { 1, 2, 1.0e-10, 20 }, true);
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
 
 ```c++
 //f(x) = 2x^3 + x^2 - 3x + 5
 Cubic test{ 5, -3, 1, 2 };
 auto solutions = test.getSolutions();

 for (const auto& x : solutions) {
   std::cout << x << std::endl;
   // or call x.real() and x.imag() to get the real/complex part
 }
 
 /*
   ====== OUTPUT ======
   
   (-1.93877822138267,0)
   (0.719389110691337,0.878607528100661)
   (0.719389110691337,0.878607528100661)
 */
 ```
 
The `solutions` variable is a vector of `std::complex` so the result is in the format `(realPart, imagPart)`; the usage of the other classes is identical. Please note that the parameters in input start from the coefficient with the **lower** degree so `2x^3 + x^2 - 3x + 5` is `test{ 5, -3, 1, 2 }` (the reverse order). Another way:

```c++
Equation test{ std::move("2x^3+x^2-3x+5") };
const auto& [x0, residual, list] = test.solveEquation(Algorithm::Secant, { -2, -1.5, 1.0e-10, 20 }, true);
```

There's also the `PolyEquation` class that finds every root, real and complex, of a given polynomial (whose degree should be equal or greater than 1). This root finding algorithm gives you an approximation of the solutions; of course it can be used with polynomials of degree 2, 3 and 4 as well but my recommendation is:

  - Use `Quadratic`, `Cubic`, `Quartic` for 2nd, 3rd and 4th degree polynomials (you won't have an approximation of the solutions)
  - Use `PolyEquation` for polynomials with a degree equal or higher than 5 (you'll get an approximation of the solutions)
  
Of course, if you wish, you can use the `Equation` as you've seen above and use a generic root finding algorithm. The usage is exactly the same as the other polynomial classes but with the exception that you have an extra parameter: the algorithm that has to be used to find the roots.

```c++
//f(x) = x^5 - 2x^3 + x^2 - 3x + 5
PolyEquation test{ {5, -3, 1, -2, 0, 1}, PolyAlgorithm::Laguerre };
auto sol = test.getSolutions();

for (const auto& x : sol) {
  std::cout << x << std::endl;
}```

The algorithms supported in this class are Laguerre and Bairstrow but you can create new ones just adding members to the algorithm container inside the class (which is a `std::map`).
