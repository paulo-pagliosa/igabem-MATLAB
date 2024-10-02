classdef ScalarExtractor < FieldExtractor
% ScalarExtractor: scalar field extractor class
%
% Author: Paulo Pagliosa
% Last revision: 01/10/2024
%
% Description
% ===========
% An object of the class ScalarExtractor associates a scalar to
% each point resulting from the tessellation of a mesh. The scalar
% at a point of an element is determined by a ScalarField object.
%
% See also: ScalarField

%% Public properties
properties
  minError = 0;
end

%% Public read-only properties
properties (SetAccess = private)
  minValue = 0;
  maxValue = 1;
  eps = 10e-5 / sqrt(10);
end

%% Public methods
methods
  function this = ScalarExtractor(tessellator, field, varargin)
  % Constructs a scalar extractor
  %
  % Input
  % =====
  % TESSELLATOR: tesselattor object
  % FIELD: scalar field object
  % VARARGIN: if FIELD is 'u' or 't', VARARGIN{1} must be a
  % char array with any combination of 'x', 'y', and 'z', or
  % array with any combination of 1, 2, and 3. VARARGIN{1}
  % defines the component(s) of the displacement or traction
  % field used to set the scalar field to be extracted
    this = this@FieldExtractor(tessellator);
    if nargin < 2
      this.setField('u', 'z');
    else
      this.setField(field, varargin);
    end
  end

  function setField(this, field, varargin)
  % Sets the field of this extractor
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
  % Computes the field values for every point from the mesh tessellation
    this.minValue = +Inf;
    this.maxValue = -Inf;
    execute@FieldExtractor(this);
    d = this.maxValue - this.minValue;
    if d <= this.eps
      avg = (this.maxValue + this.minValue) * 0.5;
      this.minValue = avg;
      this.maxValue = avg;
      nv = (this.tessellator.resolution + 1) ^ 2;
      avg = avg * ones(nv, 1);
      for i = 1:this.tessellator.patchCount
        this.tessellator.patches(i).setScalars(avg);
      end
    elseif d <= this.minError
      % TODO
    end
  end

  function minError.set(this, value)
    if value < 0
      fprintf("'minError' must be non-negative\n");
    else
      this.minError = value;
    end
  end
end

%% Protected methods
methods (Access = protected)
  function setPatchValues(this, i, values)
    [minv, maxv] = bounds(values);
    if minv < this.minValue
      this.minValue = minv;
    end
    if maxv > this.maxValue
      this.maxValue = maxv;
    end
    this.tessellator.patches(i).setScalars(values);
  end
end

end % ScalarExtractor
