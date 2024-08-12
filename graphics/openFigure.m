function a = openFigure(title)
% Opens a new figure
%
% Author: Paulo Pagliosa
% Last revision: 12/08/2024
%
% Input
% =====
% TITLE: title of the figure to be open
%
% Output
% ======
% A: figure axes handle
  f = figure;
  if nargin == 1
    f.Name = title;
  end
  f.MenuBar = 'none';
  a = gca;
  axis(a, 'square', 'equal', 'tight', 'vis3d');
  %cameratoolbar;
  %rotate3d on;
end % openFigure

