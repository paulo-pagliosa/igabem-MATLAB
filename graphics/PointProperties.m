classdef PointProperties
% PointProperties: point properties class
%
% Author: Paulo Pagliosa
% Last revision: 01/10/2024
%
% Description
% ===========
% An object of the class PointProperties encapsulates the color, shape,
% and size of points to be rendered by a renderer.
%
% See also: Renderer

%% Public properties
properties
  color = 'black';
  shape = 'o';
  size = 5;
end

%% Public methods
methods
  function this = PointProperties(color, shape, size)
    this.color = color;
    this.shape = shape;
    this.size = size;
  end
end

end % PointProperties
