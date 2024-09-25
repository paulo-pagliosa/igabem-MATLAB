classdef Load < BC
% Load: element load class
%
% Author: Paulo Pagliosa
% Last revision: 24/09/2024
%
% Description
% ===========
% An object of the class Load represents a load applied to an element
% of a BEA model. A load can be a uniformely distributed load,
% a pressure or a torque, among others.
% A detailed documentation is available in
%
% https://github.com/paulo-pagliosa/igabem-MATLAB
%
% See also: class Element, class MeshInterface

%% Public static methods
methods (Static)
  function this = New(id, element, evaluator, varargin)
  % Constructs a load
    narginchk(3, inf);
    assert(isa(element, 'Element'), 'Element expected');
    this = Load(element.mesh, id, element);
    [evaluator, dir] = Load.parseArgs(evaluator, varargin{:});
    this.setProps(3, evaluator, dir);
  end
end

%% Protected methods
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

methods (Access = {?Load, ?LoadGroup, ?Mesh})
  function this = Load(mesh, id, element)
  % Constructs a null load
    this = this@BC(mesh, id);
    if nargin > 2
      this.element = element;
      this.dofs = [1 2 3];
    end
  end
end

%% Protected static methods
methods (Static, Access = {?BC, ?BCGroup})
  function this = loadBase(ctor, s)
    this = BC.loadBase(ctor, s);
  end

  function f = torque(O, D, S)
  % Compute the force corresponding to a torque
  %
  % Input
  % =====
  % O: coordinates of the rotation axis' origin
  % D: coordinates of the rotation axis' direction
  % S: scale of the force
  %
  % Output
  % ======
  % f: function returning the force, F, corresponding to the torque
  % T=r^F=S*|r|*D, i.e., F=S*(D^r), where r=P-P', being P'=O+(p.D)D,
  % p=P-O, and P the coordinates of the application point of F
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

end % Load
