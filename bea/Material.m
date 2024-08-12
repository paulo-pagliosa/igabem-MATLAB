classdef Material < handle
% Material: elastic material class
%
% Author: Paulo Pagliosa
% Last revision: 12/08/2024
%
% Description
% ===========
% An object of the class Material encapsulates the properties of an
% elastic material.

%% Public read-only properties
properties (SetAccess = private)
  scale = 1;
  E;
  mu;
  G;
  c1;
  c2;
  c3;
  c4;
end

%% Public methods
methods
  % Constructs a meterial
  function this = Material(E, mu)
    if nargin > 1
      this.set(E, mu);
    else
      this.initDefaultMaterial();
    end
  end

  % Sets the properties of this material
  function set(this, E, mu)
    this.E = E;
    this.mu = mu;
    this.G = E / (2 * (1 + mu));
    this.c4 = 1 - 2 * mu;
    this.c3 = 1 / (8 * pi * (1 - mu));
    this.c2 = 3 - 4 * mu;
    this.c1 = this.scale / (16 * pi * this.G * (1 - mu));
  end

  % Sets the material scale (for test only)
  function setScale(this, scale)
    if scale ~= this.scale && scale >= 1
      this.scale = scale;
      this.c1 = scale / (16 * pi * this.G * (1 - this.mu));
    end
  end
end

%% Private methods
methods (Access = private)
  function initDefaultMaterial(this)
    this.set(1e5, 0.3);
  end
end

end % Material
