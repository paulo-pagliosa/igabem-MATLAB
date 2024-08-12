classdef BCFunction

methods (Static)
  function f = constant(z)
    assert(isscalar(z), 'Scalar expected');
    f = @(~, ~, ~) z;
  end

  function f = compose(f1, f2)
    f = @(u, v, ~) f1(u) .* f2(v);
  end

  function f = bilinear(z1, z2)
    if isscalar(z1)
      z1 = [z1 z1];
    end
    if isscalar(z2)
      z2 = [z2 z2];
    end
    f = BCFunction.compose(linear(z1), linear(z2));

    function g = linear(y) %[-1,y(1)]->[1,y(2)]
      a = (y(2) - y(1)) / 2;
      b = (y(1) + y(2)) / 2;
      g = @(x) a * x + b;
    end
  end

  function [f, n] = parse(f, varargin)
    n = 0;
    if isnumeric(f)
      return;
    end
    if ischar(f)
      switch f
        case 'constant'
          f = BCFunction.constant(varargin{1});
          n = 1;
        case 'bilinear'
          f = BCFunction.bilinear(varargin{1}, varargin{2});
          n = 2;
      end
    end
    if ~isa(f, 'function_handle')
      error('BC function expected');
    end
  end
end

end % BCFunction
