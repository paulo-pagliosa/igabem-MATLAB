classdef Load < BC

methods (Static)
  function l = New(id, element, evaluator, varargin)
    narginchk(3, inf);
    l = Load(id, element);
    [evaluator, dir] = Load.parseArgs(evaluator, varargin{:});
    l.setProps(3, evaluator, dir);
  end
end

methods (Static, Access = {?BC, ?BCGroup})
  function f = torque(O, D, S)
    % O coordinates of the rotation axis' origin
    % D coordinates of the rotation axis' direction
    % S scale of the force
    % f function returning the force, F, corresponding
    %   to the torque T=r^F=S*|r|*D, i.e., F=S*(D^r),
    %   where r=P-P', being P'=O+(p.D)D, p=P-O, and P
    %   the coordinates of the application point of F.
    D = D ./ norm(D);
    f = @force;

    function F = force(~, ~, P)
      p = P - O;
      r = p - dot(p, D) * D;
      F = S * cross(D, r);
    end
  end

  function [evaluator, dir] = parseArgs(evaluator, varargin)
    if ischar(evaluator)
      switch evaluator
        case 'pressure'
          narginchk(2, 2);
          p = varargin{1};
          assert(isscalar(p), 'Bad pressure value');
          [evaluator, dir] = BC.parseArgs(p, 'direction', 'normal');
        case 'torque'
          narginchk(4, 4);
          O = varargin{1};
          D = varargin{2};
          S = varargin{3};
          assert(numel(O) == 3, 'Bad axis origin');
          assert(numel(D) == 3, 'Bad axis direction');
          assert(isscalar(S), 'Bad torque scale');
          evaluator = Load.torque(O, D, S);
          dir = [1 1 1];
      end
    else
      [evaluator, dir] = BC.parseArgs(evaluator, varargin{:});
    end
  end
end

methods
  function this = Load(id, element)
    this = this@BC(id, element);
    this.dofs = [1 2 3];
    this.direction = [];
  end
end

methods (Access = protected)
  function setValues(this, t)
    regions = this.element.nodeRegions;
    m = this.element.nodeCount;
    for i = 1:m
      node = this.element.nodes(i);
      node.t(regions(i), :) = t(i, :); % TODO
    end
  end
end

end % Load
