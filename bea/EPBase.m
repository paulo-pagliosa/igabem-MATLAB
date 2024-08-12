classdef (Abstract) EPBase < handle

properties
  material;
  p = [];
end

properties (GetAccess = protected, SetAccess = private)
  integrator;
end

methods
  function set.material(obj, value)
    assert(isa(value, 'Material'), 'Material expected');
    obj.material = value;
  end
  
  function set(this, varargin)
    n = nargin - 1;
    assert(rem(n, 2) == 0, 'Pair property name/value missing');
    for i = 1:2:n
      this.integrator.set(varargin{i}, varargin{i + 1});
    end
  end

  function value = get(this, name)
    value = this.integrator.get(name);
  end
end

methods (Access = protected)
  function this = EPBase(material, varargin)
    this.material = material;
    this.integrator = KelvinIntegrator(material);
    this.set(varargin{:});
  end
end

end % EPBase
