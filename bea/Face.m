classdef Face < handle
% Face: control mesh face class
%
% Author: Paulo Pagliosa
% Last revision: 19/09/2024
%
% Description
% ===========
% An object of the class Face represents a quadrilateral face of the
% control mesh of a piecewise parametric surface. A face is defined by
% the nodes corresponding to its four vertices. The face node of a
% virtual vertex is empty.

%% Public read-only properties
properties (SetAccess = {?Face, ?Mesh})
  nodes (:, 1) Node;
end

%% Public methods
methods
  function this = Face(element, nodeIds)
  % Constructs a face
    if nargin > 0
      if numel(nodeIds) ~= 4
        error('Four face node ids expected');
      end
      mesh = element.mesh;
      for i = 1:4
        node = Node.virtual;
        nid = nodeIds(i);
        if nid >= 0
          node = mesh.findNode(nid);
          if isempty(node)
            error('Undefined face node %d for element %d', nid, element.id);
          end
        end
        this.nodes(i) = node;
      end
    end
  end

  function b = isEmpty(this)
  % Returns true if this face is empty
    b = isempty(this.nodes);
  end
end

end % Face
