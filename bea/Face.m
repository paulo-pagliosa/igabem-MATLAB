classdef Face < handle
% Face: control mesh face class
%
% Author: Paulo Pagliosa
% Last revision: 31/08/2024
%
% Description
% ===========
% An object of the class Face represents a quadrilateral face of the
% control mesh of a piecewise parametric surface. A face is defined by
% the nodes corresponding to its four vertices.

%% Public read-only properties
properties (SetAccess = private)
  nodes (:, 1) Node;
end

%% Public methods
methods
  function this = Face(mesh, nodeIds)
  % Constructs a face
    if nargin > 0
      if numel(nodeIds) ~= 4
        error('Four face node ids expected');
      end
      temp = mesh.findNode(nodeIds);
      if numel(temp) ~= 4
        error('Undefined node(s) in face');
      end
      this.nodes = temp;
    end
  end
end

end % Face
