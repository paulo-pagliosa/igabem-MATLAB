function mesh = readMesh(varargin)
% Reads mesh data from a file
%
% Authors: M.A. Peres and P. Pagliosa
% Last revision: 14/09/2024
%
% Input
% =====
% VARARGIN: one or more comma-separated strings.
% A string can be a flag or a filename. Flags can be:
% '-f': next file has no element face data (default: with face data)
% '-g': set the GLUE flag to TRUE (default)
% '-a': set the GLUE flag to FALSE
%
% Output
% ======
% MESH: output mesh
%
% Description
% ===========
% Creates a mesh from one or more files. For each filename given as 
% input argument, a mesh is created and its data is read from the file.
% The meshes are then combined according to the GLUE flag. If GLUE is TRUE,
% nodes with the same position are merged to form continuous elements.
% Otherwise, nodes with the same position are replicated in the final mesh,
% which results in semi-discontinuous elements. The GLUE flag is ignored if
% only one filename is given as input argument. Each connected component of
% the final mesh must represent a surface with no boundaries.
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
      case '.SE'
        elementReader = SplineElementReader;
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
end % readMesh
