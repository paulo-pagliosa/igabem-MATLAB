classdef (Abstract) Element < MeshComponent

properties
  face (1, 1) Face;
end

properties (SetAccess = {?Element, ?Mesh})
  shell (1, 1);
  nodes (:, 1) Node;
  nodeRegions (:, 1) int32;
  shapeFunction (1, 1);
end

methods (Access = protected)
  function this = Element(mesh, id, nodeIds)
    this = this@MeshComponent(mesh, id);
    this.nodes = mesh.findNode(nodeIds);
    nn = numel(this.nodes);
    if nn ~= numel(nodeIds)
      error('Undefined node(s) in element %d', id);
    end
    this.shell = mesh.outerShell;
    this.nodeRegions = ones(nn, 1);
  end
end

methods
  function nodes = nodeSet(these)
    nodes = NodeSet(these).nodes;
  end

  function n = nodeCount(this)
    n = numel(this.nodes);
  end

  function ids = nodeIds(this)
    ids = [this.nodes(:).id]';
  end

  function p = nodePositions(this)
    p = vertcat(this.nodes.position);
  end

  function u = nodeDisplacements(this)
    u = vertcat(this.nodes.u);
  end

  function t = nodeTractions(this)
    n = this.nodeCount;
    t = zeros(n, 3);
    for i = 1:n
      region = this.nodeRegions(i);
      node = this.nodes(i);
      t(i, :) = node.t(region, :);
    end
  end

  function move(this, t)
    this.nodes.move(t);
  end

  function [p, N] = positionAt(this, u, v)
    [p, N] = this.shapeFunction.interpolate(this.nodePositions, u, v);
    p = p(1:3) / p(4);
  end

  function [N, J] = normalAt(this, u, v)
    [~, ~, N] = this.tangentAt(u, v);
    if this.shell.flipNormalFlag
      N = N * -1;
    end
    J = norm(N);
    N = N ./ J;
  end
  
  function [su, sv, N] = tangentAt(this, u, v)
    [~, su, sv, N] = this.shapeFunction.interpolateDiff(this.nodePositions, ...
      u, ...
      v);
  end
end

end % Element
