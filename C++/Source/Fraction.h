#ifndef FRACTION_H
#define FRACTION_h

#include <string>
#include <exception>

namespace NA_F {

	struct Fraction {
	private:
		int numerator, denominator;
		int gcd(int a, int b) const;		
	public:
		Fraction(int aNumerator, int aDenominator) : numerator(aNumerator), denominator(aDenominator) {
			if (aDenominator == 0)
				throw std::runtime_error("Denominator cannot be zero.");			
		}
		explicit Fraction(const std::string& f);
		explicit Fraction(double x);

		void Reduce();
		void Negate();
		void Inverse();
		double toDouble() const;
		std::string toString() const;
		inline int getNumerator() const { return numerator; }
		inline int getDenominator() const { return denominator; }

		Fraction& operator++();
		Fraction operator++(int);
		Fraction& operator--();
		Fraction operator--(int);
	};

	Fraction operator+(const Fraction& fraction1, const Fraction& fraction2);
	Fraction operator-(const Fraction& fraction1, const Fraction& fraction2);
	Fraction operator*(const Fraction& fraction1, const Fraction& fraction2);
	Fraction operator/(const Fraction& fraction1, const Fraction& fraction2);

}

#endif