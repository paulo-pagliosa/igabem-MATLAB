classdef LinearTriangle < Element
% LinearTriangla: 3D linear triangle element class
%
% Author: Paulo Pagliosa
% Last revision: 12/08/2024
%
% Description
% ===========
% An object of the class LinearTriangle represents an element whose
% shape function is an object of the class LinearTriangleShapeFunction.
%
% See also: class LinearTriangleShapeFunction

%% Public methods
methods
  % Constructs a linear triangle
  function this = LinearTriangle(mesh, id, nodeIds)
    assert(numel(nodeIds) == 3, 'Bad triangle node ids');
    this = this@Element(mesh, id, nodeIds);
    this.shapeFunction = LinearTriangleShapeFunction;
  end
end

end % LinearTriangle
