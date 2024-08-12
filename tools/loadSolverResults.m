function loadSolverResults(mesh, filename)
  assert(isa(mesh, 'Mesh'), 'Mesh expected');
  file = fopen(filename, 'r');
  nn = mesh.nodeCount;
  for i = 1:nn
    s = textscan(file, 'Node %d', 1); % Node id
    assert(i == s{1} + 1);
    node = mesh.nodes(i);
    m = size(node.t, 1);
    u = readVec3(file);
    t = zeros(m, 3);
    for k = 1:m
      s = fscanf(file, '%d');
      assert(k == s + 1);
      t(k, :) = readVec3(file);
    end
    mesh.setNodeResults(i, u, t);
  end
  fclose(file);

  function v = readVec3(file)
    r = textscan(file, '%c<%f,%f,%f>', 1);
    v = [r{2} r{3} r{4}];
  end
end
