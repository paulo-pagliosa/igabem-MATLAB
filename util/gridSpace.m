function p = gridSpace(n, range)
% Generates a regular grid of NxN 2D points
%
% Author: Paulo Pagliosa
% Last revision: 12/08/2024
%
% Input
% =====
% N: number of subdivisions
% RANGE: 2x1 matrix with the domain to be divided (in both dimensions)
%
% Output
% ======
% P: (NxN)x2 matrix with the 2D point grids
  if nargin == 1
    range = [-1 1];
  end
  p = zeros(n * n, 2);
  s = linspace(range(1), range(2), n);
  k = 1;
  for j = 1:n
    for i = 1:n
      p(k, :) = [s(i) s(j)];
      k = k + 1;
    end
  end
end
