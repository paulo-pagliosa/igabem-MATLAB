function mi = testCylinderError(idx)
% Errors on cylinder
%
% Author: M. Peres
% Last revision: 01/10/2024
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
% plots curves of the "exact" and computed radial displacements on a
% line crossing the model. These values were used to generate
% Figure 26 of the paper. Also, it shows a color map of the relative
% error as in Figure 25(b).
%
% See also: testCylinder
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
Edr2 = E * dr2;
% Compute the internal pressure corresponding to the radial
% displacement u = 0.01
u = 0.01;
r = ri;
P = (u / ((1 - nu) * r + (ro2 * (1 + nu)) / r) * E * dr2) / ri2;
fprintf('Internal pressure: %g\n', P);
% Function that computes the "exact" displacements
u_r = @(r) P * ri2 / Edr2 * ((1 - nu) * r + ((ro2 * (1 + nu)) / r));
% Plot the "exact" displacements
np = 40;
x = zeros(np + 1, 1);
y = zeros(np + 1, 1);
d = (ro - ri) / np;
for i = 1:np + 1
  r = ri + (i - 1) * d;
  x(i) = r;
  y(i) = u_r(r);
end
plot(x, y);
set(gcf, 'Name', 'Radial displacements');
hold on;
% Compute boundary displacements using an EPP and plot them
pi = [ri, 0, 2];
po = [ro, 0, 2];
p = zeros(np + 1, 3);
epp = EPP(mesh, m);
epp.set('srMethod', 'TR');
d = (po - pi) / np;
for i = 1:np + 1
  p(i, :) = pi + (i - 1) * d;
  x(i) = p(i, 1);
end
u = epp.computeDisplacements(p);
y = u(:, 1);
plot(x, y);
hold off;
% Compute relative errors using a VectorComponentErrorField,...
avHandle = @(~, p, ~) u_r(sqrt(p(1) ^ 2 + p(2) ^ 2));
errorField = VectorComponentErrorField('u', 'xyz', avHandle);
%...open a mesh interface,...
mi = MeshInterface(mesh);
%...and show them as in Figure 25(b) of the paper
mi.setScalars(errorField);
mi.setColorTable(blackBody);
mi.showColorMap;
mi.showColorBar;
mi.showPatchEdges(false);
