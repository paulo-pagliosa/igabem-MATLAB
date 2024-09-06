classdef ConstraintGroup < BCGroup
% ConstraintGroup: region constraint class
%
% Author: Paulo Pagliosa
% Last revision: 06/09/2024
%
% Description
% ===========
% An object of the class ConstraintGroup represents a constraint imposed
% to the elements of an element region of a BEA model.
%
% See also: class Constraint

%% Public static methods
methods (Static)
  function this = New(id, elements, dofs, evaluator, varargin)
  % Constructs a constraint group
    narginchk(4, inf);
    assert(isa(elements, 'Element'), 'Element expected');
    ndof = numel(dofs);
    dofs = BC.parseDofs(dofs);
    [evaluator, dir] = BC.parseArgs(evaluator, varargin{:});
    cid = id * 1000;
    n = numel(elements);
    bcs = BC.empty(0, n);
    for i = 1:n
      cid = cid + 1;
      bc = Constraint(elements(i).mesh, cid, elements(i), dofs);
      bc.setProps(ndof, evaluator, dir);
      if isnumeric(bc.evaluator)
        cd = [0 0 0];
        cd(dofs > 0) = bc.evaluator;
        bc.direction = cd;
        bc.evaluator = BCFunction.constant(1);
      end
      bcs(i) = bc;
    end
    this = ConstraintGroup(elements(1).mesh, id, bcs);
  end

  function this = loadobj(s)
  % Loads a constraint group
    this = BCGroup.loadBase(@ConstraintGroup, s);
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
