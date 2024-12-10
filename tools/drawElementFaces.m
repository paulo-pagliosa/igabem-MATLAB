function [h, v, f] = drawElementFaces(mi, color, alpha)
% Draws the faces of the elements of a mesh
%
% Author: Paulo Pagliosa
% Last revision: 09/12/2024
%
% Input
% =====
% MI: MeshInterface object having the mesh with NV nodes and NE elements
% COLOR: face color (default: MI.faceColor)
% ALPHA: face transparency (default: 0.5)
%
% Output
% ======
% H: handle of the patch object containing the face data
% V: NVx3 array with the 3D coordinates of the mesh nodes
% F: NFx4 array with the vertex indices of the element faces
% that DO NOT contain virtual vertices, NF<=NE
%
% See also: Mesh, Face
  h = [];
  v = [];
  mesh = mi.mesh;
  ne = mesh.elementCount;
  f = zeros(ne, 4, 'int32');
  colors = zeros(ne, 3);
  if nargin < 2 || isempty(color)
    color = mi.faceColor;
  end
  nf = 0;
  for i = 1:ne
    face = mesh.elements(i).face;
    if face.isEmpty
      continue;
    end
    nfv = 0;
    for k = 1:4
      node = face.nodes(k);
      if node.isVirtual
        break;
      end
      f(nf + 1, k) = node.id;
      nfv = nfv + 1;
    end
    if nfv == 4
      nf = nf + 1;
      if mi.isSelectedElement(i)
        colors(nf, :) = mi.selectElementColor;
      else
        colors(nf, :) = color;
      end
    end
  end
  f = f(1:nf, :);
  if nf > 0
    v = mesh.nodePositions;
    v = v(:, 1:3);
    if nargin < 3
      alpha = 0.5;
    end
    h = patch('Parent', mi.axes, ...
      'Vertices', v, ...
      'Faces', f, ...
      'FaceVertexCData', colors, ...
      'FaceColor','flat', ...
      'FaceAlpha', alpha);
  end
end
