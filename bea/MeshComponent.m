classdef (Abstract) MeshComponent < handle & matlab.mixin.Heterogeneous
% MeshComponent: generic mesh component class
%
% Author: Paulo Pagliosa
% Last revision: 01/10/2024
%
% Description
% ===========
% The abstract class MeshComponent encapsulates the properties of a
% generic mesh component.
%
% See also: Mesh

%% Public read-only properties
properties (SetAccess = {?MeshComponent, ?Mesh})
  mesh Mesh;
  id (1, 1) int32;
end

%% Public methods
methods
  function s = saveobj(this)
  % Saves this mesh component
    s.id = this.id;
  end
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
