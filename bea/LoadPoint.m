classdef LoadPoint < handle

properties
  elements (:, 1) Element = Element.empty;
  localPositions (:, 2) double;
  smooth = true;
end

methods
  function this = LoadPoint(elements, localPositions)
    if nargin > 1
      this.elements = elements;
      this.localPositions = localPositions;
    end
  end

  function [p, N] = position(this)
    p = this.localPositions(1, :);
    [p, N] = this.elements(1).positionAt(p(1), p(2));
  end
end

end % LoadPoint
