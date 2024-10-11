function [mi, m] = testCylinder(idx)
% Test cylinder
%
% Author: M. Peres
% Last revision: 11/10/2024
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
% This function runs the analysis of a hollow cylinder subject
% to an internal pressure as described in Section 7.1.
filenames = ["cylinder96.be"; ...
  "cylinder144.be"; ...
  "cylinder216.be"; ...
  "cylinder384.be"];
modelCount = numel(filenames);
if nargin == 0
  help("testCylinder");
  return;
end
if idx < 1 || idx > modelCount
  fprintf("IDX must be in [1,%d]\n", modelCount);
  return;
end
folder = "tests/cylinder/";
fid = [58, 71, 134, 243];
filename = strcat(folder, filenames(idx));
% Read the mesh
mesh = readMesh(char(filename));
mesh.name = filenames(idx);
% Compute the load points
computeLoadPoints(mesh);
% Open a mesh interface
mi = MeshInterface(mesh);
% Apply the boundary conditions
u = -0.01;
mi.selectRegions(fid(idx));
mi.makeConstraint('xyz', u, 'direction', 'normal');
mi.deselectAllElements;
% Create the material
m = Material(1e5, 0);
% Create and run the solver
solver = ElastostaticSolver(mesh, m);
solver.set('srMethod', 'TR');
solver.set('minRatio', 1);
solver.execute;
% Save the mesh and results
save(strcat(filename, '.mat'), 'mesh');
% Figure 25(a) of the paper
mi.deformMesh(25);
mi.setScalars('t', 'xyz');
mi.setColorTable(coolWarm);
mi.showColorMap;
mi.showColorBar;
% To see the undeformed mesh, select some elements from
% outer and inner surface and invoke the following method:
mi.hidePatches;
mi.showPatchEdges(false);

