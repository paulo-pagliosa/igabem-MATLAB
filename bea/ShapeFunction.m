classdef (Abstract) ShapeFunction < handle & matlab.mixin.Heterogeneous
% ShapeFunction: generic shape function class
%
% Author: Paulo Pagliosa
% Last revision: 02/11/2024
%
% Description
% ===========
% The abstract class ShapeFunction encapsulates the behavior of
% generic shape functions associated with the nodes of an element.
% The class define methods for evaluating the shape functions and
% their derivatives given the parametric coordinates of a point,
% interpolating nodal values at a point, and computing the normal
% at a point.
%
% See also: Element

%% Public constant properties
properties (Constant)
  eps = 1e-10;
end

%% Public methods
methods (Abstract)
  N = eval(this, u, v);
  % Evaluates the shape functions at (U,V)
  [Du, Dv, N] = diff(this, u, v);
  % Evaluates the derivatives of the shape functions at (U,V)
end

methods
  function [x, N] = interpolate(this, x, u, v)
  % Interpolates nodal values X at (U,V)
    N = this.eval(u, v);
    x = ShapeFunction.weightedSum(x, N);
  end

  function [xu, xv, xp] = computeTangents(this, x, u, v)
  % Computes the tangents and position at (U,V).
  % The input parameter X is assumed to be nodal positions and weights
    [Du, Dv, N] = this.diff(u, v);
    xp = ShapeFunction.weightedSum(x, N);
    wp = 1 / xp(4);
    xp = xp(1:3) * wp;
    xu = ShapeFunction.weightedSum(x, Du);
    xu = (xu(1:3) - xu(4) * xp) * wp;
    xv = ShapeFunction.weightedSum(x, Dv);
    xv = (xv(1:3) - xv(4) * xp) * wp;
  end

  function [g, xu, xv, xp] = computeGradient(this, x, u, v)
  % Computes the gradient, tangents, and position at (U,V).
  % The input parameter X is assumed to be nodal positions and weights
    [xu, xv, xp] = this.computeTangents(x, u, v);
    g = cross(xu, xv);
    if g * g' <= this.eps
      warning('%s: zero normal at (%f,%f)\n', class(this), u, v);
    end
  end
end

%% Protected static methods
methods (Static, Access = protected)
  function x = weightedSum(x, w)
    x = sum(x .* w);
  end
end

end % ShapeFunction
