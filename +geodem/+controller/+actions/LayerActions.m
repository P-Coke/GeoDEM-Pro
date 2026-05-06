classdef LayerActions
    %LAYERACTIONS Layer inspection, export and management actions.

    methods (Static)
        function openAttributeTable(controller, layerName)
            tbl = geodem.service.layer.buildLayerAttributeTable(controller.Project, layerName);
            controller.View.showTable(tbl, ['属性表 - ' char(layerName)]);
            controller.log(['已打开属性表：' char(layerName)]);
        end

        function showInfo(controller, layerName)
            layerName = string(layerName);
            if ~controller.Project.hasLayer(layerName)
                error('GeoDEM:LayerNotFound', '图层不存在：%s', char(layerName));
            end
            tbl = geodem.service.layer.LayerInfoService.infoTable(controller.Project, layerName);
            controller.View.showTable(tbl, ['图层属性 - ' char(layerName)]);
            controller.View.setStats(geodem.service.layer.LayerInfoService.formatLines(tbl));
            controller.log(['已查看图层属性：' char(layerName)]);
        end

        function rename(controller, oldName, newName)
            controller.Project.renameLayer(oldName, newName);
            controller.updateView();
            controller.renderLayer(newName);
            controller.log(sprintf('图层已重命名：%s -> %s。', char(oldName), char(newName)));
            if strlength(controller.SelectedToolId) > 0
                controller.selectTool(controller.SelectedToolId);
            end
        end

        function delete(controller, layerName)
            controller.Project.deleteLayer(layerName);
            controller.updateView();
            if strlength(string(controller.Project.activeLayer)) > 0
                controller.renderLayer(controller.Project.activeLayer);
            else
                controller.View.renderProject(controller.Project);
            end
            controller.log(['已删除图层：' char(layerName)]);
            if strlength(controller.SelectedToolId) > 0
                controller.selectTool(controller.SelectedToolId);
            end
        end

        function exportData(controller, layerName, targetFile)
            layerName = string(layerName);
            if ~controller.Project.hasLayer(layerName)
                error('GeoDEM:LayerNotFound', '图层不存在：%s', char(layerName));
            end
            if nargin < 3 || strlength(string(targetFile)) == 0
                [~, defaultFile] = geodem.service.layer.LayerExportService.dialogSpec(controller.Project, layerName);
                targetFile = fullfile(controller.Project.outputDir, 'layers', defaultFile);
            end
            controller.View.updateProgress(0.25, "导出图层");
            files = geodem.service.layer.LayerExportService.exportData(controller.Project, layerName, targetFile);
            controller.View.updateProgress(0.85, "写入文件");
            controller.Project.parameters.lastExportDir = string(fileparts(char(targetFile)));
            controller.View.setStats(["图层导出完成"; string(files(:))]);
            controller.log(sprintf('图层 "%s" 已导出 %d 个文件。', char(layerName), numel(files)));
        end
    end
end
