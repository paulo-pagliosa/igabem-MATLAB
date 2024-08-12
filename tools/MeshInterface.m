classdef MeshInterface < MeshRenderer
% MeshInterface: mesh interface class
%
% Authors: M. Peres and P. Pagliosa
% Last revision: 12/08/2024
%
% Description
% ===========
% An object of the class MeshInterface is a graphic tool for visualization
% of a mesh (see class Mesh).

%% Public properties
properties
  groundFaceAlpha = 1;
  groundFaceColor = [0.8 0.8 0.8];
  groundEdgeColor = [0.4 0.4 0.4];
  selectElementColor = [0 0.3 0.6];
  nodeElementColor = [1 1 0];
end

%% Public read-only properties
properties (SetAccess = private)
  undeformedMeshAlpha = 0.2;
  undeformedMeshColor = [0.9 0.9 0.9];
  vectorColor = [255 128 0] / 255;
  vectorScale = 3;
end

%% Dependent properties
properties (Dependent)
  projection;
end

%% Private properties
properties (Access = private)
  editMode = EditMode.SELECT;
  selectMode = SelectMode.SET;
  selectNodeFilter = false;
  selectedNodeIndex (1, 1) int32 = 0;
  selectedElementFlag (:, 1) logical;
  hiddenPatchFlag (:, 1) logical;
  selectedNodePlot;
  selectedElementPlot;
  selectedElementNodePlot;
  scalarExtractor;
  vectorHandle;
  meshPlots;
  colorBar;
  toolButtons;
  rot3Tool;
  moveTool;
  zoomTool;
  lights;
  cameraGismo;
  groundPlot;
  tempFlags;
  %elementView;
end

%% Public methods
methods
  function this = MeshInterface(mesh)
    a = openFigure('Mesh View');
    set(a, 'Visible', 'off', 'NextPlot', 'add', 'Clipping', 'off');
    a.Projection = 'perspective';
    a.View = [-37.5 30];
    %cameratoolbar(a.Parent);
    material(a, 'metal');
    colormap(a.Parent, 'jet');
    this = this@MeshRenderer(a, mesh, false);
    this.selectedElementFlag = zeros(mesh.elementCount, 1, 'logical');
    this.hiddenPatchFlag = this.selectedElementFlag;
    this.setClickPatchHandle(@this.onClickPatch);
    this.scalarExtractor = ScalarExtractor(this.tesselator);
    this.flags.patchEdge = true;
    this.flags.loadPoint = false;
    this.flags.vector = false;
    this.flags.ground = false;
    this.flags.nodeElement = false;
    this.flags.undeformed.mesh = true;
    this.meshPlots.edges = [];
    this.meshPlots.regionEdges = [];
    this.meshPlots.loadPoints = [];
    this.meshPlots.vectors = [];
    this.meshPlots.undeformed.mesh = [];
    this.meshPlots.undeformed.regionEdges = [];
    this.makeEditTools;
    this.setToolbar;
    this.redraw;
    this.lights = [camlight(a, 'left') camlight(a, 'right')];
    color = [1 1 1];
    this.lights(1).Color = color;
    this.lights(2).Color = color * 0.5;
    this.cameraGismo = CameraGismo(a);
    a.Parent.WindowKeyPressFcn = @this.onKeyPress;
    %this.openElementView;
  end

  function showCameraGismo(this, flag)
    if nargin < 2
      flag = true;
    end
    this.cameraGismo.visible = flag;
  end

  function setView(this, azimuth, elevation)
    view = [azimuth elevation];
    this.axes.View = view;
    event.Axes = this.axes;
    this.onMoveCamera([], event);
  end

  function zoomIn(this, scale)
    a = this.axes.CameraViewAngle;
    this.axes.CameraViewAngle = a / scale;
  end

  function zoomOut(this, scale)
    a = this.axes.CameraViewAngle;
    this.axes.CameraViewAngle = a * scale;
  end

  function set.groundFaceColor(this, value)
    this.groundFaceColor = value;
    this.redrawGround;
  end

  function set.groundEdgeColor(this, value)
    this.groundEdgeColor = value;
    this.redrawGround;
  end

  function set.groundFaceAlpha(this, value)
    this.groundFaceAlpha = value;
    this.redrawGround;
  end

  function set.selectElementColor(this, value)
    this.selectElementColor = value;
    this.redrawSelectedElements;
  end

  function set.nodeElementColor(this, value)
    this.nodeElementColor = value;
    this.redrawSelectedNodeElements;
  end

  function showUndeformedMesh(this, flag)
    if nargin < 2
      flag = true;
    end
    if flag == this.flags.undeformed.mesh
      return;
    end
    this.flags.undeformed.mesh = flag;
    if ~isempty(this.meshPlots.undeformed.mesh)
      set(this.meshPlots.undeformed.mesh, 'Visible', flag);
    end
    if ~isempty(this.meshPlots.undeformed.regionEdges)
      set(this.meshPlots.undeformed.regionEdges, 'Visible', flag);
    end
  end

  function setUndeformedMeshAlpha(this, value)
    if value < 0 || value > 1
      return;
    end
    this.undeformedMeshAlpha = value;
    if ~isempty(this.meshPlots.undeformed.mesh)
      set(this.meshPlots.undeformed.mesh, 'FaceAlpha', value);
    end
  end

  function setUndeformedMeshColor(this, value)
    this.undeformedMeshColor = value;
    if ~isempty(this.meshPlots.undeformed.mesh)
      set(this.meshPlots.undeformed.mesh, 'FaceColor', value);
    end
  end

  function setVectorScale(this, scale)
    if scale == this.vectorScale || scale < 0
      return;
    end
    this.vectorScale = scale;
    if ~isempty(this.meshPlots.vectors)
      this.meshPlots.vectors.AutoScaleFactor = scale;
    end
  end

  function setVectorColor(this, color)
    this.vectorColor = color;
    if ~isempty(this.meshPlots.vectors)
      this.meshPlots.vectors.Color = color;
    end
  end

  function set.projection(this, value)
    this.axes.Projection = value;
  end

  function hidePatches(this, flag)
    if nargin < 2
      flag = true;
    end
    if ~flag
      index = find(this.hiddenPatchFlag)';
      this.hiddenPatchFlag(index) = false;
      this.renderPatches(index);
      this.renderPatchEdges;
    else
      index = find(this.selectedElementFlag)';
      this.selectedElementFlag(index) = false;
      this.hiddenPatchFlag(index) = true;
      this.redrawSelectedElements;
      set(this.meshPlot(index), 'Visible', false);
      if ~isempty(this.meshPlots.edges)
        set(this.meshPlots.edges(index), 'Visible', false);
        for i = index
          set(this.meshPlots.regionEdges{i}, 'Visible', false);
        end
      end
    end
  end

  function showPatchEdges(this, flag)
    if nargin < 2
      flag = true;
    end
    if flag == this.flags.patchEdge
      return;
    end
    this.flags.patchEdge = flag;
    this.renderPatchEdges;
  end

  function showNodeElements(this, flag)
    if nargin < 2
      flag = true;
    end
    if flag == this.flags.nodeElement
      return;
    end
    this.flags.nodeElement = flag;
    if flag
      this.deselectAllElements;
      this.redrawSelectedNodeElements;
    else
      index = this.mesh.nodeElements{this.selectedNodeIndex};
      this.renderPatches(index);
    end
  end

  function showColorBar(this, flag)
    if nargin == 1 || flag
      if isempty(this.colorBar)
        this.colorBar = this.makeColorBar;
        this.toolButtons(end).State = 'on';
      end
    elseif ~isempty(this.colorBar)
      delete(this.colorBar);
      this.colorBar = [];
      this.toolButtons(end).State = 'off';
    end
  end

  function setColorBarLimits(this, minv, maxv)
    this.showColorBar;
    if minv > maxv
      this.colorBar.Limits = [maxv, minv];
    else
      this.colorBar.Limits = [minv, maxv];
    end
  end

  function showColorMap(this, flag)
    if nargin == 1
      flag = true;
    end
    if flag
      this.scalarExtractor.execute;
    end
    this.flags.nodeElement = false;
    showColorMap@MeshRenderer(this, flag);
    this.redrawSelectedElements;
    if ~isempty(this.colorBar)
      this.colorBar = this.makeColorBar;
    end
  end

  function updateColorMap(this)
    flag = this.flags.colorMap;
    this.flags.colorMap = false;
    this.showColorMap(flag);
  end

  function setScalar(this, field, varargin)
    this.scalarExtractor.setField(field, varargin{:});
    this.updateColorMap;
  end

  function remesh(this, resolution)
    if this.tesselator.setResolution(resolution)
      flag = this.flags.colorMap;
      this.flags.colorMap = false;
      this.redraw;
      this.showColorMap(flag);
    end
  end

  function flipVertexNormals(this, flag)
    if nargin == 1
      flag = true;
    end
    elements = this.selectedElements;
    ne = numel(elements);
    if ne == 0
      invalid = this.tesselator.flipNormals(this.mesh.outerShell, flag);
    else
      invalid = false;
      for i = 1:ne
        if this.tesselator.flipNormals(elements(i).shell, flag)
          invalid = true;
        end
      end
    end
    if invalid
      this.redraw;
    end
  end

  function node = selectedNode(this)
    if this.selectedNodeIndex == 0
      node = Node.empty;
    else
      node = this.mesh.nodes(this.selectedNodeIndex);
    end
  end

  function selectNode(this, i)
    if i < 1 || i > this.mesh.nodeCount
      fprintf('Invalid node index');
    elseif ~(this.selectedNodeIndex == i)
      this.selectedNodeIndex = i;
      this.redrawSelectedNode;
    end
  end

  function deselectNode(this)
    this.selectedNodeIndex = 0;
    this.redrawSelectedNode;
  end

  function moveNode(this, t)
    this.selectedNode.move(t);
    index = this.mesh.nodeElements{this.selectedNodeIndex};
    this.tesselator.execute(index);
    this.flags.colorMap = false;
    this.redraw;
  end

  function elements = selectedElements(this)
    elements = this.mesh.elements(this.selectedElementFlag);
  end

  function selectElement(this, i, mode)
    if i < 1 || i > this.mesh.elementCount
      fprintf('Invalid element index');
      return;
    end
    if nargin == 2
      mode = this.selectMode;
    end
    if mode == SelectMode.REMOVE
      if this.selectedElementFlag(i)
        this.renderPatches(i);
        this.selectedElementFlag(i) = false;
        this.redrawSelectedElements;
      end
      return;
    end
    if mode == SelectMode.SET
      index = find(this.selectedElementFlag)';
      if ~isempty(index)
        if all(index == i)
          return;
        end
        this.selectedElementFlag(index) = false;
        this.renderPatches(index);
      end
    elseif this.selectedElementFlag(i)
      return;
    end
    this.showNodeElements(false);
    this.selectedElementFlag(i) = true;
    this.redrawSelectedElements;
  end

  function selectElements(this, i)
    if any(i < 1) || any(i > this.mesh.elementCount)
      fprintf('Invalid element index');
    else
      this.showNodeElements(false);
      this.selectedElementFlag(i) = true;
      this.redrawSelectedElements;
    end
  end
  
  %TODO: optimize (Peres)
  function selectRegions(this)
    Nids = [];
    Rids = [];
    Eids = [];
    processedNids = [];
    % Selected elements define the regions that will be selected
    E = this.selectedElements;
    for i = 1:numel(E)
      elem = E(i);
      Nids = [Nids elem.nodes.id];
      Rids = [Rids; elem.nodeRegions];
    end
    i=1;
    while i < numel(Nids)
      nId = Nids(i);
      rId = Rids(i);
      i = i + 1;
      if numel(find(ismember(processedNids, nId))) > 0
        continue;
      end
      processedNids = [processedNids nId];
      nodeElemIdAll = this.mesh.nodeElements{nId};
      nodeElemIdRegion = [];
      for j = 1:numel(nodeElemIdAll)
        eId = nodeElemIdAll(j);
        elem = this.mesh.elements(eId);
        nIndexElem = ismember([elem.nodes.id],nId);
        if(numel(find(ismember(Eids,eId))) == 0 && ...
            rId == elem.nodeRegions(nIndexElem))
          nodeElemIdRegion = union(nodeElemIdRegion, eId);
          Nids = [Nids elem.nodes.id];
          Rids = [Rids; elem.nodeRegions];
        end
      end 
      Eids = union(Eids, nodeElemIdRegion);
    end
    this.selectElements(Eids);
  end

  function selectAllElements(this)
    this.showNodeElements(false);
    this.selectedElementFlag(:) = true;
    this.redrawSelectedElements;
  end

  function deselectElement(this, i)
    this.selectElement(i, SelectMode.REMOVE);
  end

  function deselectAllElements(this)
    this.renderPatches(find(this.selectedElementFlag)');
    this.selectedElementFlag(:) = false;
    this.redrawSelectedElements;
  end

  function moveElement(this, u)
    elements = this.selectedElements;
    if isempty(elements)
      fprintf('No element selected\n');
      return;
    end
    nodes = elements.nodeSet;
    nodes.move(u);
    nodeIds = vertcat(nodes.id);
    meshNodeIds = vertcat(this.mesh.nodes.id);
    nodeIndex = find(ismember(meshNodeIds, nodeIds))';
    index = [];
    for i = nodeIndex
      index = union(index, this.mesh.nodeElements{i});
    end
    this.tesselator.execute(index);
    this.flags.colorMap = false;
    this.redraw;
  end

  function c = makeConstraint(this, dofs, evaluator, varargin)
    elements = this.selectedElements;
    if isempty(elements)
      fprintf('No element selected\n');
      return;
    end
    this.deformMesh(0);
    c = this.mesh.makeConstraint(elements, dofs, evaluator, varargin{:});
    this.renderDisplacements;
  end

  function b = deleteConstraint(this, constraint)
    b = false;
    m = numel(constraint);
    if m == 0
      return;
    end
    this.deformMesh(0);
    for i = 1:m
      b = bitor(b, this.mesh.deleteConstraint(constraint(i)));
    end
    this.renderDisplacements;
    b = true;
  end

  function b = deleteAllConstraints(this)
    this.deformMesh(0);
    b = this.mesh.deleteAllConstraints;
    this.renderDisplacements;
  end

  function l = makeLoad(this, evaluator, varargin)
    elements = this.selectedElements;
    if isempty(elements)
      fprintf('No element selected\n');
      return;
    end
    l = this.mesh.makeLoad(elements, evaluator, varargin{:});
    this.renderTractions;
  end

  function b = deleteLoad(this, load)
    b = false;
    m = numel(load);
    if m == 0
      return;
    end
    for i = 1:m
      b = bitor(b, this.mesh.deleteLoad(load(i)));
    end
    this.renderTractions;
    b = true;
  end

  function b = deleteAllLoads(this)
    b = this.mesh.deleteAllLoads;
    this.renderTractions;
  end

  function deformMesh(this, scale)
    if scale == 0
      delete(this.meshPlots.undeformed.mesh);
      this.meshPlots.undeformed.mesh = [];
      delete(this.meshPlots.undeformed.regionEdges);
      this.meshPlots.undeformed.regionEdges = [];
    elseif isempty(this.meshPlots.undeformed.mesh)
      h = copyobj(this.meshPlot, this.axes);
      set(h, ...
        'FaceColor', this.undeformedMeshColor, ...
        'FaceAlpha', this.undeformedMeshAlpha, ...
        'EdgeColor', 'none', ...
        'MarkerEdgeColor', 'none', ...
        'MarkerFaceColor', 'none', ...
        'Visible', this.flags.undeformed.mesh, ...
        'PickableParts', 'none');
      this.meshPlots.undeformed.mesh = h;
      if ~isempty(this.meshPlots.regionEdges)
        h = copyobj(cell2mat(this.meshPlots.regionEdges), this.axes);
        set(h, 'Color', [0.2 0.2 0.2], 'LineWidth', 1);
        this.meshPlots.undeformed.regionEdges = h;
      end
    end
    if this.mesh.deform(scale)
      this.showColorBar(false);
      this.tesselator.execute;
      this.flags.colorMap = false;
      this.redraw;
    end
  end

  function redraw(this)
    redraw@MeshRenderer(this);
    index = find(this.hiddenPatchFlag)';
    set(this.meshPlot(index), 'Visible', false);
    this.renderPatchEdges;
    this.redrawSelectedElements;
    this.redrawSelectedNode;
    this.redrawSelectedNodeElements;
    this.renderVectors;
    this.renderLoadPoints;
    this.renderGround;
  end

  function setEdgeColor(this, color)
    setEdgeColor@MeshRenderer(this, color);
    this.redrawSelectedElements;
  end

  function setFaceColor(this, color)
    setFaceColor@MeshRenderer(this, color);
    this.redrawSelectedElements;
  end

  function showEdges(this, flag)
    if nargin < 2
      flag = true;
    end
    showEdges@MeshRenderer(this, flag);
    this.redrawSelectedElements;
  end

  function showVectors(this, flag)
    handle = this.vectorHandle;
    if nargin < 2
      flag = true;
    elseif ischar(flag)
      switch flag
        case 'u'
          this.vectorHandle = @MeshInterface.uHandle;
        case 't'
          this.vectorHandle = @MeshInterface.tHandle;
        otherwise
          error('Bad vector handler');
      end
      flag = true;
    end
    if flag ~= this.flags.vector || ~isequal(handle, this.vectorHandle)
      if isempty(this.vectorHandle)
        fprintf("No vector handle specified\n");
      else
        this.flags.vector = flag;
        this.renderVectors;
      end
    end
  end

  function showLoadPoints(this, flag)
    if nargin == 1
      flag = true;
    end
    if flag == this.flags.loadPoint
      return;
    end
    this.flags.loadPoint = flag;
    this.renderLoadPoints;
  end

  function showGround(this, flag)
    if nargin == 1
      flag = true;
    end
    if flag == this.flags.ground
      return;
    end
    this.flags.ground = flag;
    this.renderGround;
  end

  function paintPatches(this, color, pids)
    np = this.mesh.elementCount;
    if nargin < 3
      pids = 1:np;
    else
      pids = pids(pids > 0);
      pids = pids(pids <= np);
      if isempty(pids)
        return;
      end
    end
  set(this.meshPlot(pids), 'FaceColor', color);
  end

  function meshColoring(this, colorMapHandler, shuffle)
    if nargin < 2
      colorMapHandler = @jet;
    elseif ~isa(colorMapHandler, 'function_handle')
      error('Colormap handler expected');
    end
    [colors, count] = meshColoring(this.mesh, true);
    nc = numel(count);
    colormap = colorMapHandler(nc);
    if nargin < 3 || shuffle
      cid = randperm(nc);
    else
      cid = 1:nc;
    end
    for i = 1:numel(colors)
      set(this.meshPlot(i), 'FaceColor', colormap(cid(colors(i)), :));
    end
  end
end

%% Private properties
methods (Access = private)
  function h = drawNodes(this, nodes, color)
    h = this.drawPoint(vertcat(nodes.position), ...
      color, ...
      this.nodeProperties.shape, ...
      this.nodeProperties.size);
  end

  function h = drawVectors(this, elements, handle)
    function x = patchVertices(element)
      x = this.tesselator.patches(this.mesh.elements == element);
      x = x.vertices;
    end

    n = this.tesselator.resolution + 1;
    p = gridSpace(n);
    n = n ^ 2;
    m = numel(elements);
    V = zeros(n, 3, m);
    X = zeros(n, 3, m);
    for k = 1:m
      element = elements(k);
      s = element.shapeFunction;
      v = handle(element);
      for i = 1:n
        V(i, :, k) = s.interpolate(v, p(i, 1), p(i, 2));
      end
      X(:, :, k) = patchVertices(element);
    end
    h = quiver3(this.axes, ...
      X(:, 1, :), X(:, 2, :), X(:, 3, :), ...
      V(:, 1, :), V(:, 2, :), V(:, 3, :), ...
      this.vectorScale);
    h.Color = this.vectorColor;
  end

  function renderPatchEdges(this)
    delete(this.meshPlots.edges);
    this.meshPlots.edges = [];
    hc = this.meshPlots.regionEdges;
    for i = 1:numel(hc)
      delete(hc{i});
    end
    this.meshPlots.regionEdges = [];
    if ~this.flags.patchEdge || isempty(this.tesselator.patchEdges)
      return;
    end
    n = this.tesselator.patchCount;
    he = zeros(n, 1);
    hc = cell(n, 1);
    for i = 1:n
      p = this.tesselator.patchEdges{i};
      isVisible = ~this.hiddenPatchFlag(i);
      he(i) = drawPatchEdges(p, 1, isVisible);
      face = this.mesh.elements(i).face;
      if ~isempty(face)
        hfc = zeros(4, 1);
        c = face.nodes;
        if ~isempty(c)
          sidx = 1;
          for k = 1:4
            eidx = sidx + this.tesselator.resolution;
            if c(k).multiplicity > 1 && c(rem(k, 4) + 1).multiplicity > 1
              hfc(k) = drawPatchEdges(p(sidx:eidx, :), 2, isVisible);
            end
            sidx = eidx;
          end
          hc{i} = hfc(hfc > 0);
        end
      end
    end
    this.meshPlots.edges = he;
    this.meshPlots.regionEdges = hc;

    function h = drawPatchEdges(p, width, isVisible)
      h = line('Parent', this.axes, ...
        'XData', p(:, 1), ...
        'YData', p(:, 2), ...
        'ZData', p(:, 3), ...
        'Color', 'black', ...
        'LineWidth', width, ...
        'Visible', isVisible);
    end
  end

  function renderLoadPoints(this)
    delete(this.meshPlots.loadPoints);
    this.meshPlots.loadPoints = [];
    if ~this.flags.loadPoint
      return;
    end
    n = this.mesh.nodeCount;
    p = zeros(n, 3);
    for i = 1:n
      p(i, :) = this.mesh.nodes(i).loadPoint.position;
    end
    s = this.nodeProperties.size + 2;
    this.meshPlots.loadPoints = this.drawPoint(p, 'red', 'x', s);
  end

  function renderVectors(this)
    delete(this.meshPlots.vectors);
    this.meshPlots.vectors = [];
    if ~this.flags.vector || isempty(this.vectorHandle)
      return;
    end
    elements = this.selectedElements;
    if isempty(elements)
      elements = this.mesh.elements;
    end
    this.meshPlots.vectors = this.drawVectors(elements, this.vectorHandle);
  end

  function renderDisplacements(this)
    this.vectorHandle = @MeshInterface.uHandle;
    this.renderVectors;
  end

  function renderTractions(this)
    this.vectorHandle = @MeshInterface.tHandle;
    this.renderVectors;
  end

  function renderGround(this)
    delete(this.groundPlot);
    this.groundPlot = [];
    if ~this.flags.ground
      return;
    end
    x = this.axes.XLim;
    y = this.axes.YLim;
    dx = (x(2) - x(1)) * 3;
    dy = (y(2) - y(1)) * 3;
    if this.iszero(dx) || this.iszero(dy)
      return;
    end
    n = 20;
    sx = dx / n;
    sy = dy / n;
    if sx < sy
      sy = sx;
      dy = sy * ceil(dy / sy);
    elseif sy < sx
      sx = sy;
      dx = sx * ceil(dx / sx);
    end
    cx = (x(1) + x(2)) * 0.5;
    cy = (y(1) + y(2)) * 0.5;
    dx = dx * 0.5;
    dy = dy * 0.5;
    x = cx - dx:sx:cx + dx;
    y = cy - dy:sy:cy + dy;
    [x, y] = meshgrid(x, y);
    h = surf(this.axes, ...
      'XData', x, ...
      'YData', y, ...,
      'ZData', zeros(size(x)), ...
      'FaceAlpha', this.groundFaceAlpha, ...
      'FaceColor', this.groundFaceColor, ...
      'EdgeColor', this.groundEdgeColor, ...
      'HitTest', 'off');
    this.groundPlot = h;
  end

  function redrawGround(this)
    if ~this.flags.ground
      this.showGround;
    else
      set(this.groundPlot, ...
      'FaceAlpha', this.groundFaceAlpha, ...
      'FaceColor', this.groundFaceColor, ...
      'EdgeColor', this.groundEdgeColor);
    end
  end

  function redrawSelectedNodeElements(this)
    if this.flags.nodeElement
      index = this.mesh.nodeElements{this.selectedNodeIndex};
      set(this.meshPlot(index), 'FaceColor', this.nodeElementColor);
    end
  end

  function redrawSelectedNode(this)
    if ~isempty(this.selectedNodePlot)
      if this.flags.nodeElement 
        index = this.mesh.nodeElements{this.selectedNodePlot.UserData};
        this.renderPatches(index);
      end
      delete(this.selectedNodePlot);
    end
    if this.selectedNodeIndex > 0
      node = this.mesh.nodes(this.selectedNodeIndex);
      this.selectedNodePlot = this.drawNodes(node, 'red');
      this.selectedNodePlot.UserData = this.selectedNodeIndex;
      this.redrawSelectedNodeElements;
    end
  end

  function redrawSelectedElements(this)
    if ~isempty(this.selectedElementNodePlot)
      delete(this.selectedElementNodePlot);
      this.selectedElementNodePlot = [];
    end
    plot = this.meshPlot(this.selectedElementFlag);
    if isempty(plot)
      return;
    end
    this.selectedElementPlot = plot;
    set(this.selectedElementPlot, 'FaceColor', this.selectElementColor);
    nodes = this.selectedElements.nodeSet;
    this.selectedElementNodePlot = this.drawNodes(nodes, 'black');
  end

  function onClickNode(this, p, ~)
    if this.editMode ~= EditMode.SELECT
      return;
    end
    this.selectNode(p.UserData);
  end

  function onClickPatch(this, p, ~)
    if this.editMode ~= EditMode.SELECT
      return;
    end
    switch this.axes.Parent.SelectionType
      case 'alt'
        this.selectMode = SelectMode.ADD;
      case 'extend'
        this.selectMode = SelectMode.REMOVE;
    end
    this.selectElement(p.UserData);
    this.selectMode = SelectMode.SET;
  end

  function onKeyPress(this, ~, key)
    if  upper(key.Character) == 'V'
      if this.editMode ~= EditMode.SELECT
        return;
      end
      f = this.selectNodeFilter;
      f = xor(f, true);
      set(this.meshPlot, 'Visible', ~f);
      if f
        this.tempFlags = this.flags;
        this.flags.nodeElement = false;
        %this.showGround(false);
        this.showLoadPoints(false);
        this.showVectors(false);
        this.showPatchEdges(false);
        this.showNodes(true);
        this.setClickNodeHandle(@this.onClickNode);
      else
        this.setClickNodeHandle(function_handle.empty);
        this.flags = this.tempFlags;
        this.redraw;
      end
      this.selectNodeFilter = f;
    end
  end

  function c = makeColorBar(this)
    c = colorbar(this.axes);
    c.Label.String = this.scalarExtractor.field.label;
    c.Label.FontSize = 12;
  end

  function setToolbar(this)
    tb = uitoolbar(this.axes.Parent);
    this.toolButtons = [...
      MeshInterface.newToggleTool(tb, ...
        'pointer_tool.mat', ...
        'Select elements', ...;
        @(~, ~) this.setEditMode(EditMode.SELECT)), ...
      MeshInterface.newToggleTool(tb, ...
        'rotate_tool.mat', ...
        'Rotate', ...;
        @(~, ~) this.setEditMode(EditMode.ROTATE)), ...
      MeshInterface.newToggleTool(tb, ...
        'pan_tool.mat', ...
        'Move', ...;
        @(~, ~) this.setEditMode(EditMode.MOVE)), ...
      MeshInterface.newToggleTool(tb, ...
        'zoom_in_tool.mat', ...
        'Zoom In', ...;
        @(~, ~) this.setEditMode(EditMode.ZOOM)), ...
      MeshInterface.newToggleTool(tb, ...
        'colorbar_tool.mat', ...
        'Show/Hide Color Bar', ...;
        @(~, ~) this.showColorbar(isempty(this.colorBar)))];
    this.toolButtons(1).State = 'on';
    this.toolButtons(end).Separator = 'on';
  end

  function makeEditTools(this)
    this.rot3Tool = rotate3d(this.axes.Parent);
    this.rot3Tool.ActionPostCallback = @this.onMoveCamera;
    this.rot3Tool.Enable = 'off';
    this.moveTool = pan(this.axes.Parent);
    this.moveTool.ActionPostCallback = @this.onMoveCamera;
    this.moveTool.ButtonDownFilter = @this.onEnablePanAndZoom;
    this.moveTool.Enable = 'off';
    this.zoomTool = zoom(this.axes.Parent);
    this.zoomTool.ActionPostCallback = @this.onMoveCamera;
    this.zoomTool.ButtonDownFilter = @this.onEnablePanAndZoom;
    this.zoomTool.Enable = 'off';
  end

  function onMoveCamera(this, ~, event)
    if event.Axes == this.cameraGismo.axes
      this.axes.View = this.cameraGismo.view;
    else
      this.cameraGismo.view = this.axes.View;
    end
    camlight(this.lights(1), 'left');
    camlight(this.lights(2), 'right');
  end

  function res = onEnablePanAndZoom(this, obj, ~)
    res = ~(obj.Parent == this.axes);
  end

  function setEditMode(this, mode)
    if this.editMode ~= mode
      this.toolButtons(this.editMode).State = 'off';
      this.rot3Tool.Enable = 'off';
      this.moveTool.Enable = 'off';
      this.zoomTool.Enable = 'off';
      switch mode
        case EditMode.ROTATE
          this.rot3Tool.Enable = 'on';
        case EditMode.MOVE
          setAxes3DPanAndZoomStyle(this.moveTool, this.axes, 'limits');
          this.moveTool.Enable = 'on';
        case EditMode.ZOOM
          setAxes3DPanAndZoomStyle(this.moveTool, this.axes, 'camera');
          this.zoomTool.Enable = 'on';
      end
      this.editMode = mode;
    end
    this.toolButtons(mode).State = 'on';
  end

  function openElementView(this)
    a = openFigure('BC View');
    f = a.Parent;
    p = f.Position;
    h = 100;
    p(2) = p(2) - h - 100;
    p(4) = p(4) + h + 100;
    f.Position = p;
    a.XLim = [-1 1];
    a.YLim = [-1 1];
    a.XTick = -1:0.5:1;
    a.YTick = -1:0.5:1;
    a.XGrid = 'on';
    a.YGrid = 'on';
    a.XMinorGrid = 'on';
    a.YMinorGrid = 'on';
    a.Units = 'pixels';
    p = a.Position;
    a.Position(2) = p(2) + 40;
    e = uicontrol('Style','edit');
    e.Units = 'pixels';
    p(2) = p(2) - h + 40;
    p(4) = h;
    e.Position = p;
    e.Min = 4;
    e.Max = 9;
    this.elementView = a;
  end
end

%% Private static methods
methods (Static, Access = private)
  function tool = newToggleTool(parent, filename, tooltip, callback)
    [~, ~, ext] = fileparts(filename);
    filename = fullfile('icons', filename);
    if (strcmp(ext, '.mat'))
      icon = load(filename);
      fields = fieldnames(icon);
      icon = icon.(fields{1});
    else
      [icon, map] = imread(filename);
      if ~isempty(map)
        icon = ind2rgb(icon, map);
      else
        maxc = max(icon(:));
        icon(icon == 0) = maxc;
        icon = double(icon) / double(maxc);
      end
    end
    tool = uitoggletool(parent);
    tool.CData = icon;
    tool.TooltipString = tooltip;
    tool.ClickedCallback = callback;
  end

  function b = iszero(x, eps)
    if nargin == 1
      eps = 1e-6;
    end
    b = abs(x) < eps;
  end

  function u = uHandle(element)
    u = element.nodeDisplacements;
  end

  function t = tHandle(element)
    t = element.nodeTractions;
  end
end

end % MeshInterface
