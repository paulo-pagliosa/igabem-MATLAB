classdef VectorComponentErrorField < ErrorField

properties (Access = private)
  field;
end

methods
  function this = VectorComponentErrorField(field, dof, avHandle)
    assert(isa(avHandle, 'function_handle'), 'Actual values handle expected');
    field = VectorComponentField(field, dof);
    this = this@ErrorField(@computeValues);
    this.field = field;
    this.handleErrorTypeChange();

    function [mv, av] = computeValues(csi, p, element)
      av = avHandle(csi, p, element);
      mv = field.valueAt(csi(1), csi(2));
    end
  end

  function setElement(this, element)
    setElement@ErrorField(this, element);
    this.field.setElement(element);
  end
end

methods (Access = protected)
  function handleErrorTypeChange(this)
    this.label = sprintf('%s %s', this.field.label, this.errorLabel);
  end
end

end % VectorComponentErrorField
