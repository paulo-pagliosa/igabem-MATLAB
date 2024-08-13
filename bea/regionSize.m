function Lm = regionSize(element, region)
% Computes the size of an element region
%
% Author: Paulo Pagliosa
% Last revision: 12/08/2024
  assert(isa(element, 'Element'), 'Element expected');
  if nargin < 2
    region = QuadRegion.default;
  end
  c1 = region.o;
  c2 = region.s + c1;
  cm = region.center;
  x1 = element.positionAt(c1(1), c1(2));
  x2 = element.positionAt(c2(1), c1(2));
  x3 = element.positionAt(c2(1), c2(2));
  x4 = element.positionAt(c1(1), c2(2));
  Lb = curveLength(x1, x2, element.positionAt(cm(1), c1(2))); % bottom edge
  Lt = curveLength(x4, x3, element.positionAt(cm(1), c2(2))); % top edge
  Ll = curveLength(x1, x4, element.positionAt(c1(1), cm(2))); % left edge
  Lr = curveLength(x2, x3, element.positionAt(c2(1), cm(2))); % right edge
  Lm = [Lb + Lt, Ll + Lr] * 0.5;

  % Point-based method by Floater and Rasmussen
  function L = curveLength(x0, x2, x1)
    s = x0 + x2;
    r = s * 0.5 + (sqrt(3) / 3) * (2 * x1 - s);
    L = norm(r - x0) + norm(x2 - r);
  end
end % regionSize
