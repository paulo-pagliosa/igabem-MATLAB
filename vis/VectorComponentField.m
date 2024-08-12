classdef VectorComponentField < ScalarField

properties (Access = private)
  vectorField;
  dof;
end

methods
  function this = VectorComponentField(field, dof)
    dof = BC.parseDofs(dof);
    dof = dof(dof > 0);
    if ischar(field)
      field = VectorField(field);
    else
      assert(isa(field, 'VectorField'), 'Vector field expected');
    end
    dofLabel = 'xyz';
    this = this@ScalarField([], ...
      sprintf('%s %s', field.label, dofLabel(dof)));
    this.vectorField = field;
    this.dof = dof;
  end

  function setElement(this, element)
    this.vectorField.setElement(element);
  end

  function x = valueAt(this, u, v)
    x = this.vectorField.valueAt(u, v);
    x = x(this.dof);
    if size(x, 2) > 1
      x = sqrt(x * x');
    end
  end
end

end % VectorComponentField
