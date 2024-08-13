classdef LinearTriangleShapeFunction < ShapeFunction
% LinearTriangleShapeFunction: 3D linear triangle shape function class
%
% Author: Paulo Pagliosa
% Last revision: 12/08/2024

%% Public methods
methods
  % Evaluates the shape functions at (U,V)
  function N = eval(~, u, v)
    % (u, v) in [-1,1]x[-1,1]
    u = (u + 1) / 2;
    v = (v + 1) / 2;
    N = [u, v, 1 - (u + v)];
  end

  % Evaluates the derivatives of the shape functions
  function [Du, Dv] = diff(~, ~, ~)
    Du = [1, 0, -1];
    Dv = [0, 1, -1];
  end
end

end % LinearTriangleShapeFunction
