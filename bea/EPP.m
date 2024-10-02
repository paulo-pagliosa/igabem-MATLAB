classdef EPP < EPBase
% EPP: linear elastostatic post-processor class
%
% Authors: M.A. Peres and P. Pagliosa
% Last revision: 01/10/2024
%
% Description
% ===========
% An object of the class EPP represents a post-processor for the
% elastostatic problem. The class defines methods to compute the
% displacements and stresses at boundary and domain points.
%
% See also: Mesh, Material

%% Public properties
properties
  mesh Mesh;
end

%% Public methods
methods
  function this = EPP(mesh, material, varargin)
  % Constructs an EPP
    this@EPBase(material, varargin{:});
    this.mesh = mesh;
    this.uHandle = IntegrationHandle(this, @initUData, @updateUData);

    function initUData(handle, element)
      handle.data = struct('ue', element.nodeDisplacements, ...
        'te', element.nodeTractions, ...
        'c', zeros(3, 3), ...
        'u', zeros(1, 3));
    end

    function updateUData(handle, p, q, N, S, w)
      [U, T] = Kelvin3.computeUT(p, q, N, handle.solver.material);
      T = T * w;
      handle.data.c = handle.data.c - T;
      t = weightedSum(handle.data.te, S) * U' * w;
      u = weightedSum(handle.data.ue, S) * T'; 
      handle.data.u = handle.data.u +  t - u;
    end

    function x = weightedSum(x, w)
      x = sum(x .* repmat(w, 1, size(x, 2)));
    end
 end

  function set.mesh(this, value)
  % Sets the mesh of this EPP
    assert(isa(value, 'Mesh'), 'Mesh expected');
    this.mesh = value;
  end
  
  function u = computeDomainDisplacements(this, points)
  % Computes the displacement at internal points
    u = this.computeDisplacements(points, true);
  end

  function u = computeDisplacements(this, points, dflag)
  % Computes the displacement at internal and boundary points
  % 
  % Input
  % =====
  % POINTS: NPx3 array with the coordinates of NP points
  % DFLAG: domain flag (default: false). If it is true, every
  % point in POINTS is assumed to be an internal point
  %
  % Output
  % ======
  % U: NPx3 array where U(K,:), K in [1:NP], is the displacement
  % of the point POINTS(K,:)
  %
  % Description
  % ===========
  % For each P=POINTS(K,:), K in [1:NP], U(K,:) is determined by
  % evaluating the BIE using P as the load point. If P is in any
  % element, E (i.e., its projection onto E is P itself), then P
  % is a boundary point (in this case, its displacement could be
  % obtained by interpolating the element's nodal displacements,
  % but even so, the BIE is fully evaluated). If DFLAG is false,
  % the projection of P is tested. Otherwise, P is assumed to be
  % an internal point
  %
  % See also: function projectPoint
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
        [cp, up, x, b] = this.computeU(p, element, dflag);
        u(k, :) = u(k, :) + up;
        bflag = bflag || b;
        c = c + cp;
        this.p = [this.p; x];
      end
      if bflag
        u(k, :) = c ^ -1 * u(k, :)';
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
      nb, ...
      nd, ...
      size(this.p, 1));
  end
  
  function u = computeBoundaryDisplacement(this, csi, p, element, eflag)
  % Computes the displacement at a boundary point
  %
  % Input
  % =====
  % CSI: 1x2 array with the parametric coordinates of P
  % P: 1x3 array with the coordinates of the boundary point
  % ELEMENT: reference to an element containing P
  % EFLAG: evaluation flag (default: false). If it is true,
  % the displacement of P is computed by evaluating the BIE
  % (to test numerical integration)
  %
  % Output
  % ======
  % U: 1x3 array with the displacement of P
    this.p = [];
    if nargin < 5 || eflag == false
      u = element.nodeDisplacements;
      u = element.shapeFunction.interpolate(u, csi(1), csi(2));
      return;
    end
    u = [0 0 0];
    c = zeros(3, 3);
    ne = this.mesh.elementCount;
    for i = 1:ne
      e = this.mesh.elements(i);
      if e == element
        [cp, up, x] = this.performInsideUIntegration(csi, p, e);
      else
        [cp, up, x] = this.computeU(p, e, false);
      end
      u = u + up;
      c = c + cp;
      this.p = [this.p; x];
    end
    u = (c ^ -1 * u')';
  end
end

%% Protected constant properties
properties (Constant, Access = protected)
  eps = 10e-5 / sqrt(10);
end

%% Protected properties
properties (Access = protected)
  uHandle IntegrationHandle;
  sHandle IntegrationHandle;
end

%% Protected methods
methods (Access = protected)
  function [c, u, x] = performOutsideUIntegration(this, p, element)
    handle = this.uHandle;
    handle.setElement(element);
    this.integrator.performOutsideIntegration(p, handle);
    c = handle.data.c;
    u = handle.data.u;
    x = handle.x;
  end

  function [c, u, x] = performInsideUIntegration(this, csi, p, element)
    handle = this.uHandle;
    handle.setElement(element);
    this.integrator.performInsideIntegration(csi, p, handle);
    c = handle.data.c;
    u = handle.data.u;
    x = handle.x;
  end

  function [c, u, x, b] = computeU(this, p, element, dflag)
    b = false;
    if ~dflag
      [d, csi] = projectPoint(element, p);
      b = abs(d) <= this.eps;
    end
    if ~b
      [c, u, x] = this.performOutsideUIntegration(p, element);
    else
      [c, u, x] = this.performInsideUIntegration(csi, p, element);
    end
  end
end

end % EPP
