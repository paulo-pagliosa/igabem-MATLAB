classdef (Abstract) ElementReader < handle
% ElementReader: generic element reader class
%
% Author: Paulo Pagliosa
% Last revision: 12/08/2024
%
% Description
% ===========
% The abstract class ElementReader encapsulates the behavior of a generic
% reader of element data. 

%% Public read-only properties
properties (SetAccess = protected)
  elementType;
  mesh;
end

%% Public methods
% Reads element data from a file
methods (Abstract)
  element = read(this, file, flags);
end

%% Protected methods
methods (Access = protected)
  % Constructor
  function this = ElementReader(elementType)
    this.elementType = elementType;
    this.mesh = Mesh;
    this.mesh.setElementType(elementType);
  end
end

end % ElementReader
