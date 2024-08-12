classdef Node < MeshComponent

properties
  position (1, 4) double;
  loadPoint;
end

properties (SetAccess = {?Mesh, ?BC, ?BCGroup, ?Solver})
  multiplicity int32 = 1;
  dofs int32 = [0 0; 0 0; 0 0];
  u (1, 3) double = [0 0 0];
  t (:, 3) double = [0 0 0];  
end

methods
  function this = Node(mesh, id, position)
    this = this@MeshComponent(mesh, id);
    this.position = position;
  end

  function move(these, u)
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

end % Node
