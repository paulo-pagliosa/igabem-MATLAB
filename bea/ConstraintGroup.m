classdef ConstraintGroup < BCGroup
% ConstraintGroup: region constraint class
%
% Author: Paulo Pagliosa
% Last revision: 31/08/2024
%
% Description
% ===========
% An object of the class ConstraintGroup represents a constraint imposed
% to the elements of an element region of a BEA model.
%
% See also: class Constraint

%% Public methods
methods
  function this = ConstraintGroup(id, elements, dofs, evaluator, varargin)
  % Constructs a constraint group
    narginchk(4, inf);
    this = this@BCGroup(id, elements);
    ndof = numel(dofs);
    dofs = BC.parseDofs(dofs);
    [evaluator, dir] = BC.parseArgs(evaluator, varargin{:});
    id = id * 1000;
    ne = numel(elements);
    this.bcs = Constraint.empty(0, ne);
    for i = 1:ne
      id = id + 1;
      cg = Constraint(id, elements(i), dofs);
      cg.setProps(ndof, evaluator, dir);
      if isnumeric(cg.evaluator)
        nd = [0 0 0];
        nd(dofs > 0) = cg.evaluator;
        cg.direction = nd;
        cg.evaluator = BCFunction.constant(1);
      end
      this.bcs(i) = cg;
    end
  end
end

%% Protected methods
methods (Access = protected)
  function setValues(this, nodes, regions, u)
    dofs = this.dofs;
    m = numel(nodes);
    for i = 1:m
      node = nodes(i);
      for k = 1:3
        dof = dofs(k);
        if dof > 0
          Constraint.checkDof(dof, node, regions, u, i);
        end
      end
    end
    for i = 1:m
      node = nodes(i);
      for k = 1:3
        dof = dofs(k);
        if dof > 0
          Constraint.setValue(dof, node, regions, u, i);
        end
      end
    end
  end
end

end % ConstraintGroup
