classdef TriangleMesh < handle
% TriangleMesh: triangle mesh class
%
% Author: Paulo Pagliosa
% Last revision: 12/08/2024
%
% Description
% ===========
% An object of the class TriangleMesh represents mesh of triangles in 3D.

%% Public read-only properties
properties (SetAccess = private)
  id (1, 1) int32;
  vertices (:, 3) double;
  faces (:, 3) int32;
  vertexNormals (:, 3) double;
  scalars (:, 1) double;
end

%% Public methods
methods
  % Constructs a triangle mesh
  function this = TriangleMesh(id, vertices, faces, normals)
    this.id = id;
    this.vertices = vertices;
    this.faces = faces;
    if nargin == 4
      this.setVertexNormals(normals);
    end
  end

  % Sets the vertex normals of this triangle mesh
  function setVertexNormals(this, normals)
    assert(all(size(normals) == size(this.vertices)));
    this.vertexNormals = normals;
  end

  % Sets the vertex scalats of this triangle mesh
  function setScalars(this, scalars)
    assert(numel(scalars) == size(this.vertices, 1));
    this.scalars = scalars;
  end
end

end % TriangleMesh
