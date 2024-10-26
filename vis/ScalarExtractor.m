classdef ScalarExtractor < FieldExtractor
% ScalarExtractor: scalar field extractor class
%
% Author: Paulo Pagliosa
% Last revision: 23/10/2024
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
end

%% Public methods
methods
  function this = ScalarExtractor(tessellator, field, varargin)
  % Constructs a scalar extractor
  %
  % Input
  % =====
  % TESSELLATOR: tesselattor object
  % FIELD: scalar field object or 'u' or 't'
  % VARARGIN: if FIELD is 'u' or 't', then the displacement or
  % traction is used to set the scalar at a point, P, inside a
  % boundary element. In this case, VARARGIN{1} can be:
  % - 'direction': the scalar is the projection of the displacement
  % or traction at P onto the direction given by VARARGIN{2}
  % - 'normal': the scalar is the projection of the displacement or
  % traction at P onto the normal at P
  % - a char array with any combination of 'x', 'y', and 'z', or an
  % array with any combination of 1, 2, and 3: the scalar is a
  % component (e.g, 'z') or the module of the vector of two or more
  % components (e.g, 'xy' or 'xyz') of the displacement or traction
  % at P
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
      dof = [];
      direction = [];
      if nargin < 3
        dof = 'z';
      else
        switch varargin{1}
          case 'direction'
            assert(nargin > 3, 'Direction vector expected');
            direction = varargin{2};
          case 'normal'
            assert(nargin < 4, 'Unexpected argument');
          otherwise
            dof = varargin{1};
        end
      end
      if ~isempty(dof)
        field = VectorComponentField(field, dof);
      else
        field = VectorProjectionField(field, direction);
      end
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

%% Protected properties
properties (Access = protected, Constant)
  eps = 10e-5 / sqrt(10);
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
