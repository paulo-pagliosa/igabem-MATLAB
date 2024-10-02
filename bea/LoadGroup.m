classdef LoadGroup < BCGroup
% LoadGroup: region load class
%
% Author: Paulo Pagliosa
% Last revision: 01/10/2024
%
% Description
% ===========
% An object of the class LoadGroup represents a load applied to
% elements of an element region of a BEA model.
%
% See also: Load

%% Public methods
methods
  function s = saveobj(this)
    % Saves this load group object
    s = saveobj@BCGroup(this);
    s.regions = this.regions;
    s.t = this.t;
  end
end

%% Public static methods
methods (Static)
  function lg = New(id, elements, evaluator, varargin)
  % Constructs a load group
    narginchk(3, inf);
    assert(isa(elements, 'Element'), 'Element expected');
    [evaluator, dir] = Load.parseArgs(evaluator, varargin{:});
    lid = id * 1000;
    n = numel(elements);
    bcs = Load.empty(0, n);
    for i = 1:n
      lid = lid + 1;
      bc = Load(elements(i).mesh, lid, elements(i));
      bc.setProps(3, evaluator, dir);
      if isnumeric(bc.evaluator)
        bc.direction = bc.evaluator;
        bc.evaluator = BCFunction.constant(1);
      end
      bcs(i) = bc;
    end
    lg = LoadGroup(elements(1).mesh, id, bcs);
  end

  function this = loadobj(s)
  % Loads a load group
    this = BCGroup.loadBase(@LoadGroup, s);
    this.regions = s.regions;
    this.t = s.t;
  end
end

%% Private properties
properties (Access = private)
  regions;
  t;
end

%% Protected methods
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
