function outputs = exportContoursShapefile(deformationResult, filePath)
%EXPORTCONTOURSSHAPEFILE Export contour lines and max subsidence point.

if isempty(deformationResult)
    error('GeoDEM:MissingDeformation', 'No deformation result is available for Shapefile export.');
end
if nargin < 2 || isempty(filePath)
    filePath = fullfile(pwd, 'subsidence_contours.shp');
end
filePath = char(filePath);
[folder, baseName, ext] = fileparts(filePath);
if isempty(ext)
    ext = '.shp';
end
if isempty(folder)
    folder = pwd;
end
if ~exist(folder, 'dir')
    mkdir(folder);
end
contourPath = fullfile(folder, [baseName ext]);
pointPath = fullfile(folder, [baseName '_max_subsidence' ext]);

lines = deformationResult.contours.Lines;
if isempty(lines)
    contourStruct = struct('Geometry', {}, 'X', {}, 'Y', {}, 'Level', {});
else
    contourStruct(numel(lines)) = struct('Geometry', 'Line', 'X', [], 'Y', [], 'Level', NaN);
    for i = 1:numel(lines)
        contourStruct(i).Geometry = 'Line';
        contourStruct(i).X = lines(i).X;
        contourStruct(i).Y = lines(i).Y;
        contourStruct(i).Level = lines(i).Level;
    end
end
if ~isempty(contourStruct)
    shapewrite(contourStruct, contourPath);
end

p = deformationResult.maxSubsidencePoint;
pointStruct = struct('Geometry', 'Point', 'X', p.X, 'Y', p.Y, 'DeltaZ', p.DeltaZ, ...
    'BaseDEM', p.BaseDEM, 'MonitorDEM', p.MonitorDEM);
shapewrite(pointStruct, pointPath);
outputs = struct('Contours', contourPath, 'MaxSubsidencePoint', pointPath);
end
