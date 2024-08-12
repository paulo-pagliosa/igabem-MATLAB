classdef VectorField < Field

properties (SetAccess = protected)
  dim = 3;
end

methods
  function this = VectorField(handle, label)
    if ischar(handle)
      switch handle
        case 'u'
          handle = @(element) element.nodeDisplacements;
          dflLabel = 'displacement';
        case 't'
          handle = @(element) element.nodeTractions;
          dflLabel = 'traction';
        otherwise
          error('Unknown vector field');
      end
      if nargin < 2
        label = dflLabel;
      end
    elseif ~isa(handle, 'function_handle')
      error('Invalid vector field');
    end
    this = this@Field(handle, label);
  end
end

end % VectorField
