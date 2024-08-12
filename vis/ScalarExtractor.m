classdef ScalarExtractor < FieldExtractor

properties
  minError = 0;
end

properties (SetAccess = private)
  minValue = 0;
  maxValue = 1;
  eps = 10e-5 / sqrt(10);
end

methods
  function this = ScalarExtractor(tesselator, field, varargin)
    this = this@FieldExtractor(tesselator);
    if nargin < 2
      this.setField('u', 'z');
    else
      this.setField(field, varargin);
    end
  end

  function minError.set(this, value)
    if value < 0
      fprintf("'minError' must be non-negative\n");
    else
      this.minError = value;
    end
  end

  function setField(this, field, varargin)
    if ischar(field)
      if nargin < 3
        dof = 'z';
      else
        dof = varargin{1};
      end
      field = VectorComponentField(field, dof);
    end
    setField@FieldExtractor(this, field);
  end

  function execute(this)
    this.minValue = +Inf;
    this.maxValue = -Inf;
    execute@FieldExtractor(this);
    d = this.maxValue - this.minValue;
    if d <= this.eps
      avg = (this.maxValue + this.minValue) * 0.5;
      this.minValue = avg;
      this.maxValue = avg;
      nv = (this.tesselator.resolution + 1) ^ 2;
      avg = avg * ones(nv, 1);
      for i = 1:this.tesselator.patchCount
        this.tesselator.patches(i).setScalars(avg);
      end
    elseif d <= this.minError
      % TODO
    end
  end
end

methods (Access = protected)
  function setPatchValues(this, i, values)
    [minv, maxv] = bounds(values);
    if minv < this.minValue
      this.minValue = minv;
    end
    if maxv > this.maxValue
      this.maxValue = maxv;
    end
    this.tesselator.patches(i).setScalars(values);
  end
end

end % ScalarExtractor
