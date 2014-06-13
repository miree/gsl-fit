//gsl-fit: A command line tool to fit funcion parameters to data points
//Copyright (C) 2014 Michael Reese
//
//This program is free software: you can redistribute it and/or modify
//it under the terms of the GNU General Public License as published by
//the Free Software Foundation, either version 3 of the License, or
//(at your option) any later version.
//
//This program is distributed in the hope that it will be useful,
//but WITHOUT ANY WARRANTY; without even the implied warranty of
//MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//GNU General Public License for more details.
//
//You should have received a copy of the GNU General Public License
//along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
//comments & questions: michaelate@gmail.com

import pegged.grammar;

import gsld.multifit_nlin;

import std.array;
import std.conv;
import std.stdio;
import std.algorithm;
import std.math;
import std.mathspecial;

import core.stdc.string; 
import core.stdc.stdlib;
import std.stdio;
import std.conv;

mixin(grammar(
q{
Arithmetic:
	Expr     <- ConstAssignExpr / AssignExpr / CalcExpr
	AssignExpr < Variable :'=' CalcExpr
	ConstAssignExpr < Constant :":" CalcExpr
    CalcExpr < Factor AddExpr*
    AddExpr  < PlusFac / MinusFac
    PlusFac  < :'+' Factor
    MinusFac < :'-' Factor
    Factor   < Primary MulExpr*
    MulExpr  < MulPrim / DivPrim
    MulPrim  < :'*' Primary
    DivPrim  < :'/' Primary
    Primary  < :'(' CalcExpr :')'
              / Number
              / TernaryFunction
              / BinaryFunction
              / UnaryFunction
              / Variable
              / NegPrim
    NegPrim  < '-' Primary        

	Number   <- Mantissa Exponent / Mantissa
    Mantissa <- '.' [0-9]+
			  / [0-9]+ '.' [0-9]+
			  / [0-9]+ '.'
			  / [0-9]+ 
	Exponent <- 'e' '-' [0-9]+	
	          / 'e' [0-9]+		  
    UnaryFunction < UnaryName :'(' CalcExpr :')'
    UnaryName <- "sinh" / "cosh" / "tanh" 
               / "asinh" / "acosh" / "atanh" 
               / "sin" / "cos" / "tan" 
               / "asin" / "acos" / "atan" 
               / "erf" / "erfc" / "gamma" 
               / "sqrt"
               / "exp" / "log"
    BinaryFunction < BinaryName :'(' CalcExpr :',' CalcExpr :')'
    BinaryName <- "atan2" / "pow" / "gauss"
    TernaryFunction < TernaryName :'(' CalcExpr :',' CalcExpr :',' CalcExpr :')'
    TernaryName <- "gausslt" / "gaussrt"
    Variable <- identifier
    Constant <- identifier
}));

static ulong[string] vars;

// Evalutate an expression given in the shape of a parse tree.
// The params[] can be used to parameterize the expression
double evaluate(in ParseTree p, ref double params[], double x = 0)
{
	static double[string] constants;
	
	string join(const string[] a...) {
	    string ret;
	    foreach (s; a)
	        ret ~= s;
	    return ret;
	}
	
	real gaussrt(real x, real sigma, real tau)
	{
		return erfc(sigma/sqrt(2.0)/tau - x/sqrt(2.0)/sigma)*exp(sigma/2.0/PI-x/tau);
	}
	
	double parseToReal(in ParseTree p)
	{
		
		string functionCases(string names[])
		{
			string result;
			foreach(name; names) result ~= "case \"" ~ name ~ "\": return " ~ name ~ "(parseToReal(p.children[1]));";
			return result;
		}
		switch(p.name)
		{
			case "Arithmetic.UnaryFunction": 
			switch(p.matches[0])
			{
				mixin(functionCases(["sin","cos","tan","asin","acos","atan",
									 "sinh","cosh","tanh","asinh","acosh","atanh",
									 "erf","erfc","gamma","sqrt","exp","log"]));
				default: return double.init;
			}
			case "Arithmetic.BinaryFunction": 
			switch(p.matches[0])
			{
				case "atan2": return atan2(parseToReal(p.children[1]),parseToReal(p.children[2]));
				case "pow": return parseToReal(p.children[1])^^parseToReal(p.children[2]);
				case "gauss": 
				{
					double x = parseToReal(p.children[1]);
					double sigma = parseToReal(p.children[2]);
					return exp(-0.5*(x/sigma)^^2)/sqrt(2*PI)/sigma;
				}
				default: return double.init;
			}
			case "Arithmetic.TernaryFunction": 
			switch(p.matches[0])
			{
				case "gausslt": 
				{
					double x = parseToReal(p.children[1]);
					double sigma = parseToReal(p.children[2]);
					double tau = parseToReal(p.children[2]);
					return gaussrt(x,sigma,tau);
				}
				case "gaussrt": 
				{
					double x = parseToReal(p.children[1]);
					double sigma = parseToReal(p.children[2]);
					double tau = parseToReal(p.children[2]);
					return gaussrt(-x,sigma,tau);
				}
				default: return double.init;
			}
			case "Arithmetic.Number": return to!double(join(p.matches));
			case "Arithmetic.Variable":
				if (p.matches[0] == "x")
					return x;
				else if (p.matches[0] in vars) 
					return params[vars[p.matches[0]]]; 
				else 
					return constants.get(p.matches[0],double.init);
			case "Arithmetic.Factor": { double result = 1; foreach(child; p.children) result *= parseToReal(child); return result; }
			case "Arithmetic.DivPrim": return 1./parseToReal(p.children[0]);
			case "Arithmetic.CalcExpr": { double result = 0; foreach(child; p.children) result += parseToReal(child); return result; }
			case "Arithmetic.ConstAssignExpr": 
			{
				double value = parseToReal(p.children[1]); 
				constants[p.matches[0]] = value;
				return value;
			}
			case "Arithmetic.AssignExpr": 
			{ 
				double value = parseToReal(p.children[1]); 
				if (p.matches[0] !in vars)
				{
					vars[p.matches[0]] = params.length;
					params ~= value;
				}
				else 
				{
					params[vars[p.matches[0]]] = value;
				}
				return value; 
			}
			case "Arithmetic.Primary", "Arithmetic.MulExpr", "Arithmetic.MulPrim",
			     "Arithmetic.AddExpr", "Arithmetic.PlusFac", "Arithmetic.Expr",
			     "Arithmetic":
				return parseToReal(p.children[0]);
			case "Arithmetic.MinusFac", "Arithmetic.NegPrim": 
				return -parseToReal(p.children[0]);
				
			default: return double.init;
		}
	}
	
	return parseToReal(p);
}

void main(string args[])
{
	if (args.length < 4)
	{
	    writeln("gsl-fit  Copyright (C) 2014  Michael Reese");
		writeln("This program comes with ABSOLUTELY NO WARRANTY");
		writeln("This is free software, and you are welcome to redistribute it");
		writeln("under certain conditions.");
		writeln("You should have received a copy of the GNU General Public License");
		writeln("along with this program.  If not, see <http://www.gnu.org/licenses/>.");
		writeln();
		writeln("usage: ", args[0], " datafile function {<par>=<value>|<const>:<value>}");
		return;
	}

	auto parseTree = Arithmetic(args[2]);
	// setting initial values for parameters is done by 
	// evaluating assignment expressions using the parser
	double[] params;
	foreach(assignstr; args[3..$])
		evaluate(Arithmetic(assignstr),params);

	// reading data points from file
	Dp!double[] data;
	double x_min, x_max;
	{	auto f = File(args[1],"r");
		int i = 0;
		foreach(line; f.byLine())
		{
			auto values = map!(to!double)(split(line,' '));
			if (values.length == 2)
				data ~= Dp!double(values[0],values[1]);
			else if (values.length == 3)
				data ~= Dp!double(values[0],values[1],values[2]);
			else
				writeln("invalid data: ", line);
			
			if (i++ == 0)
			{
				x_min = values[0];
				x_max = values[0];
			}
			else
			{
				x_min = min(x_min,values[0]);
				x_max = max(x_max,values[0]);
			}
		}
	}
	double fun(double x, double params[])
	{
		return evaluate(parseTree, params, x);
	}
	
	// do the fit
	auto fit = MultifitNlin!(double,typeof(&fun)) (&fun, data, params, true);
	fit.run(100);
	auto result_par = fit.result_params;
	auto result_err = fit.result_errors;
	auto result_cov = fit.result_covar;
	writeln("--------------------------------------------------------");
	writeln("chi^2/n_dof = ", fit.result_red_chi_sqr);
	writeln("--------------------------------------------------------");
	foreach (key, index; vars)
		writefln("%12s = %12s +- %12s", key, result_par[index], result_err[index]);
	writeln("--------------------------------------------------------");
	foreach (key, index; vars)
		writef("%12s",key);
	writeln;
	foreach (key, index; vars)
	{
		foreach (key2, index2; vars)
			writef("%12s",result_cov[index][index2]);
		writeln;
	}
	writeln("--------------------------------------------------------");
	
	// write the function and its one-sigma error to a file
	{	auto f = File("function.dat","w");
		foreach(point; fit.result_function_values(x_min-5*(x_max-x_min),x_max+5*(x_max-x_min)))
			f.writeln(point[0]," ",point[1]," ",point[2]);
	}
}

