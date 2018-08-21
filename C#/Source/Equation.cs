using System;
using System.Diagnostics;
using System.Collections.Generic;
using org.mariuszgromada.math.mxparser;

namespace EquationSolver {

    using AlgorithmCode = Func<List<double>, bool, (double, double, List<double>)>;    

    struct Polynomial {
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

    sealed class Equation {
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
}
