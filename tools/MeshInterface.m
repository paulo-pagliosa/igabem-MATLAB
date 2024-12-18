classdef MeshInterface < MeshRenderer
% MeshInterface: mesh interface class
%
% Authors: M.A. Peres and P. Pagliosa
% Last revision: 18/12/2024
%
% Description
% ===========
% An object of the class MeshInterface is a graphic tool for visualization
% of the geometry and analysis results of a BEA model.
% A detailed documentation is available in
%
% https://github.com/paulo-pagliosa/igabem-MATLAB
%
% See also: Mesh

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
  creaseEdgeWidth = 2;
  virtualPoints VirtualPointSet;
  bounds (:, 1) BoundingBox = BoundingBox.empty;
  patchEdgeColor = [0 0 0];
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
    this.scalarExtractor = ScalarExtractor(this.tessellator);
    this.selectedElementFlag = zeros(mesh.elementCount, 1, 'logical');
    this.hiddenPatchFlag = this.selectedElementFlag;
    this.setClickPatchHandle(@this.onClickPatch);
    this.flags.patchEdge = true;
    this.flags.loadPoint = false;
    this.flags.virtualPoint = false;
    this.flags.vector = false;
    this.flags.ground = false;
    this.flags.nodeElement = false;
    this.flags.undeformed.mesh = true;
    this.meshPlots.edges = [];
    this.meshPlots.regionEdges = [];
    this.meshPlots.loadPoints = [];
    this.meshPlots.virtualPoints = [];
    this.meshPlots.vectors = [];
    this.meshPlots.undeformed.mesh = [];
    this.meshPlots.undeformed.regionEdges = [];
    this.makeEditTools;
    this.setToolbar;
    this.redraw;
    this.lights = makeLights(a);
    this.cameraGismo = CameraGismo(a);
    a.Parent.WindowKeyPressFcn = @this.onKeyPress;
    %this.openElementView;

    function lights = makeLights(axes)
      lights = [camlight(axes, 'left') camlight(axes, 'right')];
      color = [1 1 1];
      lights(1).Color = color;
      lights(2).Color = color * 0.5;
    end
  end

  function showCameraGismo(this, flag)
    if nargin < 2
      flag = true;
    end
    this.cameraGismo.visible = flag;
  end

  function updateCameraGismo(this, position)
    if nargin < 2 || position == this.cameraGismo.position
      this.cameraGismo.update;
    else
      this.cameraGismo.setPosition(position);
    end
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

  function setCreaseEdgeWidth(this, width)
    width = max(width, 1);
    if width ~= this.creaseEdgeWidth
      this.creaseEdgeWidth = width;
      for i = 1:numel(this.meshPlots.regionEdges)
        set(this.meshPlots.regionEdges{i}, 'LineWidth', width);
      end
    end
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
    value = min(max(value, 0), 1);
    if value ~= this.groundFaceAlpha
      this.groundFaceAlpha = value;
      this.redrawGround;
    end
  end

  function set.selectElementColor(this, value)
    this.selectElementColor = value;
    this.redrawSelectedElements;
  end

  function set.nodeElementColor(this, value)
    this.nodeElementColor = value;
    this.redrawSelectedNodeElements;
  end

  function setPatchEdgeColor(this, color)
    this.patchEdgeColor = color;
    if ~isempty(this.meshPlots.edges)
      set(this.meshPlots.edges, 'Color', color);
      for i = 1:1:numel(this.meshPlots.regionEdges)
        set(this.meshPlots.regionEdges{i}, 'Color', color);
      end
    end
  end

  function setLightColor(this, color)
    this.lights(1).Color = color;
    this.lights(2).Color = color * 0.5;
  end

  function value = get.virtualPoints(this)
    if isempty(this.virtualPoints)
      this.virtualPoints = VirtualPointSet(this.mesh);
    end
    value = this.virtualPoints;
  end

  function value = get.bounds(this)
    if isempty(this.bounds)
      this.bounds = this.tessellator.bounds;
    end
    value = this.bounds;
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
    value = min(max(value, 0), 1);
    if value ~= this.undeformedMeshAlpha
      this.undeformedMeshAlpha = value;
      if ~isempty(this.meshPlots.undeformed.mesh)
        set(this.meshPlots.undeformed.mesh, 'FaceAlpha', value);
      end
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
    a = scale > 0;
    if ~isempty(this.meshPlots.vectors)
      set(this.meshPlots.vectors, 'AutoScaleFactor', scale, 'AutoScale', a);
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

  function hideAllPatches(this)
    this.selectAllElements;
    this.hidePatches;
  end

  function showPatchEdges(this, flag)
    if nargin < 2
      flag = true;
    end
    if flag == this.flags.patchEdge
      return;
    end
    this.flags.patchEdge = flag;
    if flag
      this.renderPatchEdges;
    elseif ~isempty(this.meshPlots.edges)
      set(this.meshPlots.edges, 'Visible', false);
      for i = 1:numel(this.meshPlots.regionEdges)
        set(this.meshPlots.regionEdges{i}, 'Visible', false);
      end
    end
  end

  function showNodeElements(this, flag)
    if nargin < 2
      flag = true;
    end
    if flag == this.flags.nodeElement
      return;
    end
    if flag
      if this.selectedNodeIndex == 0
        fprintf('No selected node\n');
        return;
      end
      this.deselectAllElements;
      this.flags.nodeElement = true;
      this.redrawSelectedNodeElements;
    else
      this.flags.nodeElement = false;
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

  function setColorTable(this, colors)
    if size(colors, 2) ~= 3
      fprintf('Bad color table dimension\n');
    else
      this.axes.Colormap = colors;
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

  function setScalars(this, field, varargin)
    this.scalarExtractor.setField(field, varargin{:});
    this.updateColorMap;
  end

  function remesh(this, resolution)
    if this.tessellator.setResolution(resolution)
      this.bounds = BoundingBox.empty;
      flag = this.flags.colorMap;
      this.flags.colorMap = false;
      this.redraw;
      this.showColorMap(flag);
    end
  end

  function flipVertexNormals(this, flag, sid)
    if nargin < 2
      flag = true;
    end
    if nargin < 3
      shell = Shell.empty;
    elseif sid < 1 || sid > this.mesh.shellCount
      fprintf('Invalid shell index: %d\n', sid);
      return;
    else
      shell = this.mesh.shells(sid);
    end
    if isempty(shell)
      elements = this.selectedElements;
      if isempty(elements)
        shell = this.mesh.outerShell;
      else
        invalid = false;
        for i = 1:numel(elements)
          if this.tessellator.flipNormals(elements(i).shell, flag)
            invalid = true;
          end
        end
      end
    end
    if ~isempty(shell)
      invalid = this.tessellator.flipNormals(shell, flag);
    else
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
      fprintf('Invalid node index: %d\n', i);
    elseif ~(this.selectedNodeIndex == i)
      this.selectedNodeIndex = i;
      this.redrawSelectedNode;
    end
  end

  function deselectNode(this)
    this.selectedNodeIndex = 0;
    this.redrawSelectedNode;
    this.flags.nodeElement = false;
  end

  function moveNode(this, t)
    if this.selectedNodeIndex == 0
      fprintf('No selected node\n');
      return;
    end
    this.selectedNode.move(t);
    index = this.mesh.nodeElements{this.selectedNodeIndex};
    this.tessellator.execute(index);
    this.bounds = BoundingBox.empty;
    this.flags.colorMap = false;
    this.redraw;
  end

  function elements = selectedElements(this)
    elements = this.mesh.elements(this.selectedElementFlag);
  end

  function selectElement(this, i, mode)
    if i < 1 || i > this.mesh.elementCount
      fprintf('Invalid element index: %d\n', i);
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
      fprintf('Invalid element index\n');
    else
      this.showNodeElements(false);
      this.selectedElementFlag(i) = true;
      this.redrawSelectedElements;
    end
  end

  function b = isSelectedElement(this, i)
    if any(i < 1) || any(i > this.mesh.elementCount)
      fprintf('Invalid element index\n');
      b = false;
    else
      b = this.selectedElementFlag(i);
    end
  end

  function eids = pickRegions(this, eids)
  % Picks element regions
  %
  % Input
  % =====
  % THIS: reference to a MeshInterface object
  % EIDS: optional array with element IDs
  %
  % Output
  % ======
  % EIDS: array with the picked element IDs 
  %
  % Description
  % ===========
  % Picks all elements belonging to the regions containing a set,
  % E, of seed elements. The input parameter EIDS provides the
  % IDs of the seed elements in E. If EIDS is omitted or empty,
  % the set E is given by the current selected elements, which
  % remain selected. The method uses a stack of node IDs and node
  % regions. For each element in E:
  % - Push onto the stack the node IDs and node regions of all
  %   unvisited element nodes.
  % - While the stack is not empty:
  %   - Pop from the stack the ID (NID) and region (RID) of a node
  %   - For each unpicked element influeced by the node:
  %     - If the region of the element node (whose ID is) NID is
  %       equal to RID, then:
  %       - Select the element.
  %       - Push onto the stack the node IDs and node regions of
  %         all unvisited element nodes.
    if nargin > 1 && ~isempty(eids)
      if any(eids < 1) || any(eids > this.mesh.elementCount)
        fprintf('Invalid element index\n');
        return;
      end
      E = this.mesh.elements(unique(eids, 'stable'));
    else
      % Selected elements define the regions to be picked
      E = this.selectedElements;
      if isempty(E)
        fprintf('No selected element\n');
        return;
      end
    end
    pushedNodeFlag = zeros(this.mesh.nodeCount, 1, 'logical');
    nidStack = Stack(0);
    ridStack = Stack(0);
    eids = [];
    for e = 1:numel(E)
      pushNodes(E(e));
      while ~nidStack.isEmpty
        nid = nidStack.pop;
        rid = ridStack.pop;
        nodeElements = this.mesh.nodeElements{nid};
        for k = 1:numel(nodeElements)
          eid = nodeElements(k);
          if ~ismember(eid, eids)
            element = this.mesh.elements(eid);
            nids = element.nodeIds;
            [~, nidx] = ismember(nid, nids);
            if rid == element.nodeRegions(nidx)
              eids = union(eids, eid);
              pushNodes(element);
            end
          end
        end
      end
    end

    function pushNodes(element)
      nodes = element.nodes;
      for i = 1:numel(nodes)
        id = nodes(i).id;
        if ~pushedNodeFlag(id)
          nidStack.push(id);
          ridStack.push(element.nodeRegions(i));
          pushedNodeFlag(id) = true;
        end
      end
    end
  end

  function selectRegions(this, eids)
  % Selects element regions
  %
  % Input
  % =====
  % THIS: reference to a MeshInterface object
  % EIDS: optional array with element IDs
  %
  % Output
  % ======
  % EIDS: selected element IDs 
  %
  % Description
  % ===========
  % Selects all elements belonging to the regions containing a set
  % of seed elements. The input parameter EIDS provides the IDs of
  % the seed elements. If EIDS is omitted or empty, the set is
  % given by the current selected elements.
    if nargin < 2
      eids = [];
    end
    eids = this.pickRegions(eids);
    if ~isempty(eids)
      this.deselectAllElements;
      this.selectElements(eids);
    end
  end

  function selectShell(this, sid)
    if nargin > 1
      if sid < 1 || sid > this.mesh.shellCount
        fprintf('Invalid shell index: %d\n', sid);
        return;
      end
      this.deselectAllElements;
      shell = this.mesh.shells(sid);
    else
      elements = this.selectedElements;
      if isempty(elements)
        fprintf('No selected element\n');
        return;
      end
      shell = elements(1).shell;
    end
    if this.mesh.shellCount == 1
      this.selectAllElements;
    else
      elements = this.mesh.elements;
      elements = elements([elements.shell] == shell);
      this.selectElements([elements.id]);
    end
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
    this.tessellator.execute(index);
    this.bounds = BoundingBox.empty;
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
        set(h, 'Color', [0.2 0.2 0.2], 'LineWidth', 1, 'Visible', true);
        this.meshPlots.undeformed.regionEdges = h;
      end
    end
    if this.mesh.deform(scale)
      this.showColorBar(false);
      this.tessellator.execute;
      this.bounds = BoundingBox.empty;
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
    this.renderVirtualPoints;
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

  function showVectors(this, flag, eids)
    handle = this.vectorHandle;
    update = false;
    if nargin < 2
      flag = true;
    elseif ischar(flag)
      switch flag
        case 'u'
          handle = @MeshInterface.uHandle;
        case 't'
          handle = @MeshInterface.tHandle;
        case 'update'
          update = true;
        otherwise
          error("Bad vector handler");
      end
      flag = true;
      if ~isequal(handle, this.vectorHandle)
        update = true;
      end
    end
    if nargin < 3
      eids = [];
    elseif ~flag
      warning("Unused element ID(s)");
    end
    if ~isempty(eids)
      if any(eids < 0) || any(eids > this.mesh.elementCount)
        fprintf('Invalid element index\n');
        return;
      end
      update = true;
    end
    if flag ~= this.flags.vector || update
      if isempty(handle)
        fprintf("No vector handler specified\n");
        return;
      end
      this.vectorHandle = handle;
      this.flags.vector = flag | update;
      this.renderVectors(eids);
    end
  end

  function nr = showVectorsByRegion(this, handle, colors)
    if nargin < 1 || isempty(handle)
      handle = this.vectorHandle;
    elseif handle == 'u'
      handle = @MeshInterface.uHandle;
    elseif handle == 't'
      handle = @MeshInterface.tHandle;
    else
      error("Bad vector handler");
    end
    if nargin < 3 || isempty(colors)
      colors = this.axes.ColorOrder;
    end
    cidx = 1;
    this.showVectors(false);
    this.setVectorScale(0);
    this.vectorHandle = handle;
    this.flags.vector = true;
    nr = processRegions(this, @regionHandle);

    function regionHandle(mi, ~, eids)
      h = mi.drawVectors(eids, colors(cidx, :));
      if ~isempty(h)
        mi.meshPlots.vectors(end + 1) = h;
        cidx = rem(cidx, size(colors, 1)) + 1;
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

  function showVirtualPoints(this, flag)
    if nargin == 1
      flag = true;
    end
    if flag == this.flags.virtualPoint
      return;
    end
    this.flags.virtualPoint = flag;
    this.renderVirtualPoints;
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

  function pids = paintPatches(this, color, pids)
    np = this.mesh.elementCount;
    if nargin < 3
      pids = find(this.selectedElementFlag);
      if isempty(pids)
        pids = 1:np;
      else
        this.deselectAllElements;
      end
    else
      pids = pids(pids > 0);
      pids = pids(pids <= np);
      if isempty(pids)
        return;
      end
    end
    pids = pids(~this.hiddenPatchFlag(pids));
    set(this.meshPlot(pids), 'FaceColor', color, 'FaceAlpha', this.faceAlpha);
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

  function h = drawVectors(this, eids, color)
    function x = patchVertices(element)
      x = this.tessellator.patches(this.mesh.elements == element);
      x = x.vertices;
    end

    h = [];
    eids = eids(~this.hiddenPatchFlag(eids));
    if isempty(eids)
      return;
    end    
    n = this.tessellator.resolution + 1;
    p = gridSpace(n);
    n = n ^ 2;
    m = numel(eids);
    V = zeros(n, 3, m);
    X = zeros(n, 3, m);
    for k = 1:m
      element = this.mesh.elements(eids(k));
      s = element.shapeFunction;
      v = this.vectorHandle(element);
      for i = 1:n
        V(i, :, k) = s.interpolate(v, p(i, 1), p(i, 2));
      end
      X(:, :, k) = patchVertices(element);
    end
    if any(V(:))
      h = quiver3(this.axes, ...
        X(:, 1, :), X(:, 2, :), X(:, 3, :), ...
        V(:, 1, :), V(:, 2, :), V(:, 3, :), ...
        this.vectorScale);
      h.Color = color;
    end
  end

  function renderPatchEdges(this)
    delete(this.meshPlots.edges);
    this.meshPlots.edges = [];
    hc = this.meshPlots.regionEdges;
    for i = 1:numel(hc)
      delete(hc{i});
    end
    this.meshPlots.regionEdges = [];
    if ~this.flags.patchEdge || isempty(this.tessellator.patchEdges)
      return;
    end
    np = this.tessellator.patchCount;
    he = zeros(np, 1);
    hc = cell(np, 1);
    for i = 1:np
      p = this.tessellator.patchEdges{i};
      isVisible = ~this.hiddenPatchFlag(i);
      he(i) = drawPatchEdges(p, 1, isVisible);
      face = this.mesh.elements(i).face;
      if ~face.isEmpty
        hfc = zeros(4, 1);
        c = face.nodes;
        sidx = 1;
        for k = 1:4
          eidx = sidx + this.tessellator.resolution;
          if ~c(k).isVirtual && c(k).multiplicity > 1
            cn = c(rem(k, 4) + 1);
            if ~cn.isVirtual && cn.multiplicity > 1
              hfc(k) = drawPatchEdges(p(sidx:eidx, :), ...
                this.creaseEdgeWidth, ...
                isVisible);
            end
          end
          sidx = eidx;
        end
        hc{i} = hfc(hfc > 0);
      end
    end
    this.meshPlots.edges = he;
    this.meshPlots.regionEdges = hc;

    function h = drawPatchEdges(p, width, isVisible)
      h = line('Parent', this.axes, ...
        'XData', p(:, 1), ...
        'YData', p(:, 2), ...
        'ZData', p(:, 3), ...
        'Color', this.patchEdgeColor, ...
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
    nn = this.mesh.nodeCount;
    p = zeros(nn, 3);
    nlp = 0;
    for i = 1:nn
      lp = this.mesh.nodes(i).loadPoint;
      if isempty(lp)
        break;
      end
      p(i, :) = lp.position;
      nlp = nlp + 1;
    end
    if nlp ~= nn
      fprintf('Missing load point(s)\n');
      this.flags.loadPoint = false;
    else
      s = this.nodeProperties.size;
      this.meshPlots.loadPoints = this.drawPoint(p, 'red', 'o', s);
    end
  end

  function renderVirtualPoints(this)
    delete(this.meshPlots.virtualPoints);
    this.meshPlots.virtualPoints = [];
    if ~this.flags.virtualPoint
      return;
    end
    p = this.virtualPoints.points;
    if isempty(p)
      fprintf('No virtual points\n');
      this.flags.virtualPoint = false;
      return;
    end
    s = this.nodeProperties.size;
    this.meshPlots.virtualPoints = this.drawPoint(p, 'yellow', 'o', s);
  end

  function renderVectors(this, eids)
    delete(this.meshPlots.vectors);
    this.meshPlots.vectors = [];
    if ~this.flags.vector || isempty(this.vectorHandle)
      return;
    end
    if nargin < 2 || isempty(eids)
      eids = find(this.selectedElementFlag);
      if isempty(eids)
        eids = 1:this.mesh.elementCount;
      end
    end
    this.meshPlots.vectors = this.drawVectors(eids, this.vectorColor);
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
        @(~, ~) this.showColorBar(isempty(this.colorBar)))];
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
    e = uicontrol('Style', 'edit');
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
