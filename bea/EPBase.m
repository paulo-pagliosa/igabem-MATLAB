classdef (Abstract) EPBase < handle
% EPBase: base class for elastostatic processors
%
% Author: Paulo Pagliosa
% Last revision: 31/08/2024
%
% Description
% ===========
% The abstract class EPBase is a base class for elastostatic processors,
% i.e., the elastostatic solver and its post-processor. These objects
% relies on the integration scheme described in Section 5 for evaluating
% the jump term and influence matrices of a given element.
%
% See also: class Material, class KelvinIntegrator, and derived classes
% ElastostaticSolver and EPP
% class EPP

%% Public properties
properties
  material;
  p = [];
end

%% Protected read-only properties
properties (GetAccess = protected, SetAccess = private)
  integrator;
end

%% Public methods
methods
  function set.material(obj, value)
  % Sets the material of this object
    assert(isa(value, 'Material'), 'Material expected');
    obj.material = value;
  end
  
  function set(this, varargin)
  % Sets properties of the integrator of this object
    n = nargin - 1;
    assert(rem(n, 2) == 0, 'Pair property name/value missing');
    for i = 1:2:n
      this.integrator.set(varargin{i}, varargin{i + 1});
    end
  end

  function value = get(this, name)
  % Returns the value of a property of the integrator of this object
    value = this.integrator.get(name);
  end
end

%% Protected methods
methods (Access = protected)
  function this = EPBase(material, varargin)
    this.material = material;
    this.integrator = KelvinIntegrator(material);
    this.set(varargin{:});
  end
end

end % EPBase
