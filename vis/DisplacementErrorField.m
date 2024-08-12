classdef DisplacementErrorField < ErrorField

properties (Access = private)
  eCount;
  uLabel;
end

methods
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

  function setElement(this, element)
    fprintf('Evaluating element %d/%d\n', element.id, this.eCount);
    setElement@ErrorField(this, element);
  end
end

methods (Access = protected)
  function handleErrorTypeChange(this)
    this.label = sprintf('%s %s', this.uLabel, this.errorLabel);
  end
end

end % DisplacementErrorField
