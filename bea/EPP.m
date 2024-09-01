classdef EPP < EPBase
% EPP: linear elastostatic post-processor class
%
% Authors: M.A. Peres and P. Pagliosa
% Last revision: 31/08/2024
%
% See also: class Mesh, class Material

%% Public properties
properties
  mesh;
end

%% Private constants
properties (Constant, Access = private)
  eps = 10e-5 / sqrt(10);
end

%% Public methods
methods
  function this = EPP(mesh, material, varargin)
  % Constructs an EPP
    this@EPBase(material, varargin{:});
    this.mesh = mesh;
  end

  function set.mesh(obj, value)
  % Sets the mesh of this EPP
    assert(isa(value, 'Mesh'), 'Mesh expected');
    obj.mesh = value;
  end
  
  function u = computeDomainDisplacements(this, points)
  % Computes the displacement at internal points
    u = this.computeDisplacement(points, true);
  end

  function u = computeDisplacements(this, points, dflag)
  % Computes the displacement at internal and/or boundary points
    if nargin < 3
      dflag = false;
    end
    this.p = [];
    fprintf('**Computing displacements...\n');
    np = size(points, 1);
    u = zeros(np, 3);
    dots = min(40, np);
    fprintf('%s\n', repmat('*', 1, dots));
    slen = dots / np;
    step = 1;
    nb = 0;
    nd = 0;
    ne = this.mesh.elementCount;
    for k = 1:np
      c = zeros(3, 3);
      bflag = false;
      p = points(k, :);
      for i = 1:ne
        element = this.mesh.elements(i);
        [cp, h, g, x, b] = this.computeHG(p, element, dflag);
        u(k, :) = u(k, :) + this.computeU(element, g, h);
        bflag = bflag || b;
        c = c + cp;
        temp = [this.p; x];
        this.p = temp;
      end
      if bflag
        u(k, :) = c^-1 * u(k, :)';
        nb = nb + 1;
      else
        nd = nd + 1;
      end        
      % Print progress
      if k * slen >= step
        fprintf('.');
        step = step + 1;
      end
    end
    fprintf('\n**DONE\n');
    fprintf('Boundary points: %d\nDomain points: %d\nGauss points: %d\n', ...
      nb, nd, size(this.p, 1));
  end
  
  function u = computeBoundaryDisplacement(this, csi, p, element)
  % Computes the displacement at boundary points
    this.p = [];
    u = [0 0 0];
    c = zeros(3, 3);
    ne = this.mesh.elementCount;
    for i = 1:ne
      e = this.mesh.elements(i);
      if e == element
        [cp, h, g, x] = this.integrator.insideIntegration(csi, p, e);
      else
        [cp, h, g, x] = this.computeHG(p, e, false);
      end
      u = u + this.computeU(e, g, h);
      c = c + cp;
      temp = [this.p; x];
      this.p = temp;
    end
    u = (c^-1 * u')';
  end
end

%% Private methods
methods (Access = private)
  function [c, h, g, x, b] = computeHG(this, p, element, dflag)
    b = false;
    if ~dflag
      [d, csi] = projectPoint(element, p);
      b = abs(d) <= this.eps;
    end
    if ~b
      [c, h, g, x] = this.integrator.outsideIntegration(p, element);
    else
      [c, h, g, x] = this.integrator.insideIntegration(csi, p, element);
    end
  end

  function u = computeU(this, element, g, h)
    u = reshape(element.nodeDisplacements', [] ,1);
    t = reshape(element.nodeTractions', [], 1);
    u = (g / this.material.scale * t - h * u)';
  end
end

end % EPP
