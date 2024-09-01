classdef NodeSet < handle
% NodeSet: node set class
%
% Author: Paulo Pagliosa
% Last revision: 31/08/2024
%
% Description
% ===========
% An object of the class NodeSet represents a set of nodes that influence
% a set of elements.
%
% See also: class Node, class Element

%% Public read-only properties
properties (SetAccess = private)
  nodes (:, 1) Node = Node.empty;
end

%% Public methods
methods
  function this = NodeSet(element)
  % Contructs a node set from a set of elements
    this.nodes = element.nodes;
    n = numel(element);
    if n > 1
      mesh = element(1).mesh;
      nodeIds = element(1).nodeIds;
      for i = 2:n
        assert(element(i).mesh == mesh, ...
          'Element is not a member of ''%s''', ...
          mesh.name);
        nodeIds = union(nodeIds, element(i).nodeIds);
      end
      this.nodes = mesh.findNode(nodeIds);
    end
  end

  function n = size(this)
  % Returns the number of nodes in this node set
    n = numel(this.nodes);
  end

  function index = index(this, node)
  % Returns the index of the nodes in this node set
    n = numel(node);
    index = zeros(n, 1, 'int32');
    for k = 1:n
      i = find(this.nodes == node(k));
      if ~isempty(i)
        index(k) = i;
      end
    end
  end
end
  
end % NodeSet
