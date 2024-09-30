classdef Material < handle
% Material: elastic material class
%
% Author: Paulo Pagliosa
% Last revision: 30/09/2024
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
  c5;
  c6;
end

%% Public methods
methods
  function this = Material(E, mu)
  % Constructs a material
    if nargin > 0
      this.set(E, mu);
    else
      this.initDefaultMaterial();
    end
  end

  function set(this, E, mu)
  % Sets the properties of this material
    this.E = E;
    this.mu = mu;
    this.G = E / (2 * (1 + mu));
    % Constants for Kelvin fundamental solutions:
    % U,...
    this.c1 = this.scale / (16 * pi * this.G * (1 - mu));
    this.c2 = 3 - 4 * mu;
    % ...T and D,...
    this.c3 = 1 / (8 * pi * (1 - mu));
    this.c4 = 1 - 2 * mu;
    %...and S
    this.c5 = this.G / (4 * pi * (1 - mu));
    this.c6 = this.c2 - 2;
  end

  function setScale(this, scale)
  % Sets the material scale (for test only)
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
