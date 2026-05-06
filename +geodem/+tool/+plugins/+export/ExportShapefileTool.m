classdef ExportShapefileTool
    %EXPORTSHAPEFILETOOL Shapefile export plugin.

    methods (Static)
        function spec = spec()
            P = @(varargin) geodem.tool.ToolParameterSpec(varargin{:});
            spec = geodem.tool.ToolSpec("export_shapefile", "Shapefile 导出", ...
                "导出沉降等值线和最大沉降点 Shapefile。", ...
                "成果输出", "GIS", "shape", [
                    P("outputName", "文件名", "text", "subsidence_contours.shp")
                ], @geodem.tool.plugins.export.ExportShapefileTool.run);
            spec.ValidateFcn = @geodem.tool.plugins.export.ExportShapefileTool.validate;
        end

        function [isValid, messages] = validate(project, params)
            messages = geodem.tool.ToolValidator.validateSchema(geodem.tool.plugins.export.ExportShapefileTool.spec(), project, params);
            if isempty(project.activeDeformation())
                messages(end + 1, 1) = "尚未生成形变分析结果。"; %#ok<AGROW>
            end
            [isValid, messages] = geodem.tool.ToolValidator.finish(messages);
        end

        function result = run(ctx, params)
            deformation = ctx.Project.activeDeformation();
            if isempty(deformation)
                error('GeoDEM:MissingDeformation', '请先完成 DEM 差分分析。');
            end
            outputName = geodem.tool.ToolRegistry.getString(params, "outputName", "subsidence_contours.shp");
            dataDir = fullfile(ctx.Project.outputDir, 'data');
            if ~exist(dataDir, 'dir'), mkdir(dataDir); end
            outputs = geodem.service.export.exportContoursShapefile(deformation, fullfile(dataDir, char(outputName)));
            result = geodem.tool.ToolResult("Messages", ["沉降等值线 Shapefile：" + string(outputs.Contours); "最大沉降点 Shapefile：" + string(outputs.MaxSubsidencePoint)], "Stats", outputs);
        end
    end
end
