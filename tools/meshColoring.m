function [colors, count, sets] = meshColoring(mesh, check)
% Colors the elements of a mesh
%
% Author: Paulo Pagliosa
% Last revision: 12/08/2024
%
% Input
% =====
% MESH: mesh to be colored
% CHECK: check flag (default: FALSE)
%
% Output
% ======
% COLORS: NEx1 array where COLORS(I) is the color of the I-th element
% of MESH, I in [1:NE]
% COUNT: NCx1 array where the COUNT(I) is the number of elements with
% the I-th color, I in [1:NC]
% SETS: NCx1 cell array where SETS{I} is a COUNT(I)x1 array with the ids
% of the elements colored with I in [1:NC]
%
% Description
% ===========
% Colors the elements of MESH as described in Section 6.3 of the paper.
  assert(isa(mesh, 'Mesh'), 'Mesh expected');
  ne = mesh.elementCount;
  colors = -ones(ne, 1);
  nodeElements = mesh.nodeElements;
  count = zeros(ne, 1);
  queue = Queue;
  queue.add(1);
  while ~queue.isEmpty
    id = queue.remove;
    if colors(id) ~= -1
      continue;
    end
    used_colors = false(ne, 1);
    u = horzcat(nodeElements{mesh.elements(id).nodeIds});
    u = u(u ~= id);
    queue.add(u);
    for i = 1 : numel(u)
      c = colors(u(i));
      if c ~= -1
        used_colors(c) = true;
      end
    end
    c = find(used_colors == false, 1);
    if isempty(c)
      disp(used_colors);
      disp(colors(u));
      error('Error: no color for element %d', id);
    end
    colors(id) = c;
    count(c) = count(c) + 1;
  end
  count = count(count > 0);
  nc = numel(count);
  fprintf('**DONE (%d colors)\n', nc);
  if nargin > 1 && check
    for i = 1:numel(nodeElements)
      u = nodeElements(i);
      c = colors(u{:});
      u = unique(c);
      assert(isempty(setdiff(u, c)), '**Bad colors (element %d)', i);        
    end
    disp('Elements by color:');
    disp(count);
  end
  if nargout > 2
    sets = cell(nc, 1);
    for i = 1:nc
      sets{i} = find(colors == i);
    end
  end
end
