classdef ToolContext < handle
    %TOOLCONTEXT Runtime context passed from controller to a tool.

    properties
        Project
        ProjectRoot = ""
        OutputDir = ""
        ActiveLayer = ""
        SelectedLayers = strings(0, 1)
        LogFcn = []
    end

    methods
        function obj = ToolContext(project, projectRoot, outputDir, activeLayer, selectedLayers, logFcn)
            if nargin >= 1, obj.Project = project; end
            if nargin >= 2, obj.ProjectRoot = string(projectRoot); end
            if nargin >= 3, obj.OutputDir = string(outputDir); end
            if nargin >= 4, obj.ActiveLayer = string(activeLayer); end
            if nargin >= 5, obj.SelectedLayers = string(selectedLayers); end
            if nargin >= 6, obj.LogFcn = logFcn; end
        end

        function log(obj, message)
            if ~isempty(obj.LogFcn)
                obj.LogFcn(message);
            elseif ~isempty(obj.Project)
                obj.Project.addLog(message);
            end
        end
    end
end
