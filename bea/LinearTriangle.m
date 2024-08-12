classdef LinearTriangle < Element

methods
  function this = LinearTriangle(mesh, id, nodeIds)
    assert(numel(nodeIds) == 3, 'Bad triangle node ids');
    this = this@Element(mesh, id, nodeIds);
    this.shapeFunction = LinearTriangleShapeFunction;
  end
end

end % LinearTriangle
