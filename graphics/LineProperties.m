classdef LineProperties
% LineProperties: line properties class
%
% Author: Paulo Pagliosa
% Last revision: 12/08/2024
%
% Description
% ===========
% An object of the class LineProperties encapsulates the color, style,
% and width of lines to be rendered by a renderer (see the class Renderer).

%% Public properties
properties
  color = 'black';
  style = '-';
  width = 1;
end

%% Public methods
methods
  function this = LineProperties(color, style, width)
    this.color = color;
    this.style = style;
    this.width = width;
  end
end

end % LineProperties
