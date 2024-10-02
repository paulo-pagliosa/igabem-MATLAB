classdef (Abstract) FieldExtractor < handle
% FieldExtractor: generic field extractor class
%
% Author: Paulo Pagliosa
% Last revision: 01/10/2024
%
% Description
% ===========
% The abstract class FieldExtractor encapsulates the behavior of a
% generic field extractor. A field extractor associates a quantity
% (scalar or vector) with each point resulting from the tessellation
% of a mesh. The value of the quantity at a point on an element is
% determined by an object of a class derived from the abstract class
% Field. The method for associating field values with points on an
% element must be implemented in classes derived from FieldExtractor.
%
% See also: Field, MeshTessellator

%% Public read-only properties
properties (SetAccess = protected)
  tessellator;
  field;
end

%% Public methods
methods
  function setField(this, field)
  % Sets the field of this extractor
    assert(isa(field, 'Field'), 'Field expected');
    this.field = field;
  end

  function execute(this)
  % Computes the field values for every point from the mesh tessellation
    assert(~isempty(this.field), 'Field not set');
    mesh = this.tessellator.mesh;
    ne = mesh.elementCount;
    resolution = this.tessellator.resolution;
    nv = (resolution + 1) ^ 2;
    dp = 2 / double(resolution);
    for i = 1:ne
      this.field.setElement(mesh.elements(i));
      values = zeros(nv, this.field.dim);
      j = 1;
      for v = -1:dp:1
        for u = -1:dp:1
          values(j, :) = this.field.valueAt(u, v);
          j = j + 1;
        end
      end
      this.setPatchValues(i, values);
    end
  end
end

%% Protected methods
methods (Access = protected)
  function this = FieldExtractor(tessellator)
    assert(isa(tessellator, 'MeshTessellator'), 'Mesh tessellator expected');
    this.tessellator = tessellator;
  end
end

methods (Abstract, Access = protected)
  setPatchValues(this, i, values);
end

end % FieldExtractor
