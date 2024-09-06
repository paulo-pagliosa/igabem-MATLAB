classdef LinearTriangle < Element
% LinearTriangla: 3D linear triangle element class
%
% Author: Paulo Pagliosa
% Last revision: 06/09/2024
%
% Description
% ===========
% An object of the class LinearTriangle represents an element whose
% shape function is an object of the class LinearTriangleShapeFunction.
%
% See also: class LinearTriangleShapeFunction

%% Public methods
methods
  function this = LinearTriangle(mesh, id)
  % Constructs a linear triangle
    this = this@Element(mesh, id);
    if ~isempty(mesh)
      this.shapeFunction = LinearTriangleShapeFunction;
    end
  end
end

%% Public static methods
methods (Static)
  function this = loadobj(s)
  % Loads a linear triangle
    this = Element.loadBase(@LinearTriangle, s);
  end
end

%% Protected methods
methods (Access = {?Element, ?Mesh})
  function checkNodes(this)
    assert(numel(this.nodes) == 3, 'Bad triangle nodes');
  end
end

end % LinearTriangle
