classdef (Abstract) Element < MeshComponent
% Element: generic element class
%
% Author: Paulo Pagliosa
% Last revision: 01/10/2024
%
% Description
% ===========
% The abstract class Element is a mesh component that encapsulates the
% properties and behavior of a generic element of a BEA model. The
% properties of an element are the set of element nodes, the element
% region for each element node, the element shape functions, and the
% element face. The class define methods for getting the element node set,
% and the id, position, displacement, and traction values of the element
% nodes. Also, there are methods for computing the position, tangents,
% and normal given the parametric coordinates of a point in the element.
%
% See also: Mesh, Node, NodeSet, Face

%% Public properties
properties (Abstract)
  typeId int32;
end

properties
  face (1, 1) Face;
end

%% Public read-only properties
properties (SetAccess = {?Element, ?Mesh})
  shell Shell;
  nodes (:, 1) Node;
  nodeRegions (:, 1) int32;
  shapeFunction (1, 1);
end

%% Public methods
methods
  function s = saveobj(this)
  % Saves this element
    s = saveobj@MeshComponent(this);
    s.typeId = this.typeId;
    s.nodeRegions = this.nodeRegions;
    s.shapeFunction = this.shapeFunction;
  end

  function nodes = nodeSet(these)
  % Returns the node set of this element
    nodes = NodeSet(these).nodes;
  end

  function n = nodeCount(this)
  % Returns the number of nodes of this element
    n = numel(this.nodes);
  end

  function ids = nodeIds(this)
  % Returns the node ids of this element
    ids = [this.nodes(:).id]';
  end

  function p = nodePositions(this)
  % Returns the node positions of this element
    p = vertcat(this.nodes.position);
  end

  function u = nodeDisplacements(this)
  % Returns the node displacements of this element
    u = vertcat(this.nodes.u);
  end

  function t = nodeTractions(this)
  % Returns the node traction values of this element
    n = this.nodeCount;
    t = zeros(n, 3);
    for i = 1:n
      region = this.nodeRegions(i);
      node = this.nodes(i);
      t(i, :) = node.t(region, :);
    end
  end

  function move(this, t)
  % Moves the nodes of this element
    this.nodes.move(t);
  end

  function [p, N] = positionAt(this, u, v)
  % Computes the position at (U,V)
    [p, N] = this.shapeFunction.interpolate(this.nodePositions, u, v);
    p = p(1:3) / p(4);
  end

  function [N, J] = normalAt(this, u, v)
  % Computing the normal at (U,V)
    [~, ~, N] = this.tangentAt(u, v);
    if this.shell.flipNormalFlag
      N = N * -1;
    end
    J = norm(N);
    N = N ./ J;
  end

  function [Su, Sv, N, p] = tangentAt(this, u, v)
  % Compute the tangents and normal at (U,V)
    [N, Su, Sv, p] = this.shapeFunction.computeNormal(this.nodePositions, ...
      u, ...
      v);
  end
end

%% Protected methods
methods (Access = {?Element, ?Mesh})
  function checkNodes(~)
    % do nothing
  end
end

%% Protected static methods
methods (Static, Access = {?Element, ?Mesh})
  function ctor = findConstructor(className)
    c = meta.class.fromName(className);
    assert(~isempty(c), 'Unable to find class %s', className);
    s = findobj(c.SuperclassList, 'Name', 'Element');
    assert(~isempty(s), '%s is not derived from Element', className);
    ctor = findobj(c.MethodList, 'Name', className, 'Access', 'public');
    assert(~isempty(ctor), 'No public constructor in class %s', className);
    ctor = ctor.Name;
  end

  function this = create(ctor, mesh, id, varargin)
    args = horzcat({mesh, id}, varargin{:});
    this = feval(ctor, args{:});
  end

  function this = loadBase(ctor, s)
    this = ctor(Mesh.empty, s.id);
    this.typeId = s.typeId;
    this.nodeRegions = s.nodeRegions;
    this.shapeFunction = s.shapeFunction;
  end
end

end % Element
