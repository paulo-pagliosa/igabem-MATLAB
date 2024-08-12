classdef ShapeFunction < handle & matlab.mixin.Heterogeneous

methods (Abstract)
  N = eval(this, u, v);
  [Du, Dv] = diff(this, u, v);
end

methods
  function [x, N] = interpolate(this, x, u, v)
    N = this.eval(u, v);
    x = ShapeFunction.weightedSum(N, x);
  end

  function [xp, xu, xv, dn] = interpolateDiff(this, x, u, v)
    u0 = u;
    v0 = v;
    maxIt = 10;
    for i = 1:maxIt
      [Du, Dv] = this.diff(u, v);
      xu = ShapeFunction.weightedSum(Du, x);
      xv = ShapeFunction.weightedSum(Dv, x);
      xp = this.interpolate(x, u, v);
      wp = 1 / xp(4);
      xp = xp(1:3) * wp;
      xu = (xu(1:3) - xu(4) * xp) * wp;
      xv = (xv(1:3) - xv(4) * xp) * wp;
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

methods (Static, Access = protected)
  function x = weightedSum(w, x)
    x = sum(x .* repmat(w, 1, size(x, 2)));
  end
end

end % ShapeFunction
