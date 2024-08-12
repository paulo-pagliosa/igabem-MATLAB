classdef ElementReader < handle

properties (SetAccess = protected)
  elementType;
  mesh;
end
  
methods (Abstract)
  element = read(this, file, flags);
end

methods (Access = protected)
  function this = ElementReader(elementType)
    this.elementType = elementType;
    this.mesh = Mesh;
    this.mesh.setElementType(elementType);
  end
end

end % ElementReader
