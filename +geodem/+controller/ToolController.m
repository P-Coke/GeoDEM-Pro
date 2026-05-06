classdef ToolController < handle
    %TOOLCONTROLLER Owns geoprocessing tool selection and execution.

    properties
        App
    end

    methods
        function obj = ToolController(app)
            obj.App = app;
        end

        function preprocessClouds(obj), obj.selectAndRun("clean_pointcloud"); end
        function extractCommonArea(obj), obj.selectAndRun("common_extent"); end
        function buildDems(obj), obj.selectAndRun("build_dem"); end
        function analyzeDeformation(obj), obj.selectAndRun("dem_difference"); end
        function runOneClick(obj), obj.selectAndRun("workflow_analysis"); end
        function exportResults(obj), obj.selectAndRun("export_results"); end
        function generateReport(obj), obj.selectAndRun("generate_report"); end
        function exportGeoTiff(obj), obj.selectAndRun("export_geotiff"); end
        function exportShapefile(obj), obj.selectAndRun("export_shapefile"); end
        function compareMethods(obj), obj.selectAndRun("compare_methods"); end
        function runProfile(obj), obj.selectAndRun("profile_analysis"); end

        function activateProfileAnalysis(obj)
            obj.selectTool("profile_analysis");
            obj.App.setActiveMapTool("profile");
        end

        function selectTool(obj, toolId)
            app = obj.App;
            spec = geodem.tool.ToolRegistry.get(toolId);
            app.SelectedToolId = string(toolId);
            key = matlab.lang.makeValidName(char(spec.Id));
            if isfield(app.Project.toolDefaults, key)
                defaults = app.Project.toolDefaults.(key);
            else
                defaults = struct();
            end
            app.View.showTool(spec, defaults, app.Project);
        end

        function resetSelectedToolDefaults(obj)
            app = obj.App;
            if strlength(app.SelectedToolId) == 0
                return;
            end
            key = matlab.lang.makeValidName(char(app.SelectedToolId));
            if isfield(app.Project.toolDefaults, key)
                app.Project.toolDefaults = rmfield(app.Project.toolDefaults, key);
            end
            obj.selectTool(app.SelectedToolId);
            app.log('已重置当前工具参数。');
        end

        function runSelectedTool(obj, params)
            app = obj.App;
            if strlength(app.SelectedToolId) == 0
                error('GeoDEM:NoSelectedTool', '请先选择一个工具。');
            end
            if nargin < 2 || isempty(params)
                params = app.View.readToolParameters();
            end
            spec = geodem.tool.ToolRegistry.get(app.SelectedToolId);
            [isValid, messages] = spec.validate(app.Project, params);
            if ~isValid
                error('GeoDEM:InvalidToolParameters', '%s', strjoin(messages, newline));
            end
            app.runSafely(@() obj.runTool(app.SelectedToolId, params));
        end

        function runTool(obj, toolId, params)
            geodem.controller.ToolRunner.run(obj.App, toolId, params);
        end
    end

    methods (Access = private)
        function selectAndRun(obj, toolId)
            obj.selectTool(toolId);
            obj.runSelectedTool();
        end
    end
end
