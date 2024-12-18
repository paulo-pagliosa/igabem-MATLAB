classdef CameraGismo < handle
% CameraGismo: camera gismo class
%
% Author: Paulo Pagliosa
% Last revision: 18/12/2024
%
% Description
% ===========
% An object of the class CameraGismo is rendered as a small cube
% representing a camera orientation. The positive directions of the
% camera axis x, y, and z are represented by the cube faces filled in red,
% green, and blue, respectively. The negative directions are represented
% by the faces with diagonal lines in the same colors. A camera gismo is
% drawn on the axes passed as an argument in the constructor.

%% Dependent properties
properties (Dependent)
  view;
  visible;
end

%% Public read-only properties
properties (SetAccess = private)
  axes;
  client;
  location = "";
end

%% Public methods
methods
  function this = CameraGismo(client, location)
  % Constructs a camera gismo
    assert(isa(client, 'matlab.graphics.axis.Axes'), 'Axes expected');
    this.axes = CameraGismo.makeAxes(client);
    this.client = client;
    if nargin < 2
      location = "SW";
    end
    this.setLocation(location);
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

  function setLocation(this, location)
  % Sets the location of this camera gismo w.r.t. its figure
    location = upper(location);
    i = find(CameraGismo.locations == location);
    if isempty(i)
      error('Bad camera gismo location');
    end
    if i ~= this.locationIndex
      this.location = location;
      this.locationIndex = i;
      this.update;
    end
  end

  function update(this)
  % Updates this camera gismo
    s = 50;
    x = 30;
    y = 30;
    b = CameraGismo.locationBits(this.locationIndex);
    if b % SW
      p = this.axes.Parent.Position;
      switch bitand(b, 0b0011)
        case 1
          x = p(3) - (x + s);
        case 2
          x = (p(3) - s) / 2;
      end
      switch bitand(b, 0b1100)
        case 4
          y = p(4) - (y + s);
        case 8
          y = (p(4) - s) / 2;
      end
    end
    set(this.axes, 'Position', [x, y, s, s]);
  end

  function set.visible(this, value)
  % Shows/hides this camera gismo
    set(this.axes.Children, 'Visible', value);
  end
end

%% Private properties
properties (Access = private, Constant)
  locations = ["SW", "SE", "S", "NW", "NE", "N"];
  % locationBits: yyxx
  % SW: 0000, SE: 0001, S: 0010
  % NW: 0100, NE: 0101, N: 0110
  locationBits = [0b0000 0b0001 0b0010 0b0100 0b0101 0b0110];
end

properties (Access = private)
  locationIndex = 0;
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
    set(a, 'Visible', 'off', ...
      'Clipping', 'off', ...
      'Units', 'pixels', ...,
      'Projection', client.Projection, ...
      'View', client.View);
  end
end

end % CameraGismo
