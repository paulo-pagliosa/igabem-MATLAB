function mesh = toTriangular(mesh, resolution)
  assert(isa(mesh, 'Mesh'), 'Mesh expected');
  assert(~mesh.empty, 'Mesh is empty')
  if mesh.triangular
    return;
  end
  temp = Mesh;
  temp.setElementType('LinearTriangle');
  nodeId = 0;
  elementId = 0;
  nf = 2 * resolution ^ 2;
  faces = zeros(nf, 3, 'int32');
  k = 1;
  p = 1;
  for i = 1:resolution
    for j = 1:resolution
      q = p + resolution + 2;
      faces(k, :) = [p, p + 1, q];
      k = k + 1;
      faces(k, :) = [p, q, q - 1];
      k = k + 1;
      p = p + 1;
    end
    p = p + 1;
  end
  nodes = Node.empty(0, 1);
  dp = 2 / double(resolution);
  ne = mesh.elementCount;
  for i = 1:ne
    element = mesh.elements(i);
    s = element.shapeFunction;
    r = element.nodePositions;
    k = 1;
    for v = -1:dp:1
      vedge = v == -1 || v == 1;
      for u = -1:dp:1
        p = s.interpolate(r, u, v);
        p = p ./ p(4);
        dist = inf;
        if vedge || u == -1 || u == 1
          [node, dist] = temp.findNearestNode(p);
        end
        if dist > eps
          nodeId = nodeId + 1;
          node = temp.makeNode(nodeId, p);
        end
        nodes(k) = node;
        k = k + 1;
      end
    end
    for k = 1:nf
      nodeIds = vertcat(nodes(faces(k, :)).id);
      elementId = elementId + 1;
      temp.makeElement(elementId, nodeIds);
    end
  end
  mesh = temp;
end % toTriangular
