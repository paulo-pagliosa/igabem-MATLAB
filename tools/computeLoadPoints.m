function mesh = computeLoadPoints(mesh, eps, dlp)
% Computes the load points from a mesh with no LTHs
%
% Author: Paulo Pagliosa
% Last revision: 05/09/2024
%
% Input
% =====
% MESH: mesh with no LTHs
% EPS: precision to compare point positions (default: 1e-6)
% DLP: parametric distance to shift load points at corners or on
% boundary edges (default: 0.2)
%
% Output
% ======
% MESH: mesh with load points
%
% Description
% ===========
% Define collocation points as described in Section 4.4 of the paper.
% It is assumed the input mesh has no semi-discontinuous elements.
% Thus, for a mesh resulting in a surface with boundaries, this
% function must be called  BEFORE using the function readMesh to
% combine it with others. Also, it is assumed the input mesh does not
% contain linked tangency handles or virtual vertices (in these cases,
% the C++ pre-processor must be used to define collocation points)
%
% See also: function readMesh
  assert(isa(mesh, 'Mesh'), 'Mesh expected');
  ne = mesh.elementCount;
  assert(ne > 0, 'No elements in mesh');
  if nargin < 2
    eps = 1e-6;
  end
  if nargin < 3
    dlp = 1 / 5;
  end
  nn = mesh.nodeCount;
  lp_p = zeros(nn, 3);
  lp_nid = zeros(nn, 1);
  lp_element = cell(nn, 1);
  lp_lpk = cell(nn, 1);
  element_pidx = zeros(ne, 4);
  ip = 0;
  c_lc = [-1 -1; 1 -1; 1 1; -1 1];
  for e = 1:ne
    element = mesh.elements(e);
    face = element.face;
    emptyFace = face.isEmpty;
    for k = 1:4
      lp = c_lc(k, :);
      p = element.positionAt(lp(1), lp(2));
      pidx = findPoint(p, lp_p(1:ip, :), eps);
      if isempty(pidx)
        ip = ip + 1;
        lp_p(ip, :) = p;
        lp_element{ip} = element;
        lp_lpk{ip} = k;
        element_pidx(e, k) = ip;
        if ~emptyFace && ~isempty(face.nodes(k))
          lp_nid(ip) = face.nodes(k).id;
        else
          lp_nid(ip) = ip;
        end
      else
        temp_e = lp_element{pidx};
        lp_element{pidx} = [temp_e; element];
        temp_k = lp_lpk{pidx};
        lp_lpk{pidx} = [temp_k; k];
        element_pidx(e, k) = pidx;
      end
    end
  end
  fprintf('Number of nodes: %d\n', nn);
  fprintf('Number of load points: %d\n', ip);
  assert(nn == ip, 'Number of nodes and load points do not match');
  %fprintf('%10.4f %10.4f %10.4f\n', lp_p');
  d_map = cell(4);
  d_map{1, 2} = [1 0]; d_map{2, 1} = [-1 0];
  d_map{2, 3} = [0 1]; d_map{3, 2} = [0 -1];
  d_map{4, 3} = [1 0]; d_map{3, 4} = [-1 0];
  d_map{1, 4} = [0 1]; d_map{4, 1} = [0 -1];
  for i = 1:nn
    nid = lp_nid(i);
    %fprintf('Setting LP %d\n', nid);
    lp = handleBorder(lp_lpk{i}, lp_element{i});
    mesh.nodes(nid).loadPoint = LoadPoint(lp_element{i}, lp);
  end

  function pidx = findPoint(p, points, eps)
    [np, ~] = size(points);
    if np == 0
      pidx = [];
      return;
    end
    dist = zeros(np, 1);
    dist = dist + (points(:, 1) - p(1)) .^ 2;
    dist = dist + (points(:, 2) - p(2)) .^ 2;
    dist = dist + (points(:, 3) - p(3)) .^ 2;
    pidx = 1:np;
    pidx = pidx(dist <= eps * eps);
  end

  function lp = handleBorder(lpk, elements)
    lp = c_lc(lpk, :);
    [n, ~] = size(lpk);
    switch n
      case 1 % corner
        lp = sign(lp) * (1 - dlp);
      case 2 % edge
        k1 = [lpk(1) - 1, lpk(1) + 1];
        k2 = [lpk(2) - 1, lpk(2) + 1];
        for d = 1:2
          if k1(d) < 1
            k1(d) = 4;
          elseif k1(d) > 4
            k1(d) = 1;
          end
          if k2(d) < 1
            k2(d) = 4;
          elseif k2(d) > 4
            k2(d) = 1;
          end
        end
        ev = findEdgeVertex(k1, k2);
        assert(~isempty(ev), 'No common edge for adjacent elements');
        for d = 1:2
          lp(d, :) = lp(d, :) + d_map{lpk(d), ev(d)} * dlp;
        end
    end
    function ev = findEdgeVertex(k1, k2)
      ev = [];
      for f = 1:2
        v1 = k1(f);
        p1 = element_pidx(elements(1).id, v1);
        for s = 1:2
          v2 = k2(s);
          p2 = element_pidx(elements(2).id, v2);
          if p1 == p2
            ev = [v1 v2];
            return;
          end
        end
      end
    end
  end
end % computeLoadPoints
