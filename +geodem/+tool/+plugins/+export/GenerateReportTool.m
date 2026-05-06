classdef GenerateReportTool
    %GENERATEREPORTTOOL HTML/DOCX report generation plugin.

    methods (Static)
        function spec = spec()
            P = @(varargin) geodem.tool.ToolParameterSpec(varargin{:});
            spec = geodem.tool.ToolSpec("generate_report", "报告生成", ...
                "生成中文 HTML/DOCX 分析报告。", ...
                "成果输出", "Workflow", "report", [
                    P("outputDir", "输出目录", "text", "")
                ], @geodem.tool.plugins.export.GenerateReportTool.run);
            spec.ValidateFcn = @geodem.tool.plugins.export.GenerateReportTool.validate;
        end

        function [isValid, messages] = validate(project, params)
            messages = geodem.tool.ToolValidator.validateSchema(geodem.tool.plugins.export.GenerateReportTool.spec(), project, params);
            if isempty(project.activeDeformation())
                messages(end + 1, 1) = "尚未生成形变分析结果。"; %#ok<AGROW>
            end
            [isValid, messages] = geodem.tool.ToolValidator.finish(messages);
        end

        function result = run(ctx, params)
            outputDir = geodem.tool.ToolRegistry.getString(params, "outputDir", ctx.Project.outputDir);
            if strlength(outputDir) == 0, outputDir = ctx.Project.outputDir; end
            reports = geodem.service.export.generateReport(ctx.Project, struct('outputDir', char(outputDir)));
            result = geodem.tool.ToolResult("Messages", "报告已生成：" + string(reports.HTML), "Stats", reports);
        end
    end
end
