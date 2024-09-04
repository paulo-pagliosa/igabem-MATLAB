classdef (Abstract) ShapeFunction < handle & matlab.mixin.Heterogeneous
% ShapeFunction: generic shape function class
%
% Author: Paulo Pagliosa
% Last revision: 04/09/2024
%
% Description
% ===========
% The abstract class ShapeFunction encapsulates the behavior of a
% generic set of element shape functions associated with the nodes of an
% element. The class define methods for evaluating the shape functions
% and their derivatives given the parametric coordinates of a point,
% interpolating nodal values at a point, and computing the normal at a point.
%
% See also: class Element

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
  % Computes tangents and position at (u,v).
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

  function [dn, xu, xv, xp] = computeNormal(this, x, u, v)
  % Computes normal, tangents, and position at (u,v).
  % The input parameter X is assumed to be nodal positions and weights
    u0 = u;
    v0 = v;
    maxIt = 10;
    for i = 1:maxIt
      [xu, xv, xp] = this.computeTangents(x, u, v);
      dn = cross(xu, xv);
      if dn * dn' > 1e-6
        return;
      end
      d = 1e-4;
      u = u - eps(d); %sign(u) * d;
      v = v - eps(d); %sign(v) * d;
    end
    warning('%s: zero normal at (%f,%f)\n', class(this), u0, v0);

    function r = eps(d)
      r = (d + d) * rand(1) - d;
    end
  end
end

%% Protected static methods
methods (Static, Access = protected)
  function x = weightedSum(x, w)
    x = sum(x .* repmat(w, 1, size(x, 2)));
  end
end

end % ShapeFunction
