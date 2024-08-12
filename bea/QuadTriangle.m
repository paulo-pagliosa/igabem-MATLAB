classdef QuadTriangle

properties
  p1 (1, 2) double;
  p2 (1, 2) double;
  p3 (1, 2) double;
end

methods
  function this = QuadTriangle(p1, p2, p3)
    if nargin > 0
      this.p1 = p1;
      this.p2 = p2;
      this.p3 = p3;
    end
  end

  function p = positionAt(this, u, v)
    b1 = (1 + u) * (1 - v) * 0.25;
    b2 = (1 + u) * (1 + v) * 0.25;
    p = b1 * this.p1 + b2 * this.p2 + (1 - (b1 + b2)) * this.p3;
  end

  function J = jacobian(this, u, v)
    su = (1 - v) * this.p1 + (1 + v) * this.p2 - 2 * this.p3;
    sv = (1 + u) * this.p2 - (1 + u) * this.p1;
    J = (su(1) * sv(2) - su(2) * sv(1)) / 16;
  end
end

end % QuadTriangle
