function mi = testTee
% Test tee
%
% Author: M. Peres
% Last revision: 25/09/2024
%
% Output
% ======
% MI: MeshInterface object showing the mesh
%
% Description
% ===========
% This function runs the analysis of the tee-shaped model as
% described in Section 7.2.
  name = 'tests/tee/tee';
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
  % The T-spline faces were purposely designed with clockwise
  % orientation. We inverte the normals to fix this issue
  mi.flipVertexNormals;
  if ~solved
    eid_front = 560;
    eid_top = 322;
    eid_bottom = 571;
    % Apply the boundary conditions: loads...
    mi.selectRegions(eid_top);
    mi.makeLoad('torque', [0 0 0], [0 0 1], 20);
    mi.makeLoad([0 20 0]);
    % ...and constraints
    mi.selectRegions([eid_front eid_bottom]);
    mi.makeConstraint('xyz', 0);
    mi.deselectAllElements;
    % Create the material
    m = Material(210e3, 0.3);
    % Create and run the solver. This may take a while...
    solver = ElastostaticSolver(mesh,m);
    solver.set('srMethod', 'TR');
    solver.set('minRatio', 1);
    solver.execute;
    % Save the mesh and results
    save(a, 'mesh');
  end
  % Figure 33(a) of the paper
  mi.deformMesh(50);
  mi.setScalars('u', 'xyz');
  mi.setColorTable(coolWarm);
  mi.showColorMap;
  mi.showColorBar;
  mi.showPatchEdges(false);
end % testTee
