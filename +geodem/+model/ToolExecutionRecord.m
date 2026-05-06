classdef ToolExecutionRecord
    %TOOLEXECUTIONRECORD Serializable history entry for one tool run.

    properties
        Id = ""
        ToolId = ""
        ToolName = ""
        Status = "Pending"
        StartTime = ""
        EndTime = ""
        DurationSeconds = NaN
        Parameters = struct()
        InputLayers = strings(0, 1)
        OutputLayers = strings(0, 1)
        Messages = strings(0, 1)
        ErrorMessage = ""
    end

    methods
        function obj = ToolExecutionRecord(toolId, toolName, status, startTime, endTime, durationSeconds, params, inputLayers, outputLayers, messages, errorMessage)
            if nargin >= 1, obj.ToolId = string(toolId); end
            if nargin >= 2, obj.ToolName = string(toolName); end
            if nargin >= 3, obj.Status = string(status); end
            if nargin >= 4, obj.StartTime = string(startTime); end
            if nargin >= 5, obj.EndTime = string(endTime); end
            if nargin >= 6, obj.DurationSeconds = durationSeconds; end
            if nargin >= 7, obj.Parameters = params; end
            if nargin >= 8, obj.InputLayers = string(inputLayers); end
            if nargin >= 9, obj.OutputLayers = string(outputLayers); end
            if nargin >= 10, obj.Messages = string(messages); end
            if nargin >= 11, obj.ErrorMessage = string(errorMessage); end
            stamp = char(datetime('now', 'Format', 'yyyyMMddHHmmssSSS'));
            obj.Id = string(sprintf('%s_%s', matlab.lang.makeValidName(char(obj.ToolId)), stamp));
        end
    end
end
