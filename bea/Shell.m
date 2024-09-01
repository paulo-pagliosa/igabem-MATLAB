classdef Shell < MeshComponent
% Shell: shell class
%
% Author: Paulo Pagliosa
% Last revision: 31/08/2024
%
% Description
% ===========
% An object of the class Shell is a mesh component that represents a
% connected component of a BEA model (not fully implemented yet).
%
% See also: class Mesh

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
end

end % Shell
