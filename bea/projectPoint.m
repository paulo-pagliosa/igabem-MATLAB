function [d, rc] = projectPoint(element, P, region)
% Projects a point onto an element region
%
% Author: Paulo Pagliosa
% Last revision: 12/08/2024
%
% Input
% =====
% ELEMENT: element onto which the point will be projected
% P: 3D point to project
% REGION: element region domain
%
% Output
% ======
% D: distance from P to REGION
% RC: parametric coordinates of the projection
  assert(isa(element, 'BezierElement'), 'BezierElement expected');
  if nargin < 3
    region = QuadRegion.default;
  end
  r1 = region.o;
  r2 = region.s + r1;
  rc = region.center;
  eps = 1e-5;
  maxIt = 20;
  it = 0;
  while it < maxIt
    it = it + 1;
    [S, Su, Sv, Suu, Suv, Svv] = diff2(element, rc);
    r = S - P;
    % Check by point coincidence
    d = norm(r);
    if d <= eps
      break;
    end
    f = r * Su';
    g = r * Sv';
    % Check by zero cossine
    if abs(f) / (norm(Su) * d) <= eps && abs(g) / (norm(Sv) * d) <= eps
      break;
    end
    J(2, 2) = Sv * Sv' + r * Svv'; 
    J(1, 1) = Su * Su' + r * Suu'; 
    J(1, 2) = Su * Sv' + r * Suv';
    J(2, 1) = J(1, 2);
    x = (J \ -[f; g])' + rc;
    % Ensure the projection is in the element    
    if x(1) < r1(1)
      x(1) = r1(1);
    elseif x(1) > r2(1)
      x(1) = r2(1);
    end
    if x(2) < r1(2)
      x(2) = r1(2);
    elseif x(2) > r2(2)
      x(2) = r2(2);
    end
    % Check if parameters do not change significantly
    if norm((x(1) - rc(1)) * Su + (x(2) - rc(2)) * Sv) <= eps
      break;
    end
    rc = x;
  end
  %fprintf("Iterations: %d\n", it);

  function d = norm(x)
    d = sqrt(x * x');
  end

  function [N, D, H] = evalBezierCurve3(u)
    u2 = u * u;
    uc = 1 - u;
    uc2 = uc * uc;
    N(4) = u2 * u;
    N(3) = 3 * u2 * uc;
    N(2) = 3 * uc2 * u;
    N(1) = uc2 * uc;
    D(4) = 3 * u2;
    D(3) = -9 * u2 + 6 * u;
    D(2) = 9 * u2 - 12 * u + 3;
    D(1) = -3 * uc2;
    H(4) = 6 * u;
    H(3) = -18 * u + 6;
    H(2) = 18 * u - 12;
    H(1) = 6 * uc;
  end

  function [N, Du, Dv, Duu, Duv, Dvv] = evalBezierPatch3(C, u, v)
    [uw, duw, d2uw] = evalBezierCurve3(u);  
    [vw, dvw, d2vw] = evalBezierCurve3(v);
    N = mul(C, uw, vw);
    Du = mul(C, duw, vw);
    Dv = mul(C, uw, dvw);
    Duu = mul(C, d2uw, vw);
    Duv = mul(C, duw, dvw);
    Dvv = mul(C, uw, d2vw);
    
    function s = mul(C, a, b)
      s = C * reshape(kron(a, b')', [], 1);
    end
  end

  function x = blend(w, x)
    x = sum(x .* repmat(w, 1, size(x, 2)));
  end

  function [S, Su, Sv, Suu, Suv, Svv] = diff2(element, c)
    [N, Du, Dv, Duu, Duv, Dvv] = evalBezierPatch3(element.shapeFunction.C, ...
      (c(1) + 1) / 2, ...
      (c(2) + 1) / 2);
    p = element.nodePositions;
    S = blend(N, p); S = S(1:3);
    Su = blend(Du, p); Su = Su(1:3);
    Sv = blend(Dv, p); Sv = Sv(1:3);
    Suu = blend(Duu, p); Suu = Suu(1:3);
    Suv = blend(Duv, p); Suv = Suv(1:3);
    Svv = blend(Dvv, p); Svv = Svv(1:3);
  end
end % projectPoint
