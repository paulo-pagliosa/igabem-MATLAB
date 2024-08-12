classdef LoadGroup < BCGroup

methods
  function this = LoadGroup(id, elements, evaluator, varargin)
    narginchk(3, inf);
    this = this@BCGroup(id, elements);
    [evaluator, dir] = Load.parseArgs(evaluator, varargin{:});
    id = id * 1000;
    ne = numel(elements);
    this.bcs = Load.empty(0, ne);
    for i = 1:ne
      id = id + 1;
      lg = Load(id, elements(i));
      lg.setProps(3, evaluator, dir);
      if isnumeric(lg.evaluator)
        lg.direction = lg.evaluator;
        lg.evaluator = BCFunction.constant(1);
      end
      this.bcs(i) = lg;
    end
  end
end

properties (Access = private)
  regions;
  t;
end

methods (Access = protected)
  function setValues(this, nodes, regions, t)
    m = numel(nodes);
    for i = 1:m
      node = nodes(i);
      region = regions(i);
      temp = node.t(region, :);
      node.t(region, :) = temp + t(i, :); % TODO
    end
    this.regions = regions;
    this.t = t;
  end
end

methods (Access = {?LoadGroup, ?Mesh})
  function unload(this)
    nodes = this.elements.nodeSet;
    m = numel(nodes);
    for i = 1:m
      node = nodes(i);
      region = this.regions(i);
      temp = node.t(region, :);
      node.t(region, :) = temp - this.t(i, :); % TODO
    end
  end
end

end % LoadGroup
