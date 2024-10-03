classdef ProgressBar < handle
% ProgressBar: simple progress bar class
%
% Author: Paulo Pagliosa
% Last revision: 03/10/2024

%% Public methods
methods
  function this = ProgressBar(maxSteps)
  % Constructs a progress bar
    assert(maxSteps > 0, 'Max steps must be positive');
    this.length = min(this.maxLength, maxSteps);
    this.stepLength = this.length / maxSteps;
    this.maxSteps = maxSteps;
  end

  function start(this)
  % Starts this progress bar
    fprintf('%s\n', repmat('*', 1, this.length));
    this.step = 1;
  end

  function update(this, k)
  % Updates the progress of this progress bar
    while k * this.stepLength >= this.step
      if this.step == this.maxSteps
        break;
      end
      fprintf('.');
      this.step = this.step + 1;
    end
  end
end

%% Private constant properties
properties (Access = private, Constant)
  maxLength = 40;
end

%% Private properties
properties (Access = private)
  maxSteps;
  length;
  stepLength;
  step;
end

end % ProgressBar
