function [mi, m] = testPlate
% Test plate
%
% Author: M. Peres
% Last revision: 11/10/2024
%
% Output
% ======
% MI: MeshInterface object showing the mesh
% M: material used in BEA
%
% Description
% ===========
% This function runs the analysis of the thick plate with holes as
% described in Section 7.2.
  name = 'tests/plate/plate';
  filename = [name '.be'];
  a = strcat(filename, '.mat');
  solved = exist(a, 'file');
  if solved
    % Load the mesh
    a = load(a, 'mesh');
    mesh = a.mesh;
    clear a;
  else
    % Read the mesh. We use the flag '-f' since the model was
    % generated with has no element face data
    mesh = readMesh('-f', char(filename));
    mesh.name = 'tee';
  end
  mi = MeshInterface(mesh);
  % Create the material
  m = Material(210e3, 0.3);
  if ~solved
    eid_h1 = 9;
    eid_h2 = 117;
    eid_h3 = 141;
    eid_h4 = 69;
    eid_hc = 21;
    % Apply the boundary conditions: contraints...
    mi.selectRegions(eid_hc);
    mi.makeConstraint('xyz', 0);
    % ...and loads
    mi.selectRegions(eid_h1);
    mi.makeLoad(-1000, 'direction', 'normal');
    mi.selectRegions(eid_h3);
    mi.makeLoad(+1000, 'direction', 'normal');
    mi.selectRegions([eid_h2 eid_h4]);
    mi.makeLoad([0 0 100]);
    mi.deselectAllElements;
    % Create and run the solver. This may take some time...
    solver = ElastostaticSolver(mesh, m);
    solver.set('srMethod', 'TR');
    solver.set('minRatio', 1);
    solver.execute();
    % Save the mesh and results
    save(a, 'mesh');
  end
  % Figure 34(b) of the paper
  mi.deformMesh(15);
  mi.setScalars('u', 'xyz');
  mi.setColorTable(coolWarm);
  mi.showColorMap;
  mi.showColorBar;
  mi.showPatchEdges(false);
end % testPlate
