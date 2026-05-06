classdef ToolValidator
    %TOOLVALIDATOR Provides shared parameter-schema validation helpers.

    methods (Static)
        function [isValid, messages] = validateTool(spec, project, params)
            messages = strings(0, 1);
            if nargin < 3 || isempty(params)
                params = struct();
            end
            messages = geodem.tool.ToolValidator.validateSchema(spec, project, params);
            [isValid, messages] = geodem.tool.ToolValidator.finish(messages);
        end

        function messages = validateSchema(spec, project, params)
            messages = strings(0, 1);
            for i = 1:numel(spec.Parameters)
                p = spec.Parameters(i);
                field = char(p.Name);
                value = [];
                if isstruct(params) && isfield(params, field)
                    value = params.(field);
                end
                if p.Required && (isempty(value) || strlength(string(value)) == 0 || startsWith(string(value), "<"))
                    messages(end + 1, 1) = "缺少必需参数：" + p.Label; %#ok<AGROW>
                    continue;
                end
                if string(p.Type) == "layer" && ~isempty(value) && strlength(string(value)) > 0 && ~startsWith(string(value), "<")
                    idx = find(project.layers.Name == string(value), 1);
                    if isempty(idx)
                        messages(end + 1, 1) = "图层不存在：" + string(value); %#ok<AGROW>
                    elseif strlength(p.LayerType) > 0 && project.layers.Type(idx) ~= string(p.LayerType)
                        messages(end + 1, 1) = "图层类型不匹配：" + string(value) + " 需要 " + p.LayerType; %#ok<AGROW>
                    end
                elseif string(p.Type) == "numeric" && ~isempty(value)
                    numericValue = double(value);
                    if ~isfinite(numericValue)
                        messages(end + 1, 1) = "参数必须是有限数值：" + p.Label; %#ok<AGROW>
                    elseif ~isempty(p.Limits) && (numericValue < p.Limits(1) || numericValue > p.Limits(2))
                        messages(end + 1, 1) = "参数超出范围：" + p.Label; %#ok<AGROW>
                    end
                end
            end
        end

        function [isValid, messages] = finish(messages)
            isValid = isempty(messages);
            if isValid
                messages = "参数有效，可以运行。";
            end
        end

        function messages = validateDifferentParams(messages, params, fieldA, fieldB, message)
            if isstruct(params) && isfield(params, fieldA) && isfield(params, fieldB)
                a = string(params.(fieldA));
                b = string(params.(fieldB));
                if strlength(a) > 0 && strlength(b) > 0 && ~startsWith(a, "<") && a == b
                    messages(end + 1, 1) = string(message);
                end
            end
        end

    end
end
