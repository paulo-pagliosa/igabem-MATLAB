classdef VectorField < Field
% VectorField: vector field class
%
% Author: Paulo Pagliosa
% Last revision: 31/08/2024
%
% Description
% ===========
% An object of the class VectorField computes a 3D vector
% (e.g., displacement or traction) at a point on an element.

%% Public read-onky properties
properties (SetAccess = protected)
  dim = 3;
end

%% Public methods
methods
  function this = VectorField(handle, label)
  % Constructs a vector field
  %
  % Input
  % =====
  % HANDLE: handle to a function that returns the 3D vectors associated
  % with the nodes of an element. The function takes as input parameter
  % a reference to the element. Alternatively, HANDLE can 'u' or 't'.
  % In this case, the vectors are the displacements or tractions of the
  % element's nodes, respectively
  % LABEL: field label
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
