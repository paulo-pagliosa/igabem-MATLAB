classdef (Abstract) MeshComponent < handle & matlab.mixin.Heterogeneous

properties (SetAccess = {?MeshComponent, ?Mesh})
  mesh (1, 1) Mesh;
  id (1, 1) int32;
end

methods (Access = protected)
  function this = MeshComponent(mesh, id)
    assert(isa(mesh, 'Mesh'), 'Mesh expected');
    this.mesh = mesh;
    this.id = id;
  end
end

end % MeshComponent
