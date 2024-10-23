classdef ErrorField < ScalarField
% ErrorField: generic error field class
%
% Author: Paulo Pagliosa
% Last revision: 22/10/2024
%
% Description
% ===========
% An object of the class ErrorField is an evaluator of scalars
% defined by an absolute or relative error at a point on an element.
%
% See also: ErrorType

%% Public read-only properties
properties (SetAccess = private)
  errorType ErrorType = ErrorType.RELATIVE;
end

%% Private properties
properties (Access = private)
  valuesHandle;
end

%% Public methods
methods
  function this = ErrorField(handle)
  % Constructs an error field
  %
  % Input
  % =====
  % HANDLE: handle to a function that returns a pair [MV,AV], where MV
  % is the measured value and AV is the actual value. The function takes
  % as input paramaters the parametric coordinates [U,V] of a point on
  % an element at which the values are evaluated, the spatial position
  % [X,Y,Z] of the point, and a reference to the element
    assert(isa(handle, 'function_handle'), 'Function handle expected');
    this.valuesHandle = handle;
  end

  function setErrorType(this, errorType)
  % Sets the error type of this field
    if errorType ~= this.errorType
      this.errorType = errorType;
      this.handleErrorTypeChange;
    end
  end

  function x = valueAt(this, u, v)
  % Computes the field value at a point on the element of this field
    p = this.element.positionAt(u, v);
    [mv, av] = this.valuesHandle([u, v], p, this.element);
    x = abs(mv - av);
    if this.errorType == ErrorType.RELATIVE
      x = x / av * 100;
    end
  end
end

%% Protected methods
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
