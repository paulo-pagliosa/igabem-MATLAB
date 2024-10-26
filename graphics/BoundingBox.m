classdef BoundingBox < handle
% BoundingBox: bounding box class
%
% Author: Paulo Pagliosa
% Last revision: 23/10/2024
%
% Description
% ===========
% An object of the class BoundingBox represents a 3D axis-aligned
% bounding box (AABB). The class defines methods to compute properties
% such as center, volume, area, and size. Also, there are methods to
% draw and inflate to "swallow" a 3D point.

%% Public read-only properties
properties (SetAccess = protected)
  p1 (1, 3) double;
  p2 (1, 3) double;
end

%% Public methods
methods
  function this = BoundingBox(p1, p2)
  % Constructs a bounding box
    if nargin == 0
      this.setEmpty;
      return;
    end
    narginchk(1, 2);
    if nargin == 2
      this.p1 = min(p1, p2);
      this.p2 = max(p1, p2);
    elseif ~isa(p1, 'BoundingBox')
      error('BoudingBox or two points expected');
    else
      this.p1 = p1.p1;
      this.p2 = p1.p2;
    end
  end

  function setEmpty(this)
  % Sets this bounding box empty
    this.p1 = [+Inf, +Inf, +Inf];
    this.p2 = [-Inf, -Inf, -Inf];
  end

  function c = center(this)
  % Computes the center of this bounding box
    c = (this.p1 + this.p2) * 0.5;
  end

  function d = diagonalLength(this)
  % Computes the diagonal length of this bounding box
    d = this.p2 - this.p1;
    d = sqrt(d * d');
  end

  function s = dimensions(this)
  % Computes the size of this bounding box
    s = this.p2 - this.p1;
  end

  function a = area(this)
  % Computes the area of this bounding box
    a = this.dimensions;
    a = a(1) * (a(2) + a(3)) + a(2) * a(3);
    a = a + a;
  end

  function v = volume(this)
  % Computes the volume of this bounding box
    v = prod(this.dimensions);
  end

  function b = isEmpty(this)
  % Returns true if this bounding bix is empty
    b = any((this.dimensions) < 0);
  end

  function [h, v, f] = draw(this, axes, color, alpha)
  % Draws this bounding box
    if nargin < 4
      alpha = 0.5;
    end
    if nargin < 3
      color = [0.8, 0.8, 0.8];
    end
    [v, f] = makeBox(this.p1, this.p2);
    h = patch('Parent', axes, ...
      'Vertices', v, ...
      'Faces', f, ...
      'FaceColor', color, ...
      'FaceAlpha', alpha);
  end

  function inflate(this, p)
  % Inflates this bounding box to contain the point (set) P
    if isa(p, 'BoundingBox')
      this.p1 = min(this.p1, p.p1);
      this.p2 = max(this.p2, p.p2);
    elseif isscalar(p) && p > 0
      c = this.center + (1 - p);
      this.p1 = this.p1 * p + c;
      this.p2 = this.p2 * p + c;
    elseif size(p, 1) > 1
      inflateAABB(this, min(p));
      inflateAABB(this, max(p));
    else
      inflateAABB(this, p);
    end
  end
end

%% Private methods
methods (Access = private)
  function inflateAABB(this, p)
    this.p1 = min(this.p1, p);
    this.p2 = max(this.p2, p);
  end
end

end % BoundingBox
