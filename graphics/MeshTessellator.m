classdef MeshTessellator < handle
% MeshTessellator: mesh tessellator class
%
% Author: Paulo Pagliosa
% Last revision: 03/10/2024
%
% Description
% ===========
% An object of the class MeshTessellator transforms every element of a
% mesh into a triangle submesh.
%
% See also: Mesh

%% Public read-only properties
properties (SetAccess = private)
  mesh (1, 1) Mesh;
  resolution int32 = 10; % number of divisions in each direction
  patches (:, 1) TriangleMesh = TriangleMesh.empty;
  patchEdges (:, 1) cell = cell.empty;
end

%% Public methods
methods
  function this = MeshTessellator(mesh, resolution)
  % Constructs a mesh tessellator
    narginchk(1, 2);
    this.mesh = mesh;
    if nargin == 2
      if resolution < 1
        resolution = 1;
      end
      this.resolution = resolution;
    end
    this.execute;
  end

  function n = patchCount(this)
  % Returns the number of tessellated patches
    n = numel(this.patches);
  end

  function b = setResolution(this, value)
  % Sets the resolution of this tessellator
    b = value > 0 && value ~= this.resolution;
    if b
      this.resolution = value;
      this.patches = TriangleMesh.empty;
      this.patchEdges = cell.empty;
      this.execute;
    end
  end

  function b = flipNormals(this, shell, flag)
  % Flips vertex normals of a mesh shell
    assert(isa(shell, 'Shell'), 'Shell expected');
    if ~(shell.mesh == this.mesh)
      error('Bad shell');
    end
    if nargin < 3
      flag = true;
    end
    if flag == shell.flipNormalFlag
      b = false;
      return;
    end
    shell.flipNormalFlag = flag;
    np = numel(this.patches);
    for i = 1:np
      if this.mesh.elements(i).shell == shell
        p = this.patches(i);
        N = p.vertexNormals;
        if ~isempty(N)
          p.setVertexNormals(-N);
        end
      end
    end
    b = true;
  end

  function execute(this, index)
  % Executes the tessellation
    narginchk(1, 2);
    if this.mesh.triangular
      this.handleTrianguleMesh;
      return;
    end
    ne = this.mesh.elementCount;
    if nargin == 1 || numel(this.patches) ~= ne
      index = 1:ne;
    end
    ns = 2 * this.resolution ^ 2;
    faces = zeros(ns, 3, 'int32');
    k = 1;
    p = 1;
    for i = 1:this.resolution
      for j = 1:this.resolution
        q = p + this.resolution + 2;
        faces(k, :) = [p, p + 1, q];
        k = k + 1;
        faces(k, :) = [p, q, q - 1];
        k = k + 1;
        p = p + 1;
      end
      p = p + 1;
    end
    ns = this.resolution + 1;
    nv = ns ^ 2;
    dp = 2 / double(this.resolution);
    pidx = zeros(1, 4 * this.resolution + 1);
    pidx(1) = 1;
    s = double([1 ns -1 -ns]);
    l = 1;
    for i = 1:4
      p = pidx(l);
      k = l + 1;
      l = l + this.resolution;
      pidx(k:l) = p + s(i) * (1:this.resolution);
    end
    for i = reshape(index, 1, [])
      if i < 1 || i > ne
        continue;
      end
      element = this.mesh.elements(i);
      s = element.shapeFunction;
      r = element.nodePositions;
      vertices = zeros(nv, 3);
      N = zeros(nv, 3);
      sign = 1;
      if element.shell.flipNormalFlag
        sign = -1;
      end
      k = 1;
      for v = -1:dp:1
        for u = -1:dp:1
          [g, ~, ~, p] = s.computeGradient(r, u, v);
          vertices(k, :) = p;
          N(k, :) = g ./ norm(g) * sign;
          k = k + 1;
        end
      end
      this.patches(i) = TriangleMesh(i, vertices, faces, N);
      this.patchEdges{i} = vertices(pidx, :);
    end
  end
end

%% Private methods
methods (Access = private)
  function handleTrianguleMesh(this)
    if ~isempty(this.patches)
      return;
    end
    m = this.mesh.elementCount;
    f = zeros(m, 3);
    for i = 1:m
      f(i, :) = this.mesh.elements(i).nodeIds;
    end
    v = this.mesh.nodePositions;
    v = v(:, 1:3);
    this.patches = TriangleMesh(1, v, f);
  end
end

end % MeshTessellator
