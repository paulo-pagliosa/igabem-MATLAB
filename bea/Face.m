classdef Face < handle
% An object of the class Face repreents a quadrilateral face of the
% control mesh of a piecewise parametric surface. A face is defined
% by four nodes corresponding to its four vertices.

properties
  nodes (:, 1) Node;
end

methods
  function this = Face(mesh, nodeIds)
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
