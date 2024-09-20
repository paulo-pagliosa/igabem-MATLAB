function pidx = findPoint(p, points, eps)
% Finds the nearest point in a 3D point set
%
% Author: Paulo Pagliosa
% Last revision: 20/09/2024
%
% Input
% =====
% P: 1x3 matrix with point coordinates
% POINTS: NPx3 matrix with point set coordinates
% EPS: precision to compare point positions
%
% Output
% ======
% PIDX: index of the nearest point
%
% Description
% ===========
% Given the coordinates of a 3D point set POINTS and of a 3D point P,
% this function finds the point in POINTS whose distance to P is less
% than EPS. The index the nearest point, if any, is returned in PIDX.
  [np, ~] = size(points);
  if np == 0
    pidx = [];
    return;
  end
  dist = zeros(np, 1);
  dist = dist + (points(:, 1) - p(1)) .^ 2;
  dist = dist + (points(:, 2) - p(2)) .^ 2;
  dist = dist + (points(:, 3) - p(3)) .^ 2;
  pidx = 1:np;
  pidx = pidx(dist <= eps * eps);
end % findPoint
