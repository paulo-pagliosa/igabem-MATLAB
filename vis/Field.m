classdef (Abstract) Field < handle
% Field: generic field class
%
% Author: Paulo Pagliosa
% Last revision: 31/08/2024
%
% Description
% ===========
% The abstract class Field encapsulates the behavior of a generic
% field evaluator. A field evaluator computes the value of a quantity
% (scalar or vector) at a point on an element.
%
% See also: class Element

%% Public properties
properties
  label;
end

%% Public read-only properties
properties (Abstract, SetAccess = protected)
  dim;
end

%% Protected properties
properties (Access = protected)
  nodalValuesHandle;
  nodalValues;
  shapeFunction;
end

%% Public methods
methods
  function setElement(this, element)
  % Sets the element of this field
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
  % Computes the field value at a point on the element of this field
    x = this.shapeFunction.interpolate(this.nodalValues, u, v);
  end
end

%% Protected methods
methods (Access = protected)
  function this = Field(nodalValuesHandle, label)
    if nargin > 0
      this.nodalValuesHandle = nodalValuesHandle;
      this.label = label;
    end
  end
end

end % Field
