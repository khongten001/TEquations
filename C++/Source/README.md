# Installation

You just need to import the content of this folder and include `Equation.h` as header in your program. Here's a step-by-step guide that's good for Visual Studio:

 1. Create a new empty project (for example a Windows Console Application).
 2. Save everything, just in case.
 3. Copy the contents (the h/cpp files and the Parser folder) in the project folder. In this way you have in the same folder the cpp file with the `main()` and the h/cpp files of the Equation library.
 4. Go on Project > Add Existing Items > Navigate to the project folder > Select everything (the Parser folder and the h/cpp files called Equation and Fraction) > Click Add
 5. Now you can type `#include "Equation.h"` and jump to the next section!

Visual Studio may not compile correctly because there isn't the `stdafx.h` header in my library. You have 2 ways to solve this:

 - Add `#include "stdafx.h"` where needed
 - Go on Project > Properties > Configuration properties > C/C++ > Precompiled Headers and set the **Not Using Precompiled Headers** option
 
If you are not using Visual Studio you just need to be sure that you have a C++11 (C++14 or higher would be better) compiler and copy paste the files in the same folder as your main. Import the all the files and then type `#include "Equation.h"`.

# Usage

The `Equation` class is a generic equation solver that takes the expression (as string) in input. Please note that an expression must be properly written otherwise an exception will be raised (for example `2*x` is good but `2x` not). Let's see an example where we try to solve `f(x) = e^x-2x^2`:

``` c++
int main() {

  using namespace NA_Equation;

  try {
	
    //f(x) = e^x - 2x^2
    Equation test{ std::move("exp(x)-2*x^2") };
    auto eqSolution = test.solveEquation(Algorithm::Newton, { 1.3, 1.0e-10, 20 }, true);

    std::cout << "Solution [x0] = " << std::get<0>(eqSolution) << std::endl;
    std::cout << "Residual [f(x0)] = " << std::get<1>(eqSolution) << std::endl;

  } catch (const std::exception& err) {
    std::cerr << "Ops: " << err.what() << std::endl;
  }

  return 0;
}
```

The usage is very easy: create an Equation object and use `solveEquation()` to get the solutions. The `eqSolution` is a tuple so you need to call `std::get`. Let's see in particular the signature of solve Equation:

``` c++
Result solveEquation(Algorithm algorithm, const std::vector<double>& inputList, bool guessList = false);
```

 - Resul
