function nr = paintRegions(mi, colors, eid)
% Paints element regions of a mesh
%
% Author: Paulo Pagliosa
% Last revision: 30/11/2024
%
% Input
% =====
% MI: MeshInterface object having the mesh to be painted
% COLORS: color table (default: MI.AXES.COLORORDER)
% EID: element id of the first region to be painted (default: 1)
%
% Output
% ======
% NR: number of painted regions
%
% See also: processRegions
  assert(isa(mi, 'MeshInterface'));
  if nargin < 2 || isempty(colors)
    colors = mi.axes.ColorOrder;
  end
  if nargin < 3
    eid = 1;
  end
  nr = processRegions(mi, @handle, eid);

  function handle(mi, r, eids)
    cidx = rem(r - 1, size(colors, 1)) + 1;
    mi.paintPatches(colors(cidx, :), eids);
  end
end % paintRegions
