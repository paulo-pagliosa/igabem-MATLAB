classdef QuadRegion
% QuadRegion: quadrangular region class
%
% Authors: M> peres and P. Pagliosa
% Last revision: 12/08/2024
%
% Description
% ===========
% An object of the class QuadRegion represents a quadrangular (sub)region
% of the integration domain of an element, as described in Section 5
% of the paper.

%% Public properties
properties
  depth;
end

%% Public read-only properties
properties (SetAccess = private)
  o (1, 2) double; % origin
  s (1, 2) double; % size
end

%% Public methods
methods
  % Constructs a quad region
  function this = QuadRegion(o, s, depth)
    if nargin > 0
      this.o = o;
      this.s = s;
      this.depth = depth;
    end
  end

  % Computes the Jacobian of this quad region
  function J = jacobian(this)
    J = this.s(1) * this.s(2) * 0.25;
  end

  % Computes the domain coordinate u at CSI in [-1:1]
  function csi = u(this, csi)
    csi = this.o(1) + this.s(1) * (csi + 1) * 0.5;
  end

  % Computes the domain coordinate v at CSI in [-1:1]
  function csi = v(this, csi)
    csi = this.o(2) + this.s(2) * (csi + 1) * 0.5;
  end

  % Computes the center of this quad region
  function c = center(this)
    c = this.o + this.s * 0.5;
  end

  % Splits this quad region into 2 subregions along u
  function sr = splitU(this, csi)
    assert(csi >= 0 && csi <= 1);
    o1 = this.o;
    s2 = this.s;
    s2(1) = s2(1) * csi;
    d2 = this.depth + 1;
    sr = [QuadRegion(o1, s2, d2) QuadRegion([o1(1) + s2(1), o1(2)], s2, d2)];
  end

  % Splits this quad region into 2 subregions along v
  function sr = splitV(this, csi)
    assert(csi >= 0 && csi <= 1);
    o1 = this.o;
    s2 = this.s;
    s2(2) = s2(2) * csi;
    d2 = this.depth + 1;
    sr = [QuadRegion(o1, s2, d2) QuadRegion([o1(1), o1(2) + s2(2)], s2, d2)];
  end
end

%% Public static methods
methods (Static)
  function r = default
    r = QuadRegion([-1 -1], [2 2], 0);
  end
end

end % QuadRegion
