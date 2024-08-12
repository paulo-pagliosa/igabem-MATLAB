classdef BezierElement < Element

methods
  function this = BezierElement(mesh, id, degree, nodeIds, C)
    this = this@Element(mesh, id, nodeIds);
    this.shapeFunction = BezierShapeFunction(degree, C);
  end
end

end % BezierElement
