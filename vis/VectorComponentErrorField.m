classdef VectorComponentErrorField < ErrorField
% VectorComponentErrorField: vector component error field class
%
% Author: Paulo Pagliosa
% Last revision: 22/10/2024
%
% Description
% ===========
% An object of the class VectorComponentErrorField is an evaluator of
% errors on a component (e.g, 'z') or the module of the vector of two
% or more components (e.g, 'xy' or 'xyz') of a vector field.
%
% See also: VectorField

%% Private properties
properties (Access = private)
  field;
end

%% Public methods
methods
  function this = VectorComponentErrorField(field, dof, avHandle)
  % Constructs a vector component error field
  %
  % Input
  % =====
  % FIELD: a VectorField object or 'u' or 't'
  % DOF: char array with any combination of 'x', 'y', and 'z', or an
  % array with any combination of 1, 2, and 3. DOF defines the
  % component(s) of the vector field used to compute measured values
  % AVHANDLE: handle to a function that returns the actual value at a
  % point on an element. The function takes as input paramaters the
  % parametric coordinates [U,V] of the point, the spatial position
  % [X,Y,Z] of the point, and a reference to the element
    assert(isa(avHandle, 'function_handle'), 'Function handle expected');
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
  % Sets the element of this field
    this.field.setElement(element);
    this.setElement@ErrorField(element);
  end
end

%% Protected methods
methods (Access = protected)
  function handleErrorTypeChange(this)
    this.label = sprintf('%s %s', this.field.label, this.errorLabel);
  end
end

end % VectorComponentErrorField
