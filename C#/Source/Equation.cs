using System;
using System.Diagnostics;
using System.Numerics;
using System.Collections.Generic;
using org.mariuszgromada.math.mxparser;

namespace EquationSolver {

    using AlgorithmCode = Func<List<double>, bool, (double, double, List<double>)>; 

    public struct Polynomial {
        private double[] poly;

        private int degree;

        private double Horner(double x) {
            int power = 0;
            double result = 0;

            for (var i = poly.Length - 1; i >= 0; i--) {
                result += poly[i] * Math.Pow(x, power);
                power++;
            }
            return result;
        }

        public Polynomial(List<double> coeff) : this(coeff.ToArray()) { }

        public Polynomial(double[] coeff) {
            if (coeff[0] == 0)
                throw new ArithmeticException("The highest degree coefficient cannot be zero");

            poly = new double[coeff.Length];
            degree = coeff.Length - 1;

            for(int i = 0; i < coeff.Length; ++i)
                poly[i] = coeff[i];            
        }

        public void Negate() {
            for(int i = 0; i < poly.Length; ++i)
                poly[i] *= -1;
        }

        public int Degree {
            get { return degree; }
        }

        public Polynomial GetDerivative() {
            if (degree == 0) {
                return new Polynomial(new double[] { 0 });
            } else {
                double[] temp = new double[poly.Length - 1];

                for (var i = 0; i < poly.Length - 1; ++i)
                    temp[i] = poly[i + 1] * (i + 1);
                return new Polynomial(temp);
            }
        }

        public double EvaluateOn(double x)
            => Horner(x);

        public double this[int key] {
            get { return poly[key]; }
        }
       
    }

    public enum Algorithm { Newton = 0, NewtonWithMultiplicity = 1, Secant = 2 }

    public sealed class Equation {
        private const double h = 1.0e-13;
        
        private long time;

        private Dictionary<Algorithm, AlgorithmCode> algorithmList;

        private Argument varX;

        private Expression expr;

        private Argument varDer;

        private Expression derivative;

        private void Init() {
            algorithmList.Add(Algorithm.Newton,
                (List<double> inputList, bool guessList) => {
                    if (inputList.Count != 3)
                        throw new ArgumentException("The inputList array must contain 3 parameters: the initial guess, the tolerance and the max.number of iterations");

                    double x0 = inputList[0];
                    double toll = inputList[1];
                    double diff = inputList[1] + 1;
                    int n = 0;
                    int n_max = (int)inputList[2];

                    List<double> guesses = null;
                    if (guessList)
                        guesses = new List<double> { x0 };

                    while ((diff >= toll) && (n < n_max)) {
                        double der = EvaluateDerivativeOn(x0);
                        if (der == 0)
                            throw new DivideByZeroException("Found a f'(x) = 0");

                        diff = -EvaluateOn(x0) / der;
                        x0 += diff;
                        guesses?.Add(x0);

                        diff = Math.Abs(diff);
                        ++n;
                    }

                    return (x0, EvaluateOn(x0), guesses);
                }
            );

            algorithmList.Add(Algorithm.NewtonWithMultiplicity,
                (List<double> inputList, bool guessList) => {
                    if (inputList.Count != 4)
                        throw new ArgumentException("The inputList array must contain 4 parameters: the initial guess, the tolerance, the max. number of iterations and the multiplicity.");

                    double x0 = inputList[0];
                    double toll = inputList[1];
                    double diff = inputList[1] + 1;
                    int n = 0;
                    int n_max = (int)inputList[2];
                    int r = (int)inputList[3];

                    List<double> guesses = null;
                    if (guessList)
                        guesses = new List<double> { x0 };

                    while ((diff >= toll) && (n < n_max)) {
                        double der = EvaluateDerivativeOn(x0);
                        if (der == 0)
                            throw new DivideByZeroException("Found a f'(x) = 0");

                        diff = -r * (EvaluateOn(x0) / der);
                        x0 += diff;
                        guesses?.Add(x0);

                        diff = Math.Abs(diff);
                        ++n;
                    }

                    return (x0, EvaluateOn(x0), guesses);
                }
            );

            algorithmList.Add(Algorithm.Secant,
                (List<double> inputList, bool guessList) => {
                    if (inputList.Count != 4)
                        throw new ArgumentException("The Points array must contain 4 parameters: the first guess, the second guess, the tolerance and the max. number of iterations.");

                    int n = 1;
                    var xold = inputList[0];
                    var x0 = inputList[1];
                    var toll = inputList[2];
                    int n_max = (int)inputList[3];

                    List<double> guesses = null;
                    if (guessList)
                        guesses = new List<double> { x0 };

                    var fold = EvaluateOn(xold);
                    var fnew = EvaluateOn(x0);
                    double diff = toll + 1;

                    while ((diff >= toll) && (n < n_max)) {
                        double den = fnew - fold;
                        if (den == 0)
                            throw new DivideByZeroException("Denominator is zero");

                        diff = -(fnew * (x0 - xold)) / den;
                        xold = x0;
                        fold = fnew;
                        x0 = x0 + diff;

                        diff = Math.Abs(diff);
                        ++n;

                        guesses?.Add(x0);
                        fnew = EvaluateOn(x0);
                    }

                    return (x0, EvaluateOn(xold), guesses);
                }
            );
        }

        public Equation(string expression) {
            time = 0;     
            
            varX = new Argument("x", 0);
            varDer = new Argument("x", 0);

            expr = new Expression(expression, varX);
            if (!expr.checkSyntax())
                throw new FormatException("Wrong input equation, please check the syntax");

            derivative = new Expression("der(" + expression + ", x)", varDer);
            algorithmList = new Dictionary<Algorithm, AlgorithmCode>();

            Init();
        }

        public double EvaluateOn(double x) {
            varX.setArgumentValue(x);
            return expr.calculate();
        }

        public double EvaluateDerivativeOn(double x) {
            varDer.setArgumentValue(x);
            return derivative.calculate();
        }

        public double ElapsedMilliseconds()
            => time;

        public (double, double, List<double>) SolveEquation(Algorithm algorithm, List<double> inputList, bool guessList = false) {
            Stopwatch sw = new Stopwatch();

            sw.Start();
            (double, double, List<double>) valueToReturn = algorithmList[algorithm](inputList, guessList);
            sw.Stop();

            time = sw.ElapsedMilliseconds;
            return valueToReturn;
        }

        public (double, double, List<double>) SolveEquation(double guess) {
            return SolveEquation(Algorithm.Newton, new List<double> { guess, 1.0e-10, 20 }, false);
        }

    }

    public abstract class PolyBase {
        private Polynomial Poly;

        private int PDegree;

        protected Polynomial GetPoly { 
            get { return Poly; }
        }

        public PolyBase(List<double> coeff) {
            Poly = new Polynomial(coeff);
            PDegree = Poly.Degree;
        }

        public abstract List<Complex> GetSolutions();

        public double EvaluateOn(double point) {
            return Poly.EvaluateOn(point);
        }

        public int Degree => PDegree;

        public Polynomial Derivative => Poly.GetDerivative();
    }

    public class Quadratic: PolyBase {
        private double Fa, Fb, Fc;

        public Quadratic(double a, double b, double c) : base(new List<double> { a, b, c }) {
            Fa = c;
            Fb = b;
            Fc = a;
        }

        public double GetDiscriminant() 
            => Fb * Fb - 4 * Fa * Fc;

        public override List<Complex> GetSolutions() {
            List<Complex> result = new List<Complex> { };

            var delta = GetDiscriminant();
            if (delta > 0) {
                result.Add(new Complex(((-Fb + Math.Sqrt(delta)) / (2 * Fa)), 0) );
                result.Add(new Complex(((-Fb - Math.Sqrt(delta)) / (2 * Fa)), 0));
            } else {
                result.Add(new Complex( -Fb / (2 * Fa), Math.Sqrt(Math.Abs(delta)) / (2 * Fa)) );
                result.Add(new Complex( -Fb / (2 * Fa), -Math.Sqrt(Math.Abs(delta)) / (2 * Fa)));
            }

            return result;
        }
    }

    public class Cubic : PolyBase {
        private double Fa, Fb, Fc, Fd;

        public Cubic(double a, double b, double c, double d) : base(new List<double> { a, b, c, d }) {
            Fa = d;
            Fb = c;
            Fc = b;
            Fd = a;
        }

        public double GetDiscriminant()
            => Fc * Fc * Fb * Fb - 4 * Fd * Fb * Fb * Fb - 4 * Fc * Fc * Fc * Fa + 18 * Fa * Fb * Fc * Fd - 27 * Fd * Fd * Fa * Fa;

        private double Cbrt(double val) {
            return (val >= 0) ? Math.Pow(val, 1 / 3) : -Math.Pow(-val, 1 / 3);        
        }

        public override List<Complex> GetSolutions() {
            List<Complex> result = new List<Complex> { };

            double TWO_PI = 2 * Math.Acos(-1);
            double FOUR_PI = 4 * Math.Acos(-1);

            var a = Fb / Fa;
            var b = Fc / Fa;
            var c = Fd / Fa;
            var q = (3 * b - a * a) / 9.0;
            var r = (9 * a * b - 27 * c - 2 * a * a * a) / 54.0;

            var a_over_3 = a / 3;
            var q_cube = q * q * q;
            var delta = q_cube + (r * r);

            if (delta < 0) {
                var theta = Math.Acos(r / Math.Sqrt(-q_cube));
                var sqrt_q = Math.Sqrt(-q);

                result.Add(new Complex((sqrt_q * 2 * Math.Cos(theta / 3) - a_over_3), 0));
                result.Add(new Complex((sqrt_q * 2 * Math.Cos((theta + TWO_PI) / 3) - a_over_3), 0));
                result.Add(new Complex((sqrt_q * 2 * Math.Cos((theta + FOUR_PI) / 3) - a_over_3), 0));
            } else {

                if (delta > 0) {
                    var sqrt_d = Math.Sqrt(delta);
                    var s = Cbrt(r + sqrt_d);
                    var t = Cbrt(r - sqrt_d);
                    var realPart = a_over_3 + ((s + t) / 2);

                    result.Add(new Complex((s + t) - a_over_3, 0));
                    result.Add(new Complex(-realPart, (Math.Sqrt(3) * (-t + s) / 2)));
                    result.Add(new Complex(-realPart, (Math.Sqrt(3) * (-t + s) / 2)));
                } else {
                    result.Add(new Complex(2 * Cbrt(r) - a_over_3, 0));
                    result.Add(new Complex(2 * Cbrt(r) - a_over_3, 0));
                    result.Add(new Complex(2 * Cbrt(r) - a_over_3, 0));
                }

            }

            return result;
        }
    }

    public class Quartic : PolyBase {
        private double Fa, Fb, Fc, Fd, Fe;

        public Quartic(double a, double b, double c, double d, double e) : base(new List<double> { a, b, c, d, e }) {
            Fa = e;
            Fb = d;
            Fc = c;
            Fd = b;
            Fe = a;
        }

        public double GetDiscriminant() {
            var k = Fb * Fb * Fc * Fc * Fd * Fd - 4.0 * Fd * Fd * Fd * Fb * Fb * Fb - 4.0 * Fd * Fd * Fc * Fc * Fc * Fa +
            18.0 * Fd * Fd * Fd * Fc * Fb * Fa - 27.0 * Fd * Fd * Fd * Fd * Fa * Fa + 256.0 * Fe * Fe * Fe * Fa * Fa * Fa;
            var p = Fe * (-4.0 * Fc * Fc * Fc * Fb * Fb + 18.0 * Fd * Fc * Fb * Fb * Fb + 16.0 * Fc * Fc * Fc * Fc * Fa -
                80.0 * Fd * Fc * Fc * Fb * Fa - 6.0 * Fd * Fd * Fb * Fb * Fa + 144.0 * Fd * Fd * Fa * Fa * Fc);
            var r = Fe * Fe * (-27 * Fb * Fb * Fb * Fb + 144 * Fc * Fb * Fb * Fa - 128 * Fc * Fc * Fa * Fa - 192 * Fd * Fb * Fa * Fa);

            return (k + p + r);
        }            

        public override List<Complex> GetSolutions() {
            List<Complex> result = new List<Complex> { };

            var a = new Complex(Fa, 0);
            var b = new Complex(Fb / Fa, 0);
            var c = new Complex(Fc / Fa, 0);
            var d = new Complex(Fd / Fa, 0);
            var e = new Complex(Fe / Fa, 0);

            var Q1 = c * c - 3.0 * b * d + 12.0 * e;
            var Q2 = 2.0 * c * c * c - 9.0 * b * c * d + 27.0 * d * d + 27.0 * b * b * e - 72.0 * c * e;
            var Q3 = 8.0 * b * c - 16.0 * d - 2.0 * b * b * b;
            var Q4 = 3.0 * b * b - 8.0 * c;

            var temp = Q2 * Q2 / 4.0 - Q1 * Q1 * Q1;
            var Q5 = Complex.Pow(Complex.Sqrt(temp) + Q2 / 2.0, 1.0 / 3.0);
            var Q6 = (Q1 / Q5 + Q5) / 3.0;
            temp = Q4 / 12.0 + Q6;
            var Q7 = Complex.Sqrt(temp) * 2.0;

            temp = (4.0 * Q4 / 6.0 - 4.0 * Q6 - Q3 / Q7);
            result.Add((-b - Q7 - Complex.Sqrt(temp)) / 4.0);
            result.Add((-b - Q7 + Complex.Sqrt(temp)) / 4.0);
            temp = (4.0 * Q4 / 6.0 - 4.0 * Q6 + Q3 / Q7);
            result.Add((-b + Q7 - Complex.Sqrt(temp)) / 4.0);
            result.Add((-b + Q7 + Complex.Sqrt(temp)) / 4.0);

            return result;
        }
    }
    
}
