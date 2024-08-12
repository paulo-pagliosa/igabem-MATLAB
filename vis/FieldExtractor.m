classdef (Abstract) FieldExtractor < handle

properties (SetAccess = protected)
  tesselator;
  field;
end

methods
  function setField(this, field)
    assert(isa(field, 'Field'), 'Field expected');
    this.field = field;
  end

  function execute(this)
    assert(~isempty(this.field), 'Field not set');
    mesh = this.tesselator.mesh;
    ne = mesh.elementCount;
    resolution = this.tesselator.resolution;
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

methods (Access = protected)
  function this = FieldExtractor(tesselator)
    assert(isa(tesselator, 'MeshTesselator'), 'Mesh tesselator expected');
    this.tesselator = tesselator;
  end
end

methods (Abstract, Access = protected)
  setPatchValues(this, i, values);
end

end % FieldExtractor
