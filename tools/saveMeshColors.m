function saveMeshColors(mesh, filename)
% Saves element colors to be used in the C++/CUDA C++ code
%
% Author: Paulo Pagliosa
% Last revision: 01/10/2024
%
% Input
% =====
% MESH: mesh to be colored
% FILENAME: file with the color data
%
% See also: Mesh
  [colors, count] = meshColoring(mesh, true);
  nc = numel(count);
  file = fopen(filename, 'w');
  fprintf(file, '# A row specifying the number of elements and colors\n');
  fprintf(file, '%d %d\n', numel(colors), nc);
  fprintf(file, ['\n# A row per color specifying the number of elements ' ...
    'with that color\n# followed by the indices of those elements\n']);
  for i = 1:nc
    fprintf(file, '%d', count(i));
    fprintf(file, ' %d', find(colors == i) - 1);
    fprintf(file, '\n');
  end
  fclose(file);
end % saveColorMesh
