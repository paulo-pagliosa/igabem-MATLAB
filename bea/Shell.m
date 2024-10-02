classdef Shell < MeshComponent
% Shell: shell class
%
% Author: Paulo Pagliosa
% Last revision: 01/10/2024
%
% Description
% ===========
% An object of the class Shell is a mesh component that represents a
% connected component of a BEA model (not fully implemented yet).
%
% See also: Mesh

%% Public properties
properties
  flipNormalFlag = false;
end

%% Public methods
methods
  function this = Shell(mesh, id)
  % Constructs a mesh shell
    this = this@MeshComponent(mesh, id);
  end

  function s = saveobj(this)
  % Saves this mesh shell
    s = saveobj@MeshComponent(this);
    s.flipNormalFlag = this.flipNormalFlag;
  end
end

%% Public static methods
methods (Static)
  function this = loadobj(s)
  % Loads a mesh shell
    this = Shell(Mesh.empty, s.id);
    this.flipNormalFlag = s.flipNormalFlag;
  end
end

end % Shell
