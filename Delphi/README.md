# Notes

 - This library has been written using Delphi 10.2 Tokyo
 - The Parse folder has been originally created by Egbert van Nes (<a href="http://www.sparcs-center.org/expression-parser">link</a>)
 - Installation, documentation and examples can be found in the Source folder

The `Source` folder contains the source files of the library and it can be used in VCL/FMX projects. The `Component` folder contains the source code of a component that has been created using this library.

It is **very important** to keep in mind that the parser does **NOT** support implicit multiplying. This means that valid inputs for the equation are `2*x` or `(x-2)*(13+6)` but invalid inputs are `2x` or `(x-2)(13+6)`. Always explicit the operators.
