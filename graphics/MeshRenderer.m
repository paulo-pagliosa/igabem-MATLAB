classdef MeshRenderer < Renderer
% MeshRenderer: mesh renderer class
%
% Author: Paulo Pagliosa
% Last revision: 12/08/2024
%
% Description
% ===========
% An object of the class MeshRenderer is responsible for rendering a mesh.
% A mesh renderer relies on a mesh tesselator for transforming every
% element of its input mesh into into a triangle submesh. The resulting
% set of triangle submeshes are then rendered by the mesh renderer.
%
% See also: class Mesh, class MeshTesselator

%% Public properties
properties
  nodeProperties = PointProperties('blue', 'o', 5);
  vertexProperties = PointProperties('cyan', 'o', 2);
  edgeProperties = LineProperties('blue', '-', 1);
end

%% Protected properties
properties (Access = protected)
  tesselator;
  mesh;
  meshPlot;
  nodePlot;
  vertexNormalPlot;
  faceColor = [0.5 0.5 0.5];
  faceAlpha = 1;
  normalScale = 2;
  normalColor = [102, 0, 102] / 255;
  flags = struct('vertex', false, ...
    'edge', false, ...
    'vertexNormal', false, ...
    'node', false, ...
    'colorMap', false);
end

%% Private properties
properties (Access = private)
  clickNodeHandle = '';
  clickPatchHandle = '';
end

%% Public methods
methods
  % Constructs a mesh renderer
  function this = MeshRenderer(axes, mesh, redraw)
    assert(isa(mesh, 'Mesh'), 'Mesh expected');
    assert(~mesh.empty, 'Mesh is empty');
    this = this@Renderer(axes);
    this.tesselator = MeshTesselator(mesh, 4);
    this.mesh = mesh;
    if nargin < 2 || redraw
      this.redraw;
    end
  end

  % Redraws the mesh of this renderer
  function redraw(this)
    this.render;
  end

  % Sets the mesh node color
  function setNodeColor(this, color)
    this.nodeProperties.color = color;
    this.flags.node = false;
    this.showNodes(true);
  end

  % Sets the patch vertex color
  function setVertexColor(this, color)
    this.vertexProperties.color = color;
    this.flags.vertex = false;
    this.showVertices(true);
  end

  % Sets the patch edge color
  function setEdgeColor(this, color)
    this.edgeProperties.color = color;
    this.flags.edge = false;
    this.showEdges(true);
  end

  % Sets the patch face color
  function setFaceColor(this, color)
    this.faceColor = color;
    set(this.meshPlot, 'FaceColor', color);
  end

  % Sets the patch face color
  function setFaceAlpha(this, alpha)
    if alpha < 0
      alpha = 0;
    elseif alpha > 1
      alpha = 1;
    end
    this.faceAlpha = alpha;
    set(this.meshPlot, 'FaceAlpha', alpha);
  end

  % Sets the scale of normals
  function setNormalScale(this, scale)
    if scale == this.normalScale || scale < 0
      return;
    end
    this.normalScale = scale;
    if ~isempty(this.vertexNormalPlot)
      set(this.vertexNormalPlot, 'AutoScaleFactor', scale);
    end
  end

  % Sets the color of normals
  function setNormalColor(this, color)
    this.normalColor = color;
    if ~isempty(this.vertexNormalPlot)
      set(this.vertexNormalPlot, 'Color', color);
    end
  end

  % Shows the patch vertices
  function showVertices(this, flag)
    if nargin < 2
      flag = true;
    end
    if flag == this.flags.vertex
      return;
    end
    if flag
      color = this.vertexProperties.color;
    else
      color = 'none';
    end
    this.flags.vertex = flag;
    set(this.meshPlot, 'MarkerEdgeColor', color, 'MarkerFaceColor', color);
  end

  % Shows the patch edges
  function showEdges(this, flag)
    if nargin < 2
      flag = true;
    end
    if flag == this.flags.edge
      return;
    end
    if flag
      color = this.edgeProperties.color;
    else
      color = 'none';
    end
    this.flags.edge = flag;
    set(this.meshPlot, 'EdgeColor', color);
  end

  % Shows the patch normals
  function showVertexNormals(this, flag)
    if nargin < 2
      flag = true;
    end
    if flag == this.flags.vertexNormal
      return;
    end
  this.flags.vertexNormal = flag;
  this.renderVertexNormals;
  end
  
  % Shows the mesh nodes
  function showNodes(this, flag)
    if nargin < 2
      flag = true;
    end
    if flag == this.flags.node
      return;
    end
  this.flags.node = flag;
  this.renderMeshNodes;
  end
  
  % Shows the color map for the mesh scalars
  function showColorMap(this, flag)
    if nargin == 1
      flag = true;
    end
    if flag == this.flags.colorMap
      return;
    end
    this.flags.colorMap = flag;
    set(this.meshPlot, 'FaceColor', this.faceColor);
    if ~flag
      return;
    end
    np = this.tesselator.patchCount;
    for i = 1:np
      s = this.tesselator.patches(i).scalars;
      if ~isempty(s)
        set(this.meshPlot(i), 'CData', s, 'FaceColor', 'interp');
      end
    end
  end
end

%% Protected methods
methods (Access = protected)
  function setClickNodeHandle(this, handle)
    assert(isa(handle, 'function_handle'), 'Function expected');
    this.clickNodeHandle = handle;
    set(this.nodePlot, 'ButtonDownFcn', handle);
  end

  function h = drawMeshNodes(this)
    n = this.mesh.nodeCount;
    h = zeros(n, 1);
    for i = 1:n
      node = this.mesh.nodes(i);
      h(i) = line('Parent', this.axes, ...
        'XData', node.position(1), ...
        'YData', node.position(2), ...
        'ZData', node.position(3), ...
        'LineStyle', 'none', ...
        'Marker', this.nodeProperties.shape, ...
        'MarkerSize', this.nodeProperties.size, ...
        'MarkerFaceColor', this.nodeProperties.color, ...
        'MarkerEdgeColor', this.nodeProperties.color, ...
        'ButtonDownFcn', this.clickNodeHandle, ...
        'UserData', node.id);
    end
  end

  function renderMeshNodes(this)
    delete(this.nodePlot);
    this.nodePlot = [];
    if this.flags.node
      %this.nodePlot = this.drawPoint(this.mesh.nodePositions, ...
      %  this.nodeProperties.color, ...
      %  this.nodeProperties.shape, ...
      %  this.nodeProperties.size);
      this.nodePlot = this.drawMeshNodes;
    end
  end

  function setClickPatchHandle(this, handle)
    assert(isa(handle, 'function_handle'), 'Function expected');
    this.clickPatchHandle = handle;
    set(this.meshPlot, 'ButtonDownFcn', handle);
  end

  function h = drawPatches(this, index)
    if this.flags.vertex
      vertexColor = this.vertexProperties.color;
    else
      vertexColor = 'none';
    end
    if this.flags.edge
      edgeColor = this.edgeProperties.color;
    else
      edgeColor = 'none';
    end
    np = numel(index);
    h = zeros(np, 1);
    k = 1;
    for i = index
      p = this.tesselator.patches(i);
      h(k) = patch('Parent', this.axes, ...
        'Vertices', p.vertices, ...
        'Faces', double(p.faces), ...
        'BackFaceLighting', 'unlit', ...
        'FaceColor', this.faceColor, ...
        'FaceAlpha', this.faceAlpha, ...
        'FaceLighting', 'gouraud', ...
        'MarkerEdgeColor', vertexColor, ...
        'MarkerFaceColor', vertexColor, ...
        'Marker', this.vertexProperties.shape, ...
        'MarkerSize', this.vertexProperties.size, ...
        'EdgeColor', edgeColor, ...
        'LineStyle', this.edgeProperties.style, ...
        'LineWidth', this.edgeProperties.width, ...
        'ButtonDownFcn', this.clickPatchHandle, ...
        'UserData', p.id);
      if ~isempty(p.vertexNormals)
        set(h(k), 'VertexNormals', p.vertexNormals);
      end
      if this.flags.colorMap && ~isempty(p.scalars) 
        set(h(k), 'CData', p.scalars, 'FaceColor', 'interp');
      end
      k = k + 1;
    end
  end

  function renderPatches(this, index)
    if nargin == 1
      index = 1:this.tesselator.patchCount;
    end
    if ~isempty(this.meshPlot)
      delete(this.meshPlot(index));
    end
    this.meshPlot(index) = drawPatches(this, index);
  end

  function renderVertexNormals(this)
    delete(this.vertexNormalPlot);
    this.vertexNormalPlot = [];
    if ~this.flags.vertexNormal
      return;
    end
    np = this.tesselator.patchCount;
    h = zeros(np, 1);
    for i = 1:np
      p = this.tesselator.patches(i);
      N = p.vertexNormals;
      if isempty(N)
        continue;
      end
      x = p.vertices;
      h(i) = quiver3(this.axes, ...
        x(:, 1), x(:, 2), x(:, 3), N(:, 1), N(:, 2), N(:, 3), ...
        this.normalScale);
    end
    this.vertexNormalPlot = h(h > 0);
    set(this.vertexNormalPlot, 'Color', this.normalColor);
  end

  function render(this)
    this.renderPatches;
    this.renderVertexNormals;
    this.renderMeshNodes;
  end
end

end % MeshRenderer