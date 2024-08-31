classdef EditMode < int32
% EditMode: edit modes of a MeshInterface object
%
% Author: Paulo Pagliosa
% Last revision: 31/08/2024
%
% See also: class MeshInterface
enumeration
  SELECT (1);
  ROTATE (2);
  MOVE (3);
  ZOOM (4);
end

end % EditMode
