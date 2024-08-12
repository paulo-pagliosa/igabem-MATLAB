classdef QuadRegion

properties
  depth;
end

properties (SetAccess = private)
  o (1, 2) double; % origin
  s (1, 2) double; % size
end

methods
  function this = QuadRegion(o, s, depth)
    if nargin > 0
      this.o = o;
      this.s = s;
      this.depth = depth;
    end
  end

  function J = jacobian(this)
    J = this.s(1) * this.s(2) * 0.25;
  end

  function csi = u(this, csi)
    csi = this.o(1) + this.s(1) * (csi + 1) * 0.5;
  end

  function csi = v(this, csi)
    csi = this.o(2) + this.s(2) * (csi + 1) * 0.5;
  end

  function c = center(this)
    c = this.o + this.s * 0.5;
  end

  % Split this region into 2 subregions along u
  function sr = splitU(this, csi)
    assert(csi >= 0 && csi <= 1);
    o1 = this.o;
    s2 = this.s;
    s2(1) = s2(1) * csi;
    d2 = this.depth + 1;
    sr = [QuadRegion(o1, s2, d2) QuadRegion([o1(1) + s2(1), o1(2)], s2, d2)];
  end

  % Split this region into 2 subregions along v
  function sr = splitV(this, csi)
    assert(csi >= 0 && csi <= 1);
    o1 = this.o;
    s2 = this.s;
    s2(2) = s2(2) * csi;
    d2 = this.depth + 1;
    sr = [QuadRegion(o1, s2, d2) QuadRegion([o1(1), o1(2) + s2(2)], s2, d2)];
  end
end

methods (Static)
  function r = default
    r = QuadRegion([-1 -1], [2 2], 0);
  end
end

end % QuadRegion
