classdef (Abstract) Solver < handle
% Solver: generic static linear solver class
%
% Author: Paulo Pagliosa
% Last revision: 31/08/2024
%
% Description
% ===========
% The abstract class Solver encapsulates the properties and behavior
% of a generic static linear solver for 3D BEA. The only public property
% of a solver is the BEA model to be analyzed. The protected properties
% include the global matrices H and G, the nodal displacement and traction
% vectors (for elastic problems, but they can be any other 3D vector
% variables), the nodal dofs, and the element maps discussed in Section 3
% of the paper. The protected methods implement the (sequential version
% of the pipeline) presented in Section 6.1. The class declares an abstract
% method that must be defined in derived concrete classes for computing the
% jump term and the influence matrices of a given boundary element.
%
% See also: class Mesh

%% Public properties
properties
  mesh;
end

%% Public read-only properties
properties (Access = protected)
  dofs;
  H;
  G;
  u;
  t;
  hMap;
  gMap;
end

%% Public methods
methods
  % Sets the msh of this solver
  function set.mesh(obj, value)
    assert(isa(value, 'Mesh'), 'Mesh expected');
    obj.mesh = value;
  end
end

methods
  % Performs the analysis
  function execute(this)
    fprintf('**Starting analysis...\n');
    time = tic;
    this.initialize;
    this.run;
    this.quit;
    time = toc(time);
    fprintf('**End of analysis (elapsed time: %f seconds)\n', time);
  end
end

%% Protected methods
methods (Access = protected)
  function this = Solver(mesh)
    this.mesh = mesh;
  end

  function initialize(this)
    this.mesh.renumerateAll;
    % Compute the LS equation numbers
    nn = this.mesh.nodeCount;
    nu = 3 * nn;
    this.dofs = zeros(nu, 1, 'int32');
    mIdx = zeros(nn, 1, 'int32');
    n = 0;
    m = 0;
    for i = 1:nn
      node = this.mesh.nodes(i);
      for k = 1:3
        n = n + 1;
        if node.dofs(k, 1) > 0 % constraint
          this.dofs(n) = -(3 * (m + node.dofs(k, 2) - 1) + k);
        else % load
          this.dofs(n) = n;
        end
      end
      mIdx(i) = m;
      m = m + node.multiplicity;
    end
    % Set the vectors u and t
    nt = 3 * m;
    this.u = zeros(nu, 1);
    this.t = zeros(nt, 1);
    n = 0;
    for i = 1:nn
      node = this.mesh.nodes(i);
      m = mIdx(i);
      for k = 1:3
        n = n + 1;
        region = node.dofs(k, 2);
        if node.dofs(k, 1) > 0 % constraint
          this.u(n) = node.u(k);
        end
        for r = 1:node.multiplicity
          if r == region
            continue;
          end
          this.t(3 * (m + r - 1) + k) = node.t(r, k);
        end
      end
    end
    % Allocate the matrices H and G
    this.H = zeros(nu, nu);
    this.G = zeros(nu, nt);
    % Compute the element location arrays
    ne = this.mesh.elementCount;
    this.hMap = cell(ne, 1);
    this.gMap = cell(ne, 1);
    for i = 1:ne
      element = this.mesh.elements(i);
      ids = element.nodeIds;
      idx = 3 * ids;
      idx = [idx - 2, idx - 1, idx]';
      this.hMap{element.id} = idx(:);
      idx = 3 * (mIdx(ids) + element.nodeRegions);
      idx = [idx - 2, idx - 1, idx]';
      this.gMap{element.id} = idx(:);
    end
  end

  function run(this)
    % Assembly linear system
    nn = this.mesh.nodeCount;
    ne = this.mesh.elementCount;
    fprintf('Assembling LS...\n');
    dots = min(40, nn);
    fprintf('%s\n', repmat('*', 1, dots));
    slen = dots / nn;
    step = 1;
    rows = [1 2 3];
    for k = 1:nn
      % Print progress
      if k * slen >= step
        fprintf('.');
        step = step + 1;
      end
      c = zeros(3, 3);
      s = this.mesh.nodes(k).loadPoint;
      [p, N] = s.position;
      for i = 1:ne
        element = this.mesh.elements(i);
        [cs, h, g] = this.computeHG(s, p, element);
        hCols = this.hMap{element.id};
        gCols = this.gMap{element.id};
        this.H(rows, hCols) = this.H(rows, hCols) + h;
        this.G(rows, gCols) = this.G(rows, gCols) + g;
        c = c + cs;
      end
      c = kron(N', c);
      cCols = this.hMap{s.elements(1).id};
      this.H(rows, cCols) = this.H(rows, cCols) + c;
      rows = rows + 3;
    end
    this.afterAssemblingLS;
    % Apply BCs
    uIdx = find(this.dofs < 0);
    tIdx = -this.dofs(uIdx);
    temp = -this.H(:, uIdx);
    this.H(:, uIdx) = -this.G(:, tIdx);
    this.G(:, tIdx) = temp;
    this.t(tIdx) = this.u(uIdx);
    this.beforeSolvingLS;
    fprintf('\nSolving LS...\n');
    % Solve linear system
    x = this.H \ (this.G * this.t);
    % Save nodal displacements and tractions
    n = 0;
    for i = 1:nn
      node = this.mesh.nodes(i);
      for k = 1:3
        n = n + 1;
        if node.dofs(k, 1) > 0 % constraint
          node.t(node.dofs(k, 2), k) = x(n);
        else % load
          node.u(k) = x(n);
        end
      end
    end
  end

  function afterAssemblingLS(~)
    % do nothing
  end

  function beforeSolvingLS(~)
    % do nothing
  end

  function quit(this)
    this.dofs = [];
    this.H = [];
    this.G = [];
    this.u = [];
    this.t = [];
    this.hMap = [];
    this.gMap = [];
  end
end

methods (Abstract, Access = protected)
  [c, h, g] = computeHG(this, s, p, element)
end

end % Solver
