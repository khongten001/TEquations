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

# Usage

The `Equation` class is a generic equation solver that takes the expression (as string) in input. Please note that an expression must be properly written otherwise an exception will be raised (for example `2*x` is good but `2x` not). Let's see an example where we try to solve `f(x) = e^x-2x^2`:

``` c++
using namespace NA_Equation;
std::cout.precision(15);

try {

  Equation test{ std::move("exp(x)-2*x^2") };
  auto solution = test.solveEquation(Algorithm::Newton, { 1.3, 1.0e-10, 20 }, true);
  
  // Algorithm::Newton = the root finding algorithm
  // 1.3 = the initial guess
  // 1.0e-10 = the tolerance
  // 20 = the max. number of iterations
  // true = guesses list (generate a vector containing the various x0 calculated during the execution of the algorithm)

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
    test.solveEquation(Algorithm::NewtonWithMultiplicity, { 1.3, 1.0e-10, 20. 1 }, true);
    ```
     - First parameter: the algorithm type `NewtonWithMultiplicity`
     - Second parameter: an array containing: the initial guess, the tolerance, the max. number of iterations and the multiplicity
     - Third parameter: see above
