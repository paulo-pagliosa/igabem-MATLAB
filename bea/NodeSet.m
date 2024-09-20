classdef NodeSet < handle
% NodeSet: node set class
%
% Author: Paulo Pagliosa
% Last revision: 20/09/2024
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
  function this = NodeSet(elements)
  % Contructs a node set from a set of elements
    assert(isa(elements, 'Element'), 'Element expected');
    assert(~isempty(elements), 'Empty element set');
    n = numel(elements);
    if n == 1
      this.nodes = elements.nodes;
    else
      mesh = elements(1).mesh;
      nids = elements(1).nodeIds;
      for i = 2:n
        element = elements(i);
        assert(element.mesh == mesh, ...
          'Element %d is not a member of mesh ''%s''', ...
          element.id, ...
          mesh.name);
        nids = union(nids, element.nodeIds);
      end
      this.nodes = mesh.findNode(nids);
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
