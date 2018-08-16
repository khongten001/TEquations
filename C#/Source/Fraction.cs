using System;
using System.Collections.Generic;
using System.Text.RegularExpressions;

namespace EquationLibrary {

    class Fraction {
        private int numerator;
        private int denominator;

        public int Numerator {
            get { return numerator; }
            private set { numerator = value; }
        }

        public int Denominator {
            get { return denominator; }
            private set { denominator = value; }
        }


        public Fraction(int Numerator, int Denominator) {
            if (Denominator == 0)
                throw new ArithmeticException("Denominator cannot be zero");

            numerator = Numerator;
            denominator = Denominator;
        }

        public Fraction(string f) {
            if (!Regex.IsMatch(f, "(?:[1-9][0-9]*|0)(?:/[1-9][0-9]*)?"))
                throw new ArgumentException("Wrong input format");

            var barPos = f.IndexOf("/");
            if (barPos == 0) {
                numerator = int.Parse(f);
                denominator = 1;
            } else {
                numerator = int.Parse(f.Substring(0, barPos));
                denominator = int.Parse(f.Substring(barPos + 1));
            }
        }

        public Fraction(double x) {
            int mul = (x >= 0) ? 1 : -1;
            x = Math.Abs(x);

            double limit = 1.0E-8;
            double h1 = 1, h2 = 0, k1 = 0, k2 = 1;
            double y = x;

            do {

                double a = Math.Floor(y);
                double aux = h1;
                h1 = a * h1 + h2;
                h2 = aux;
                aux = k1;
                k1 = a * k1 + k2;
                k2 = aux;
                y = 1 / (y - a);

            } while (Math.Abs(x - h1 / k1) > x * limit);

            numerator = mul * ((int)h1);
            denominator = ((int)k1);
        }

        private int GCD(int a, int b) {
            var remd = a % b;
            return (remd == 0) ? b : GCD(b, remd);
        }

        public void Reduce() {
            int sign = (numerator < 0) ? -1 : 1;
            var LGCD = GCD(numerator, denominator);
            numerator = (numerator * sign) / LGCD;
            denominator = (denominator * sign) / LGCD;
        }

        private void Swap<T>(ref T x, ref T y) {
            T t = y;
            y = x;
            x = t;
        }

        public void Inverse() {
            Swap(ref numerator, ref denominator);
        }

        public void Negate() {
            numerator *= -1;
        }

        public double ToDouble() => (double)numerator / (double)denominator;

        public override string ToString() => numerator.ToString() + "/" + denominator.ToString();

        public static implicit operator double(Fraction fraction) 
            => (double)fraction.Numerator / (double)fraction.Denominator;

        public static implicit operator string(Fraction fraction)
            => fraction.ToString();

        public static Fraction operator ++(Fraction fraction1)
            => new Fraction(fraction1.Numerator + fraction1.Denominator, fraction1.Denominator);

        public static Fraction operator --(Fraction fraction1)
            => new Fraction(fraction1.Numerator - fraction1.Denominator, fraction1.Denominator);

        public static Fraction operator +(Fraction fraction1, Fraction fraction2)
            => new Fraction(fraction1.Numerator * fraction2.Denominator + fraction1.Denominator * fraction2.Numerator, fraction1.Denominator * fraction2.Denominator);

        public static Fraction operator -(Fraction fraction1, Fraction fraction2)
            => new Fraction(fraction1.Numerator * fraction2.Denominator - fraction1.Denominator * fraction2.Numerator, fraction1.Denominator * fraction2.Denominator);

        public static Fraction operator *(Fraction fraction1, Fraction fraction2)
            => new Fraction(fraction1.Numerator * fraction2.Numerator, fraction1.Denominator * fraction2.Denominator);

        public static Fraction operator /(Fraction fraction1, Fraction fraction2)
            => new Fraction(fraction1.Numerator * fraction2.Denominator , fraction1.Denominator * fraction2.Numerator);
    }

}
