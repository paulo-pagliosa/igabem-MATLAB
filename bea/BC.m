classdef (Abstract) BC < MeshComponent
% BC: generic element boundary condition class
%
% Author: Paulo Pagliosa
% Last revision: 03/10/2024
%
% Description
% ===========
% The abstract class BC is a mesh component that encapsulates
% the properties and behavior of a generic boundary condition (BC)
% applied to an element of a BEA model. The properties of a BC are
% the element to which the boundary condition is applied, the dofs
% (specifying which degrees of freedom have prescribed values), an
% evaluator (for computing the BC values at points in the element),
% and the direction in which the prescribed values act (if defined
% as scalars).
%
% See also: Element, BCGroup

%% Public read-only properties
properties (SetAccess = {?BC, ?BCGroup, ?Mesh})
  element Element;
  dofs (1, 3);
  evaluator;
  direction;
end

%% Public methods
methods
  function s = saveobj(this)
  % Saves this boundary condition
    s = saveobj@MeshComponent(this);
    s.dofs = this.dofs;
    s.evaluator = this.evaluator;
    s.direction = this.direction;
  end

  function x = apply(this, p)
  % Applies this boundary condition to the nodes of its element
    n = this.element.nodeCount;
    idx = this.dofs(this.dofs > 0);
    if isnumeric(this.evaluator)
      c = repmat(this.evaluator, n, 1);
    else
      [A, b] = this.assemblyLS(p, idx);
      c = A \ b;
    end
    x = zeros(n, 3);
    x(:, idx) = c;
    % save(strcat('x', num2str(this.element.id)), 'x');
    this.setValues(x);
  end
end

%% Public static methods
methods (Static)
  function dof = parseDof(dof)
  % Parses a dof
    if ischar(dof)
      switch dof
        case 'x'
          dof = 1;
        case 'y'
          dof = 2;
        case 'z'
          dof = 3;
      end
    end
    if ~isscalar(dof) || dof < 1 || dof > 3
      error('Invalid dof');
    end
  end

  function dofs = parseDofs(dofs)
  % Parses XYZ dofs
    n = numel(dofs);
    assert(n > 0 && n < 4, 'Bad dof dimension');
    temp = dofs;
    dofs = [0 0 0];
    for i = 1:n
      dof = BC.parseDof(temp(i));
      if dofs(dof) > 0
        error('Bad dof array');
      end
      dofs(dof) = dof;
    end
  end
end

%% Protected methods
methods (Access = protected)
  function this = BC(mesh, id, element)
    this = this@MeshComponent(mesh, id);
    if ~isempty(mesh) && nargin > 2
      if isa(element, 'Element')
        assert(mesh == element.mesh, 'Bad element');
        this.element = element;
      else
        this.element = mesh.findElement(element);
        if isempty(this.element)
          error('Undefined element %d', element);
        end
      end
    end
  end
end

methods (Abstract, Access = protected)
  setValues(this, x);
end

methods (Access = {?BC, ?BCGroup})
  function setProps(this, dim, evaluator, direction)
    if any(direction ~= 0)
      this.direction = direction;
    end
    if isnumeric(evaluator)
      if ~isscalar(evaluator)
        if numel(evaluator) ~= dim
          error('Bad BC dimension');
        end
        if ~isempty(this.direction)
          warning('BC direction will be ignored');
        end
      elseif ~isempty(this.direction)
        evaluator = BCFunction.constant(evaluator);
      else
        evaluator = repmat(evaluator, 1, dim);
      end
    end
    this.evaluator = evaluator;
  end

  function [A, b] = assemblyLS(this, p, dofs)
    [m, n] = size(p);
    assert(n == 2, '2D vector expected');
    n = this.element.nodeCount;
    r = this.element.nodePositions;
    s = this.element.shapeFunction;
    A = zeros(m, n);
    b = zeros(m, numel(dofs));
    D = this.direction;
    if isempty(D)
      D = [1 1 1];
    end
    sign = 1;
    if this.element.shell.flipNormalFlag
      sign = -1;
    end
    for i = 1:m
      u = p(i, 1);
      v = p(i, 2);
      [P, S] = s.interpolate(r, u, v);
      A(i, :) = S';
      if isnan(this.direction)
        D = s.computeGradient(r, u, v);
        D = D ./ norm(D) * sign;
      end
      P = P(1:3) / P(4);
      c = this.evaluator(u, v, P) .* D(dofs);
      b(i, :) = c;
    end
  end
end

%% Protected static methods
methods (Static, Access = {?BC, ?BCGroup})
  function this = loadBase(ctor, s)
    this = ctor(Mesh.empty, s.id);
    this.dofs = s.dofs;
    this.evaluator = s.evaluator;
    this.direction = s.direction;
  end

  function [direction, nargs] = parseDirection(varargin)
    direction = [0 0 0];
    nargs = 0;
    n = numel(varargin); 
    if n == 0 || ~ischar(varargin{1})
      return;
    end
    if ~strcmp(varargin{1}, 'direction') || n < 2
      error('BC direction expected');
    end
    direction = varargin{2};
    if ischar(direction)
      switch direction
        case 'none'
          direction = [];
        case 'normal'
          direction = NaN;
        otherwise
          error('Invalid direction');
      end
    elseif isnumeric(direction)
      assert(numel(direction) == 3, '3D vector expected');
      l = norm(direction);
      assert(l > 0, 'Null BC direction');
      direction = direction / l;
    end
    nargs = 2;
  end

  function [evaluator, direction] = parseArgs(evaluator, varargin)
    [evaluator, nf] = BCFunction.parse(evaluator, varargin{:});
    [direction, nd] = BC.parseDirection(varargin{nf + 1:end});
    assert(nf + nd == numel(varargin), 'Too many BC arguments');
  end

  function parseProps(bc, dim, evaluator, varargin)
    [evaluator, dir] = BC.parseArgs(evaluator, varargin{:});
    bc.setProps(dim, evaluator, dir);
  end
end

end % BC
