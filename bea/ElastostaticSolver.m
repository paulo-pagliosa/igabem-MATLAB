classdef ElastostaticSolver < EPBase & Solver
% ElastostaticSolver: linear elastostatic solver class
%
% Authors: M.A. Peres and P. Pagliosa
% Last revision: 01/10/2024
%
% Description
% ==========
% An object of the class ElastostaticSolver represents a solver for
% the elastostatic problem.
%
% See also: Mesh, Material

%% Public methods
methods
  function this = ElastostaticSolver(mesh, material, varargin)
  % Constructs an elastostatic solver
    this@EPBase(material, varargin{:});
    this@Solver(mesh);
    this.hgHandle = IntegrationHandle(this, @initHGData, @updateHGData);

    function initHGData(ih, element)
      n = 3 * element.nodeCount;
      ih.data = struct('c', zeros(3, 3), ...
      'h', zeros(3, n), ...
      'g', zeros(3, n));
    end

    function updateHGData(handle, p, q, N, S, w)
      [U, T] = Kelvin3.computeUT(p, q, N, handle.solver.material);
      T = T * w;
      handle.data.c = handle.data.c - T;
      handle.data.h = handle.data.h + kron(S', T);
      handle.data.g = handle.data.g + kron(S', U * w);
    end
  end

  function testBIE(this, nids, printCFlag)
  % Evaluates the maximum integration error of BIEs as described in the
  % tests reported in Section 5 of the paper
    if nargin < 2
      nids = 1;
    end
    if nargin < 3
      printCFlag = true;
    end
    this.p = [];
    ne = this.mesh.elementCount;
    nn = numel(nids);
    for k = 1:nn
      c = zeros(3, 3);
      nid = nids(k);
      s = this.mesh.nodes(nid).loadPoint;
      [sp, ~] = s.position;
      for i = 1:ne
        element = this.mesh.elements(i);
        [cs, ~, ~] = this.computeHG(s, sp, element);
        c = c + cs;
      end
      if printCFlag
        fprintf("C(%d)=\n", nid);
        disp(c);
      end
      fprintf("Max error: %e\nTotal Gauss points: %d\n", ...
        max(max(abs(c - eye(3) / 2))), ...
        size(this.p, 1));
    end
  end

  function averageBIE(this, nids)
  % Evaluates the average integration error of BIEs as described in the
  % tests reported in Section 5 of the paper
    if nargin < 2
      nids = 1:this.mesh.nodeCount;
    end
    sumError = 0;
    error = [0, Inf];
    maxGP = 0;
    ne = this.mesh.elementCount;
    nn = numel(nids);
    for k = 1:nn
      this.p = [];
      c = zeros(3, 3);
      nid = nids(k);
      s = this.mesh.nodes(nid).loadPoint;
      [sp, ~] = s.position;
      for i = 1:ne
        element = this.mesh.elements(i);
        [cs, ~, ~] = this.computeHG(s, sp, element);
        c = c + cs;
      end
      e = max(max(abs(c - eye(3) / 2)));
      if e > error(1)
        error(1) = e;
      end
      if e < error(2)
        error(2) = e;
      end
      sumError = sumError + e;
      ng = size(this.p, 1);
      if ng > maxGP
        maxGP = ng;
      end
    end
    fprintf("Max error: [%e,%e]\nAvg error: %e\nMAx Gauss points: %d\n", ...
      error(1), error(2), ...
      sumError / nn, ...
      maxGP);
  end
end

%% Protected properties
properties (Access = protected)
  hgHandle IntegrationHandle;
end

%% Protected methods
methods (Access = protected)
  function initialize(this)
    initialize@Solver(this);
    this.material.setScale(this.material.G);
    this.p = [];
  end

  function [c, h, g] = computeHG(this, s, p, element)
    [inside, idx] = ismember(element, s.elements);
    if ~inside
      [c, h, g, x] = this.performOutsideHGIntegration(p, element);
    else
      csi = s.localPositions(idx, :);
      [c, h, g, x] = this.performInsideHGIntegration(csi, p, element);
    end
    this.p = [this.p; x];
  end

  function afterAssemblingLS(this)
    this.G = this.G / this.material.scale;
    this.material.setScale(1);
  end

  function [c, h, g, x] = performOutsideHGIntegration(this, p, element)
    handle = this.hgHandle;
    handle.setElement(element);
    this.integrator.performOutsideIntegration(p, handle);
    c = handle.data.c;
    h = handle.data.h;
    g = handle.data.g;
    x = handle.x;
  end

  function [c, h, g, x] = performInsideHGIntegration(this, csi, p, element)
    handle = this.hgHandle;
    handle.setElement(element);
    this.integrator.performInsideIntegration(csi, p, handle);
    c = handle.data.c;
    h = handle.data.h;
    g = handle.data.g;
    x = handle.x;
  end
end

end % ElastostaticSolver
