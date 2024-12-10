function h = drawNodesByFilter(mi, filter, color)
% Selects elements using a filter function
%
% Author: Paulo Pagliosa
% Last revision: 06/12/2024
%
% Input
% =====
% MI: MeshInterface object
% FILTER: filter function handle
% COLOR: nodes' color (default: 'blue')
%
% Output
% ======
% NIDS: handle to the line plot object
%
% See also: drawPoints
  assert(isa(mi, 'MeshInterface') && isa(filter, 'function_handle'));
  if nargin < 3
    color = 'blue';
  end
  h = [];
  mesh = mi.mesh;
  nn = mesh.nodeCount;
  nids = zeros(nn, 1);
  for i = 1:nn
    if filter(mesh.nodes(i))
      nids(i) = i;
    end
  end
  nids = find(nids);
  if ~isempty(nids)
    h = drawPoints(mi.axes, vertcat(mesh.nodes(nids).position), color);
  end
  fprintf('Nodes drawn: %d\n', numel(nids));
end % drawNodesByFilter
