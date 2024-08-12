function mesh = readMesh(varargin)
  mesh = [];
  glue = true;
  noFaces = false;
  for k = 1:nargin
    arg = varargin{k};
    assert(ischar(arg) && ~isempty(arg), 'Filename expected');
    if arg(1) == '-'
      switch arg(2:end)
        case 'g'
          glue = true;
        case 'a'
          glue = false;
        case 'f'
          noFaces = true;
        otherwise
          error('Unknown option');
      end
    else
      if isempty(mesh)
        mesh = readAMesh(arg);
      elseif glue
        mesh = mesh.glue(readAMesh(arg));
      else
        mesh = mesh.addComponent(readAMesh(arg));
      end
    end
  end
  if isempty(mesh)
    warning('No mesh read');
  else
    mesh.computeNodeElements;
  end

  function mesh = readAMesh(filename)
    [~, ~, ext] = fileparts(filename);
    switch upper(ext)
      case '.BE'
        elementReader = BezierElementReader;
      otherwise
        error('Unknown mesh file format (''%s'')', ext);
    end
    [f, errmsg] = fopen(filename, 'r');
      if f == -1
      error(errmsg);
      end
    mesh = elementReader.mesh;
    fprintf('\nReading nodes...');
    n = fscanf(f, '%d', 1);
    for i = 1:n
      id = fscanf(f, '%d', 1);
      position = fscanf(f, '%f', 4);
      mesh.makeNode(id, position);
    end
    fprintf('\nReading elements...');
    m = fscanf(f, '%d', 1);
    for i = 1:m
      elementReader.read(f, noFaces);
    end
    fprintf('\nReading load points...');
    for i = 1:n
      lpInfo = fscanf(f, '%d', 2);
      if isempty(lpInfo)
        break;
      end
      nodeId = lpInfo(1);
      ne = lpInfo(2);
      elementId = zeros(ne, 1, 'int32');
      uv = zeros(ne, 2);
      for j = 1:ne
        elementId(j) = fscanf(f, '%d', 1);
        uv(j, :) = fscanf(f, '%f', 2);
      end
      mesh.makeLoadPoint(nodeId, elementId, uv);
    end
    fclose(f);
    fprintf('\nEnd mesh reading\n');
    mesh.renumerateAll;
    mesh.zeroTractions;
  end
end
