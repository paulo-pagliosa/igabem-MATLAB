classdef ErrorField < ScalarField

properties (SetAccess = private)
  errorType ErrorType = ErrorType.RELATIVE;
end

properties (Access = private)
  element;
  valuesHandle;
end

methods
  % Constructor
  %
  % HANDLE is a handle to a function that returns a pair [MV, AV],
  % where MV is the measured value and AV is the actual value. The
  % function takes as paramaters:
  % [U, V]: the parametric coordinates of a point on an element at
  % which the values are evaluated;
  % P: the spatial poisition of the point; and
  % ELEMENT: the element.
  function this = ErrorField(handle)
    assert(isa(handle, 'function_handle'), 'Values handle expected');
    this.valuesHandle = handle;
  end

  function setErrorType(this, errorType)
    if errorType ~= this.errorType
      this.errorType = errorType;
      this.handleErrorTypeChange;
    end
  end

  function setElement(this, element)
    this.element = element;
  end

  function x = valueAt(this, u, v)
    p = this.element.positionAt(u, v);
    [mv, av] = this.valuesHandle([u, v], p, this.element);
    x = abs(mv - av);
    if this.errorType == ErrorType.RELATIVE
      x = x / av * 100;
    end
  end
end

methods (Access = protected)
  function handleErrorTypeChange(~)
    % do nothing
  end

  function s = errorLabel(this)
    if this.errorType == ErrorType.RELATIVE
      s = 'error (%)';
    else
      s = 'error';
    end
  end
end

end % ErrorField
