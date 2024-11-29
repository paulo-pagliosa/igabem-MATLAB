function nr = paintRegions(mi, colors, eid)
% Paints element regions of a mesh
%
% Author: Paulo Pagliosa
% Last revision: 28/11/2024
%
% Input
% =====
% MI: MeshInterface object having the mesh to be painted
% COLORS: color table (default: "gem16")
% EID: element id of the first region to be painted (default: 1)
%
% Output
% ======
% NR: number of painted regions
%
% See also: MeshInterface
  assert(isa(mi, 'MeshInterface'));
  mesh = mi.mesh;
  ne = mesh.elementCount;
  if nargin < 2 || isempty(colors)
    colors = [ ...
      0 0.447 0.741; ...
      0.850 0.325 0.098; ...
      0.929 0.694 0.125; ...
      0.494 0.184 0.556; ...
      0.466 0.674 0.188; ...
      0.301 0.745 0.933; ...
      0.635 0.078 0.184; ...
      1.000 0.839 0.039; ...
      0.396 0.509 0.992; ...
      1     0.270 0.227; ...
      0     0.639 0.639; ...
      0.796 0.517 0.364];
  end
  if nargin < 3 || eid < 1 || eid > ne
    eid = 1;
  end
  pflags = zeros(ne, 1, 'logical');
  cidx = 1;
  nr = 0;
  while true
    mi.selectRegions(eid);
    pflags(mi.paintPatches(colors(cidx, :))) = true;
    cidx = rem(cidx, size(colors, 1)) + 1;
    nr = nr + 1;
    eid = find(~pflags, 1);
    if isempty(eid)
      break;
    end
  end
end % paintRegions
