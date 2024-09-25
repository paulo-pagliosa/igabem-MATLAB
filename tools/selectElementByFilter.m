function eids = selectElementByFilter(mi, filter)
% Selects elements using a filter function
%
% Author: Paulo Pagliosa
% Last revision: 24/09/2024
%
% Input
% =====
% MI: MeshInterface object
% FILTER: filter function handle
%
% Output
% ======
% EIDS: indices of the select elements in MI
  assert(isa(mi, 'MeshInterface') && isa(filter, 'function_handle'));
  mesh = mi.mesh;
  ne = mesh.elementCount;
  eids = zeros(1, ne);
  for i = 1:ne
    if filter(mesh.elements(i))
      eids(i) = i;
    end
  end
  eids = find(eids);
  if ~isempty(eids)
    mi.deselectAllElements;
    mi.selectElements(eids);
  end
end % selectElementByFilter
