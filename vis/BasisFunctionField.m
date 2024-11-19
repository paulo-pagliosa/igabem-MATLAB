classdef BasisFunctionField < ScalarField
% BasisFunctionField: basis function field class
%
% Author: Paulo Pagliosa
% Last revision: 19/11/2024
%
% Description
% ===========
% An object of the class BasisFunctionField is a scalar field with
% the values of the basis function of a given mesh node.

%% Public methods
methods
  function this = BasisFunctionField(node, region)
  % Constructs a basis function field
    assert(isNonvirtual(node), 'Nonvirtual node expected');
    if nargin < 2
      region = 1;
    elseif region < 1 || region > node.multiplicity
      error('Bad node region %d for node %d', region, node.id);
    end
    label = sprintf("Basis Function %d", node.id);
    if node.multiplicity > 1
      label = sprintf("%s (region %d)", label, region);
    end
    this = this@ScalarField(@setNodalValues, label);
    initializeElements(this, node, region);

    function b = isNonvirtual(node)
      b = isa(node, 'Node') && ~node.isVirtual;
    end

    function v = setNodalValues(this, element)
      n = element.nodeCount;
      v = zeros(n, 1);
      e = this.elements == element;
      if ~isempty(e)
        v(this.localIndices(e)) = this.scale;
      end
    end
  end
end

methods (Access = private)
  function initializeElements(this, node, region)
    corner_csi = [-1, -1; 1 -1; 1 1; -1 1];
    mesh = node.mesh;
    eids = mesh.nodeElements{node.id};
    flag = false;
    for i = 1:numel(eids)
      element = mesh.elements(eids(i));
      lid = find(element.nodeIds == node.id);
      assert(~isempty(lid));
      if element.nodeRegions(lid) == region
        this.elements(end + 1) = element;
        this.localIndices(end + 1) = lid;
        if ~flag
          face = element.face;
          if face.isEmpty
            continue;
          end
          for k = 1:4
            if node == face.nodes(k)
              csi = corner_csi(k, :);
              N = element.shapeFunction.eval(csi(1), csi(2));
              N = N(lid);
              assert(N > 0);
              this.scale = 1 / N;
              flag = true;
              break;
            end
          end
        end
      end
    end
  end
end

%% Private properties
properties (Access = private)
  elements (:, 1) Element;
  localIndices (:, 1) double;
  scale (1, 1) double;
end

end % BasisFunctionField
