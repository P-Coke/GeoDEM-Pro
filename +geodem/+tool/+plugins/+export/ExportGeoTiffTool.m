classdef ExportGeoTiffTool
    %EXPORTGEOTIFFTOOL GeoTIFF export plugin.

    methods (Static)
        function spec = spec()
            P = @(varargin) geodem.tool.ToolParameterSpec(varargin{:});
            spec = geodem.tool.ToolSpec("export_geotiff", "GeoTIFF 导出", ...
                "导出当前 DEM/差分栅格为 GeoTIFF。", ...
                "成果输出", "GIS", "geotiff", [
                    P("outputDir", "输出目录", "text", "")
                ], @geodem.tool.plugins.export.ExportGeoTiffTool.run);
            spec.ValidateFcn = @geodem.tool.plugins.export.ExportGeoTiffTool.validate;
        end

        function [isValid, messages] = validate(project, params)
            messages = geodem.tool.ToolValidator.validateSchema(geodem.tool.plugins.export.ExportGeoTiffTool.spec(), project, params);
            if isempty(project.layerNamesByType("dem")) && isempty(project.activeDeformation())
                messages(end + 1, 1) = "没有可导出的 DEM 或差分栅格。"; %#ok<AGROW>
            end
            [isValid, messages] = geodem.tool.ToolValidator.finish(messages);
        end

        function result = run(ctx, params)
            outputDir = geodem.tool.ToolRegistry.getString(params, "outputDir", fullfile(ctx.Project.outputDir, 'data'));
            if strlength(outputDir) == 0, outputDir = fullfile(ctx.Project.outputDir, 'data'); end
            if ~exist(outputDir, 'dir'), mkdir(outputDir); end
            count = 0;
            names = ctx.Project.layerNamesByType("dem");
            for i = 1:numel(names)
                dem = geodem.tool.ToolRegistry.getDemByLayer(ctx.Project, names(i));
                fileName = string(geodem.model.ProjectState.layerKey(names(i))) + ".tif";
                geodem.service.export.exportGeoTiff(dem, ctx.Project.spatialReference, fullfile(outputDir, char(fileName)));
                count = count + 1;
            end
            deformationKeys = fieldnames(ctx.Project.deformations);
            for i = 1:numel(deformationKeys)
                deformation = ctx.Project.deformations.(deformationKeys{i});
                geodem.service.export.exportGeoTiff(deformation, ctx.Project.spatialReference, fullfile(outputDir, [deformationKeys{i} '.tif']));
                count = count + 1;
            end
            result = geodem.tool.ToolResult("Messages", sprintf('GeoTIFF 导出完成：%d 个文件。', count));
        end
    end
end
