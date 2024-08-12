classdef Stack < handle
% Stack: stack class
%
% Author: Paulo Pagliosa
% Last revision: 12/08/2024
%
% Description
% ===========
% An object of the class Stack represents a stack of objects.
% The class defines methods to push into and pop from the stack, and check
% if the stack is empty.

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
  % Constructs a stack. The parameters 'obj' and 'capacity' defines
  % the type of object ('obj' can be defaulted constructed) and the
  % initial capacity of the stack, respectively
  function this = Stack(obj, capacity)
    if nargin < 2 || capacity < this.DEFAULT_SIZE
      capacity = this.DEFAULT_SIZE;
    end
    temp(capacity) = obj;
    this.data = temp;
    this.size = 0;
  end

  % Pushes an array of objects onto the top of this stack
  function push(this, objs)
    n = numel(objs);
    s = this.size;
    this.size = this.size + n;
    this.data(s + 1:this.size) = objs;
  end

  % Pops an object from the top of this stack
  function obj = pop(this)
    if this.size == 0
      error('Empty stack');
    end
    obj = this.data(this.size);
    this.size = this.size - 1;
  end

  % Is this stack empty?
  function b = isEmpty(this)
    b = this.size == 0;
  end
end

end % Stack
