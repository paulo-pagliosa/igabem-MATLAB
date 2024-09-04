function [d, rc, S] = projectPoint(element, P, region)
% Projects a point onto an element region
%
% Author: Paulo Pagliosa
% Last revision: 04/09/2024
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
% S: spatial position of the projecction
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
    [S, Su, Sv] = diff(element, rc);
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
    J(2, 2) = Sv * Sv'; 
    J(1, 1) = Su * Su'; 
    J(1, 2) = Su * Sv';
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

  function [S, Su, Sv] = diff(element, c)
    p = element.nodePositions;
    [Su, Sv, S] = element.shapeFunction.computeTangents(p, c(1), c(2));
  end
end % projectPoint
