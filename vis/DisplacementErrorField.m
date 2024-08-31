classdef DisplacementErrorField < ErrorField
% DisplacementErrorField: displacement error field class
%
% Author: Paulo Pagliosa
% Last revision: 31/08/2024
%
% Description
% ===========
% An object of the class DisplacementErrorField is an evaluator of
% errors on a component (e.g, 'z') or the module of the vector of two
% or more components (e.g, 'xy' or 'xyz') of the displacement at a
% point on an element.

%% Private properties
properties (Access = private)
  eCount;
  uLabel;
end

%% Public methods
methods
  % Constructs a displacement error field
  %
  % Input
  % =====
  % EPP: an EPP object to evaluate the displacement at a point on
  % an element
  % DOF: char array with any combination of 'x', 'y', and 'z', or
  % an array with any combination of 1, 2, and 3. DOF defines the
  % component(s) of the displacement (evaluated by EPP) used to
  % compute measured values
  % AVHANDLE: handle to a function that returns the actual value at
  % a point on an element. The function takes as input paramaters the
  % parametric coordinates [U,V] of the point, the spatial position
  % [X,Y,Z] of the point, and a reference to the element
  %
  % See also: class EPP
  function this = DisplacementErrorField(epp, dof, avHandle)
    assert(isa(epp, 'EPP'), 'Elastostatic post-processor expected');
    assert(isa(avHandle, 'function_handle'), 'Actual values handle expected');
    dof = BC.parseDofs(dof);
    dof = dof(dof > 0);
    this = this@ErrorField(@computeValues);
    this.eCount = epp.mesh.elementCount;
    dofLabel = 'xyz';
    this.uLabel = sprintf('displacement %s', dofLabel(dof));
    this.handleErrorTypeChange;

    function [mv, av] = computeValues(csi, p, element)
      av = avHandle(csi, p, element);
      mv = epp.computeBoundaryDisplacement(csi, p, element);
      mv = mv(dof);
      if size(mv, 2) > 1
        mv = sqrt(mv * mv');
      end
    end
  end

  % Sets the element of this field
  function setElement(this, element)
    fprintf('Evaluating element %d/%d\n', element.id, this.eCount);
    setElement@ErrorField(this, element);
  end
end

%% Protected methods
methods (Access = protected)
  function handleErrorTypeChange(this)
    this.label = sprintf('%s %s', this.uLabel, this.errorLabel);
  end
end

end % DisplacementErrorField
