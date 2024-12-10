function h = drawPoints(axes, points, color, shape, pointSize)
% Draws a point set
%
% Author: Paulo Pagliosa
% Last revision: 06/12/2024
%
% Input
% =====
% AXES: axes in which the points will be drawn
% POINTS: NPx3 matrix with the points' coordinates
% COLOR: points' color
% SHAPE: points' shape (default: 'o')
% POINTSIZE: points' size (default = 5)
%
% Output
% ======
% H: handle to the line plot object
  if nargin < 4
    shape = 'o';
  end
  if nargin < 5
    pointSize = 5;
  end
  h = line('Parent', axes, ...
    'XData', points(:, 1), ...
    'YData', points(:, 2), ...
    'ZData', points(:, 3), ...
    'LineStyle', 'none', ...
    'MarkerFaceColor', color, ...
    'MarkerEdgeColor', color, ...
    'Marker', shape, ...
    'MarkerSize', pointSize, ...
    'HitTest', 'off');
end % drawPoints
