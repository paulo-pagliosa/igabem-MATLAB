classdef GaussPoints < handle
% GaussPoints: Gauss points cache class
%
% Author: Paulo Pagliosa
% Last revision: 12/08/2024
%
% Description
% ===========
% An object of the class GaussPoints holds a cache storing
% coordinates and weights of Gauss points.

%% Private properties
properties (Access = private)
  cache (:, 2) cell;
end

%% Public methods
methods
  function [x, w] = get(this, n)
    if size(this.cache, 1) <= n || numel(this.cache{n, 1}) == 0
      [x, w] = computeGaussPoints(n, -1, 1);
      this.cache{n, 1} = x;
      this.cache{n, 2} = w;
    else
      x = this.cache{n, 1};
      w = this.cache{n, 2};
    end
  end
end

end % GaussPoints
