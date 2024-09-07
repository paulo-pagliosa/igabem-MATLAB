function printMesh(mesh, fid)
% Prints a mesh for debug
%
% Author: Paulo Pagliosa
% Last revision: 06/09/2024
%
% Input
% =====
% MESH: mesh to be saved
% FID: file id (default: standard output)
  assert(isa(mesh, 'Mesh'), 'Mesh expected');
  if nargin < 2
    fid = 1;
  end
  fprintf(fid, "Mesh name: '%s'\n", mesh.name);
  n = mesh.nodeCount;
  fprintf(fid, "Nodes: %d\n", n);
  for i = 1:n
    node = mesh.nodes(i);
    p = node.position;
    d = node.dofs;
    u = node.u;
    fprintf(fid, "% 4d m:%d p(%g,%g,%g) dofs(%d,%d,%d) u(%g,%g,%g)\n", ...
      node.id, node.multiplicity, ...
      p(1), p(2), p(3), ...
      d(1), d(2), d(3), ...
      u(1), u(2), u(3));
  end
  n = mesh.elementCount;
  fprintf(fid, "Elements: %d\n", n);
  for i = 1:n
    element = mesh.elements(i);
    en = element.nodes;
    fprintf(fid, "% 4d %s [%d", element.id, class(element), en(1).id);
    for k = 2:numel(en)
      fprintf(fid, ",%d", en(k).id);
    end
    fprintf(fid, "]\n");
  end
  n = numel(mesh.constraints);
  fprintf(fid, "Constraints: %d\n", n);
  for i = 1:n
    cg = mesh.constraints(i);
    fprintf(fid, "% 4d [%d", cg.id, cg.bcs(1).element.id);
    for k = 2:numel(cg.bcs)
      fprintf(fid, ",%d", cg.bcs(k).element.id);
    end
    fprintf(fid, "]\n");
  end
  n = numel(mesh.loads);
  fprintf(fid, "Loadss: %d\n", n);
  for i = 1:n
    lg = mesh.loads(i);
    fprintf(fid, "% 4d [%d", lg.id, lg.bcs(1).element.id);
    for k = 2:numel(lg.bcs)
      fprintf(fid, ",%d", lg.bcs(k).element.id);
    end
    fprintf(fid, "]\n");
  end
end % printMesh
