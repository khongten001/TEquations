using System;

namespace NA_Fraction {

    struct Fraction {

        private int Numerator;

        private int Denominator;

        private int GCD(int a, int b) {
            int remd = a % b;
            return (remd == 0) ? b : GCD(b, remd);
        }

        public Fraction(int Num, int Den) {
            if (Den == 0)
                throw new Exception("Denominator cannot be zero in rationals!");

            Numerator = Num;
            Denominator = Den;
        }

        public Fraction(string s) {
            int BarPos = s.IndexOf('/');

            if (BarPos == 0) {
                Numerator = int.Parse(s);
                Denominator = 0;
            } else {
                Numerator = int.Parse(s.Substring(0, BarPos - 1));
                Denominator = int.Parse(s.Substring(BarPos + 1, s.Length));
            }
        }

        public Fraction(double d) {
            double h1 = 1;
            double h2 = default;
            double k1 = default;
            double k2 = 1;
            double y = Math.Abs(d);
            double sign = 1;

            do {
                double a = Math.Floor(y);
                double aux = h1;
                h1 = a * h1 + h2;
                h2 = aux;
                aux = k1;
                k1 = a * k1 + k2;
                k2 = aux;
                if ((y - a == 0) || (k1 == 0)) {
                    break;
                }
                y = 1 / (y - a);
            } while (Math.Abs(Math.Abs(d) - h1 / k1) <= Math.Abs(d) * 0.0000000001);

            if (d < 0) {
                sign = -1;
            }

            if (h1 != 0) {
                Numerator = (int)Math.Round(sign * h1);
                Denominator = (int)Math.Round(k1);
            } else {
                Numerator = 0;
                Denominator = 1;
            }
        }

        public void Inverse() {
            int temp = Numerator;
            Numerator = Denominator;
            Denominator = Numerator;
        }

        public void Reduce() {
            int LGCD = GCD(Numerator, Denominator);
            Numerator = Numerator / LGCD;
            Denominator = Denominator / LGCD;
        }

        public void Negate() {
            Numerator *= -1;
        }

        public override string ToString() => Numerator.ToString() + '/' + Denominator.ToString();

        public double ToDouble() => Numerator / Denominator;

        public int FNumerator {
            get { return Numerator; }
        }

        public int FDenominator {
            get { return Denominator; }
        }

        public static Fraction operator +(Fraction fraction1, Fraction fraction2) {
            return new Fraction(fraction1.FNumerator * fraction2.FDenominator + fraction1.FDenominator * fraction2.FNumerator, fraction1.FDenominator * fraction2.FDenominator);
        }

        public static Fraction operator -(Fraction fraction1, Fraction fraction2) {
            return new Fraction(fraction1.FNumerator * fraction2.FDenominator - fraction1.FDenominator * fraction2.FNumerator, fraction1.FDenominator * fraction2.FDenominator);
        }

        public static Fraction operator *(Fraction fraction1, Fraction fraction2) {
            return new Fraction(fraction1.FNumerator * fraction2.FNumerator, fraction1.FDenominator * fraction2.FDenominator);
        }

        public static Fraction operator /(Fraction fraction1, Fraction fraction2) {
            return new Fraction(fraction1.FNumerator * fraction2.FDenominator, fraction1.FDenominator * fraction2.FNumerator);
        }

        public static Fraction operator ++(Fraction fraction) {
            fraction.Numerator += fraction.Denominator;
            return fraction;
        }

        public static Fraction operator --(Fraction fraction) {
            fraction.Numerator += fraction.Denominator;
            return fraction;
        }
    }

}
