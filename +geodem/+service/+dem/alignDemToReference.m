function [alignedDem, didAlign] = alignDemToReference(referenceDem, movingDem, method)
%ALIGNDEMTOREFERENCE Resample a DEM onto a reference DEM grid.

if nargin < 3 || isempty(method)
    method = 'linear';
end
method = char(method);
didAlign = ~sameGrid(referenceDem, movingDem);
if ~didAlign
    alignedDem = movingDem;
    return;
end

Z = interp2(movingDem.XGrid, movingDem.YGrid, movingDem.Z, referenceDem.XGrid, referenceDem.YGrid, method, NaN);
alignedDem = geodem.model.DemRaster(referenceDem.XGrid, referenceDem.YGrid, Z, referenceDem.resolution, movingDem.method, movingDem.name);
alignedDem.qualityMetrics.AlignedToReference = true;
alignedDem.qualityMetrics.SourceRows = size(movingDem.Z, 1);
alignedDem.qualityMetrics.SourceCols = size(movingDem.Z, 2);
alignedDem.qualityMetrics.SourceXMin = movingDem.bounds.XMin;
alignedDem.qualityMetrics.SourceXMax = movingDem.bounds.XMax;
alignedDem.qualityMetrics.SourceYMin = movingDem.bounds.YMin;
alignedDem.qualityMetrics.SourceYMax = movingDem.bounds.YMax;
end

function tf = sameGrid(a, b)
tf = isequal(size(a.Z), size(b.Z));
if ~tf
    return;
end
tf = max(abs(a.XGrid(:) - b.XGrid(:)), [], 'omitnan') <= 1e-6 && ...
     max(abs(a.YGrid(:) - b.YGrid(:)), [], 'omitnan') <= 1e-6;
end
