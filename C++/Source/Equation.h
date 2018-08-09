#ifndef EQUATION_H
#define EQUATION_H

#include <map>
#include <tuple>
#include <vector>
#include <string>
#include <complex>
#include <functional>
#include <initializer_list>
#include "Parser/fparser.hh"

namespace NA_Equation {

	struct Polynomial {
	private:
		std::vector<double> poly;
		int polyDegree;
		double horner(double x) const;
	public:
		explicit Polynomial(const std::vector<double>& x) : poly(x), polyDegree(x.size() - 1) {
			if (poly[0] == 0)
				throw std::runtime_error("The highest degree coefficient cannot be zero");
		};
		void negate();
		int getDegree() const;
		Polynomial getDerivative() const;
		double evaluateOn(double x) const;
		const std::vector<double>& toStdVector() const;

		auto begin() const { return poly.begin(); }
		auto end() const { return poly.end(); }
		auto rbegin() const { return poly.rbegin(); }
		auto rend() const { return poly.rend(); }
	};

	using Result = std::tuple<double, double, std::vector<double>>;
	using AlgorithmCode = std::function<Result(std::vector<double>, bool)>;
	enum class Algorithm { Newton = 0, NewtonWithMultiplicity = 1, Secant = 2 };

	class Equation final {
	private:
		const double h = 1.0e-13;

		double x;
		double time;
		std::string expr;
		FunctionParser parser;
		std::map<Algorithm, AlgorithmCode> algorithmList;
	protected:
		void init();
	public:
		Equation(const std::string& expression = "0") : expr(expression), x(0), time(0) {
			parser.Parse(this->expr, "x");
			init();
		}
		Equation(std::string&& expression = "0") : expr(std::move(expression)), x(0), time(0) {
			parser.Parse(this->expr, "x");
			init();
		}
		double evaluateOn(double x);
		double elapsedMilliseconds() const;
		double evaluateDerivative(double x);
		Result solveEquation(double guess);
		Result solveEquation(Algorithm algorithm, const std::vector<double>& inputList, bool guessList = false);
	};

	using PolyResult = std::vector<std::complex<double>>;

	class PolyBase {
	private:
		Polynomial poly;
	protected:
		const Polynomial & getPoly() const;
	public:
		explicit PolyBase(const std::vector<double>& i) : poly(i) {}
		virtual ~PolyBase() = default;

		virtual PolyResult getSolutions() const = 0;
		int getDegree() const;
		Polynomial getDerivative() const;
	};

	class Quadratic : public PolyBase {
	private:
		double Fa, Fb, Fc;
	public:
		Quadratic(double a, double b, double c) : PolyBase({ c, b, a }), Fa(c), Fb(b), Fc(a) {}
		PolyResult getSolutions() const override;
		double getDiscriminant() const;
	};

	class Cubic : public PolyBase {
	private:
		double Fa, Fb, Fc, Fd;
	public:
		Cubic(double a, double b, double c, double d) : PolyBase({ d, c, b, a }), Fa(d), Fb(c), Fc(b), Fd(a) {}
		PolyResult getSolutions() const override;
		double getDiscriminant() const;
	};

	class Quartic : public PolyBase {
	private:
		double Fa, Fb, Fc, Fd, Fe;
	public:
		Quartic(double a, double b, double c, double d, double e) : PolyBase({ e, d, c, b, a }), Fa(e), Fb(d), Fc(c), Fd(b), Fe(a) {}
		PolyResult getSolutions() const override;
		double getDiscriminant() const;
	};

	using PolyResult = std::vector<std::complex<double>>;
	using PolyCode = std::function<PolyResult(std::vector<double>)>;
	enum class PolyAlgorithm { Laguerre = 0, Bairstrow = 1 };

	class PolyEquation : public PolyBase {
	private:
		std::map<PolyAlgorithm, PolyCode> algorithm;
		PolyAlgorithm method;
		void init();
	public:
		explicit PolyEquation(const std::vector<double>& coeff, PolyAlgorithm method_) : PolyBase(coeff), method(method_) { init(); }
		PolyResult getSolutions() const override;
	};
}

#endif
