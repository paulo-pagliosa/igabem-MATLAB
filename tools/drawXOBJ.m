function h = drawXOBJ(axes, v, fdata, color)
% Draws an extended OBJ
%
% Author: Paulo Pagliosa
% Last revision: 12/12/2024
%
% Input
% =====
% AXES: axes in which the OBJ will be drawn
% V: array with the coordinates of the object vertices
% FDATA: cell array with the object faces
% COLOR: color for FACES{1} (default: white). AXES.COLORORDER is
% used for the other faces
%
% Output
% ======
% H: handle to patches
%
% See also: readXOBJ
  if nargin < 4
    color = [1 1 1];
  end
  if size(v, 2) == 4
    v = v(:, 1:3) ./ v(:, 4);
  end
  n = numel(fdata);
  h = zeros(n, 1);
  c = axes.ColorOrder;
  k = 1;
  while k <= n
    h(k) = makePatch(axes, v, fdata{k}, color);
    color = c(mod(k, size(c, 1)), :);
    k = k + 1;
  end

  function h = makePatch(axes, v, f, color)
    [u, ~, i] = unique(f, 'stable');
    v = v(u, :);
    f = reshape(i, size(f));
    h = patch('Parent', axes, ...)
      'Vertices', v, ...
      'Faces', f, ...
      'FaceColor', color, ...
      'FaceLighting', 'flat', ...
      'MarkerSize', 4, ...
      'Marker', 'o', ...
      'MarkerFaceColor', 'black');
  end
end % drawXOBJ
