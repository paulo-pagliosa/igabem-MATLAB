classdef EditMode < int32
% EditMode: edit modes of a MeshInterface object
%
% Author: Paulo Pagliosa
% Last revision: 01/10/2024
%
% See also: MeshInterface
enumeration
  SELECT (1);
  ROTATE (2);
  MOVE (3);
  ZOOM (4);
end

end % EditMode
