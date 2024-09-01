classdef LoadPoint < handle
% LoadPoint: load point class
%
% Author: Paulo Pagliosa
% Last revision: 31/08/2024
%
% Description
% ===========
% An object of the class LoadPoint represents a load point
% associated with a node of a BEA model. The properties of
% a load point are a set of elements containing the load point
% and the parametric coordinates of the load point relative to
% the intrinsic coordinate system of its elements.
%
% See also: class Element, class Node

%% Public properties
properties
  elements (:, 1) Element = Element.empty;
  localPositions (:, 2) double;
  smooth = true;
end

%% Public methods
methods
  function this = LoadPoint(elements, localPositions)
  % Constructs a load point
    if nargin > 1
      this.elements = elements;
      this.localPositions = localPositions;
    end
  end

  function [p, N] = position(this)
  % Computes the spatial position of this load point
    p = this.localPositions(1, :);
    [p, N] = this.elements(1).positionAt(p(1), p(2));
  end
end

end % LoadPoint
