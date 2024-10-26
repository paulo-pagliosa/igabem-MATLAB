function epp = testCylinderStress(idx)
% Tests cylinder stresses
%
% Author: Paulo Pagliosa
% Last revision: 26/10/2024
%
% Input
% =====
% IDX: index of the mesh file 'cylinderN.be', where the number
% of elements, N, is 96 (IDX=1), 144 (IDX=2), 216 (IDX=3), or
% 384 (IDX=4)
%
% Output
% ======
% MI: MeshInterface object showing the mesh
%
% Description
% ===========
% This function runs the analysis of a hollow cylinder subject to an
% internal pressure as described in Section 7.1 of the paper. It
% plots curves of the "exact" and computed radial stresses on a
% line crossing the model.
%
% See also: testCylinderError
filenames = ["cylinder96.be"; ...
  "cylinder144.be"; ...
  "cylinder216.be"; ...
  "cylinder384.be"];
modelCount = numel(filenames);
if nargin == 0
  help("testCylinderError");
  return;
end
if idx < 1 || idx > modelCount
  fprintf("IDX must be in [1,%d]\n", modelCount);
  return;
end
folder = "tests/cylinder/";
% Load the mesh and results
filename = strcat(folder, filenames(idx));
a = strcat(filename, '.mat');
if ~exist(a, 'file')
  fprintf("%s not found: Call testCylinder(%d)\n", a, idx);
  return;
end
a = load(a, 'mesh');
mesh = a.mesh;
clear a;
% Create the material
E = 1e5;
nu = 0;
m = Material(E, nu);
% Set some constants
ri = 0.5;
ro = 1;
ri2 = ri * ri;
ro2 = ro * ro;
dr2 = ro2 - ri2;
% Compute the internal pressure corresponding to the radial
% displacement u = 0.01
u = 0.01;
r = ri;
P = (u / ((1 - nu) * r + (ro2 * (1 + nu)) / r) * E * dr2) / ri2;
fprintf('Internal pressure: %g\n', P);
% Function that computes the "exact" radial stresses
s_r = @(r) P * ri2 / dr2 * (1 - ro2 / r ^ 2);
% Plot the "exact" radial stresses
np = 40;
x = zeros(np + 1, 1);
y = zeros(np + 1, 1);
p = zeros(np + 1, 3);
dr = (ro - ri) / np;
O = [0 0 2];
D = [1 0 0];
pi = ri * D + O;
dp = dr * D;
for i = 1:np + 1
  p(i, :) = pi + (i - 1) * dp;
  x(i) = ri + (i - 1) * dr;
  y(i) = s_r(x(i));
end
plot(x, y);
set(gcf, 'Name', 'Radial stresses');
hold on;
% Compute radial stresses using an EPP and plot them
epp = EPP(mesh, m);
epp.set('srMethod', 'TR');
s = epp.computeStresses(p);
t = zeros(np + 1, 1);
for i = 1:np + 1
  sp = s(:, :, i) * D';
  t(i) = D * sp;
end
plot(x, t);
hold off;
[minS, maxS] = bounds(y);
E = abs(t - y);
fprintf("Max absolute error: %g in [%g:%g]\n", max(E), minS, maxS);
e = y ~= 0;
x = x(e);
y = y(e);
t = t(e);
e = abs((t - y) ./ y);
[max_e, i] = max(e);
fprintf("Max relative error: %.3g%% (r: %g exact: %g BEA: %g)\n", ...
  max_e * 100, ...
  x(i), ...
  y(i), ...
  t(i));
