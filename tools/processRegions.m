function nr = processRegions(mi, handle, eid)
% Processes element regions of a mesh
%
% Author: Paulo Pagliosa
% Last revision: 30/11/2024
%
% Input
% =====
% MI: MeshInterface object having the mesh to be processed
% HANDLE: processing function handle. The function takes as input:
% the mesh interface objet, the index of the region to be
% processed, and an array with the IDs of the region elements
% EID: element id of the first region to be processed (default: 1)
%
% Output
% ======
% NR: number of regions
%
% See also: MeshInterface
  assert(isa(mi, 'MeshInterface') && isa(handle, 'function_handle'));
  mesh = mi.mesh;
  ne = mesh.elementCount;
  if nargin < 3 || eid < 1 || eid > ne
    eid = 1;
  end
  pflags = zeros(ne, 1, 'logical');
  nr = 0;
  while true
    eid = mi.pickRegions(eid);
    if isempty(eid)
      break;
    end
    nr = nr + 1;
    handle(mi, nr, eid);
    pflags(eid) = true;
    eid = find(~pflags, 1);
    if isempty(eid)
      break;
    end
  end
end % processRegions
