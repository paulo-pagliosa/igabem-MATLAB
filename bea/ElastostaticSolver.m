classdef ElastostaticSolver < EPBase & Solver
% ElastostaticSolver: linear elastostatic solver class
%
% Authors: M.A. Peres and P. Pagliosa
% Last revision: 12/08/2024
%
% See also: class Mesh, class Material

%% Public methods
methods
  % Constructs an elastostatic solver
  function this = ElastostaticSolver(mesh, material, varargin)
    this@EPBase(material, varargin{:});
    this@Solver(mesh);
  end

  % Evaluates the maximum integration error of BIEs as described in the
  % tests reported in Section 5 of the paper
  function testBIE(this, nids, printCFlag)
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

  % Evaluates the average integration error of BIEs as described in the
  % tests reported in Section 5 of the paper
  function averageBIE(this, nids)
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
      [c, h, g, x] = this.integrator.outsideIntegration(p, element);
    else
      csi = s.localPositions(idx, :);
      [c, h, g, x] = this.integrator.insideIntegration(csi, p, element);
    end
    temp = [this.p; x];
    this.p = temp;
  end

  function afterAssemblingLS(this)
    this.G = this.G / this.material.scale;
    this.material.setScale(1);
  end
end

end % ElastostaticSolver