classdef (Abstract) ElementReader < handle
% ElementReader: generic element reader class
%
% Author: Paulo Pagliosa
% Last revision: 01/10/2024
%
% Description
% ===========
% The abstract class ElementReader encapsulates the behavior of a generic
% reader of element data.
%
% See also: readMesh

%% Public read-only properties
properties (SetAccess = protected)
  elementType;
  mesh;
end

%% Public methods
methods (Abstract)
% Reads element data from a file
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
