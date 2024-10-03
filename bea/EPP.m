classdef EPP < EPBase
% EPP: linear elastostatic post-processor class
%
% Authors: M.A. Peres and P. Pagliosa
% Last revision: 03/10/2024
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
    this.sHandle = IntegrationHandle(this, @initSData, @updateSData);

    function initUData(handle, element)
      handle.data = struct('u_e', element.nodeDisplacements, ...
        't_e', element.nodeTractions, ...
        'c', zeros(3, 3), ...
        'u', zeros(1, 3));
    end

    function updateUData(handle, p, q, N, S, w)
      [U, T] = Kelvin3.computeUT(p, q, N, handle.solver.material);
      T = T * w;
      handle.data.c = handle.data.c - T;
      t = sum(handle.data.t_e .* S) * U' * w;
      u = sum(handle.data.u_e .* S) * T';
      handle.data.u = handle.data.u + t - u;
    end

    function initSData(handle, element)
      handle.data = struct('u_e', element.nodeDisplacements, ...
        't_e', element.nodeTractions, ...
        's', zeros(3, 3));
    end

    function updateSData(handle, p, q, N, S, w)
      u = sum(handle.data.u_e .* S) * w;
      t = sum(handle.data.t_e .* S) * w;
      [D, S] = Kelvin3.computeDS(p, q, N, handle.solver.material);
      d = D(:, :, 1) * t(1) + D(:, :, 2) * t(2) + D(:, :, 3) * t(3);
      s = S(:, :, 1) * u(1) + S(:, :, 2) * u(2) + S(:, :, 3) * u(3);
      handle.data.s = handle.data.s + d - s;
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
  % an internal point.
  %
  % See also: projectPoint
    if nargin < 3
      dflag = false;
    end
    this.p = [];
    fprintf('**Computing displacements...\n');
    np = size(points, 1);
    u = zeros(np, 3);
    pbar = ProgressBar(np);
    pbar.start;
    nb = 0;
    nd = 0;
    ne = this.mesh.elementCount;
    for k = 1:np
      c = zeros(3, 3);
      bflag = false;
      p = points(k, :);
      for i = 1:ne
        e = this.mesh.elements(i);
        [ce, ue, x, b] = this.computeU(p, e, dflag);
        u(k, :) = u(k, :) + ue;
        bflag = bflag || b;
        c = c + ce;
        this.p = [this.p; x];
      end
      if bflag
        u(k, :) = c ^ -1 * u(k, :)';
        nb = nb + 1;
      else
        nd = nd + 1;
      end        
      % Print progress
      pbar.update(k);
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
        [ce, ue, x] = this.performInsideUIntegration(csi, p, e);
      else
        [ce, ue, x] = this.computeU(p, e, false);
      end
      u = u + ue;
      c = c + ce;
      this.p = [this.p; x];
    end
    u = (c ^ -1 * u')';
  end

  function u = computeDomainStresses(this, points)
  % Computes the stress at internal points
    u = this.computeStresses(points, true);
  end

  function s = computeStresses(this, points, dflag)
  % Computes the stress at internal and boundary points
  % 
  % Input
  % =====
  % POINTS: NPx3 array with the coordinates of NP points
  % DFLAG: domain flag (default: false). If it is true, every
  % point in POINTS is assumed to be an internal point
  %
  % Output
  % ======
  % S: 3x3xNPx3 array where S(:,:,K), K in [1:NP], is the stress
  % of the point POINTS(K,:)
  %
  % Description
  % ===========
  % For each P=POINTS(K,:), K in [1:NP], S(:,:,K) is computed by
  % evaluating the stress BIE taking P as the load point if P is
  % not a boundary point. Otherwise, the stress at P is computed
  % analytically. The projection of P is tested iff DFLAG==true.
  % Otherwise, P is assumed to be an internal point.
    if nargin < 3
      dflag = false;
    end
    this.p = [];
    fprintf('**Computing stresses...\n');
    np = size(points, 1);
    s = zeros(3, 3, np);
    pbar = ProgressBar(np);
    pbar.start;
    nb = 0;
    nd = 0;
    ne = this.mesh.elementCount;
    for k = 1:np
      bflag = false;
      p = points(k, :);
      for i = 1:ne
        e = this.mesh.elements(i);
        if ~dflag
          [b, csi] = EPP.isInElement(p, e);
          if b
            bflag = true;
            s(:, :, k) = this.computeBoundaryStress(csi, p, e);
            break;
          end
        end
        [se, x] = this.performOutsideSIntegration(p, e);
        s(:, :, k) = s(:, :, k) + se;
        this.p = [this.p; x];
      end
      if bflag
        nb = nb + 1;
      else
        nd = nd + 1;
      end        
      % Print progress
      pbar.update(k);
    end
    fprintf('\n**DONE\n');
    fprintf('Boundary points: %d\nDomain points: %d\nGauss points: %d\n', ...
      nb, ...
      nd, ...
      size(this.p, 1));
  end

  function s = computeBoundaryStress(this, csi, p, element)
  % Computes the stress at a boundary point
    s = zeros(3, 3);
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

  function [c, u, x, bflag] = computeU(this, p, element, dflag)
    bflag = false;
    if ~dflag
      [bflag, csi] = EPP.isInElement(p, element);
    end
    if ~bflag
      [c, u, x] = this.performOutsideUIntegration(p, element);
    else
      [c, u, x] = this.performInsideUIntegration(csi, p, element);
    end
  end

  function [s, x] = performOutsideSIntegration(this, p, element)
    handle = this.sHandle;
    handle.setElement(element);
    this.integrator.performOutsideIntegration(p, handle);
    s = handle.data.s;
    x = handle.x;
  end
end

%% Protected static methods
methods (Access = protected, Static)
  function [b, csi] = isInElement(p, element)
    [d, csi] = projectPoint(element, p);
    b = abs(d) <= EPP.eps;
  end
end

end % EPP
