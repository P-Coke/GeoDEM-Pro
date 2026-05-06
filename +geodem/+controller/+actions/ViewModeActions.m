classdef ViewModeActions
    %VIEWMODEACTIONS Owns rendering, visibility, map tools, and workspace mode changes.

    methods (Static)
        function renderLayer(controller, layerName)
            if strlength(string(layerName)) == 0
                controller.log('没有可显示的图层。');
                return;
            end
            if isempty(controller.Project.layers) || ~any(controller.Project.layers.Name == string(layerName))
                controller.log(['未找到图层：' char(string(layerName))]);
                return;
            end
            controller.Project.activeLayer = string(layerName);
            controller.Project.mapToolState.selectedLayer = string(layerName);
            viewId = controller.View.currentViewId();
            controller.Project.activeViewId = viewId;
            viewState = controller.Project.getViewState(viewId);
            viewState.ActiveLayer = string(layerName);
            viewState.Kind = controller.View.currentViewKind();
            viewState = viewState.touch();
            controller.Project.setViewState(viewId, viewState);
            if ~isempty(controller.Project.layers)
                controller.Project.layers.Visible(:) = false;
                controller.Project.setLayerVisible(layerName, true);
                controller.View.setLayers(controller.Project.layers);
            end
            controller.View.renderLayer(controller.Project, layerName);
            controller.View.captureCurrentViewState(controller.Project);
            controller.View.updateStatusBar(controller.Project, [], "就绪");
        end

        function zoomToLayer(controller, layerName)
            layerName = geodem.controller.actions.LayerUiActions.defaultLayer(controller, layerName);
            controller.View.zoomToLayer(controller.Project, layerName);
        end

        function hideLayer(controller, layerName)
            layerName = geodem.controller.actions.LayerUiActions.defaultLayer(controller, layerName);
            if strlength(layerName) == 0 || ~controller.Project.hasLayer(layerName)
                controller.log('没有可隐藏的图层。');
                return;
            end
            controller.Project.setLayerVisible(layerName, false);
            if controller.Project.activeLayer == layerName
                visibleNames = controller.Project.layers.Name(controller.Project.layers.Visible);
                if isempty(visibleNames)
                    controller.Project.activeLayer = "";
                    controller.View.renderProject(controller.Project);
                else
                    controller.Project.activeLayer = visibleNames(end);
                    controller.View.renderLayer(controller.Project, controller.Project.activeLayer);
                end
            end
            controller.View.setLayers(controller.Project.layers);
            controller.log(['已隐藏图层：' char(layerName)]);
        end

        function syncLayerVisibility(controller, checkedLayerNames)
            if isempty(controller.Project.layers)
                return;
            end
            controller.Project.layers.Visible(:) = false;
            if ~isempty(checkedLayerNames)
                layerName = checkedLayerNames(end);
                controller.Project.setLayerVisible(layerName, true);
                controller.Project.activeLayer = string(layerName);
                controller.Project.mapToolState.selectedLayer = string(layerName);
                viewId = controller.View.currentViewId();
                viewState = controller.Project.getViewState(viewId);
                viewState.ActiveLayer = string(layerName);
                viewState.Kind = controller.View.currentViewKind();
                controller.Project.setViewState(viewId, viewState);
            end
            controller.updateView();
            if strlength(string(controller.Project.activeLayer)) > 0
                controller.renderLayer(controller.Project.activeLayer);
            end
        end

        function setActiveMapTool(controller, toolName)
            controller.Project.mapToolState.activeTool = string(toolName);
            viewId = controller.View.currentViewId();
            viewState = controller.Project.getViewState(viewId);
            viewState.ActiveTool = string(toolName);
            controller.Project.setViewState(viewId, viewState);
            if any(string(toolName) == ["identify","measure","profile"])
                controller.Project.mapToolState.measurePoints = zeros(0, 2);
            end
            controller.View.setActiveMapTool(toolName);
        end

        function handleMapClick(controller, x, y)
            viewState = controller.Project.getViewState(controller.View.currentViewId());
            tool = string(viewState.ActiveTool);
            if strlength(tool) == 0 || tool == "none"
                tool = string(controller.Project.mapToolState.activeTool);
            end
            switch tool
                case "identify"
                    controller.runSafely(@() geodem.controller.actions.MapInteractionActions.identifyAt(controller, x, y));
                case "measure"
                    controller.runSafely(@() geodem.controller.actions.MapInteractionActions.measureAt(controller, x, y));
                case "profile"
                    controller.runSafely(@() geodem.controller.actions.MapInteractionActions.profileFromClicks(controller, x, y));
                case "pan"
                    return;
                otherwise
                    controller.runSafely(@() geodem.controller.actions.MapInteractionActions.identifyAt(controller, x, y));
            end
        end

        function setViewMode(controller, mode)
            controller.View.selectViewMode(mode);
            controller.Project.activeViewId = controller.View.currentViewId();
            controller.View.renderProject(controller.Project);
        end

        function showActiveDeformation(controller)
            result = controller.Project.activeDeformation();
            if isempty(result)
                controller.selectTool("dem_difference");
                controller.log('尚未生成差分结果，请先运行 DEM 作差工具。');
                return;
            end
            layerName = "";
            names = controller.Project.layerNamesByType("deformation");
            if ~isempty(names)
                layerName = names(end);
            end
            if strlength(layerName) > 0
                controller.setViewMode('map');
                controller.renderLayer(layerName);
            end
        end
    end
end
