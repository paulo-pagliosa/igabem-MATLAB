function [h, v, f] = drawElementFaces(mesh, axes, color, alpha)
% Draws the faces of the elements of a mesh
%
% Author: Paulo Pagliosa
% Last revision: 26/10/2024
%
% Input
% =====
% MESH: reference to a mesh with NV nodes and NE elements
% AXES: handle of the axes in which the faces will be drawn
% COLOR: face color (default: [0.8, 0.8, 0.8])
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
  ne = mesh.elementCount;
  f = zeros(ne, 4, 'int32');
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
    end
  end
  f = f(1:nf, :);
  if nf > 0
    v = mesh.nodePositions;
    v = v(:, 1:3);
    if nargin < 4
      alpha = 0.5;
    end
    if nargin < 3
      color = [0.8, 0.8, 0.8];
    end
    h = patch('Parent', axes, ...
      'Vertices', v, ...
      'Faces', f, ...
      'FaceColor', color, ...
      'FaceAlpha', alpha);
  end
end
