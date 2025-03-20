classdef Mesh < handle
% Mesh: BEA model class
%
% Authors: Paulo Pagliosa
% Last revision: 19/03/2025
%
% Description
% ===========
% An object of the class Mesh represents a BEA model. The properties
% of a mesh are the set of mesh nodes, elements, constraints, loads,
% and node elements (the set of elements influenced by each mesh node).
% A detailed documentation is available in
%
% https://github.com/paulo-pagliosa/igabem-MATLAB
%
% See also: Node, Element, Constraint, Load

%% Public properties
properties
  name = 'Unnammed';
end

properties (Dependent)
  outerShell;
end

%% Public read-only properties
properties (SetAccess = private)
  nodes (:, 1) Node = Node.empty;
  shells (:, 1) Shell = Shell.empty;
  elements (:, 1) Element = Element.empty;
  constraints (:, 1) ConstraintGroup = ConstraintGroup.empty;
  loads (:, 1) LoadGroup = LoadGroup.empty;
  nodeElements (:, 1) cell;
  triangular logical = false;
end

%% Private properties
properties (Access = private)
  nextConstraintId = 1;
  nextLoadId = 1;
  warpingScale = 0;
  dirtyFlags = false(1, 3);
  elementCtor;
end

%% Public methods
methods
  function s = saveobj(this)
    % Save mesh name
    s.name = this.name;
    % Save plain node properties
    s.nodes = this.nodes;
    % Save plain mesh shell properties
    s.shells = this.shells;
    % Save plain element properties
    s.elements = this.elements;
    n = numel(s.elements);
    s.elementFaces = zeros(n, 4);
    s.elementShells = zeros(n, 1);
    s.elementNodes = cell(n, 1);
    for i = 1:n
      element = this.elements(i);
      s.elementShells(i) = element.shell.id;
      s.elementNodes{i} = [element.nodes.id];
      face = element.face;
      if ~face.isEmpty
        for k = 1:4
          s.elementFaces(i, k) = face.nodes(k).id;
        end
      end
    end
    % Save plain load point properties
    n = numel(s.nodes);
    s.loadPoints = LoadPoint.empty(0, n);
    s.loadPointElements = cell(n, 1);
    for i = 1:n
      lp = s.nodes(i).loadPoint;
      if isempty(lp)
        break;
      end
      s.loadPoints(i) = lp;
      s.loadPointElements{i} = [lp.elements.id];
    end
    % Save plain constraint properties
    s.constraints = this.constraints;
    n = numel(s.constraints);
    s.constraintElements = cell(n, 1);
    for i = 1:n
      bces = [s.constraints(i).bcs.element];
      s.constraintElements{i} = [bces.id];
    end
    % Save plain load properties
    s.loads = this.loads;
    n = numel(s.loads);
    s.loadElements = cell(n, 1);
    for i = 1:n
      bces = [s.loads(i).bcs.element];
      s.loadElements{i} = [bces.id];
    end
    % Save other mesh properties
    s.nodeElements = this.nodeElements;
    s.triangular = this.triangular;
    s.nextConstraintId = this.nextConstraintId;
    s.nextLoadId = this.nextLoadId;
    s.warpingScale = this.warpingScale;
    s.dirtyFlags = this.dirtyFlags;
    s.elementCtor = this.elementCtor;
  end

  function b = isEmpty(this)
    b = isempty(this.nodes) || isempty(this.elements);
  end

  function n = shellCount(this)
    n = numel(this.shells);
  end

  function os = get.outerShell(this)
    os = this.shells(1);
  end

  function node = makeNode(this, id, position)
    node = Node(this, id, position);
    this.nodes(end + 1, 1) = node;
    this.dirtyFlags(1) = true;
  end

  function n = nodeCount(this)
    n = numel(this.nodes);
  end

  function ids = nodeIds(this)
    ids = vertcat(this.nodes.id);
  end

  function p = nodePositions(this)
    p = vertcat(this.nodes.position);
  end

  function node = findNode(this, id)
    node = Node.empty(0, 1);
    nids = this.nodeIds;
    n = 0;
    for i = 1:numel(id)
      k = find(nids == id(i));
      if ~isempty(k)
        n = n + 1;
        node(n) = this.nodes(k);
      end
    end
  end

  function [nodes, dists] = findNearestNode(this, point)
    [np, dim] = size(point);
    assert(dim == 4, '4D point expected');
    nodes = Node.empty(np, 0);
    dists = inf(np, 1);
    n = this.nodeCount;
    if n == 0
      return;
    end
    p = this.nodePositions;
    for i = 1:np
      d = zeros(n, 1);
      for k = 1:dim
        d = d + (p(:, k) - point(i, k)) .^ 2;
      end
      [d, k] = min(d);
      dists(i) = sqrt(d);
      nodes(i) = this.nodes(k);
    end
  end

  function move(this, t)
    this.nodes.move(t);
  end

  function setNodeResults(this, id, u, t)
    assert(id > 0 && id <= this.nodeCount);
    node = this.nodes(id);
    assert(size(node.t, 1) == size(t, 1));
    node.u = u;
    node.t = t;
  end

  function setElementType(this, className)
    this.elementCtor = Element.findConstructor(className);
  end

  function element = makeElement(this, id, nodeIds, varargin)
    assert(~isempty(this.elementCtor), 'Unspecified element type');
    if isempty(this.shells)
      this.shells = Shell(this, 1);
    end
    element = Element.create(this.elementCtor, this, id, varargin);
    nn = this.setElementNodes(element, nodeIds);
    element.nodeRegions = ones(nn, 1);
    element.shell = this.outerShell;
    this.setTriangular(isa(element, 'LinearTriangle'));
    this.elements(end + 1, 1) = element;
    this.dirtyFlags(2) = true;
  end

  function n = elementCount(this)
    n = numel(this.elements);
  end

  function ids = elementIds(this)
    ids = vertcat(this.elements.id);
  end

  function element = findElement(this, id)
    element = Element.empty(0, 1);
    eids = this.elementIds;
    n = 0;
    for i = 1:numel(id)
      k = find(eids == id(i));
      if ~isempty(k)
        n = n + 1;
        element(n) = this.elements(k);
      end
    end
  end

  function computeNodeElements(this)
    this.nodeElements = cell(this.nodeCount, 1);
    meshNodeIds = this.nodeIds;
    n = this.elementCount;
    for i = 1:n
      element = this.elements(i);
      ids = element.nodeIds;
      index = find(ismember(meshNodeIds, ids))';
      for k = index
        this.nodeElements{k}(1, end + 1) = i;
      end
    end
  end

  function zeroTractions(this)
    n = this.nodeCount;
    for i = 1:n
      node = this.nodes(i);
      node.t = zeros(node.multiplicity, 3);
    end
  end

  function [c, u] = makeConstraint(this, element, dofs, evaluator, varargin)
    if isnumeric(element)
      element = this.elements(element);
    end
    cid = this.nextConstraintId;
    c = ConstraintGroup.New(cid, element, dofs, evaluator, varargin{:});
    u = c.apply;
    this.constraints(end + 1, 1) = c;
    this.nextConstraintId = cid + 1;
  end

  function b = deleteConstraint(this, constraint)
    if ~isa(constraint, 'ConstraintGroup')
      error('Constraint group expected');
    end
    b = false;
    if ~(constraint.mesh == this)
      return;
    end
    ids = vertcat(this.constraints.id);
    idx = find(ids == constraint.id);
    if isempty(idx)
      return;
    end
    Constraint.release(constraint.elements.nodeSet, constraint.dofs);
    this.constraints(idx) = [];
    b = true;
  end

  function b = deleteAllConstraints(this)
    if isempty(this.constraints)
      b = false;
      return;
    end
    m = this.nodeCount;
    for i = 1:m
      node = this.nodes(i);
      node.dofs = [0 0; 0 0; 0 0];
      node.u = [0 0 0];
    end
    this.constraints = ConstraintGroup.empty;
    b = true;
  end

  function [l, t] = makeLoad(this, element, evaluator, varargin)
    if isnumeric(element)
      element = this.elements(element);
    end
    lid = this.nextLoadId;
    l = LoadGroup.New(lid, element, evaluator, varargin{:});
    t = l.apply;
    this.loads(end + 1, 1) = l;
    this.nextLoadId = lid + 1;
  end

  function b = deleteLoad(this, load)
    if ~isa(load, 'LoadGroup')
      error('Load group expected');
    end
    b = false;
    if ~(load.mesh == this)
      return;
    end
    ids = vertcat(this.loads.id);
    idx = find(ids == load.id);
    if isempty(idx)
      return;
    end
    load.unload;
    this.loads(idx) = [];
    b = true;
  end

  function b = deleteAllLoads(this)
    if isempty(this.loads)
      b = false;
      return;
    end
    m = this.nodeCount;
    for i = 1:m
      node = this.nodes(i);
      node.t = zeros(size(node.t));
    end
    this.loads = LoadGroup.empty;
    b = true;
  end

  function renumerateNodes(this)
    if ~this.dirtyFlags(1)
      return;
    end
    n = this.nodeCount;
    for i = 1:n
      this.nodes(i).id = i;
    end
    this.dirtyFlags(1) = false;
  end

  function renumerateElements(this)
    if ~this.dirtyFlags(2)
      return;
    end
    n = this.elementCount;
    for i = 1:n
      this.elements(i).id = i;
    end
    this.dirtyFlags(2) = false;
  end

  function renumerateShells(this)
    if ~this.dirtyFlags(3)
      return;
    end
    n = this.shellCount;
    for i = 1:n
      this.shells(i).id = i;
    end
    this.dirtyFlags(3) = false;
  end

  function renumerateAll(this)
    this.renumerateNodes;
    this.renumerateElements;
    this.renumerateShells;
  end

  function lp = makeLoadPoint(this, nodeId, elementId, localPosition)
    node = this.findNode(nodeId);
    assert(~isempty(node), 'Node % not found', nodeId);
    element = this.findElement(elementId);
    assert(numel(element) == size(localPosition, 1), 'Bad load point');
    lp = LoadPoint(element, localPosition);
    node.loadPoint = lp;
  end

  function this = addComponent(this, mesh)
    assert(isa(mesh, 'Mesh'), 'Mesh expected');
    if mesh == this
      return;
    end
    this.nodes = [this.nodes; mesh.nodes];
    this.setTriangular(mesh.triangular);
    this.elements = [this.elements; mesh.elements];
    this.shells = [this.shells; mesh.shells];
    [mesh.nodes(:).mesh] = deal(this);
    [mesh.elements(:).mesh] = deal(this);
    [mesh.shells(:).mesh] = deal(this);
    mesh.nodes = Node.empty;
    mesh.elements = Element.empty;
    mesh.shells = Shell.empty;
    mesh.nodeElements = {};
    this.nodeElements = {};
    this.dirtyFlags(:) = true;
    this.renumerateAll;
    this.zeroTractions;
  end

  function this = glue(this, mesh, eps)
    assert(isa(mesh, 'Mesh'), 'Mesh expected');
    if mesh == this
      return;
    end
    if this.shellCount > 1 || mesh.shellCount > 1
      fprintf('Unable to glue multiple shells');
      return;
    end
    n = mesh.elementCount;
    if n == 0
      fprintf('No elements to glue\n');
      return;
    end
    if nargin < 3
      eps = 1e-6;
    end
    mesh.renumerateNodes;
    meshNodes = mesh.nodes;
    [nearestNodes, d] = this.findNearestNode(mesh.nodePositions);
    glueCondition = d < eps;
    glueNodes = nearestNodes(glueCondition);
    meshNodes(glueCondition) = glueNodes;
    m = [glueNodes(:).multiplicity];
    m = num2cell(m + 1);
    [glueNodes(:).multiplicity] = deal(m{:});
    for i = 1:n
      element = mesh.elements(i);
      element.mesh = this;
      element.nodes = meshNodes(element.nodeIds);
      element.nodeRegions = [element.nodes(:).multiplicity];
      element.shell = this.shells(1);
    end
    meshNodes = meshNodes(~glueCondition);
    if ~isempty(meshNodes)
      this.nodes = [this.nodes; meshNodes];
      [meshNodes(:).mesh] = deal(this);
    end
    mesh.nodes = Node.empty;
    this.setTriangular(mesh.triangular);
    this.elements = [this.elements; mesh.elements];
    mesh.elements = Element.empty;
    mesh.shells = Shell.empty;
    mesh.nodeElements = {};
    this.nodeElements = {};
    this.dirtyFlags(:) = true;
    this.renumerateAll;
    this.zeroTractions;
  end

  function b = deform(this, warpingScale)
    if warpingScale < 0 || warpingScale == this.warpingScale
      b = false;
      return;
    end
    scale = warpingScale - this.warpingScale;
    this.warpingScale = warpingScale;
    u = vertcat(this.nodes.u) .* scale;
    this.nodes.move(u);
    b = true;
  end
end

%% Public static methods
methods (Static)
  function this = loadobj(s)
    % Load plain mesh data
    this = Mesh;
    % Restore mesh name
    this.name = s.name;
    % Restore nodes
    [s.nodes.mesh] = deal(this);
    this.nodes = s.nodes;
    % Restore mesh shells
    [s.shells.mesh] = deal(this);
    this.shells = s.shells;
    % Restore elements
    n = numel(s.elements);
    for i = 1:n
      element = s.elements(i);
      element.shell = s.shells(s.elementShells(i));
      element.nodes = s.nodes(s.elementNodes{i});
      face = Face; % create a new face
      for k = 1:4
        nid = s.elementFaces(i, k);
        if nid > 0
          face.nodes(k) = s.nodes(nid);
        else
          face.nodes(k) = Node.virtual;
        end
      end
      element.face = face;
      element.mesh = this;
    end
    this.elements = s.elements;
    % Restore load points
    if ~isempty(s.loadPoints)
      n = numel(s.nodes);
      for i = 1:n
        lp = s.loadPoints(i);
        lp.elements = s.elements(s.loadPointElements{i});
        s.nodes(i).loadPoint = lp;
      end
    end
    % Restore constraints
    [s.constraints.mesh] = deal(this);
    n = numel(s.constraints);
    for i = 1:n
      restoreBCs(s.constraints, i, s.constraintElements{i});
    end
    this.constraints = s.constraints;
    % Restore loads
    [s.loads.mesh] = deal(this);
    n = numel(s.loads);
    for i = 1:n
      restoreBCs(s.loads, i, s.loadElements{i});
    end
    this.loads = s.loads;
    % Restore other mesh properties
    this.nodeElements = s.nodeElements;
    this.triangular = s.triangular;
    this.nextConstraintId = s.nextConstraintId;
    this.nextLoadId = s.nextLoadId;
    this.warpingScale = s.warpingScale;
    this.dirtyFlags = s.dirtyFlags;
    this.elementCtor = s.elementCtor;

    function restoreBCs(bcGroup, bcid, eids)
      bcElements = this.elements(eids);
      bcGroup(bcid).elements = unique(bcElements, 'stable');
      bcs = bcGroup(bcid).bcs;
      for b = 1:numel(bcs)
        bcs(b).mesh = this;
        bcs(b).element = bcElements(b);
      end
    end
  end

  function setNodeRegions(element, nodeRegions)
    n = numel(nodeRegions);
    assert(n == element.nodeCount, 'Bad node region size');
    nodeRegions = int32(nodeRegions');
    element.nodeRegions = nodeRegions;
    m = [element.nodes(:).multiplicity];
    m = num2cell(max(m, nodeRegions));
    [element.nodes(:).multiplicity] = deal(m{:});
  end
end

%% Private methods
methods (Access = private)
  function nn = setElementNodes(this, element, nodeIds)
    element.nodes = this.findNode(nodeIds);
    nn = numel(element.nodes);
    if nn ~= numel(nodeIds)
      error('Undefined node(s) in element %d', element.id);
    end
    element.checkNodes;
  end

  function setTriangular(this, flag)
    if numel(this.elements) == 0
      this.triangular = flag;
    else
      this.triangular = this.triangular && flag;
    end
  end
end

%% Private static methods
methods (Static, Access = private)
  function ctor = findElementConstructor(className)
    c = meta.class.fromName(className);
    assert(~isempty(c), 'Unable to find class %s', className);
    s = findobj(c.SuperclassList, 'Name', 'Element');
    assert(~isempty(s), '%s is not derived from Element', className);
    ctor = findobj(c.MethodList, 'Name', className, 'Access', 'public');
    assert(~isempty(ctor), 'No public constructor in class %s', className);
  end
end

end % Mesh
