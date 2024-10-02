classdef BezierElementReader < ElementReader
% BezierElementReader: Bezier element reader class
%
% Author: Paulo Pagliosa
% Last revision: 01/10/2024
%
% Description
% ===========
% An object of the class BezierElementReader reads Bezier element data
% from a file. The element data includes: the id, the number of nodes, 
% the id and element region of each node, and optionally, the node ids
% of the face associated with the element.
%
% See also: BezierElement, Node, Face

%% Public methods
methods
  function this = BezierElementReader
  % Constructs a Bezier element reader
    this@ElementReader('BezierElement');
  end

  function element = read(this, file, noFaces)
  % Reads element data from a file
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
    element = this.mesh.makeElement(id, nodeIds, dg, C');
    Mesh.setNodeRegions(element, nodeRegions);
    if ~noFaces
      element.face = Face(element, faceNodeIds);
    end
  end
end

end % BezierElementReader
