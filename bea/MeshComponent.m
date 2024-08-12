classdef (Abstract) MeshComponent < handle & matlab.mixin.Heterogeneous
% MeshComponent: generic mesh component class
%
% Author: Paulo Pagliosa
% Last revision: 12/08/2024
%
% Description
% ===========
% The abstract clas MeshComponent encapsulates the properties of a
% generic mesh component.
%
% See also: class Mesh

%% Public read-only properties
properties (SetAccess = {?MeshComponent, ?Mesh})
  mesh (1, 1) Mesh;
  id (1, 1) int32;
end

%% Protected methods
methods (Access = protected)
  function this = MeshComponent(mesh, id)
    assert(isa(mesh, 'Mesh'), 'Mesh expected');
    this.mesh = mesh;
    this.id = id;
  end
end

end % MeshComponent
