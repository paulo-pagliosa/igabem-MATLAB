classdef (Abstract) ScalarField < Field
% ScalarField: generic scalar field class
%
% Author: Paulo Pagliosa
% Last revision: 31/08/2024
%
% Description
% ===========
% The abstract class ScalarField encapsulates the behavior of a generic
% scalar field evaluator. A scalar field evaluator computes a scalar at
% a point on an element.

%% Protected properties
properties (SetAccess = protected)
  dim = 1;
end

end % ScalarField
