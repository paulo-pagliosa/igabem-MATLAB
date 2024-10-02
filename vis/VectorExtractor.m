classdef VectorExtractor < FieldExtractor
% VectorExtractor: vector field extractor class
%
% Author: Paulo Pagliosa
% Last revision: 01/10/2024
%
% Description
% ===========
% An object of the class VectorExtractor associates a vector to
% each point resulting from the tessellation of a mesh. The vector
% at a point of an element is determined by a VectorField object.
%
% See also: VectorField

%% Public methods
methods
  function this = VectorExtractor(tessellator, field)
  % Constructs a vector extractor
  %
  % Input
  % =====
  % TESSELLATOR: tesselattor object
  % FIELD: vector field object or 'u' or 't'
    this = this@FieldExtractor(tessellator);
    if nargin < 2
      field = 'u';
    end
    this.setField(field);
  end

  function setField(this, field)
  % Sets the field of this extractor
    if ischar(field)
      field = VectorField(field);
    end
    setField@FieldExtractor(this, field);
  end
end

%% Protected methods
methods (Access = protected)
  function setPatchValues(~, ~, ~)
    % TODO
  end
end

end % FieldExtractor
