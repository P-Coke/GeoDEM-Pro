classdef ToolSpec
    %TOOLSPEC Registry metadata and execution hook for one geoprocessing tool.

    properties
        Id = ""
        Name = ""
        Description = ""
        RibbonTab = ""
        RibbonGroup = ""
        Icon = "tool"
        Parameters = geodem.tool.ToolParameterSpec.empty(0, 1)
        ExecuteFcn = []
        ValidateFcn = []
    end

    methods
        function obj = ToolSpec(id, name, description, ribbonTab, ribbonGroup, icon, parameters, executeFcn)
            if nargin >= 1, obj.Id = string(id); end
            if nargin >= 2, obj.Name = string(name); end
            if nargin >= 3, obj.Description = string(description); end
            if nargin >= 4, obj.RibbonTab = string(ribbonTab); end
            if nargin >= 5, obj.RibbonGroup = string(ribbonGroup); end
            if nargin >= 6, obj.Icon = string(icon); end
            if nargin >= 7, obj.Parameters = parameters; end
            if nargin >= 8, obj.ExecuteFcn = executeFcn; end
        end

        function result = execute(obj, context, params)
            if isempty(obj.ExecuteFcn)
                error('GeoDEM:ToolMissingExecuteFcn', 'Tool %s has no execution function.', obj.Id);
            end
            result = obj.ExecuteFcn(context, params);
        end

        function [isValid, messages] = validate(obj, project, params)
            if isempty(obj.ValidateFcn)
                [isValid, messages] = geodem.tool.ToolValidator.validateTool(obj, project, params);
            else
                [isValid, messages] = obj.ValidateFcn(project, params);
            end
        end
    end
end
