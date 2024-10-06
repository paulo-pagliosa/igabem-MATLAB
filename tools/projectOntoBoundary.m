function [x, element, csi, d] = projectOntoBoundary(mesh, p)
% Projects a 3D point onto a boundary element mesh
%
% Author: Paulo Pagliosa
% Last revision: 05/10/2024
%
% Input
% =====
% MESH: reference to a boundary element mesh
% P: spatial coordinates of the 3D point to be projected
%
% Output
% ======
% X: spatial coordinates of the projected point
% ELEMENT: reference to an element containing the projected point
% CSI: parametric coordinates of X w.r.t. the ELEMENT's local system
% D: distance between P and X
%
% TODO: improve the search by using a spatial data structure.

% See also: projectPoint
  assert(isa(mesh, 'Mesh'), 'Mesh expected');
  d = Inf;
  for i = 1:mesh.elementCount
    e = mesh.elements(i);
    [d_e, csi_e, x_e] = projectPoint(e, p);
    if d_e < d
      x = x_e;
      element = e;
      csi = csi_e;
      d = d_e;
    end
  end
end % projectOntoBoundary
