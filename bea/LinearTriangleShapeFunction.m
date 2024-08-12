classdef LinearTriangleShapeFunction < ShapeFunction

methods
  function N = eval(~, u, v)
    % (u, v) in [-1,1]x[-1,1]
    u = (u + 1) / 2;
    v = (v + 1) / 2;
    N = [u, v, 1 - (u + v)];
  end

  function [Du, Dv] = diff(~, ~, ~)
    Du = [1, 0, -1];
    Dv = [0, 1, -1];
  end
end

end % LinearTriangleShapeFunction
