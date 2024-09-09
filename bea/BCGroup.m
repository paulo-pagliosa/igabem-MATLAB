classdef (Abstract) BCGroup < MeshComponent
% BCGroup: generic region boundary condition class
%
% Author: Paulo Pagliosa
% Last revision: 09/09/2024
%
% Description
% ===========
% The abstract class BCGroup is a mesh component that encapsulates
% the properties and behavior of a generic boundary conditions applied
% to the elements of an element region of a BEA model.
%
% See also: class Element, class BC

%% Publc properties
properties
  resolution = 10;
end

%% Public read-only properties
properties (SetAccess = {?BCGroup, ?Mesh})
  elements (:, 1) Element = Element.empty;
  bcs (:, 1) BC = BC.empty;
end

%% Public methods
methods
  function s = saveobj(this)
    % Saves this BC group
    s = saveobj@MeshComponent(this);
    s.bcs = this.bcs;
    s.resolution = this.resolution;
  end

  function set.resolution(this, value)
  % Sets the number of samples in U and V to evaluate this BC group
    if value < 5 || value > 20
      fprintf("'resolution' must be in range [5,20]\n");
    else
      this.resolution = value;
    end
  end

  function dofs = dofs(this)
  % Returns the dofs of this BC group
    dofs = this.bcs(1).dofs;
  end

  function merge(this, group)
  % Merges two BC groups
    assert(isa(group, 'BCGroup'), 'BC group expected');
    if group == this
      return;
    end
    if this.mesh ~= group.mesh || any(this.dofs ~= group.dofs)
      error('Mismatch BC groups');
    end
    this.setBCs([this.bcs; group.bcs]);
    group.bcs = BC.empty;
    group.elements = Element.empty;
  end

  function x = apply(this)
  % Applies the BCs in this BC group to the node set of its elements
    n = this.resolution;
    p = gridSpace(n);
    nodes = NodeSet(this.elements);
    n = nodes.size;
    regions = zeros(n, 1);
    for i = 1:n
      regions(i) = this.nodeRegion(nodes.nodes(i));
    end
    m = numel(this.bcs);
    s = size(p, 1);
    r = m * s;
    A = zeros(r, n);
    dofs = this.dofs;
    dofs = dofs(dofs > 0);
    b = zeros(r, numel(dofs));
    rows = 1:s;
    for i = 1:m
      bc = this.bcs(i);
      [Ai, bi] = bc.assemblyLS(p, dofs);
      cols = nodes.index(bc.element.nodes);
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

%% Protected methods
methods (Access = {?BCGroup, ?Mesh})
  function this = BCGroup(mesh, id, bcs)
    this = this@MeshComponent(mesh, id);
    if ~isempty(mesh) && ~isempty(bcs)
      assert(isa(bcs, 'BC'), 'BC expected');
      for i = 1:numel(bcs)
        assert(this.mesh == bcs(i).mesh, 'Bad BC');
      end
      this.setBCs(bcs);
    end
  end

  function setBCs(this, bcs)
    this.elements = unique([bcs.element], 'stable');
    this.bcs = bcs;
  end

  function region = nodeRegion(this, node)
    region = 0;
    n = numel(this.elements);
    for i = 1:n
      element = this.elements(i);
      m = element.nodeCount;
      for k = 1:m
        if element.nodes(k) == node
          r = element.nodeRegions(k);
          if region == 0
            region = r;
          elseif r ~= region
            error('Multiple BC regions at node %d', node.id);
          end
        end
      end
    end
  end
end

methods (Abstract, Access = protected)
  setValues(this, nodes, regions, x);
end

%% Protected static methods
methods (Static, Access = {?BCGroup, ?Mesh})
  function this = loadBase(ctor, s)
    this = ctor(Mesh.empty, s.id, BC.empty);
    this.bcs = s.bcs;
    this.resolution = s.resolution;
  end
end

end % BCGroup
