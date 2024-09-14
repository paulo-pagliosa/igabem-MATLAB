classdef Node < MeshComponent
% Node: node class
%
% Author: Paulo Pagliosa
% Last revision: 14/09/2024
%
% Description
% ===========
% An object of the class Node is a mesh component that represents a node
% of a BEA model. The properties of a node are the position (and weight),
% multiplicity, dofs (defining which degrees of freedom are unknowns or
% have prescribed values), displacement, traction values (according to the
% multiplicity), and associated load point.
%
% See also: class Mesh, class LoadPoint

%% Public properties
properties
  position (1, 4) double;
  loadPoint;
end

%% Public read-only properties
properties (SetAccess = {?Mesh, ?BC, ?BCGroup, ?Solver})
  multiplicity int32 = 1;
  dofs int32 = [0 0; 0 0; 0 0];
  u (1, 3) double = [0 0 0];
  t (:, 3) double = [0 0 0];  
end

%% Public constant properties
properties (Constant)
  virtual = Node(Mesh.empty, -1, [0 0 0 0]);
end

%% Public methods
methods
  function this = Node(mesh, id, position)
  % Constructs a node
    this = this@MeshComponent(mesh, id);
    this.position = position;
  end

  function s = saveobj(this)
    % Saves this node
    s = saveobj@MeshComponent(this);
    s.position = this.position;
    s.multiplicity = this.multiplicity;
    s.dofs = this.dofs;
    s.u = this.u;
    s.t = this.t;
  end

  function b = isVirtual(this)
    b = this == Node.virtual;
  end

  function move(these, u)
  % Moves a set of nodes
    assert(size(u, 2) == 3, '3D point expected');
    n = numel(these);
    if (size(u, 1) ~= n)
      u = repmat(u, n, 1);
    end
    p = vertcat(these.position);
    p(:, 1:3) = p(:, 1:3) + u;
    for i = 1:n
      these(i).position = p(i, :);
    end
  end
end

%% Public static methods
methods (Static)
  function this = loadobj(s)
  % Loads a node
    this = Node(Mesh.empty, s.id, s.position);
    this.multiplicity = s.multiplicity;
    this.dofs = s.dofs;
    this.u = s.u;
    this.t = s.t;
  end
end

end % Node
