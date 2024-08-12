classdef BezierElementReader < ElementReader

methods
  function this = BezierElementReader
    this@ElementReader('BezierElement');
  end

  function element = read(this, file, noFaces)
    elementInfo = fscanf(file, '%d', 3);
    id = elementInfo(1);
    nn = elementInfo(2);
    dg = elementInfo(3);
    if ~noFaces
      faceNodeIds = fscanf(file, '%d', 4);
    end
    nodeIds = fscanf(file, '%d', nn);
    nodeRegions = fscanf(file, '%d', nn);
    C = fscanf(file, '%f', [(dg + 1) ^ 2, nn]);
    element = this.mesh.makeElement(id, dg, nodeIds, C');
    Mesh.setNodeRegions(element, nodeRegions);
    if ~noFaces
      element.face = Face(this.mesh, faceNodeIds);
    end
  end
end

end % BezierElementReader
