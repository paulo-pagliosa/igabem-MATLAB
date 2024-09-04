classdef LinearTriangleShapeFunction < ShapeFunction
% LinearTriangleShapeFunction: 3D linear triangle shape function class
%
% Author: Paulo Pagliosa
% Last revision: 04/09/2024

%% Public methods
methods
  function N = eval(~, u, v)
  % Evaluates the shape functions at (U,V)
    % (u, v) in [-1,1]x[-1,1]
    u = (u + 1) / 2;
    v = (v + 1) / 2;
    N = [u, v, 1 - (u + v)];
  end

  function [Du, Dv, N] = diff(this, u, v)
  % Evaluates the derivatives of the shape functions
    Du = [1, 0, -1];
    Dv = [0, 1, -1];
    if nargout > 2
      N = this.eval(u, v);
    end
  end
end

end % LinearTriangleShapeFunction
