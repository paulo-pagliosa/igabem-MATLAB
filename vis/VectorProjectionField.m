classdef VectorProjectionField < ScalarField
% VectorProjectionField: vector projection field class
%
% Author: Paulo Pagliosa
% Last revision: 22/10/2024
%
% Description
% ===========
% An object of the class VectorProjectionField is an evaluator of
% scalars defined by the projection of vectors from a vector field
% onto a given direction or boundary normal.
%
% See also: VectorField

%% Private properties
properties (Access = private)
  vectorField VectorField;
  direction double;
end

%% Public methods
methods
  function this = VectorProjectionField(field, direction)
  % Constructs a vector projection field
  %
  % Input
  % =====
  % FIELD: a VectorField object or 'u' or 't'
  % DIRECTION: 1x3 array with the coordinates of the direction vector.
  % If DIRECTION is missing, then the vector at a boundary point, P,
  % is projected onto the normal at P
    if ischar(field)
      field = VectorField(field);
    else
      assert(isa(field, 'VectorField'), 'Vector field expected');
    end
    if nargin < 2 || isempty(direction)
      d = [];
      s = [field.label ' onto normal'];
    else
      d = norm(direction);
      assert(d > 0 && numel(direction) == 3, 'Bad direction');
      d = direction / d;
      s = sprintf('%s onto (%.1g,%.1g,%.1g)', field.label, d(1), d(2), d(3));
    end
    this = this@ScalarField([], s);
    this.vectorField = field;
    this.direction = d;
  end

  function setElement(this, element)
  % Sets the element of this field
    this.vectorField.setElement(element);
    this.element = element;
  end

  function x = valueAt(this, u, v)
  % Computes the field value at a point on the element of this field
    if ~isempty(this.direction)
      D = this.direction;
    else
      D = this.element.normalAt(u, v);
    end
    x = sum(this.vectorField.valueAt(u, v) .* D);
  end
end

end % VectorProjectionField
