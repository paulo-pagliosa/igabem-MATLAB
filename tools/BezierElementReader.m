classdef BezierElementReader < ElementReader
% BezierElementReader: Bezier element reader class
%
% Author: Paulo Pagliosa
% Last revision: 12/08/2024
%
% Description
% ===========
% An object of the class BezierElementReader reads Bezier element data
% from a file. The element data includes: the id, the number of nodes, 
% the id and element region of each node, and optionally, the node ids
% of the face associated with the element.
%
% See also: class BezierElement, class Node, class Face

%% Public methods
methods
  % Constructor
  function this = BezierElementReader
    this@ElementReader('BezierElement');
  end

  % Reads element data from a file
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