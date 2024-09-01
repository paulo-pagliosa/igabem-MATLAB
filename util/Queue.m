classdef Queue < handle
% Queue: queue class
%
% Author: Paulo Pagliosa
% Last revision: 31/08/2024
%
% Description
% ===========
% An object of the class Queue represents a queue of numeric values.
% The class defines methods to add into and remove from the queue, check
% if the queue is empty, and tranform the queue into an array.

%% Public read-only properties
properties (SetAccess = private)
  DEFAULT_SIZE = 10;
  size;
end

%% Private properties
properties (GetAccess = private, SetAccess = private)
  data;
end

%% Public methods
methods
  function this = Queue(capacity)
  % Constructs a queue. The input parameter CAPACITY defines the
  % initial capacity of the queue
    if nargin < 1 || capacity < this.DEFAULT_SIZE
      capacity = this.DEFAULT_SIZE;
    end
    this.data = zeros(capacity, 1);
    this.size = 0;
  end

  function add(this, value)
  % Adds a value at the tail of this queue
    n = length(value);
    s = this.size - length(this.data) + n;
    if s > 0
      s = this.roundSize(s, this.DEFAULT_SIZE);
      this.data = [this.data; zeros(s, 1)];
    end
    s = this.size + 1;
    this.size = this.size + n;
    this.data(s : this.size) = value;
  end

  function d = toArray(this)
  % Transforms this queue into an array
    d = this.data(1 : this.size);
  end

  function head = remove(this)
  % Removes the value from the head of this queue
    if this.size == 0
      error('Empty queue');
    end
    head = this.data(1);
    last = this.size;
    this.size = this.size - 1;
    this.data(1 : this.size) = this.data(2 : last);
  end

  function b = isEmpty(this)
  % Is this empty empty?
    b = this.size == 0;
  end
end

%% Private static methods
methods (Access = private, Static)
  function n = roundSize(size, n)
    n = floor((size + n - 1) / n) * n;
  end
end

end % Queue
