classdef BezierShapeFunction < ShapeFunction

properties (GetAccess = public)
  degree;
  C double;
end

methods (Access = public)
  function this = BezierShapeFunction(degree, C)
    assert(degree == 3 || degree == 4, 'Bad Bezier shape function degree');
    this.degree = degree;
    this.C = C;
    if degree == 3
      this.basis = @Bernstein.basis3x3;
      this.derivativeU = @Bernstein.derivativeU3x3;
      this.derivativeV = @Bernstein.derivativeV3x3;
    elseif degree == 4
      this.basis = @Bernstein.basis4x4;
      this.derivativeU = @Bernstein.derivativeU4x4;
      this.derivativeV = @Bernstein.derivativeV4x4;
    end
  end

  function N = eval(this, u, v)
    N = this.C * reshape(this.basis(u, v)', [], 1);
  end

  function [Du, Dv] = diff(this, u, v)
    Du = this.C * reshape(this.derivativeU(u, v)', [], 1);
    Dv = this.C * reshape(this.derivativeV(u, v)', [], 1);
  end
end

properties (Access = private)
  basis;
  derivativeU;
  derivativeV;
end

end % BezierShapeFunction
