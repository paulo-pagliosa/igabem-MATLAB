classdef IntegrationHandle < handle
% IntegrationHandle: integration handle class
%
% Author: Paulo Pagliosa
% Last revision: 07/10/2024
%
% Description
% ===========
% An object of the class IntegrationHandle encapsulates data
% used for and resulting from evaluating integrals over an
% element, which depends on the load point, the BIE kernels,
% and the analysis solver or post-processor.

%% Public properties
properties
  data; % integration-dependent data
  x (:, 3) double; % Gauss points
end

%% Public read-only properties
properties (SetAccess = private)
  solver;
  element Element;
end

%% Private properties
properties (Access = {?IntegrationHandle, ?EPBase})
  initData = @IntegrationHandle.dflInitData;
  updateData function_handle;
end

%% Public methods
methods
  function this = IntegrationHandle(solver, initData, updateData)
  % Constructs an integration handle
    assert(isa(solver, 'EPBase'), 'Solver expected ');
    this.solver = solver;
    if nargin > 1
      this.initData = initData;
    end
    if nargin > 2
      this.updateData = updateData;
    end
  end

  function set.initData(this, value)
  % Sets the function that initializes integration data
    assert(isa(value, 'function_handle'));
    this.initData = value;
  end

  function set.updateData(this, value)
  % Sets the function that updates integration data
    assert(isa(value, 'function_handle'));
    this.updateData = value;
  end

  function setElement(this, element)
  % Initializes integration data for an element
    assert(~isempty(this.updateData), 'No updating function');
    this.element = element;
    this.initData(this);
    this.x = [];
  end

  function q = integrate(this, p, u, v, w)
  % Updates data resulting from the integration
  %
  % Input
  % =====
  % P: spatial coordinates of the load point
  % U and V: parametric coordinates of the target point
  % W: integration weight (including the region Jacobian)
  %
  % Output
  % ======
  % Q: spatial coordinates of the target point
    [q, S] = this.element.positionAt(u, v);
    [N, J] = this.element.normalAt(u, v);
    this.updateData(this, p, q, N, S, J * w);
  end
end

%% Private static methods
methods (Access = private, Static)
  function dflInitData(this, ~)
    this.data = struct;
  end
end

end % IntegrationHandle
