classdef Shell < MeshComponent

properties
  flipNormalFlag = false;
end

methods
  function this = Shell(mesh, id)
    this = this@MeshComponent(mesh, id);
  end
end

end % Shell
