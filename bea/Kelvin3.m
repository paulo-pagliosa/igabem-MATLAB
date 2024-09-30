classdef Kelvin3 < handle
% Kelvin3: 3D Kelvin fundamental solutions class
%
% Authors: M.A. Peres and P. Pagliosa
% Last revision: 30/09/2024
%
% Description
% ===========
% The class Kelvin3 defines a static method for computing the 3D Kelvin
% fundamental solutions for displacements, tractions, and stresses.

%% Public static methods
methods (Static)
  function [U, T] = computeUT(p, q, N, m)
    % Computes the fundamental solutions U and T
    %
    % Input
    % =====
    % P: 1x3 array with the coordinates of the source point 
    % Q: 1x3 array with the coordinates of the target point 
    % N: 1x3 array with the corrdinates of the normal at the target point
    % M: material at the target point
    %
    % Output
    % ======
    % U: 3x3 array with the components of the tensor U
    % T: 3x3 array with the components of the tensor T
    r = q - p;
    invr = 1 / norm(r);
    r = r * invr;
    c = m.c1 * invr;
    U(1, 1) = c * (m.c2 + r(1) * r(1));
    U(2, 2) = c * (m.c2 + r(2) * r(2));
    U(3, 3) = c * (m.c2 + r(3) * r(3));
    U(1, 2) = c * r(1) * r(2); 
    U(2, 1) = U(1,2); 
    U(1, 3) = c * r(1) * r(3);
    U(3, 1) = U(1,3);
    U(2, 3) = c * r(2) * r(3);
    U(3, 2) = U(2,3);
    rN = r * N';
    c = -m.c3 * invr ^ 2;
    T(1, 1) = c * (m.c4 + 3 * r(1) * r(1)) * rN;
    T(2, 2) = c * (m.c4 + 3 * r(2) * r(2)) * rN;
    T(3, 3) = c * (m.c4 + 3 * r(3) * r(3)) * rN;
    T(1, 2) = c * (3 * r(1) * r(2) * rN - m.c4 * (N(2) * r(1) - N(1) * r(2)));	
    T(2, 1) = c * (3 * r(1) * r(2) * rN - m.c4 * (N(1) * r(2) - N(2) * r(1)));
    T(1, 3) = c * (3 * r(1) * r(3) * rN - m.c4 * (N(3) * r(1) - N(1) * r(3)));
    T(3, 1) = c * (3 * r(1) * r(3) * rN - m.c4 * (N(1) * r(3) - N(3) * r(1)));
    T(2, 3) = c * (3 * r(2) * r(3) * rN - m.c4 * (N(3) * r(2) - N(2) * r(3)));
    T(3, 2) = c * (3 * r(2) * r(3) * rN - m.c4 * (N(2) * r(3) - N(3) * r(2)));
  end
end

end % Kelvin3
