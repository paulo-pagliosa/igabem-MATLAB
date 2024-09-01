classdef Constraint < BC
% Constraint: element constraint class
%
% Author: Paulo Pagliosa
% Last revision: 31/08/2024
%
% Description
% ===========
% An object of the class Constraint represents a displacement contrainst
% imposed to an element of a BEA model.
% A detailed documentation is available in
%
% https://github.com/paulo-pagliosa/igabem-MATLAB
%
% See also: class Element, class MeshInterface

%% Public constants
properties (Constant)
  tolerance = 1 / 100;
end

%% Public static methods
methods (Static)
  function c = New(id, element, dofs, evaluator, varargin)
  % Constructs a constraint
    narginchk(4, inf);
    c = Constraint(id, element, BC.parseDofs(dofs));
    BC.parseProps(c, numel(dofs), evaluator, varargin{:});
  end
end

%% Private methods
methods (Access = {?Constraint, ?ConstraintGroup})
  function this = Constraint(id, element, dofs)
    this = this@BC(id, element);
    this.dofs = dofs;
    this.direction = [];
  end
end

%% Protected methods
methods (Access = protected)
  function setValues(this, u)
    regions = this.element.nodeRegions;
    m = this.element.nodeCount;
    for i = 1:m
      node = this.element.nodes(i);
      for k = 1:3
        dof = this.dofs(k);
        if dof > 0
          Constraint.checkDof(dof, node, regions, u, i);
        end
      end
    end
    for i = 1:m
      node = this.element.nodes(i);
      for k = 1:3
        dof = this.dofs(k);
        if dof > 0
          Constraint.setValue(dof, node, regions, u, i);
        end
      end
    end
  end
end

%% Private static methods
methods (Static, Access = {?Constraint, ?ConstraintGroup, ?Mesh})
  function checkDof(dof, node, regions, u, i)
    if node.dofs(dof, 1) == 0
      return;
    end
    if node.dofs(dof, 2) ~= regions(i)
      error('Multiple constraint values at node %d', node.id);
    end
    v = u(i, dof);
    r = node.u(dof);
    e = abs(v - r);
    if e < Constraint.tolerance
      return;
    end
    e = e / abs(max(v, r));
    if e > Constraint.tolerance
      error('Multiple constraint values at node %d (error: %f)', node.id, e);
    end
  end

  function setValue(dof, node, regions, u, i)
    node.dofs(dof, 1) = node.dofs(dof, 1) + 1;
    node.dofs(dof, 2) = regions(i);
    node.u(dof) = u(i, dof);
  end

  function release(nodes, dofs)
    m = numel(nodes);
    for i = 1:m
      node = nodes(i);
      for k = 1:3
        dof = dofs(k);
        if dof > 0
          node.dofs(dof, 1) = node.dofs(dof, 1) - 1;
          if node.dofs(dof, 1) == 0
            node.u(dof) = 0;
            node.dofs(dof, 2) = 0;
          end
        end
      end
    end
  end
end

end % Constraint
