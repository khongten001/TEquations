#include "Fraction.h"
#include <cmath>
#include <regex>

namespace NA_Fraction {

	double MixedFraction::toDouble() const {
		return whole + (num / den);
	}

	std::string MixedFraction::toString() const {
		return std::to_string(whole) + " " + std::to_string(num) + "/" + std::to_string(den);
	}

	Fraction::Fraction(const std::string& f) {
		//this regex ensures that the denominator will never be zero. Only integers and fractions are accepted
		if (!std::regex_match(f, std::regex{ "(?:[1-9][0-9]*|0)(?:\/[1-9][0-9]*)?" }))
			throw std::runtime_error("Wrong input format");		

		auto barPos = f.find("/");
		if (barPos == std::string::npos) {
			numerator = std::stoi(f);
			denominator = 1;
		}
		else {
			numerator = std::stoi(f.substr(0, barPos));
			denominator = std::stoi(f.substr(barPos + 1, f.length()));
		}
	}

	Fraction::Fraction(double x) {
		int mul = (x >= 0) ? 1 : -1;
		x = fabs(x);

		double limit = 1.0E-6;
		double h1 = 1, h2 = 0, k1 = 0, k2 = 1;
		double y = x;

		do {

			double a = floor(y);
			double aux = h1;
			h1 = a * h1 + h2;
			h2 = aux;
			aux = k1;
			k1 = a * k1 + k2;
			k2 = aux;
			y = 1 / (y - a);

		} while (fabs(x - h1 / k1) > x*limit);

		numerator = mul * static_cast<int>(h1);
		denominator = static_cast<int>(k1);
	}

	int Fraction::gcd(int a, int b) const {
		int remd = a % b;
		return (remd == 0) ? b : gcd(b, remd);
	}

	void Fraction::Reduce() {
		int LGCD = gcd(numerator, denominator);
		numerator = numerator / LGCD;
		denominator = denominator / LGCD;
	}

	void Fraction::Inverse() {
		std::swap(numerator, denominator);
	}

	void Fraction::Negate() {
		numerator *= -1;
	}

	double Fraction::toDouble() const {
		return static_cast<double>(numerator) / denominator;
	}

	std::string Fraction::toString() const {
		return std::string(std::to_string(numerator) + "/" + std::to_string(denominator));
	}

	Fraction::operator double() const {
		return toDouble();
	}

	Fraction::operator std::string() const {
		return toString();
	}

	std::optional<MixedFraction> Fraction::toMixedFraction() const {
		if (numerator > denominator) {
			return std::optional<MixedFraction>{ MixedFraction{numerator / denominator, numerator % denominator, denominator} };
		} else {
			return std::nullopt;
		}
	}

	Fraction& Fraction::operator++() {
		numerator += denominator;
		return *this;
	}

	Fraction& Fraction::operator--() {
		numerator -= denominator;
		return *this;
	}

	Fraction Fraction::operator++(int) {
		Fraction s(*this);
		s.numerator += s.denominator;
		return s;
	}

	Fraction Fraction::operator--(int) {
		Fraction s(*this);
		s.numerator -= s.denominator;
		return s;
	}

	Fraction operator+(const Fraction& fraction1, const Fraction& fraction2) {
		return Fraction(fraction1.getNumerator()*fraction2.getDenominator() + fraction1.getDenominator()*fraction2.getNumerator(), fraction1.getDenominator() * fraction2.getDenominator());
	}

	Fraction operator-(const Fraction& fraction1, const Fraction& fraction2) {
		return Fraction(fraction1.getNumerator()*fraction2.getDenominator() - fraction1.getDenominator()*fraction2.getNumerator(), fraction1.getDenominator() * fraction2.getDenominator());
	}

	Fraction operator*(const Fraction& fraction1, const Fraction& fraction2) {
		return Fraction(fraction1.getNumerator()*fraction2.getNumerator(), fraction1.getDenominator() * fraction2.getDenominator());
	}

	Fraction operator/(const Fraction& fraction1, const Fraction& fraction2) {
		return Fraction(fraction1.getNumerator()*fraction2.getDenominator(), fraction1.getDenominator() * fraction2.getNumerator());
	}
}
