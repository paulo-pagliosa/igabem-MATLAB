classdef BezierElement < Element
% BezierElement: Bezier element class
%
% Author: Paulo Pagliosa
% Last revision: 31/08/2024
%
% Description
% ===========
% An object of the class BezierElement represents an element whose
% shape function is an object of the class BezierShapeFunction.
%
% See also: class BezierShapeFunction

%% Public methods
methods
  function this = BezierElement(mesh, id, degree, nodeIds, C)
  % Constructs a Bezier element
    this = this@Element(mesh, id, nodeIds);
    this.shapeFunction = BezierShapeFunction(degree, C);
  end
end

end % BezierElement
