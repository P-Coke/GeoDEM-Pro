function profile = profileAnalysis(baseDem, monitorDem, startPoint, endPoint, sampleCount)
%PROFILEANALYSIS Sample two DEMs and their difference along a line.

if nargin < 5 || isempty(sampleCount)
    sampleCount = 200;
end
sampleCount = max(2, round(sampleCount));
startPoint = double(startPoint(:)');
endPoint = double(endPoint(:)');
if numel(startPoint) ~= 2 || numel(endPoint) ~= 2
    error('GeoDEM:InvalidProfileLine', 'Profile start and end points must be [x y].');
end
lineLength = hypot(endPoint(1) - startPoint(1), endPoint(2) - startPoint(2));
if lineLength <= eps
    error('GeoDEM:InvalidProfileLine', 'Profile start and end points cannot be the same.');
end

t = linspace(0, 1, sampleCount)';
x = startPoint(1) + (endPoint(1) - startPoint(1)) .* t;
y = startPoint(2) + (endPoint(2) - startPoint(2)) .* t;
distance = hypot(x - x(1), y - y(1));
baseZ = interp2(baseDem.XGrid(1, :), baseDem.YGrid(:, 1), baseDem.Z, x, y, 'linear', NaN);
monitorZ = interp2(monitorDem.XGrid(1, :), monitorDem.YGrid(:, 1), monitorDem.Z, x, y, 'linear', NaN);
deltaZ = monitorZ - baseZ;
valid = isfinite(baseZ) & isfinite(monitorZ) & isfinite(deltaZ);
if ~any(valid)
    error('GeoDEM:ProfileNoValidSamples', 'Profile line does not intersect valid cells in both DEMs.');
end

profile = table(distance, x, y, baseZ, monitorZ, deltaZ, valid, ...
    'VariableNames', {'Distance','X','Y','BaseDEM','MonitorDEM','DeltaZ','Valid'});
end
