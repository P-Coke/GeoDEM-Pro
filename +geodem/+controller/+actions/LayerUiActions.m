classdef LayerUiActions
    %LAYERUIACTIONS Owns layer-related dialogs and confirmations.

    methods (Static)
        function rename(controller, layerName)
            layerName = geodem.controller.actions.LayerUiActions.defaultLayer(controller, layerName);
            if strlength(layerName) == 0
                controller.log('没有可重命名的图层。');
                return;
            end
            answer = inputdlg({'新图层名称'}, '重命名图层', 1, {char(layerName)});
            if isempty(answer)
                return;
            end
            controller.runSafely(@() geodem.controller.actions.LayerActions.rename(controller, layerName, string(answer{1})));
        end

        function delete(controller, layerName)
            layerName = geodem.controller.actions.LayerUiActions.defaultLayer(controller, layerName);
            if strlength(layerName) == 0
                controller.log('没有可删除的图层。');
                return;
            end
            selection = uiconfirm(controller.View.UIFigure, "删除图层 """ + layerName + """？", '删除图层', ...
                'Options', {'删除','取消'}, 'DefaultOption', 2, 'CancelOption', 2, 'Icon', 'warning');
            if selection ~= "删除"
                return;
            end
            controller.runSafely(@() geodem.controller.actions.LayerActions.delete(controller, layerName));
        end

        function exportData(controller, layerName)
            layerName = geodem.controller.actions.LayerUiActions.defaultLayer(controller, layerName);
            if strlength(layerName) == 0 || ~controller.Project.hasLayer(layerName)
                controller.log('没有可导出的图层。');
                return;
            end
            [filters, defaultFile] = geodem.service.layer.LayerExportService.dialogSpec(controller.Project, layerName);
            defaultDir = geodem.service.layer.LayerExportService.preferredExportDir(controller.Project, 'layers');
            if ~exist(defaultDir, 'dir'), mkdir(defaultDir); end
            [file, path] = uiputfile(filters, '导出图层数据', fullfile(defaultDir, defaultFile));
            if isequal(file, 0)
                return;
            end
            controller.runSafely(@() geodem.controller.actions.LayerActions.exportData(controller, layerName, fullfile(path, file)));
        end

        function layerName = defaultLayer(controller, layerName)
            if nargin < 2 || isempty(layerName) || strlength(string(layerName)) == 0
                layerName = controller.Project.activeLayer;
            end
            layerName = string(layerName);
        end
    end
end
