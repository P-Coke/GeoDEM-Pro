classdef ParameterPanelBuilder
    %PARAMETERPANELBUILDER Build and read dynamic Geoprocessing tool panels.

    methods (Static)
        function render(parent, toolSpec, defaults, project, runCallback, resetCallback)
            if nargin < 3 || isempty(defaults), defaults = struct(); end
            if nargin < 4, project = []; end
            if nargin < 5, runCallback = []; end
            if nargin < 6, resetCallback = []; end

            delete(parent.Children);
            geodem.compat.setUiProperty(parent, 'Scrollable', 'on');
            paramCount = numel(toolSpec.Parameters);
            rowHeights = [{'fit', 54, 8}, repmat({30}, 1, paramCount), {50, 38}];
            rowCount = numel(rowHeights);
            layout = uigridlayout(parent, [rowCount 2]);
            layout.RowHeight = rowHeights;
            layout.ColumnWidth = {112, '1x'};
            layout.Padding = [10 8 10 10];
            layout.RowSpacing = 5;
            layout.ColumnSpacing = 8;
            geodem.compat.setUiProperty(layout, 'Scrollable', 'on');

            titleLabel = uilabel(layout, 'Text', char(toolSpec.Name), 'FontSize', 15, 'FontColor', [0.10 0.22 0.36]);
            geodem.compat.setUiProperty(titleLabel, 'FontWeight', 'bold');
            titleLabel.Layout.Row = 1;
            titleLabel.Layout.Column = [1 2];
            desc = uitextarea(layout, 'Editable', 'off', 'Value', cellstr(wrapDescription(toolSpec.Description)), ...
                'BackgroundColor', [0.985 0.99 0.995]);
            desc.Layout.Row = 2;
            desc.Layout.Column = [1 2];
            desc.FontSize = 11;
            desc.Enable = 'off';

            controls = struct();
            specs = toolSpec.Parameters;
            for i = 1:paramCount
                spec = specs(i);
                row = i + 3;
                labelText = spec.Label;
                if spec.Required
                    labelText = labelText + " *";
                end
                label = uilabel(layout, 'Text', char(labelText), 'FontColor', [0.25 0.33 0.42]);
                label.Layout.Row = row;
                label.Layout.Column = 1;
                ctrl = geodem.view.ParameterPanelBuilder.createControl(layout, spec, defaults, project);
                ctrl.Layout.Row = row;
                ctrl.Layout.Column = 2;
                if strlength(spec.Tooltip) > 0
                    geodem.compat.setUiProperty(ctrl, 'Tooltip', char(spec.Tooltip));
                end
                controls.(matlab.lang.makeValidName(char(spec.Name))) = ctrl;
            end

            validationArea = uitextarea(layout, 'Editable', 'off', 'Value', {'正在检查参数...'}, ...
                'BackgroundColor', [0.96 0.98 1.00], 'FontSize', 11);
            validationArea.Layout.Row = paramCount + 4;
            validationArea.Layout.Column = [1 2];
            validationArea.Enable = 'off';

            buttonGrid = uigridlayout(layout, [1 3]);
            buttonGrid.Layout.Row = paramCount + 5;
            buttonGrid.Layout.Column = [1 2];
            buttonGrid.ColumnWidth = {'1x', 126, 84};
            buttonGrid.Padding = [0 2 0 0];
            buttonGrid.ColumnSpacing = 8;
            uilabel(buttonGrid, 'Text', '参数只作用于当前工具', 'FontColor', [0.45 0.52 0.60]);
            runButton = uibutton(buttonGrid, 'Text', '运行工具', 'ButtonPushedFcn', @(~, ~) runCallback());
            geodem.compat.setUiProperty(runButton, 'Icon', geodem.view.IconFactory.getIcon(projectRoot(project), 'spark', 24));
            runButton.Layout.Column = 2;
            geodem.compat.setUiProperty(runButton, 'BackgroundColor', [0.00 0.39 0.76]);
            runButton.FontColor = [1 1 1];
            geodem.compat.setUiProperty(runButton, 'FontWeight', 'bold');
            resetButton = uibutton(buttonGrid, 'Text', '重置', 'ButtonPushedFcn', @(~, ~) resetCallback());
            resetButton.Layout.Column = 3;
            geodem.compat.setUiProperty(resetButton, 'BackgroundColor', [0.92 0.94 0.97]);
            resetButton.FontColor = [0.20 0.27 0.34];
            if isempty(runCallback), runButton.Enable = 'off'; end
            if isempty(resetCallback), resetButton.Enable = 'off'; end

            parent.UserData = struct('ToolId', toolSpec.Id, 'ToolName', toolSpec.Name, 'ToolSpec', toolSpec, ...
                'ParameterSpecs', specs, 'Controls', controls, 'RunButton', runButton, 'ValidationArea', validationArea);
            geodem.view.ParameterPanelBuilder.attachValidationCallbacks(parent, project);
            geodem.view.ParameterPanelBuilder.updateValidation(parent, project);
        end

        function params = read(parent)
            params = struct();
            if isempty(parent.UserData) || ~isstruct(parent.UserData) || ~isfield(parent.UserData, 'ParameterSpecs')
                return;
            end
            specs = parent.UserData.ParameterSpecs;
            controls = parent.UserData.Controls;
            for i = 1:numel(specs)
                spec = specs(i);
                key = matlab.lang.makeValidName(char(spec.Name));
                if ~isfield(controls, key) || ~isvalid(controls.(key))
                    continue;
                end
                ctrl = controls.(key);
                value = [];
                switch string(spec.Type)
                    case {"dropdown", "layer"}
                        value = string(ctrl.Value);
                        if startsWith(value, "<")
                            value = "";
                        end
                    case "numeric"
                        value = ctrl.Value;
                    case "logical"
                        value = ctrl.Value;
                    otherwise
                        value = string(ctrl.Value);
                end
                params.(char(spec.Name)) = value;
            end
        end

        function attachValidationCallbacks(parent, project)
            if isempty(parent.UserData) || ~isstruct(parent.UserData) || ~isfield(parent.UserData, 'Controls')
                return;
            end
            controls = parent.UserData.Controls;
            names = fieldnames(controls);
            for i = 1:numel(names)
                ctrl = controls.(names{i});
                if ~isvalid(ctrl)
                    continue;
                end
                if isprop(ctrl, 'ValueChangedFcn')
                    ctrl.ValueChangedFcn = @(~, ~) geodem.view.ParameterPanelBuilder.updateValidation(parent, project);
                end
            end
        end

        function updateValidation(parent, project)
            if isempty(parent.UserData) || ~isstruct(parent.UserData) || ~isfield(parent.UserData, 'ToolSpec')
                return;
            end
            params = geodem.view.ParameterPanelBuilder.read(parent);
            [isValid, messages] = parent.UserData.ToolSpec.validate(project, params);
            runButton = parent.UserData.RunButton;
            validationArea = parent.UserData.ValidationArea;
            if isvalid(runButton)
                if isValid
                    runButton.Enable = 'on';
                else
                    runButton.Enable = 'off';
                end
            end
            if isvalid(validationArea)
                validationArea.Value = cellstr(messages);
                if isValid
                    geodem.compat.setUiProperty(validationArea, 'BackgroundColor', [0.94 0.99 0.95]);
                else
                    geodem.compat.setUiProperty(validationArea, 'BackgroundColor', [1.00 0.95 0.93]);
                end
            end
        end

        function ctrl = createControl(parent, spec, defaults, project)
            value = geodem.view.ParameterPanelBuilder.defaultForSpec(spec, defaults, project);
            switch string(spec.Type)
                case "layer"
                    items = geodem.view.ParameterPanelBuilder.layerItems(project, spec.LayerType);
                    if isempty(items)
                        items = {'<无可用图层>'};
                    end
                    value = geodem.view.ParameterPanelBuilder.validDropValue(value, items, spec, project);
                    ctrl = uidropdown(parent, 'Items', items, 'Value', value);
                case "dropdown"
                    items = spec.Items;
                    if isstring(items), items = cellstr(items); end
                    if isempty(items), items = {' '}; end
                    value = geodem.view.ParameterPanelBuilder.validDropValue(value, items, spec, project);
                    ctrl = uidropdown(parent, 'Items', items, 'Value', value);
                case "numeric"
                    args = {'Value', double(value)};
                    if ~isempty(spec.Limits)
                        args = [args, {'Limits', spec.Limits}]; %#ok<AGROW>
                    end
                    ctrl = uieditfield(parent, 'numeric', args{:});
                case "logical"
                    ctrl = uicheckbox(parent, 'Text', '', 'Value', logical(value));
                otherwise
                    ctrl = uieditfield(parent, 'text', 'Value', char(string(value)));
            end
        end

        function value = defaultForSpec(spec, defaults, project)
            key = char(spec.Name);
            if isstruct(defaults) && isfield(defaults, key)
                value = defaults.(key);
                return;
            end
            value = spec.DefaultValue;
            if string(spec.Type) == "layer" && strlength(string(value)) == 0 && ~isempty(project)
                if strlength(string(project.activeLayer)) > 0 && geodem.view.ParameterPanelBuilder.layerMatches(project, project.activeLayer, spec.LayerType)
                    value = string(project.activeLayer);
                end
            end
        end

        function items = layerItems(project, layerType)
            items = {};
            if isempty(project) || isempty(project.layers)
                return;
            end
            layerType = string(layerType);
            if strlength(layerType) == 0
                names = project.layers.Name;
            else
                names = project.layers.Name(project.layers.Type == layerType);
            end
            items = cellstr(names);
        end

        function tf = layerMatches(project, layerName, layerType)
            tf = false;
            if isempty(project.layers), return; end
            idx = find(project.layers.Name == string(layerName), 1);
            tf = ~isempty(idx) && (strlength(string(layerType)) == 0 || project.layers.Type(idx) == string(layerType));
        end

        function value = validDropValue(value, items, spec, project)
            itemsStr = string(items);
            value = string(value);
            if any(itemsStr == value)
                value = char(value);
                return;
            end
            idx = 1;
            name = string(spec.Name);
            if any(name == ["monitorLayer","monitorDemLayer"]) && numel(items) >= 2
                idx = 2;
            elseif any(name == ["baseLayer","baseDemLayer","inputLayer"]) && ~isempty(project) && strlength(string(project.activeLayer)) > 0
                active = string(project.activeLayer);
                found = find(itemsStr == active, 1);
                if ~isempty(found)
                    idx = found;
                end
            end
            value = char(items{idx});
        end
    end
end

function lines = wrapDescription(text)
text = string(text);
if strlength(text) == 0
    lines = "";
else
    lines = text;
end
end

function root = projectRoot(project)
root = pwd;
if ~isempty(project) && isprop(project, 'outputDir')
    root = fileparts(char(project.outputDir));
end
end
