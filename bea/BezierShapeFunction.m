classdef BezierShapeFunction < ShapeFunction
% BezierShapeFunction: Bezier shape function class
%
% Authors: M.A. Peres and P. Pagliosa
% Last revision: 12/08/2024
%
% Description
% ===========
% An object of the class BezierShapeFunction represents a set of shape
% functions defined by a linear operator, C (resulting from the Bezier
% extraction as described in Section 4.2 and Section 4.3 of the paper),
% applied to Bernstein basis functions.
%
% See also: class Bernstein

%% Public read-only properties
properties (SetAccess = private)
  degree;
  C double;
end

%% Public methods
methods
  % Constructor
  function this = BezierShapeFunction(degree, C)
    assert(degree == 3 || degree == 4, 'Bad Bezier shape function degree');
    this.degree = degree;
    this.C = C;
    if degree == 3
      this.basis = @Bernstein.basis3x3;
      this.derivativeU = @Bernstein.derivativeU3x3;
      this.derivativeV = @Bernstein.derivativeV3x3;
    elseif degree == 4
      this.basis = @Bernstein.basis4x4;
      this.derivativeU = @Bernstein.derivativeU4x4;
      this.derivativeV = @Bernstein.derivativeV4x4;
    end
  end

  % Evaluates the shape functions at (U,V)
  function N = eval(this, u, v)
    N = this.C * reshape(this.basis(u, v)', [], 1);
  end

  % Evaluates the derivatives of the shape functions at (U,V)
  function [Du, Dv] = diff(this, u, v)
    Du = this.C * reshape(this.derivativeU(u, v)', [], 1);
    Dv = this.C * reshape(this.derivativeV(u, v)', [], 1);
  end
end

%% Private properties
properties (Access = private)
  basis;
  derivativeU;
  derivativeV;
end

end % BezierShapeFunction
