classdef Kelvin3 < handle
% Kelvin3: 3D Kelvin fundamental solutions class
%
% Authors: M.A. Peres and P. Pagliosa
% Last revision: 12/08/2024
%
% Description
% ===========
% The class Kelvin3 defines a static method for computing the
% 3D Kelvin fundamental solutions.

%% Public static methods
methods (Static)
  function [U, T] = eval(r, dr, N, m)
    c = m.c1 / r;
    U(1,1) = c * (m.c2 + dr(1) * dr(1));
    U(2,2) = c * (m.c2 + dr(2) * dr(2));
    U(3,3) = c * (m.c2 + dr(3) * dr(3));
    U(1,2) = c * dr(1) * dr(2); 
    U(2,1) = U(1,2); 
    U(1,3) = c * dr(1) * dr(3);
    U(3,1) = U(1,3);
    U(2,3) = c * dr(2) * dr(3);
    U(3,2) = U(2,3);
    d = N * dr';
    c = -m.c3 / (r * r);
    T(1,1) = c * (m.c4 + 3 * dr(1) * dr(1)) * d;
    T(2,2) = c * (m.c4 + 3 * dr(2) * dr(2)) * d;
    T(3,3) = c * (m.c4 + 3 * dr(3) * dr(3)) * d;
    T(1,2) = c * (3 * dr(1) * dr(2) * d - m.c4 * (N(2) * dr(1) - N(1) * dr(2)));	
    T(2,1) = c * (3 * dr(1) * dr(2) * d - m.c4 * (N(1) * dr(2) - N(2) * dr(1)));
    T(1,3) = c * (3 * dr(1) * dr(3) * d - m.c4 * (N(3) * dr(1) - N(1) * dr(3)));
    T(3,1) = c * (3 * dr(1) * dr(3) * d - m.c4 * (N(1) * dr(3) - N(3) * dr(1)));
    T(2,3) = c * (3 * dr(2) * dr(3) * d - m.c4 * (N(3) * dr(2) - N(2) * dr(3)));
    T(3,2) = c * (3 * dr(2) * dr(3) * d - m.c4 * (N(2) * dr(3) - N(3) * dr(2)));
  end
end

end % Kelvin
