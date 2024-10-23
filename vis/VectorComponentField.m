classdef VectorComponentField < ScalarField
% VectorComponentField: vector component field class
%
% Author: Paulo Pagliosa
% Last revision: 22/10/2024
%
% Description
% ===========
% An object of the class VectorComponentField is an evaluator of
% scalars defined by a component (e.g, 'z') or the module of the
% vector of two or more components (e.g, 'xy' or 'xyz') of vectors
% from a vector field.
%
% See also: VectorField

%% Private properties
properties (Access = private)
  vectorField;
  dof;
end

%% Public methods
methods
  function this = VectorComponentField(field, dof)
  % Constructs a vector component field
  %
  % Input
  % =====
  % FIELD: a VectorField object or 'u' or 't'
  % DOF: char array with any combination of 'x', 'y', and 'z', or an
  % array with any combination of 1, 2, and 3. DOF defines the
  % component(s) of the vector field used to generate scalar values
    if ischar(field)
      field = VectorField(field);
    else
      assert(isa(field, 'VectorField'), 'Vector field expected');
    end
    dof = BC.parseDofs(dof);
    dof = dof(dof > 0);
    dofLabel = 'xyz';
    this = this@ScalarField([], ...
      sprintf('%s %s', field.label, dofLabel(dof)));
    this.vectorField = field;
    this.dof = dof;
  end

  function setElement(this, element)
  % Sets the element of this field
    this.vectorField.setElement(element);
    this.setElement@ScalarField(element);
  end

  function x = valueAt(this, u, v)
  % Computes the field value at a point on the element of this field
    x = this.vectorField.valueAt(u, v);
    x = x(this.dof);
    if size(x, 2) > 1
      x = sqrt(x * x');
    end
  end
end

end % VectorComponentField
