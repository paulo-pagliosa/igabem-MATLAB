classdef BezierElement < Element
% BezierElement: Bezier element class
%
% Author: Paulo Pagliosa
% Last revision: 01/10/2024
%
% Description
% ===========
% An object of the class BezierElement represents an element whose
% shape function is an object of the class BezierShapeFunction.
%
% See also: BezierShapeFunction

%% Public properties
properties
  typeId = 0;
end

%% Public methods
methods
  function this = BezierElement(mesh, id, degree, C)
  % Constructs a Bezier element
    this = this@Element(mesh, id);
    if ~isempty(mesh) && nargin > 2
      this.shapeFunction = BezierShapeFunction(degree, C);
    end
  end
end

%% Public static methods
methods (Static)
  function this = loadobj(s)
  % Loads a Bezier element
    this = Element.loadBase(@BezierElement, s);
  end
end

end % BezierElement
