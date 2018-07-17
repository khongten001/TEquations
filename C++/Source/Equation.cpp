#include "Equation.h"
#include <cmath>
#include <chrono>
#include <algorithm>

namespace NA_Equation {

	// --------- POLYNOMIAL CLASS --------- //

	double Polynomial::horner(double x) const {
		auto k = poly.size() - 1;
		auto result = poly[k];

		for (auto i = k - 1; i > 0; --i)
			result = result * x + poly[i];
		return result;
	}

	void Polynomial::negate() {
		for (auto it = poly.begin(); it != poly.end(); ++it)
			(*it) *= -1;
	}

	int Polynomial::getDegree() const {
		return this->polyDegree;
	}

	Polynomial Polynomial::getDerivative() const {
		if (polyDegree == 0) {
			return Polynomial({ 0 });
		}
		else {
			std::vector<double> temp{};
			temp.reserve(poly.size() - 1);

			for (auto i = 0; i < poly.size() - 1; ++i)
				temp.push_back(poly[i + 1] * (i + 1));
			return Polynomial(temp);
		}

	}

	double Polynomial::evaluateOn(double x) const {
		return this->horner(x);
	}

	const std::vector<double>& Polynomial::toStdVector() const {
		return poly;
	}

	// --------- EQUATION CLASS --------- //

	double Equation::evaluateOn(double x) {
		double var[1] = { x };
		return parser.Eval(var);
	}

	double Equation::elapsedMilliseconds() const {
		return time;
	}

	double Equation::evaluateDerivative(double x) {
		double var[1] = { x + h };
		double res = parser.Eval(var);

		double var2[1] = { x };
		return (res - parser.Eval(var2)) / h;
	}

	Result Equation::solveEquation(double guess) {
		return this->solveEquation(Algorithm::Newton, {guess, 1.0e-10, 20}, false);
	}

	Result Equation::solveEquation(Algorithm algorithm, const std::vector<double>& inputList, bool guessList) {
		auto t1 = std::chrono::high_resolution_clock::now();
		auto result = algorithmList.at(algorithm)(inputList, guessList);
		auto t2 = std::chrono::high_resolution_clock::now();

		this->time = std::chrono::duration_cast<std::chrono::milliseconds>(t2 - t1).count();
		return result;
	}

	void Equation::init() {
		//Newton method
		algorithmList[Algorithm::Newton] = [&](const std::vector<double>& inputList, bool guessList) {

			if (inputList.size() != 3)
				throw std::runtime_error("The inputList array must contain 3 parameters: the initial guess, the tolerance and the max. number of iterations");

			auto x0 = inputList[0];
			auto toll = inputList[1];
			auto diff = inputList[1] + 1;
			auto n = 0;
			auto n_max = static_cast<int>(inputList[2]);
			std::vector<double> guessesList = {};

			if (guessList) {
				guessesList.reserve(n_max);
				guessesList.push_back(x0);
			}

			while ((diff >= toll) && (n < n_max)) {
				auto der = this->evaluateDerivative(x0);
				if (der == 0)
					throw std::runtime_error("Found a f'(x) = 0");

				double var[1]{ x0 };
				diff = -parser.Eval(var) / der;
				x0 = x0 + diff;

				if (guessList)
					guessesList.push_back(x0);

				diff = fabs(diff);
				++n;
			}

			double var[1]{ x0 };
			auto residual = parser.Eval(var);
			if (guessList)
				guessesList.shrink_to_fit();

			return Result{ x0, residual, guessesList };
		};

		//Newton method
		algorithmList[Algorithm::NewtonWithMultiplicity] = [&](const std::vector<double>& inputList, bool guessList) {

			if (inputList.size() != 4)
				throw std::runtime_error("The inputList array must contain 4 parameters: the initial guess, the tolerance, the max. number of iterations and the multiplicity");

			auto x0 = inputList[0];
			auto toll = inputList[1];
			auto diff = inputList[1] + 1;
			auto n = 0;
			auto n_max = static_cast<int>(inputList[2]);
			auto r = static_cast<int>(inputList[3]);

			std::vector<double> guessesList = {};

			if (guessList) {
				guessesList.reserve(n_max);
				guessesList.push_back(x0);
			}

			while ((diff >= toll) && (n < n_max)) {
				auto der = this->evaluateDerivative(x0);
				if (der == 0)
					throw std::runtime_error("Found a f'(x) = 0");

				double var[1]{ x0 };
				diff = -r * (parser.Eval(var) / der);
				x0 = x0 + diff;

				if (guessList)
					guessesList.push_back(x0);

				diff = fabs(diff);
				++n;
			}

			double var[1]{ x0 };
			auto residual = parser.Eval(var);
			if (guessList)
				guessesList.shrink_to_fit();

			return Result{ x0, residual, guessesList };
		};

		//Secant method
		algorithmList[Algorithm::Secant] = [&](const std::vector<double>& inputList, bool guessList) {

			if (inputList.size() != 4)
				throw std::runtime_error("The Points array must contain 4 parameters: the first guess, the second guess, the tolerance and the max. number of iterations.");

			auto n = 1;
			auto xold = inputList[0];
			auto x0 = inputList[1];
			auto toll = inputList[2];
			auto n_max = static_cast<int>(inputList[3]);
			std::vector<double> guessesList = {};

			if (guessList) {
				guessesList.reserve(n_max);
				guessesList.push_back(x0);
			}

			double var[1]{ xold };
			auto fold = parser.Eval(var);
			double var2[1]{ x0 };
			auto fnew = parser.Eval(var2);
			auto diff = toll + 1;

			while ((diff >= toll) && (n < n_max)) {
				auto den = fnew - fold;
				if (den == 0)
					throw std::runtime_error("Denominator is zero");

				diff = -(fnew*(x0 - xold)) / den;
				xold = x0;
				fold = fnew;
				x0 = x0 + diff;
				diff = abs(diff);
				++n;

				if (guessList)
					guessesList.push_back(x0);

				double var3[1]{ x0 };
				fnew = parser.Eval(var3);
			}

			double var3[1]{ xold };
			auto residual = parser.Eval(var3);
			if (guessList)
				guessesList.shrink_to_fit();

			return Result{ x0, residual, guessesList };
		};

	}

	const Polynomial& PolyBase::getPoly() const {
		return this->poly;
	}

	int PolyBase::getDegree() const {
		return poly.getDegree();
	}

	Polynomial PolyBase::getDerivative() const {
		return poly.getDerivative();
	}

	double Quadratic::getDiscriminant() const {
		return Fb * Fb - 4 * Fa*Fc;
	}

	PolyResult Quadratic::getSolutions() const {
		auto delta = std::complex<double>(getDiscriminant());
		auto result = PolyResult{};
		result.reserve(2);

		result.emplace_back( (-Fb + std::sqrt(delta)) / (2 * Fa) );
		result.emplace_back( (-Fb - std::sqrt(delta)) / (2 * Fa) );

		return result;
	}

	double Cubic::getDiscriminant() const {
		return Fc*Fc*Fb*Fb - 4*Fd*Fb*Fb*Fb - 4*Fc*Fc*Fc*Fa + 18*Fa*Fb*Fc*Fd - 27*Fd*Fd*Fa*Fa;

	}

	PolyResult Cubic::getSolutions() const {

		const auto TWO_PI = 2 * std::acos(-1);
		const auto FOUR_PI = 4 * std::acos(-1);

		auto result = PolyResult{};
		result.reserve(3);

		auto a = Fb / Fa;
		auto b = Fc / Fa;
		auto c = Fd / Fa;
		auto q = (3 * b - a * a) / 9.0;
		auto r = (9 * a * b - 27 * c - 2 * a * a * a) / 54.0;

		auto a_over_3 = a / 3;
		auto q_cube = q * q * q;
		auto delta = q_cube + (r*r);

		if (delta < 0) {
			auto theta = std::acos(r / sqrt(-q_cube));
			auto sqrt_q = sqrt(-q);

			result.emplace_back( (sqrt_q * 2 * cos(theta / 3) - a_over_3) );
			result.emplace_back( (sqrt_q * 2 * cos((theta + TWO_PI) / 3) - a_over_3) );
			result.emplace_back( (sqrt_q * 2 * cos((theta + FOUR_PI) / 3) - a_over_3) );
		} else {

			if (delta > 0) {
				auto sqrt_d = sqrt(delta);
				auto s = cbrt(r + sqrt_d);
				auto t = cbrt(r - sqrt_d);
				auto realPart = a_over_3 + ((s + t) / 2);

				result.emplace_back( (s + t) - a_over_3 );
				result.emplace_back( -realPart, (sqrt(3)*(-t + s) / 2) );
				result.emplace_back( -realPart, (sqrt(3)*(-t + s) / 2) );
			} else {
				result.emplace_back( 2*cbrt(r) - a_over_3 );
				result.emplace_back( 2 * cbrt(r) - a_over_3 );
				result.emplace_back( 2 * cbrt(r) - a_over_3 );
			}

		}

		return result;
	}

	double Quartic::getDiscriminant() const {
		auto k = Fb * Fb*Fc*Fc*Fd*Fd - 4.0*Fd*Fd*Fd*Fb*Fb*Fb - 4.0*Fd*Fd*Fc*Fc*Fc*Fa +
				 18.0*Fd*Fd*Fd*Fc*Fb*Fa - 27.0*Fd*Fd*Fd*Fd*Fa*Fa + 256.0*Fe*Fe*Fe*Fa*Fa*Fa;
	    auto p = Fe * (-4.0*Fc*Fc*Fc*Fb*Fb + 18.0*Fd*Fc*Fb*Fb*Fb + 16.0*Fc*Fc*Fc*Fc*Fa -
				 80.0*Fd*Fc*Fc*Fb*Fa - 6.0*Fd*Fd*Fb*Fb*Fa + 144.0*Fd*Fd*Fa*Fa*Fc);
		auto r = Fe * Fe*(-27 * Fb*Fb*Fb*Fb + 144 * Fc*Fb*Fb*Fa - 128 * Fc*Fc*Fa*Fa - 192 * Fd*Fb*Fa*Fa);

		return (k + p + r);
	}

	PolyResult Quartic::getSolutions() const {
		auto result = PolyResult{};
		result.reserve(4);

		auto a = std::complex<double>{ Fa };
		auto b = std::complex<double>{ Fb / Fa };
		auto c = std::complex<double>{ Fc / Fa };
		auto d = std::complex<double>{ Fd / Fa };
		auto e = std::complex<double>{ Fe / Fa };

		auto Q1 = c * c - 3.0 * b * d + 12.0 * e;
		auto Q2 = 2.0 * c * c * c - 9.0 * b * c * d + 27.0 * d * d + 27.0 * b * b * e - 72.0 * c * e;
		auto Q3 = 8.0 * b * c - 16.0 * d - 2.0 * b * b * b;
		auto Q4 = 3.0 * b * b - 8.0 * c;

		auto temp = Q2 * Q2 / 4.0 - Q1 * Q1 * Q1;
		auto Q5 = std::pow(std::sqrt(temp) + Q2 / 2.0, 1.0 / 3.0);
		auto Q6 = (Q1 / Q5 + Q5) / 3.0;
		temp = Q4 / 12.0 + Q6;
		auto Q7 = std::sqrt(temp) * 2.0;

		temp = (4.0 * Q4 / 6.0 - 4.0 * Q6 - Q3 / Q7);
		result.emplace_back(std::complex<double> {(-b - Q7 - std::sqrt(temp)) / 4.0});
		result.emplace_back(std::complex<double> {(-b - Q7 + std::sqrt(temp)) / 4.0});
		temp = (4.0 * Q4 / 6.0 - 4.0 * Q6 + Q3 / Q7);
		result.emplace_back( std::complex<double> {(-b + Q7 - std::sqrt(temp)) / 4.0} );
		result.emplace_back( std::complex<double> {(-b + Q7 + std::sqrt(temp)) / 4.0} );

		return result;
	}

	void PolyEquation::init() {
		//Laguerre
		algorithm[PolyAlgorithm::Laguerre] = [](const std::vector<double>& points) {
			//missing implementation, will do it soon...
			return PolyResult{};
		};

		//Bairstrow
		algorithm[PolyAlgorithm::Bairstrow] = [](const std::vector<double>& points) {
			//missing implementation, will do it soon...
			return PolyResult{};
		};
	}

	PolyResult PolyEquation::getSolutions() const {
		return algorithm.at(method)( getPoly().toStdVector() );
	}
}
