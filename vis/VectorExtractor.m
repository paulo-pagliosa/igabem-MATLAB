classdef VectorExtractor < FieldExtractor

methods
  function this = VectorExtractor(tesselator, field)
    this = this@FieldExtractor(tesselator);
    if nargin < 2
      field = 'u';
    end
    this.setField(field);
  end

  function setField(this, field)
    if ischar(field)
      field = VectorField(field);
    end
    setField@FieldExtractor(this, field);
  end
end

methods (Access = protected)
  function setPatchValues(~, ~, ~)
    % TODO
  end
end

end % FieldExtractor
