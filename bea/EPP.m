classdef EPP < EPBase
% EPP: linear elastostatic post-processor class
%
% Authors: M.A. Peres and P. Pagliosa
% Last revision: 07/10/2024
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
    this.uHandle = IntegrationHandle(this, @initUData, @updateUData);
    this.sHandle = IntegrationHandle(this, @initSData, @updateSData);
    this.mesh = mesh;

    function initUData(handle)
      handle.data = struct('u_e', handle.element.nodeDisplacements, ...
        't_e', handle.element.nodeTractions, ...
        'c', zeros(3, 3), ...
        'u', zeros(1, 3));
    end

    function updateUData(handle, p, q, N, S, w)
      [U, T] = Kelvin3.computeUT(p, q, N, handle.solver.material);
      T = T * w;
      handle.data.c = handle.data.c - T;
      u = sum(handle.data.u_e .* S) * T';
      u = sum(handle.data.t_e .* S) * U' * w - u;
      handle.data.u = handle.data.u + u;
    end

    function initSData(handle)
      handle.data = struct('u_e', handle.element.nodeDisplacements, ...
        't_e', handle.element.nodeTractions, ...
        's', zeros(3, 3));
    end

    function updateSData(handle, p, q, N, S, w)
      % Set the regularization terms from a constant stress field
      t = N * this.sr.s;
      u = this.sr.u + (q - this.sr.p) * this.sr.e;
      % Compute the traction and displacement at the target point
      t = sum(handle.data.t_e .* S) - t;
      u = sum(handle.data.u_e .* S) - u;
      % Compute the Kelvin kernels D and S
      [D, S] = Kelvin3.computeDS(p, q, N, handle.solver.material);
      d = D(:, :, 1) * t(1) + D(:, :, 2) * t(2) + D(:, :, 3) * t(3);
      s = S(:, :, 1) * u(1) + S(:, :, 2) * u(2) + S(:, :, 3) * u(3);
      % Update the stress at the load point
      handle.data.s = handle.data.s + (d - s) * w;
    end
 end

  function set.mesh(this, value)
  % Sets the mesh of this EPP
    assert(~isempty(value) && isa(value, 'Mesh'), 'Mesh expected');
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
    % For each point P in POINTS
    for k = 1:np
      c = zeros(3, 3);
      bflag = false;
      proj.d = Inf;
      p = points(k, :);
      % For each element E
      for i = 1:ne
        e = this.mesh.elements(i);
        % Project P onto E
        [d, csi] = projectPoint(e, p);
        % If the projection is the boundary point closest to P,
        % save E and the projection's parametric coordinates
        if d < proj.d
          proj.d = d;
          proj.element = e;
          proj.csi = csi;
        end
        % If P is a boundary point, perform inside integration
        if d <= EPP.eps
          if dflag
            warning('Point %d is in element %d', k, i);
          end
          [ce, ue, x] = this.performInsideUIntegration(csi, p, e);
          bflag = true;
        % Otherwise, perform outside integration
        else
          [ce, ue, x] = this.performOutsideUIntegration(p, e);
        end
        % Update the displacement of P
        u(k, :) = u(k, :) + ue;
        c = c + ce;
        this.p = [this.p; x];
      end
      % Apply regularization
      if bflag
        u(k, :) = c ^ -1 * u(k, :)';
        nb = nb + 1;
      else
        up = proj.element.displacementAt(proj.csi(1), proj.csi(2));
        u(k, :) = u(k, :) + up - up * c';
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
    if nargin < 5 || eflag == false
      u = element.displacementAt(csi(1), csi(2));
      return;
    end
    this.p = [];
    u = [0 0 0];
    c = zeros(3, 3);
    ne = this.mesh.elementCount;
    for i = 1:ne
      e = this.mesh.elements(i);
      if e == element
        [ce, ue, x] = this.performInsideUIntegration(csi, p, e);
      else
        [ce, ue, x] = this.computeU(p, e);
      end
      u = u + ue;
      c = c + ce;
      this.p = [this.p; x];
    end
    u = u * (c ^ -1)';
    fprintf('Gauss points: %d\n', size(this.p, 1));
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
      p = points(k, :);
      [xp, e, csi, d] = projectOntoBoundary(this.mesh, p);
      [sp, ~, ~, ep, up] = this.computeBoundaryStress(csi, xp, e);
      % Add the stress at the projection point for regularization
      s(:, :, k) = sp;
      bflag = d <= EPP.eps;
      if bflag
        if dflag
          warning('Point %d is in element %d', k, e.id);
        end
        nb = nb + 1;
      else
        this.setSRData(xp, sp, ep, up);
        for i = 1:ne
          e = this.mesh.elements(i);
          [se, x] = this.performOutsideSIntegration(p, e);
          s(:, :, k) = s(:, :, k) + se;
          this.p = [this.p; x];
        end
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

  function [s, t, N, e, u] = computeBoundaryStress(this, csi, ~, element)
  % Computes the stress at a boundary point
  %
  % Input
  % =====
  % CSI: 1x2 array with the parametric coordinates of P
  % P: 1x3 array with the coordinates of the boundary point
  % ELEMENT: reference to an element containing P
  %
  % Output
  % ======
  % S: 3x3 array with the stress at P
  % T: 3x1 array with the traction at P
  % N: 3x1 array with the coordinates of the normal at P
  % E: 3x3 array with the strain at P
  % U: 3x1 array with the displacement at P
    [v1, v2, N] = element.tangentAt(csi(1), csi(2));
    inv_nv1 = 1 / norm(v1);
    inv_nv2 = 1 / norm(v2);
    cost = v1 * v2' * inv_nv1 * inv_nv2;
    inv_sint = 1 / sqrt(1 - cost ^ 2);
    J11 = inv_nv1;
    J12 = -cost * inv_sint * inv_nv1;
    J22 = inv_sint * inv_nv2;
    % Make a orthonormal local system at P
    N = N / norm(N);
    v1 = v1 * inv_nv1;
    v2 = cross(N, v1);
    % Local to global rotation matrix
    R = [v1', v2', N'];
    % Compute the global traction...
    [Su, Sv, S] = element.shapeFunction.diff(csi(1), csi(2));
    t = sum(element.nodeTractions .* S);
    %...and local displacement derivatives at P
    ue = element.nodeDisplacements;
    du = [sum(ue .* Su); sum(ue .* Sv)] * R(:, 1:2);
    % Compute the local strains
    e = zeros(3, 3);
    e(1, 1) = du(1, 1) * J11;
    e(1, 2) = du(1, 1) * J12 + du(2, 1) * J22;
    e(2, 2) = du(1, 2) * J12 + du(2, 2) * J22;
    % Compute the local stress at P
    m = this.material;
    s = zeros(3, 3);
    s(:, 3) = t * R;
    c1 = 1 / (1 - m.nu);
    c2 = 2 * m.G;
    s(1, 1) = c1 * (c2 * (e(1, 1) + m.nu * e(2, 2)) + m.nu * s(3, 3));
    s(2, 2) = c1 * (c2 * (e(2, 2) + m.nu * e(1, 1)) + m.nu * s(3, 3));
    s(1, 2) = c2 * e(1, 2);
    s(2, 1) = s(1, 2);
    s(3, 1) = s(1, 3);
    s(3, 2) = s(2, 3);
    % Transform the strain from local to global and compute
    % the global displacement (for regularization)
    if nargout > 3
      e(2, 1) = e(1, 2);
      e(1:2, 3) = s(1:2, 3) / c2;
      e(3, 1:2) = e(1:2, 3);
      e(3, 3) = c1 * ((1 - 2 * m.nu) * s(3, 3) / c2 ...
        - m.nu * (e(1, 1) + e(2, 2)));
      e = R * e * R';
      u = sum(ue .* S);
    end
    % Transform the stress from local to global
    s = R * s * R';
    %this.checkSE(s, e, m);
  end
end

%% Protected constant properties
properties (Constant, Access = protected)
  eps = 10e-4 / sqrt(10);
end

%% Protected properties
properties (Access = protected)
  uHandle IntegrationHandle;
  sHandle IntegrationHandle;
end

properties (Access = protected, Transient)
  srData;
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

  function [c, u, x, flag] = computeU(this, p, element)
    [flag, csi] = this.isInElement(p, element);
    if flag
      [c, u, x] = this.performInsideUIntegration(csi, p, element);
    else
      [c, u, x] = this.performOutsideUIntegration(p, element);
    end
  end

  function [s, x] = performOutsideSIntegration(this, p, element)
    handle = this.sHandle;
    handle.setElement(element);
    this.integrator.performOutsideIntegration(p, handle);
    s = handle.data.s;
    x = handle.x;
  end

  function setSRData(this, p, s, e, u)
    e(1, 2) = e(1, 2) / 2;
    e(1, 3) = e(1, 3) / 2;
    e(2, 1) = e(1, 2);
    e(2, 3) = e(2, 3) / 2;
    e(3, 1) = e(1, 3);
    e(3, 2) = e(2, 3);
    this.sr.p = p;
    this.sr.u = u;
    this.sr.e = e;
    this.sr.s = s;
  end
end

%% Private properties
properties (Access = private, Transient)
  sr;
end

%% Private static methods
methods (Access = private, Static)
  function [b, csi] = isInElement(p, element)
    [d, csi] = projectPoint(element, p);
    b = d <= EPP.eps;
  end

  function checkSE(s, e, m)
  % Check stress and strain for debug
    sg = zeros(3, 3);
    eg = zeros(3, 3);
    e_kk = m.nu / (1 - 2 * m.nu) * sum(diag(e));
    s_kk = m.nu * sum(diag(s));
    dk = eye(3);
    for i = 1:3
      for j = 1:3
        sg(i, j) = 2 * m.G * (e(i, j) + e_kk * dk(i, j));
        eg(i, j) = ((1 + m.nu) * s(i, j) - s_kk * dk(i, j)) / m.E;
      end
    end
    fprintf("ds:%g dg:%g\n", norm(s - sg), norm(e - eg));
  end
end

end % EPP
