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
 
If you are not using Visual Studio you just need to be sure that you have a C++11 (C++14 or higher would be better) compiler and copy paste the files in the same folder as your main.

# Usage
