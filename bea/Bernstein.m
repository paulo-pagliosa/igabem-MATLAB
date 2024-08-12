classdef Bernstein
% Bernstein: Bernstein function basis class
%
% Authors: M.A. Peres and P. Pagliosa
% Last revision: 12/08/2024
%
% Description
% ===========
% The class Bernstein defines static methods for computing the
% Bernsteing basis functions of degrees 3 and 4 and their derivatives.

%% Public static methods
methods (Static)
  function b = basis2(u)
    b(3) = 0.25 * (1 + u) * (1 + u);
    b(2) = 0.50 * (1 - u) * (1 + u);
    b(1) = 0.25 * (1 - u) * (1 - u);
  end

  function b = basis3(u)
    b(4) = 0.125 * (1 + u) * (1 + u) * (1 + u);
    b(3) = 0.375 * (1 - u) * (1 + u) * (1 + u);
    b(2) = 0.375 * (1 - u) * (1 - u) * (1 + u);
    b(1) = 0.125 * (1 - u) * (1 - u) * (1 - u);
  end

  function b = basis4(u)
    b(5) = 0.0625 * (1 + u) * (1 + u) * (1 + u) * (1 + u);
    b(4) = 0.250  * (1 - u) * (1 + u) * (1 + u) * (1 + u);
    b(3) = 0.375  * (1 - u) * (1 - u) * (1 + u) * (1 + u);
    b(2) = 0.250  * (1 - u) * (1 - u) * (1 - u) * (1 + u);
    b(1) = 0.0625 * (1 - u) * (1 - u) * (1 - u) * (1 - u);
  end

  function b = basis2x2(u, v)
    b = kron(Bernstein.basis2(u), Bernstein.basis2(v)');
  end

  function b = basis3x3(u, v)
    b = kron(Bernstein.basis3(u), Bernstein.basis3(v)');
  end

  function b = basis4x4(u, v)
    b = kron(Bernstein.basis4(u), Bernstein.basis4(v)');
  end

  function d = derivative3(u)
    b = 3 * Bernstein.basis2(u);
    d(4) = +b(3);
    d(3) = +b(2) - b(3);
    d(2) = +b(1) - b(2);
    d(1) = -b(1);
  end

  function d = derivativeU3x3(u, v)
    d = kron(Bernstein.derivative3(u), Bernstein.basis3(v)');
  end

  function d = derivativeV3x3(u, v)
    d = kron(Bernstein.basis3(u), Bernstein.derivative3(v)');
  end

  function d = derivative4(u)
    b = 3 * Bernstein.basis3(u);
    d(5) = +b(4);
    d(4) = +b(3) - b(4);
    d(3) = +b(2) - b(3);
    d(2) = +b(1) - b(2);
    d(1) = -b(1);
  end

  function d = derivativeU4x4(u, v)
    d = kron(Bernstein.derivative4(u), Bernstein.basis4(v)');
  end

  function d = derivativeV4x4(u, v)
    d = kron(Bernstein.basis4(u), Bernstein.derivative4(v)');
  end
end

end % Bernstein
