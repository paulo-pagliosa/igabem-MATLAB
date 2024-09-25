function eids = selectElementByPosition(mi, test)
% Selects elements using a position test function
%
% Authors: M. Peres and P. Pagliosa
% Last revision: 24/09/2024
%
% Input
% =====
% MI: MeshInterface object
% TEST: position test function handle
%
% Output
% ======
% EIDS: indices of the select elements in MI
  assert(isa(test, 'function_handle'));
  eids = selectElementByFilter(mi, @filter);

  function b = filter(e)
    flags(4) = test(e.positionAt(-1, +1));
    flags(3) = test(e.positionAt(+1, +1));
    flags(2) = test(e.positionAt(+1, -1));
    flags(1) = test(e.positionAt(-1, -1));
    b = all(flags);
  end
end % selectElementByPosition
