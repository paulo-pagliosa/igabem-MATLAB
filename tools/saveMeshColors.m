function saveMeshColors(mesh, filename)
  [colors, count] = meshColoring(mesh, true);
  nc = numel(count);
  file = fopen(filename, 'w');
  fprintf(file, '# A row specifying the number of elements and colors\n');
  fprintf(file, '%d %d\n', numel(colors), nc);
  fprintf(file, ['\n# A row per color specifying the number of elements ' ...
    'with that color\n# followed by the indices of those elements\n']);
  for i = 1:nc
    fprintf(file, '%d', count(i));
    fprintf(file, ' %d', find(colors == i) - 1);
    fprintf(file, '\n');
  end
  fclose(file);
end
