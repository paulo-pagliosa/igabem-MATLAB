classdef BezierElement < Element
% BezierElement: Bezier element class
%
% Author: Paulo Pagliosa
% Last revision: 12/08/2024
%
% Description
% ===========
% An object of the class BezierElement represents an element whose
% shape function is an object of the class BezierShapeFunction.
%
% See also: class BezierShapeFunction

%% Public methods
methods
  % Constructs a Bezier element
  function this = BezierElement(mesh, id, degree, nodeIds, C)
    this = this@Element(mesh, id, nodeIds);
    this.shapeFunction = BezierShapeFunction(degree, C);
  end
end

end % BezierElement
