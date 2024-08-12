function saveSolverData(mesh, material, filename)
% Saves mesh and material data to be used in the C++/CUDA C++ code
%
% Author: Paulo Pagliosa
% Last revision: 12/08/2024
%
% Input
% =====
% MESH: mesh to be saved
% MATERIAL: material to be saved
% FILENAME: file with the mesh and material data
  assert(isa(mesh, 'Mesh'), 'Mesh expected');
  assert(isa(material, 'Material'), 'Material expected');
  file = fopen(filename, 'w');
  mesh.renumerateAll;
  nn = mesh.nodeCount;
  % Compute the LS equation numbers
  nu = 3 * nn;
  dofs = zeros(nu, 1, 'int32');
  tIdx = zeros(nn, 1, 'int32');
  dIdx = 0;
  nt = 0;
  ps = 0;
  for i = 1:nn
    node = mesh.nodes(i);
    for k = 1:3
      dIdx = dIdx + 1;
      if node.dofs(k, 1) > 0 % BC is a constraint
        dofs(dIdx) = -(3 * (nt + node.dofs(k, 2) - 1) + k);
      else % BC is a load
        dofs(dIdx) = dIdx;
      end
    end
    tIdx(i) = nt;
    nt = nt + node.multiplicity;
    if ~isempty(node.loadPoint)
      ps = ps + numel(node.loadPoint.elements);
    end
  end
  ne = mesh.elementCount;
  ls = 0;
  for i = 1:ne
    ls = ls + mesh.elements(i).nodeCount;
  end
  fprintf(file, ['# A row specifying the number of nodes, elements and ' ...
    'tractions,\n# the size of the incidence lists of all elements, ' ...
    'and the size\n# of the load point data array\n']);
  fprintf(file, '%d %d %d %d %d\n', nn, ne, nt, ls, ps);
  % Set the vectors u and t
  nt = 3 * nt;
  u = zeros(nu, 1);
  t = zeros(nt, 1);
  dIdx = 0;
  fprintf(file, ['\n# A row per node specifying the position ([x,y,z,w]), ' ...
    'the\n# multiplicity (m), and the dof codes (dofs) of the node.\n' ...
    '# If dofs[i] == 0, then ALL tractions t[r,i] of the node,\n' ...
    '# r=[0,m), are prescribed and u[i] is unknown. Otherwise,\n' ...
    '# the displacement u[i] is prescribed and the traction of\n' ...
    '# the node region r=dofs[i]-1, t[r,i], is unknown\n']);
  for i = 1:nn
    node = mesh.nodes(i);
    dofCodes = [0 0 0];
    nt = tIdx(i);
    for k = 1:3
      dIdx = dIdx + 1;
      region = node.dofs(k, 2);
      if node.dofs(k, 1) > 0 % BC is a constraint
        u(dIdx) = node.u(k);
        dofCodes(k) = region;
      else % BC is a load
        for r = 1:node.multiplicity
          if r == region
            continue;
          end
          t(3 * (nt + r - 1) + k) = node.t(r, k);
        end
      end
    end
    fprintf(file, ...
      '%.8g %.8g %.8g %.8g %d %d %d %d\n', ...
      node.position, ...
      node.multiplicity, ...
      dofCodes);
  end
  fprintf(file, ['\n# A row per node with the displacement (u[i], i=[0,3))' ...
    '\n# and the m tractions (t[r,i], r=[0,m)) of the node\n']);
  for i = 1:nn
    node = mesh.nodes(i);
    fprintf(file, '%.8g %.8g %.8g', node.u);
    for k = 1:node.multiplicity
      fprintf(file, ' %.8g %.8g %.8g', node.t(k, :));
    end
    fprintf(file, '\n');
  end
  % Compute the element location arrays
  hMap = cell(ne, 1);
  gMap = cell(ne, 1);
  fprintf(file, ['\n# Several rows per element. The first row specifies\n' ...
    '# the size (s) of the incidence list of the element.\n' ...
    '# The next two rows contain the node ids and the node regions\n' ...
    '# of the element, respectively. Those are followed by s rows,\n' ...
    '# each one with 16 real numbers corresponding to a row of the\n' ...
    '# Bezier extraction matrix of the element\n']);
  for i = 1:ne
    element = mesh.elements(i);
    ids = element.nodeIds;
    idx = 3 * ids;
    idx = [idx - 2, idx - 1, idx]';
    hMap{element.id} = idx(:);
    idx = 3 * (tIdx(ids) + element.nodeRegions);
    idx = [idx - 2, idx - 1, idx]';
    gMap{element.id} = idx(:);
    fprintf(file, '%d\n', element.nodeCount);
    saveRow(file, '%d', ids - 1);
    saveRow(file, '%d', element.nodeRegions - 1);
    C = element.shapeFunction.C;
    for k = 1:element.nodeCount
      saveRow(file, '%.8g', C(k, :));
    end
  end
  fprintf(file, ['\n# A row per load point specifying the number (n) ' ...
    'of elements\n# containing the load point, followed by n triples ' ...
    '(id,u,v), \n# where id is the element index and (u,v) are ' ...
    'the parametric\n# coordinates of the load point wrt the element ' ...
    'local system\n']);
  for i = 1:nn
    lp = mesh.nodes(i).loadPoint;
    if isempty(lp)
      break;
    end
    ps = numel(lp.elements);
    fprintf(file, '%d', ps);
    for k = 1:ps
      fprintf(file, ' %d', lp.elements(k).id - 1);
      fprintf(file, ' %.8g %.8g', lp.localPositions(k, :));
    end
    fprintf(file, '\n');
  end
  fprintf(file, ['\n# A row specifying the Young''s modulus (E) and the\n' ...
    '# Poisson''s ratio (\\mu) of the material\n']);
  fprintf(file, '%g %g\n', material.E, material.mu);
  fclose(file);

  function saveRow(file, fmt, data)
    fprintf(file, [fmt, ' '], data(1:end - 1));
    fprintf(file, [fmt '\n'], data(end));
  end
end % saveSolverData