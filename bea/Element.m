classdef (Abstract) Element < MeshComponent
% Element: generic element class
%
% Author: Paulo Pagliosa
% Last revision: 12/08/2024
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
% See also: class Mesh, class Node, class NodeSet, class Face

%% Public properties
properties
  face (1, 1) Face;
end

%% Public read-only properties
properties (SetAccess = {?Element, ?Mesh})
  shell (1, 1);
  nodes (:, 1) Node;
  nodeRegions (:, 1) int32;
  shapeFunction (1, 1);
end

%% Protected methods
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

%% Public methods
methods
  % Returns the node set of this element
  function nodes = nodeSet(these)
    nodes = NodeSet(these).nodes;
  end

  % Returns the number of nodes of this element
  function n = nodeCount(this)
    n = numel(this.nodes);
  end

  % Returns the node ids of this element
  function ids = nodeIds(this)
    ids = [this.nodes(:).id]';
  end

  % Returns the node positions of this element
  function p = nodePositions(this)
    p = vertcat(this.nodes.position);
  end

  % Returns the node displacements of this element
  function u = nodeDisplacements(this)
    u = vertcat(this.nodes.u);
  end

  % Returns the node traction values of this element
  function t = nodeTractions(this)
    n = this.nodeCount;
    t = zeros(n, 3);
    for i = 1:n
      region = this.nodeRegions(i);
      node = this.nodes(i);
      t(i, :) = node.t(region, :);
    end
  end

  % Moves the nodes of this element
  function move(this, t)
    this.nodes.move(t);
  end

  % Computing the position at (U,V)
  function [p, N] = positionAt(this, u, v)
    [p, N] = this.shapeFunction.interpolate(this.nodePositions, u, v);
    p = p(1:3) / p(4);
  end

  % Computing the normal at (U,V)
  function [N, J] = normalAt(this, u, v)
    [~, ~, N] = this.tangentAt(u, v);
    if this.shell.flipNormalFlag
      N = N * -1;
    end
    J = norm(N);
    N = N ./ J;
  end

  % Compute the tangents and normal at (U,V)
  function [su, sv, N] = tangentAt(this, u, v)
    [~, su, sv, N] = this.shapeFunction.computeNormal(this.nodePositions, ...
      u, ...
      v);
  end
end

end % Element
