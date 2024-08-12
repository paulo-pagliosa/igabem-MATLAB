classdef Mesh < handle

properties
  name = 'Unnammed';
end

properties (Dependent)
  outerShell;
end

properties (SetAccess = private)
  nodes (:, 1) Node = Node.empty;
  shells (:, 1) Shell = Shell.empty;
  elements (:, 1) Element = Element.empty;
  constraints (:, 1) ConstraintGroup = ConstraintGroup.empty;
  loads (:, 1) LoadGroup = LoadGroup.empty;
  nodeElements (:, 1) cell;
  triangular logical = false;
end

properties (Access = private)
  nextConstraintId = 1;
  nextLoadId = 1;
  warpingScale = 0;
  dirtyFlags = false(1, 3);
end

methods
  function b = empty(this)
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
    %f = @(h)~isempty(find(id == h.id, 1));
    %node = findobj(this.nodes, '-function', f);
    ids = this.nodeIds;
    n = numel(id);
    node = Node.empty(0, 1);
    for i = 1:n
      k = find(ids == id(i));
      if ~isempty(k)
        node(i) = this.nodes(k);
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
    this.elementCtor = this.findElementConstructor(className);
  end

  function element = makeElement(this, id, degree, nodeIds, varargin)
    if isempty(this.shells)
      this.shells = Shell(this, 1);
    end
    element = this.createElement(id, degree, nodeIds, varargin);
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
    %f = @(h)~isempty(find(id == h.id, 1));
    %element = findobj(this.elements, '-function', f);
    ids = this.elementIds;
    n = numel(id);
    element = Element.empty(0, 1);
    for i = 1:n
      k = find(ids == id(i));
      if ~isempty(k)
        element(i) = this.elements(k);
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
    c = ConstraintGroup(cid, element, dofs, evaluator, varargin{:});
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
    l = LoadGroup(lid, element, evaluator, varargin{:});
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
    if mesh == this
      return;
    end
    assert(isa(mesh, 'Mesh'), 'Mesh expected');
    assert(mesh.shellCount == 1, 'Unable to glue multiple shells');
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
      ids = element.nodeIds;
      element.nodes = meshNodes(ids);
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

methods (Static)
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

properties(Access = private)
  elementCtor
end

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

methods (Access = private)
  function element = createElement(this, id, degree, nodeIds, varargin)
    ctor = this.elementCtor;
    assert(~isempty(ctor), 'Unspecified element type');
    args = horzcat({this, id, degree, nodeIds}, varargin{:});
    element = feval(ctor.Name, args{:});
  end

  function setTriangular(this, flag)
    if numel(this.elements) == 0
      this.triangular = flag;
    else
      this.triangular = this.triangular && flag;
    end
  end
end

end % Mesh
