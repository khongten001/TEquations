#ifndef FRACTION_H
#define FRACTION_h

#include <string>
#include <optional>
#include <exception>

namespace NA_Fraction {

	struct MixedFraction {
	private:
		int whole;
		int num, den;
	public:
		MixedFraction(int wholePart, int numerator, int denominator) : whole(wholePart), num(numerator), den(denominator) {
			if (numerator > denominator)
				throw std::logic_error("Numerator cannot be greater than the denominator.");

			if (denominator == 0)
				throw std::logic_error("Denominator cannot be zero.");
		}
		
		inline int getWholePart() const { return whole; }
		inline int getNumerator() const { return num; }
		inline int getDenominator() const { return den; }
		std::string toString() const;
		double toDouble() const;
	};

	struct Fraction {
	private:
		int numerator, denominator; 
		int gcd(int a, int b) const;
	public:
		Fraction(int aNumerator, int aDenominator) : numerator(aNumerator), denominator(aDenominator) {
			if (aDenominator == 0)
				throw std::logic_error("Denominator cannot be zero.");
		}
		explicit Fraction(const std::string& f);
		explicit Fraction(double x);
		explicit Fraction(const MixedFraction& m) : numerator(m.getWholePart() * m.getDenominator() + m.getNumerator()), 
													denominator(m.getDenominator()) {};

		void Reduce();
		void Negate();
		void Inverse();
		double toDouble() const;
		std::string toString() const;
		operator double() const;
		operator std::string() const;
		std::optional<MixedFraction> toMixedFraction() const;
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
