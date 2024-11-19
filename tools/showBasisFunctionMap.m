function showBasisFunctionMap(mi, nid, region)
% Shows a color map of the basis function of a given mesh node
%
% Author: Paulo Pagliosa
% Last revision: 19/11/2024
%
% Input
% =====
% MI: MeshInterface object
% NID: mesh node id (default: selected node id or 1)
% REGION: node region (default: 1)
%
% See also: MeshInterface, BasisFunctionField
  assert(isa(mi, 'MeshInterface'));
  mesh = mi.mesh;
  if nargin < 2
    node = mi.selectedNode;
    if isempty(node)
      node = mesh.nodes(1);
    end
  elseif nid < 1 || nid > mesh.nodeCount
    error('Bad node id: %d', nid);
  else
    node = mesh.nodes(nid);
  end
  if nargin < 3
    region = 1;
  end
  bff = BasisFunctionField(node, region);
  mi.setScalars(bff);
  mi.showColorMap;
  mi.showColorBar;
end % showBasisFunctionMap
