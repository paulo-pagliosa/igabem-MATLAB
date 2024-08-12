classdef BCGroup < MeshComponent

properties (SetAccess = protected)
  elements (:, 1) Element = Element.empty;
  bcs BC = BC.empty;
end

methods (Access = protected)
  function this = BCGroup(id, elements)
    assert(isa(elements, 'Element'), 'Mesh element expected');
    mesh = elements(1).mesh;
    for i = 2:numel(elements)
      assert(elements(i).mesh == mesh, 'Bad elements');
    end
    this = this@MeshComponent(mesh, id);
    this.elements = elements;
  end

  function nodeRegion = nodeRegion(this, node)
    nodeRegion = 0;
    n = numel(this.elements);
    for i = 1:n
      element = this.elements(i);
      m = element.nodeCount;
      for k = 1:m
        if element.nodes(k) == node
          r = element.nodeRegions(k);
          if nodeRegion == 0
            nodeRegion = r;
          elseif r ~= nodeRegion
            error('Multiple BC regions at node %d', node.id);
          end
        end
      end
    end
  end
end

methods
  function dofs = dofs(this)
    dofs = this.bcs(1).dofs;
  end

  function merge(this, group)
    assert(isa(group, 'BCGroup'), 'BC group expected');
    if group == this
      return;
    end
    if this.mesh ~= group.mesh || any(this.dofs ~= group.dofs)
      error('Mismatch BC groups');
    end
    % TODO: check for duplicate elements
    this.elements = [this.elements; group.elements];
    this.bcs = [this.bcs; group.bcs];
    group.elements = Element.empty;
    group.bcs = BC.empty;
  end

  function x = apply(this)
    n = 10; % TODO
    p = gridSpace(n);
    nodes = NodeSet(this.elements);
    n = nodes.size;
    regions = zeros(n, 1);
    for i = 1:n
      regions(i) = this.nodeRegion(nodes.nodes(i));
    end
    m = numel(this.elements);
    s = size(p, 1);
    r = m * s;
    A = zeros(r, n);
    dofs = this.dofs;
    dofs = dofs(dofs > 0);
    b = zeros(r, numel(dofs));
    rows = 1:s;
    for i = 1:m
      [Ai, bi] = this.bcs(i).assemblyLS(p, dofs);
      cols = nodes.index(this.elements(i).nodes);
      A(rows, cols) = Ai;
      b(rows, :) = bi;
      rows = rows + s;
    end
    A = sparse(A);
    x = zeros(n, 3);
    x(:, dofs) = A \ b;
    this.setValues(nodes.nodes, regions, x);
  end
end

methods (Abstract, Access = protected)
  setValues(this, nodes, regions, x);
end

end % BCGroup
