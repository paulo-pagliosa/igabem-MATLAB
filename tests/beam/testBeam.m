function [mi, m] = testBeam
% Test beam
%
% Author: M. Peres
% Last revision: 29/10/2024
%
% Output
% ======
% MI: MeshInterface object showing the mesh
% M: material used in BEA
%
% Description
% ===========
% This function runs the analysis of the beam with semi-discontinuous
% elements as described in Section 7.2.
  name = 'tests/beam/beam';
  filename = [name '.be'];
  a = strcat(filename, '.mat');
  solved = exist(a, 'file');
  if solved
    % Load the mesh
    a = load(a, 'mesh');
    mesh = a.mesh;
    clear a;
  else
    % Read the mesh
    mesh = readMesh(char(filename));
    mesh.name = 'beam';
    % Compute the load points
    computeLoadPoints(mesh);
  end
  mi = MeshInterface(mesh);
  % Create the material
  m = Material(1e5,0.3);
  if ~solved
    eid_ends = [3, 221];
    eid_t1 = 198;
    eid_t2 = 160;
    eid_t3 = 107;
    eid_t4 = 53;
    % Apply the boundary conditions: contraints...
    mi.selectRegions(eid_ends);
    mi.makeConstraint('xyz', 0);
    % ...and loads
    t1 = 2;
    t2 = 1;
    t3 = 6;
    t4 = 4;
    mi.selectRegions(eid_t1);
    mi.makeLoad([0, 0, +t1]);
    mi.selectRegions(eid_t2);
    mi.makeLoad([0, +t2, 0]);
    mi.selectRegions(eid_t3);
    mi.makeLoad([0, 0, -t3]);
    mi.selectRegions(eid_t4);
    mi.makeLoad([0, -t4, 0]);
    mi.deselectAllElements;
    % Create and run the solver
    solver = ElastostaticSolver(mesh, m);
    solver.set('srMethod', 'TR');
    solver.set('minRatio', 1);
    solver.execute();
    % Save the mesh and results
    save(a, 'mesh');
  end
  % Figure 30(b) of the paper
  mi.setView(132, 15);
  mi.showPatchEdges(false);
  mi.deformMesh(100);
  mi.setUndeformedMeshAlpha(0);
  mi.setScalars('u', 'z');
  mi.setColorTable(coolWarm);
  mi.showColorMap;
  mi.showColorBar;
end % testBeam
