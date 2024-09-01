classdef CameraGismo < handle
% CameraGismo: camera gismo class
%
% Author: Paulo Pagliosa
% Last revision: 31/08/2024
%
% Description
% ===========
% An object of the class CameraGismo is rendered as a small cube
% representing a camera orientation. The positive directions of the
% camera axis x, y, and z are represented by the cube faces filled in red,
% green, and blue, respectively. The negative directions are represented
% by the faces with diagonal lines in the same colors. A camera gismo is
% drawn on axes passed as an argument in the constructor.

%% Dependent properties
properties (Dependent)
  view;
  visible;
end

%% Public read-only properties
properties (SetAccess = private)
  axes;
  client;
end

%% Public methods
methods
  function this = CameraGismo(client)
  % Constructs a camera gismo
    assert(isa(client, 'matlab.graphics.axis.Axes'), 'Axes expected');
    this.axes = CameraGismo.makeAxes(client);
    this.client = client;
    this.render;
  end

  function value = get.view(this)
  % Returns the view of this camera gismo
    value = this.axes.View;
  end

  function set.view(this, value)
  % Sets the view of this camera gismo
    this.axes.View = value;
  end

  function set.visible(this, value)
  % Shows/hides this camera gismo
    set(this.axes.Children, 'Visible', value);
  end
end

%% Private methods
methods (Access = private)
  function renderLine(this, p1, p2, color)
    line('Parent', this.axes, ...
      'Color', color, ...
      'LineWidth', 2, ...
      'XData', [p1(1) p2(1)], ...
      'YData', [p1(2) p2(2)], ...
      'ZData', [p1(3) p2(3)]);
  end

  function render(this)
    v = [0 0 0; 1 0 0; 1 1 0; 0 1 0; 0 0 1; 1 0 1; 1 1 1; 0 1 1];
    f = [1 5 8 4; 6 2 3 7; 1 2 6 5; 8 7 3 4; 2 1 4 3; 5 6 7 8];
    b = [1 1 1];
    c = [b; 1 0 0; b; 0 1 0; b; 0 0 1];
    patch('Parent', this.axes, ...
      'Vertices', v, ...
      'Faces', f, ...,
      'FaceVertexCData', c, ...,
      'FaceColor', 'flat', ...
      'EdgeColor', 'black');
    this.renderLine(v(1, :), v(8, :), [1 0 0]);
    this.renderLine(v(5, :), v(4, :), [1 0 0]);
    this.renderLine(v(1, :), v(6, :), [0 1 0]);
    this.renderLine(v(2, :), v(5, :), [0 1 0]);
    this.renderLine(v(2, :), v(4, :), [0 0 1]);
    this.renderLine(v(1, :), v(3, :), [0 0 1]);
  end
end

%% Private static methods
methods (Static, Access = private)
  function a = makeAxes(client)
    f = client.Parent;
    a = axes(f);
    axis(a, 'square', 'equal', 'tight', 'vis3d');
    x = 30;
    y = 40;
    s = 50;
    set(a, 'Visible', 'off', ...
      'Clipping', 'off', ...
      'Units', 'pixels', ...,
      'Position', [x, y, s, s], ...
      'Projection', client.Projection, ...
      'View', client.View);
  end
end

end % CameraGismo
