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
    U = zeros(3, 3);
    T = zeros(3, 3);
    r = q - p;
    invr = 1 / norm(r);
    r = r * invr;
    r11 = r(1) ^ 2;
    r12 = r(1) * r(2);
    r13 = r(1) * r(3);
    r22 = r(2) ^ 2;
    r23 = r(2) * r(3);
    r33 = r(3) ^ 2;
    c = m.c1 * invr;
    U(1, 1) = c * (m.c2 + r11);
    U(1, 2) = c * r12;
    U(1, 3) = c * r13;
    U(2, 1) = U(1, 2); 
    U(2, 2) = c * (m.c2 + r22);
    U(2, 3) = c * r23;
    U(3, 1) = U(1, 3);
    U(3, 2) = U(2, 3);
    U(3, 3) = c * (m.c2 + r33);
    rN = r * N';
    c = -m.c3 * invr ^ 2;
    T(1, 1) = c * (3 * r11 + m.c4) * rN;
    T(1, 2) = c * (3 * r12 * rN + m.c4 * (N(1) * r(2) - N(2) * r(1)));	
    T(1, 3) = c * (3 * r13 * rN + m.c4 * (N(1) * r(3) - N(3) * r(1)));
    T(2, 1) = c * (3 * r12 * rN + m.c4 * (N(2) * r(1) - N(1) * r(2)));
    T(2, 2) = c * (3 * r22 + m.c4) * rN;
    T(2, 3) = c * (3 * r23 * rN + m.c4 * (N(2) * r(3) - N(3) * r(2)));
    T(3, 1) = c * (3 * r13 * rN + m.c4 * (N(3) * r(1) - N(1) * r(3)));
    T(3, 2) = c * (3 * r23 * rN + m.c4 * (N(3) * r(2) - N(2) * r(3)));
    T(3, 3) = c * (3 * r33 + m.c4) * rN;
  end

  function [D, S] = computeDS(p, q, N, m)
    % Computes the fundamental solutions D and S
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
    % D: 3x3x3 array with the components of the tensor D
    % S: 3x33x array with the components of the tensor S
    D = zeros(3, 3, 3);
    S = zeros(3, 3, 3);
    r = q - p;
    invr = 1 / norm(r);
    r = r * invr;
    r11 = r(1) ^ 2;
    r12 = r(1) * r(2);
    r13 = r(1) * r(3);
    r22 = r(2) ^ 2;
    r23 = r(2) * r(3);
    r33 = r(3) ^ 2;
    c = m.c3 * invr ^ 2;
    D(1, 1, 1) = c * r(1) * (3 * r11 + m.c4);
    D(1, 2, 1) = c * r(2) * (3 * r11 + m.c4);
    D(1, 3, 1) = c * r(3) * (3 * r11 + m.c4);
    D(2, 1, 1) = D(1, 2, 1);
    D(2, 2, 1) = c * r(1) * (3 * r22 - m.c4);
    D(2, 3, 1) = c * (3 * r12 * r(3));
    D(3, 1, 1) = D(1, 3, 1);
    D(3, 2, 1) = D(2, 3, 1);
    D(3, 3, 1) = c * r(1) * (3 * r33 - m.c4);
    D(1, 1, 2) = c * r(2) * (3 * r11 - m.c4);
    D(1, 2, 2) = c * r(1) * (3 * r22 + m.c4);
    D(1, 3, 2) = D(2, 3, 1);
    D(2, 1, 2) = D(1, 2, 2);
    D(2, 2, 2) = c * r(2) * (3 * r22 + m.c4);
    D(2, 3, 2) = c * r(3) * (3 * r22 + m.c4);
    D(3, 1, 2) = D(1, 3, 2);
    D(3, 2, 2) = D(2, 3, 2);
    D(3, 3, 2) = c * r(2) * (3 * r33 - m.c4);
    D(1, 1, 3) = c * r(3) * (3 * r11 - m.c4);
    D(1, 2, 3) = D(2, 3, 1);
    D(1, 3, 3) = c * r(1) * (3 * r33 + m.c4);
    D(2, 1, 3) = D(1, 2, 3);
    D(2, 2, 3) = c * r(3) * (3 * r22 - m.c4);
    D(2, 3, 3) = c * r(2) * (3 * r33 + m.c4);
    D(3, 1, 3) = D(1, 3, 3);
    D(3, 2, 3) = D(2, 3, 3);
    D(3, 3, 3) = c * r(3) * (3 * r33 + m.c4);
    rN = r * N';
    c = m.c5 * invr ^ 3;
    S(1, 1, 1) = c * (m.c4 * (3 * N(1) * r11 + 2 * N(1)) - N(1) * m.c6 ...
      + 3 * rN * (m.c4 * r(1) + 2 * m.mu * r(1) - 5 * r(1) ^ 3) ...
      + 6 * N(1) * m.mu * r11);
    S(1, 2, 1) = c * (m.c4 * (N(2) + 3 * N(1) * r12) ...
      + 3 * rN * (m.mu * r(2) - 5 * r(2) * r11) ...
      + 3 * m.mu * (N(2) * r11 + N(1) * r(2) * r(1)));
    S(1, 3, 1) = c * (m.c4 * (N(3) + 3 * N(1) * r13) ...
      + 3 * rN * (m.mu * r(3) - 5 * r(3) * r11) ...
      + 3 * m.mu * (N(3) * r11 + N(1) * r(3) * r(1)));
    S(2, 1, 1) = S(1, 2, 1);
    S(2, 2, 1) = c * (3 * rN * (m.c4 * r(1) - 5 * r(1) * r22) - N(1) * m.c6 ...
      + 3 * N(1) * m.c4 * r22 + 6 * N(2) * m.mu * r12);
    S(2, 3, 1) = c * (3 * m.mu * (N(2) * r13 + N(3) * r12) ...
      - 15 * r12 * r(3) * rN + 3 * N(1) * m.c4 * r23);
    S(3, 1, 1) = S(1, 3, 1);
    S(3, 2, 1) = S(2, 3, 1);
    S(3, 3, 1) = c * (3 * rN * (m.c4 * r(1) - 5 * r(1) * r33) - N(1) * m.c6 ...
      + 3 * N(1) * m.c4 * r33 + 6 * N(3) * m.mu * r13);
    S(1, 1, 2) = c * (3 * rN * (m.c4 * r(2) - 5 * r(2) * r11) - N(2) * m.c6 ...
      + 3 * N(2) * m.c4 * r11 + 6 * N(1) * m.mu * r12);
    S(1, 2, 2) = c * (m.c4 * (N(1) + 3 * N(2) * r12) ...
      + 3 * rN * (m.mu * r(1) - 5 * r(1) * r22) ...
      + 3 * m.mu * (N(1) * r22 + N(2) * r12));
    S(1, 3, 2) = c * (3 * m.mu * (N(1) * r23 + N(3) * r12) ...
      - 15 * r12 * r(3) * rN + 3 * N(2) * m.c4 * r13);
    S(2, 1, 2) = S(1, 2, 2);
    S(2, 2, 2) = c * (m.c4 * (3 * N(2) * r22 + 2 * N(2)) - N(2) * m.c6 ...
      + 3 * rN * (m.c4 * r(2) + 2 * m.mu * r(2) - 5 * r(2) ^ 3) ...
      + 6 * N(2) * m.mu * r22);
    S(2, 3, 2) = c * (m.c4 * (N(3) + 3 * N(2) * r23) ...
      + 3 * rN * (m.mu * r(3) - 5 * r(3) * r22) ...
      + 3 * m.mu * (N(3) * r22 + N(2) * r(3) * r(2)));
    S(3, 1, 2) = S(1, 3, 2);
    S(3, 2, 2) = S(2, 3, 2);
    S(3, 3, 2) = c * (3 * rN * (m.c4 * r(2) - 5 * r(2) * r33) - N(2) * m.c6 ...
      + 3 * N(2) * m.c4 * r33 + 6 * N(3) * m.mu * r23);
    S(1, 1, 3) = c * (3 * rN * (m.c4 * r(3) - 5 * r(3) * r11) - N(3) * m.c6 ...
      + 3 * N(3) * m.c4 * r11 + 6 * N(1) * m.mu * r13);
    S(1, 2, 3) = c * (3 * m.mu * (N(1) * r23 + N(2) * r13) ...
      - 15 * r12 * r(3) * rN + 3 * N(3) * m.c4 * r12);
    S(1, 3, 3) = c * (m.c4 * (N(1) + 3 * N(3) * r13) ...
      + 3 * rN * (m.mu * r(1) - 5 * r(1) * r33) ...
      + 3 * m.mu * (N(1) * r33 + N(3) * r13));
    S(2, 1, 3) = S(1, 2, 3);
    S(2, 2, 3) = c * (3 * rN * (m.c4 * r(3) - 5 * r(3) * r22) - N(3) * m.c6 ...
      + 3 * N(3) * m.c4 * r22 + 6 * N(2) * m.mu * r23);
    S(2, 3, 3) = c * (m.c4 * (N(2) + 3 * N(3) * r23) ...
      + 3 * rN * (m.mu * r(2) - 5 * r(2) * r33) ...
      + 3 * m.mu * (N(2) * r33 + N(3) * r23));
    S(3, 1, 3) = S(1, 3, 3);
    S(3, 2, 3) = S(2, 3, 3);
    S(3, 3, 3) = c * (m.c4 * (3 * N(3) * r33 + 2 * N(3)) - N(3) * m.c6 ...
      + 3 * rN * (m.c4 * r(3) + 2 * m.mu * r(3) - 5 * r(3) ^ 3) ...
      + 6 * N(3) * m.mu * r33);
  end
end

end % Kelvin3
