classdef (Abstract) Field < handle

properties
  label;
end

properties (Abstract, SetAccess = protected)
  dim;
end

properties (Access = protected)
  nodalValuesHandle;
  nodalValues;
  shapeFunction;
end

methods
  function setElement(this, element)
    assert(isa(element, 'Element'), 'Element expected');
    this.shapeFunction = element.shapeFunction;
    if ~isempty(this.nodalValuesHandle)
      this.nodalValues = this.nodalValuesHandle(element);
      s = size(this.nodalValues);
      if s(1) ~= element.nodeCount || s(2) ~= this.dim
        error('Field: bad nodal values size');
      end
    end
  end

  function x = valueAt(this, u, v)
    x = this.shapeFunction.interpolate(this.nodalValues, u, v);
  end
end

methods (Access = protected)
  function this = Field(nodalValuesHandle, label)
    if nargin > 0
      this.nodalValuesHandle = nodalValuesHandle;
      this.label = label;
    end
  end
end

end % Field
