classdef Stack < handle
% Stack: stack class
%
% Author: Paulo Pagliosa
% Last revision: 31/08/2024
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
  function this = Stack(obj, capacity)
  % Constructs a stack. The input parameters OBJ and CAPACITY defines
  % the type of object (OBJ can be defaulted constructed) and the
  % initial capacity of the stack, respectively
    if nargin < 2 || capacity < this.DEFAULT_SIZE
      capacity = this.DEFAULT_SIZE;
    end
    temp(capacity) = obj;
    this.data = temp;
    this.size = 0;
  end

  function push(this, objs)
  % Pushes an array of objects onto the top of this stack
    n = numel(objs);
    s = this.size;
    this.size = this.size + n;
    this.data(s + 1:this.size) = objs;
  end

  function obj = pop(this)
  % Pops an object from the top of this stack
    if this.size == 0
      error('Empty stack');
    end
    obj = this.data(this.size);
    this.size = this.size - 1;
  end

  function b = isEmpty(this)
  % Is this stack empty?
    b = this.size == 0;
  end
end

end % Stack
