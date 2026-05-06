classdef ToolPluginRegistry
    %TOOLPLUGINREGISTRY Collects internal geoprocessing tool plugins.

    methods (Static)
        function specs = allSpecs()
            specs = {
                geodem.tool.plugins.pointcloud.PointCloudQualityTool.spec()
                geodem.tool.plugins.pointcloud.CleanPointCloudTool.spec()
                geodem.tool.plugins.pointcloud.DensityGridTool.spec()
                geodem.tool.plugins.pointcloud.CommonExtentTool.spec()
                geodem.tool.plugins.dem.BuildDemTool.spec()
                geodem.tool.plugins.dem.DemAccuracyTool.spec()
                geodem.tool.plugins.dem.InterpolationCompareTool.spec()
                geodem.tool.plugins.deformation.DemDifferenceTool.spec()
                geodem.tool.plugins.deformation.ProfileAnalysisTool.spec()
                geodem.tool.plugins.workflow.WorkflowAnalysisTool.spec()
                geodem.tool.plugins.export.ExportResultsTool.spec()
                geodem.tool.plugins.export.GenerateReportTool.spec()
                geodem.tool.plugins.export.ExportGeoTiffTool.spec()
                geodem.tool.plugins.export.ExportShapefileTool.spec()
            };
        end

    end
end
