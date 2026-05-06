classdef ExportResultsTool
    %EXPORTRESULTSTOOL Bulk result export plugin.

    methods (Static)
        function spec = spec()
            P = @(varargin) geodem.tool.ToolParameterSpec(varargin{:});
            spec = geodem.tool.ToolSpec("export_results", "导出成果", ...
                "导出图件、表格、GeoTIFF、Shapefile 和工程文件。", ...
                "成果输出", "Workflow", "export", [
                    P("imagePng", "PNG 图件", "logical", true)
                    P("imagePdf", "PDF 图件", "logical", true)
                ], @geodem.tool.plugins.export.ExportResultsTool.run);
            spec.ValidateFcn = @geodem.tool.plugins.export.ExportResultsTool.validate;
        end

        function [isValid, messages] = validate(project, params)
            messages = geodem.tool.ToolValidator.validateSchema(geodem.tool.plugins.export.ExportResultsTool.spec(), project, params);
            if isempty(project.layers)
                messages(end + 1, 1) = "当前工程没有可导出的图层。"; %#ok<AGROW>
            end
            [isValid, messages] = geodem.tool.ToolValidator.finish(messages);
        end

        function result = run(ctx, params)
            formats = {};
            if geodem.tool.ToolRegistry.getLogical(params, "imagePng", true), formats{end + 1} = 'png'; end %#ok<AGROW>
            if geodem.tool.ToolRegistry.getLogical(params, "imagePdf", true), formats{end + 1} = 'pdf'; end %#ok<AGROW>
            if isempty(formats), formats = {'png'}; end
            outputs = geodem.service.export.exportResults(ctx.Project, struct('outputDir', ctx.Project.outputDir, 'imageFormats', {formats}, 'data', true, 'images', true));
            result = geodem.tool.ToolResult("Messages", "成果已导出到：" + string(outputs.OutputDir), "Stats", outputs);
        end
    end
end
