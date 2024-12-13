function [vdata, fdata] = readXOBJ(filename)
% Reads an extended OBJ file
%
% Author: Paulo Pagliosa
% Last revision: 12/12/2024
%
% Input
% =====
% FILENAME: OBJ filename
%
% Output
% ======
% VDATA: array with the coordinates of the object vertices, a vertex
% per row. The number of columns is 3 for Cartesian coordinates or 4
% for homogeneous coordinates
% FDATA: cell array in which a cell, F=FDATA{I}, I=1:NUMEL(FDATA),
% is an array with the object faces having SIZE(F,2) vertex indices
% per row
  vdata = [];
  fdata = {};
  [file, errmsg] = fopen(filename, 'r');
  if file == -1
    error(errmsg);
  end
  nv = 0;
  nf = 0;
  f4 = [];
  f3 = [];
  fx = {};
  fprintf('**Reading file %s...', filename);
  while ~feof(file)
    line = fgetl(file);
    if line == -1
      continue;
    end
    [type, ~, ~, nidx] = sscanf(line, '%s' , 1);
    switch type
      case 'v'
        [v, n] = sscanf(line(nidx:end), '%f');
        if n < 3 || n > 4
          error('Bad vertex');
        end
        nv = nv + 1;
        vdata = [vdata; v']; %#ok
      case 'f'
        nf = nf + 1;
        % TODO: read v/t, v/t/n, v//n
        [f, n] = sscanf(line(nidx:end), '%f');
        switch n
          case 4
            f4 = [f4; f']; %#ok
          case 3
            f3 = [f3; f']; %#ok
          otherwise
            if n < 3
              error('Bad face');
            end
            fn = [];
            kn = numel(fx) + 1;
            for i=1:kn - 1
              temp = fx{i};
              if n == size(temp, 2)
                fn = temp;
                kn = i;
                break;
              end
            end
            fx{kn} = [fn; f']; %#ok
        end
    end
  end
  fclose(file);
  if ~isempty(f4)
    fdata = [fdata, f4];
  end
  if ~isempty(f3)
    fdata = [fdata, f4];
  end
  if ~isempty(fx)
    fdata = [fdata, fx];
  end
  fprintf('\n**Done\nVertices: %d\nFaces: %d\n', nv, nf);
end % readXOBJ
