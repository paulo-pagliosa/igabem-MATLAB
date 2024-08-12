classdef KelvinIntegrator < matlab.mixin.SetGet

properties (Constant)
  tableBeer = [3.05 1.45 0.95 0.75 0.55 0.5 0];
  eps = 1e-4;
end

properties
  dflGaussRule = 4;
  triGaussRule = 4;
  maxDepth = 3;
  minRatio = 0;
  outGaussRule = 0;
end

properties (GetAccess = private, Dependent)
  srMethod;
end

properties (Access = private)
  material;
  gp = GaussPoints;
  evalSingularRegion function_handle;
end

methods
  function this = KelvinIntegrator(material)
    this.material = material;
    this.srMethod = '4T';
  end

  % Sets the number of Gauss points above which a regular quad
  % region may be divided along a direction
  function set.dflGaussRule(this, value)
    if value < 2 || value > 8
      fprintf("'dflGaussRule' must be in range [2,8]\n");
    else
      this.dflGaussRule = value;
    end
  end

  % Sets the number of Gauss points to be used for integration
  % of a triangular region (in both directions)
  function set.triGaussRule(this, value)
    if value < 2 || value > 8
      fprintf("'triGaussRule' must be in range [2,8]\n");
    else
      this.triGaussRule = value;
    end
  end

  function set.outGaussRule(this, value)
    if value ~= 0 && value < 2
      fprintf("'outGaussRule' must be 0 or greater than to 1\n");
    else
      this.outGaussRule = value;
    end
  end

  % Sets the max subdivision level of a quad region
  function set.maxDepth(this, value)
    if value < 0 || value > 4
      fprintf("'maxDepth' must be in range [0,4]\n");
    else
      this.maxDepth = value;
    end
  end

  % Sets the aspect ratio of the image of a region above which
  % the region is divided along a direction (0: no division)
  function set.minRatio(this, value)
    if value ~= 0 && value < 1
      fprintf("'minRatio' must be 0 or greater than or equal to 1\n");
    else
      this.minRatio = value * 2;
    end
  end

  % Sets the method to be used for integration of a singular region
  function set.srMethod(this, value)
    value = upper(value);
    switch value
      case '4T'
        this.evalSingularRegion = @this.evalSingularRegion4T;
      case 'TR'
        this.evalSingularRegion = @this.evalSingularRegionTR;
      otherwise
        fprintf("'srMethod' must be '4T' or 'TR'\n");
    end
  end

  function [c, h, g, x] = outsideIntegration(this, p, element)
    out = this.initResults(element);
    r = QuadRegion.default;
    if this.outGaussRule == 0
      out = this.evalRegion(p, element, r, out);
    else
      out = this.integrateRegion(p, ...
        element, ...
        r, ...
        this.outGaussRule, ...
        this.outGaussRule, ...
        out);
    end
    c = out.c;
    h = out.h;
    g = out.g;
    x = out.x;
  end

  function [c, h, g, x] = insideIntegration(this, csi, p, element)
    out = this.initResults(element);
    region = QuadRegion.default;
    if this.minRatio == 0
      out = this.evalSingularRegion(csi, p, element, region, out);
    else
      out = this.subdSingularRegion(csi, p, element, region, out);
    end
    c = out.c;
    h = out.h;
    g = out.g;
    x = out.x;
  end
end

methods (Access = protected)
  function [U, T] = evalKernel(this, p, q, N)
    d = q - p;
    r = norm(d);
    d = d / r;
    [U, T] = Kelvin3.eval(r, d, N, this.material);
  end

  % Integrates a regular region using nu x nv Gauss points
  function out = integrateRegion(this, p, element, region, nu, nv, out)
    [xgu, wgu] = this.gp.get(nu);
    [xgv, wgv] = this.gp.get(nv);
    rJ = region.jacobian;
    % Spatial position of the Gauss points
    x = zeros(nu * nv, 3);
    k = 1;
    for i = 1:nu
      u = region.u(xgu(i));
      for j = 1:nv
        v = region.v(xgv(j));
        [N, J] = element.normalAt(u, v);
        w = wgu(i) * wgv(j) * rJ * J * 0.25;
        [q, S] = element.positionAt(u, v);
        [U, T] = this.evalKernel(p, q, N);
        T = T * w;
        out.c = out.c - T;
        out.h = out.h + kron(S', T);
        out.g = out.g + kron(S', U * w);
        x(k, :) = q;
        k = k + 1;
      end
    end
    temp = [out.x; x];
    out.x = temp;
  end

  % Integrates a regular region with adaptive subdivision
  function out = evalRegion(this, p, element, region, out)
    splitDepth = this.maxDepth - region.depth;
    stack = Stack(QuadRegion, 3 * splitDepth + 1);
    stack.push(region);
    while ~stack.isEmpty
      region = stack.pop;
      R = projectPoint(element, p, region);
      L = regionSize(element, region);
      nu = this.ruleSizeByBeer(R, L(1));
      nv = this.ruleSizeByBeer(R, L(2));
      if region.depth < splitDepth
        splitU = nu > this.dflGaussRule;
        splitV = nv > this.dflGaussRule;
        if splitU && splitV
          o = region.o;
          c = region.center;
          s = region.s * 0.5;
          d = region.depth + 1;
          stack.push(QuadRegion(o, s, d));
          stack.push(QuadRegion([c(1), o(2)], s, d));
          stack.push(QuadRegion([o(1), c(2)], s, d));
          stack.push(QuadRegion(c, s, d));
          continue;
        elseif splitU
          stack.push(region.splitU(0.5));
          continue;
        elseif splitV
          stack.push(region.splitV(0.5));
          continue;
        end
      end
      out = this.integrateRegion(p, element, region, nu, nv, out);
    end
  end

  % Integrates a triangle (degenerated quad) using n x n Gauss points
  function out = integrateTriangle(this, p, element, v, n, out)
    triangle = QuadTriangle(v(1, :), v(2, :), v(3, :));
    [xg, wg] = this.gp.get(n);
    % Spatial position of the Gauss points
    x = zeros(n * n, 3);
    k = 1;
    for i = 1:n
      u = xg(i);
      for j = 1:n
        v = xg(j);
        t = triangle.positionAt(u, v);
        [N, J] = element.normalAt(t(1), t(2));
        w = wg(i) * wg(j) * triangle.jacobian(u, v) * J * 0.25;
        [q, S] = element.positionAt(t(1), t(2));
        [U, T] = this.evalKernel(p, q, N);
        T = T * w;
        out.c = out.c - T;
        out.h = out.h + kron(S', T);
        out.g = out.g + kron(S', U * w);
        x(k, :) = q;
        k = k + 1;
      end
    end
    temp = [out.x; x];
    out.x = temp;
  end

  % Integrates a singular region with subdivision into triangles
  function out = evalSingularRegion4T(this, csi, p, element, region, out)
    o = region.o;
    c = region.s + o;
    n = this.triGaussRule;
    if ~this.isEqual(csi(2), o(2))
      out = this.integrateTriangle(p, element, [o; [c(1) o(2)]; csi], n, out);
    end
    if ~this.isEqual(csi(1), c(1))
      out = this.integrateTriangle(p, element, [[c(1) o(2)]; c; csi], n, out);
    end
    if ~this.isEqual(csi(2), c(2))
      out = this.integrateTriangle(p, element, [c; [o(1) c(2)]; csi], n, out);
    end
    if ~this.isEqual(csi(1), o(1))
      out = this.integrateTriangle(p, element, [[o(1) c(2)]; o; csi], n, out);
    end
  end

  % Integrates a singular region with subdivision into triangles and
  % quad subregions
  function out = evalSingularRegionTR(this, csi, p, element, region, out)
    o = region.o;
    s = region.s;
    x = (csi - o) ./ s * 2 - [1 1];
    b = [x + [1 1] , [1 1] - x];
    d = 2;
    for i = 1:4
      if b(i) > this.eps && b(i) < d
        d = b(i);
      end
    end
    d = s * (d * 0.5);
    c = o + s;
    ou = [o(1), max(csi(1) - d(1), o(1)), min(csi(1) + d(1), c(1))];
    ov = [o(2), max(csi(2) - d(2), o(2)), min(csi(2) + d(2), c(2))];
    su = [ou(2) - o(1), ou(3) - ou(2), c(1) - ou(3)];
    sv = [ov(2) - o(2), ov(3) - ov(2), c(2) - ov(3)];
    for i = 1:3
      if su(i) > this.eps
        for j = 1:3
          if sv(j) > this.eps
            region = QuadRegion([ou(i), ov(j)], [su(i), sv(j)], 1);
            if i == 2 && j == 2
              out = this.evalSingularRegion4T(csi, p, element, region, out);
            else
              out = this.evalRegion(p, element, region, out);
            end
          end
        end
      end
    end
  end

  % Subdivides a singular region according to its image aspect ratio
  function out = subdSingularRegion(this, csi, p, element, region, out)
    depth = region.depth;
    stack = Stack(QuadRegion, 5);
    stack.push(region);
    while ~stack.isEmpty
      region = stack.pop;
      L = regionSize(element, region);
      if L(1) / L(2) >= this.minRatio
        testSubregions(region.splitU(0.5), 1);
        continue;
      end
      if L(2) / L(1) >= this.minRatio
        testSubregions(region.splitV(0.5), 2);
        continue;
      end
      out = this.evalSingularRegion(csi, p, element, region, out);
    end

    function testSubregions(subregions, d)
      for i = 1:2
        subregion = subregions(i);
        o = subregion.o(d);
        c = subregion.s(d) + o;
        % If the load point is within the subregion, push it into the
        % stack to check its image aspect ratio
        if csi(d) + this.eps >= o && csi(d) - this.eps <= c
          stack.push(subregion);
        % Otherwise, integrate it with the outside integration scheme
        else
          subregion.depth = depth;
          out = this.evalRegion(p, element, subregion, out);
        end
      end
    end
  end
end

methods (Static, Access = private)
  function out = initResults(element)
    c = zeros(3, 3);
    n = 3 * element.nodeCount;
    h = zeros(3, n);
    g = zeros(3, n);
    out = struct('c', c, 'h', h, 'g', g, 'x', []);
  end

  function n = ruleSizeByBeer(R, L)
    assert(R > 0);
    idx = find((R / L) > KelvinIntegrator.tableBeer);
    n = idx(1) + 1; % n in [2,8]
  end

  function b = isEqual(x, y)
    b = abs(x - y) <= KelvinIntegrator.eps;
  end
end

end % KelvinIntegrator
