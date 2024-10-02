classdef VirtualPointSet < handle
% VirtualPointSet: virtual point set class
%
% Author: Paulo Pagliosa
% Last revision: 01/10/2024
%
% Description
% ===========
% An object of the class VirtualPointSet represents the set of element
% corners corresponding to the virtual nodes of a mesh. A virtual node
% is a node of the face of an element that has no corresponding mesh
% node, e.g., the end point of a T-junction face extension or a local
% point of a subd patch.
%
% See also: Node, Face

%% Public read-only properties
properties (SetAccess = private)
  points (:, 3) double;
end

%% Public methods
methods
  function this = VirtualPointSet(mesh)
  % Contructs a virtual point set of a mesh
    assert(isa(mesh, 'Mesh'), 'Mesh expected');
    lc = [-1 -1; 1 -1; 1 1; -1 1];
    ne = mesh.elementCount;
    points = zeros(ne, 3);
    ip = 0;
    for e = 1:ne
      element = mesh.elements(e);
      face = element.face;
      if face.isEmpty
        fprintf('No element faces\n');
        return;
      end
      for k = 1:4
        fnid = face.nodes(k).id;
        if fnid > 0 % node is not virtual
          continue;
        end
        csi = lc(k, :);
        p = element.positionAt(csi(1), csi(2));
        pidx = findPoint(p, points(1:ip, :), 1e-6);
        if isempty(pidx)
          ip = ip + 1;
          points(ip, :) = p;
        end
      end
    end
    this.points = points(1:ip, :);
  end
end
  
end % VirtualPointSet
