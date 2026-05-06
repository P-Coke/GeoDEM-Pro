classdef RibbonBuilder
    %RIBBONBUILDER Builds the ArcGIS-style ribbon from a data specification.

    methods (Static)
        function create(view, parent)
            view.RibbonTabGroup = uitabgroup(parent);
            tabs = geodem.view.RibbonBuilder.ribbonSpec(view);
            for i = 1:numel(tabs)
                geodem.view.RibbonBuilder.addRibbonTab(view, tabs{i}.Title, tabs{i}.Groups);
            end
        end

        function addRibbonTab(view, titleText, groups)
            tab = uitab(view.RibbonTabGroup, 'Title', titleText);
            grid = uigridlayout(tab, [1 numel(groups)]);
            grid.ColumnWidth = repmat({'fit'}, 1, numel(groups));
            grid.Padding = [8 6 8 4];
            grid.ColumnSpacing = 6;
            for i = 1:numel(groups)
                groupPanel = uipanel(grid, 'Title', groups{i}.Title, ...
                    'FontSize', 10, 'ForegroundColor', [0.20 0.30 0.42]);
                geodem.compat.setUiProperty(groupPanel, 'BackgroundColor', [0.985 0.99 0.995]);
                groupPanel.Layout.Column = i;
                btns = groups{i}.Buttons;
                cols = max(1, numel(btns));
                g = uigridlayout(groupPanel, [1 cols]);
                g.ColumnWidth = repmat({66}, 1, cols);
                g.RowHeight = {'1x'};
                g.Padding = [5 3 5 3];
                g.ColumnSpacing = 4;
                for j = 1:numel(btns)
                    spec = btns{j};
                    btn = uibutton(g, 'Text', spec.Text, ...
                        'ButtonPushedFcn', @(~, ~) spec.Callback());
                    geodem.compat.setUiProperty(btn, 'Icon', view.iconPath(spec.Icon, 32));
                    geodem.compat.setUiProperty(btn, 'IconAlignment', 'top');
                    geodem.compat.setUiProperty(btn, 'Tooltip', spec.Tooltip);
                    btn.Layout.Column = j;
                    btn.FontSize = 9;
                end
            end
        end

        function tabs = ribbonSpec(view)
            tabs = {
                geodem.view.RibbonBuilder.tabSpec('工程', {
                    geodem.view.RibbonBuilder.groupSpec('工程', {geodem.view.RibbonBuilder.btnSpec('新建','project','新建工程',@() view.Controller.newProject()), geodem.view.RibbonBuilder.btnSpec('打开','open','打开工程',@() view.Controller.openProject()), geodem.view.RibbonBuilder.btnSpec('保存','save','保存工程',@() view.Controller.saveProject())})
                    geodem.view.RibbonBuilder.groupSpec('管理', {geodem.view.RibbonBuilder.btnSpec('另存','save','另存工程',@() view.Controller.saveProjectAs()), geodem.view.RibbonBuilder.btnSpec('清空','clean','清空工作区',@() view.Controller.clearWorkspace())})
                })
                geodem.view.RibbonBuilder.tabSpec('数据', {
                    geodem.view.RibbonBuilder.groupSpec('导入', {geodem.view.RibbonBuilder.btnSpec('点云','import','批量导入 CSV/TXT/LAS/LAZ 点云',@() view.Controller.importCloud()), geodem.view.RibbonBuilder.btnSpec('LAS','las','批量导入 LAS/LAZ 点云',@() view.Controller.importLasCloud()), geodem.view.RibbonBuilder.btnSpec('DEM','dem','导入 GeoTIFF 或矩阵 DEM',@() view.Controller.importDem()), geodem.view.RibbonBuilder.btnSpec('工程','open','打开已有工程',@() view.Controller.openProject())})
                    geodem.view.RibbonBuilder.groupSpec('检查', {geodem.view.RibbonBuilder.btnSpec('体检','identify','生成点云质量体检报告',@() view.Controller.selectTool('pointcloud_quality')), geodem.view.RibbonBuilder.btnSpec('坐标','identify','检查坐标范围和高程统计',@() view.Controller.showCloudProperties()), geodem.view.RibbonBuilder.btnSpec('预览','map','显示当前激活图层',@() view.Controller.renderLayer(view.Controller.Project.activeLayer)), geodem.view.RibbonBuilder.btnSpec('属性表','attribute','打开当前图层属性表',@() view.Controller.openAttributeTable())})
                    geodem.view.RibbonBuilder.groupSpec('管理', {geodem.view.RibbonBuilder.btnSpec('全图','fullExtent','缩放至当前图层',@() view.Controller.zoomToLayer()), geodem.view.RibbonBuilder.btnSpec('清空','clean','清空当前工作区',@() view.Controller.clearWorkspace())})
                })
                geodem.view.RibbonBuilder.tabSpec('点云处理', {
                    geodem.view.RibbonBuilder.groupSpec('质量', {geodem.view.RibbonBuilder.btnSpec('体检','identify','点云质量检查报告',@() view.Controller.selectTool('pointcloud_quality')), geodem.view.RibbonBuilder.btnSpec('剔除','clean','选择异常点剔除工具',@() view.Controller.selectTool('clean_pointcloud')), geodem.view.RibbonBuilder.btnSpec('百分位','clean','按百分位剔除异常点',@() view.Controller.selectTool('clean_pointcloud')), geodem.view.RibbonBuilder.btnSpec('阈值','clean','按高程阈值剔除异常点',@() view.Controller.selectTool('clean_pointcloud'))})
                    geodem.view.RibbonBuilder.groupSpec('密度', {geodem.view.RibbonBuilder.btnSpec('密度','density','选择点云密度工具',@() view.Controller.selectTool('density_grid')), geodem.view.RibbonBuilder.btnSpec('热力图','chart','生成点云密度热力图',@() view.Controller.selectTool('density_grid'))})
                    geodem.view.RibbonBuilder.groupSpec('范围', {geodem.view.RibbonBuilder.btnSpec('共同区','clip','选择共同覆盖区工具',@() view.Controller.selectTool('common_extent')), geodem.view.RibbonBuilder.btnSpec('裁剪','clip','按共同覆盖区输出裁剪点云',@() view.Controller.selectTool('common_extent')), geodem.view.RibbonBuilder.btnSpec('缩放','fullExtent','缩放至图层',@() view.Controller.zoomToLayer())})
                })
                geodem.view.RibbonBuilder.tabSpec('DEM 构建', {
                    geodem.view.RibbonBuilder.groupSpec('格网', {geodem.view.RibbonBuilder.btnSpec('生成网格','grid','选择 DEM 构建工具并设置范围/分辨率',@() view.Controller.selectTool('build_dem')), geodem.view.RibbonBuilder.btnSpec('分辨率','grid','设置 DEM 网格分辨率',@() view.Controller.selectTool('build_dem'))})
                    geodem.view.RibbonBuilder.groupSpec('表面', {geodem.view.RibbonBuilder.btnSpec('插值','interpolate','选择插值建模方法',@() view.Controller.selectTool('build_dem')), geodem.view.RibbonBuilder.btnSpec('建模','dem','从点云生成 DEM',@() view.Controller.selectTool('build_dem')), geodem.view.RibbonBuilder.btnSpec('平滑','dem','配置 DEM 平滑参数',@() view.Controller.selectTool('build_dem')), geodem.view.RibbonBuilder.btnSpec('空洞','dem','配置 DEM 空洞填补',@() view.Controller.selectTool('build_dem'))})
                    geodem.view.RibbonBuilder.groupSpec('评价', {geodem.view.RibbonBuilder.btnSpec('精度评价','chart','交叉验证 DEM 插值精度',@() view.Controller.selectTool('dem_accuracy')), geodem.view.RibbonBuilder.btnSpec('插值对比','interpolate','选择插值方法对比工具',@() view.Controller.selectTool('compare_methods')), geodem.view.RibbonBuilder.btnSpec('属性表','attribute','打开当前 DEM 属性表',@() view.Controller.openAttributeTable()), geodem.view.RibbonBuilder.btnSpec('GeoTIFF','geotiff','选择 GeoTIFF 导出工具',@() view.Controller.selectTool('export_geotiff'))})
                })
                geodem.view.RibbonBuilder.tabSpec('形变分析', {
                    geodem.view.RibbonBuilder.groupSpec('变化', {geodem.view.RibbonBuilder.btnSpec('DEM作差','diff','选择 DEM 作差工具',@() view.Controller.selectTool('dem_difference')), geodem.view.RibbonBuilder.btnSpec('沉降','diff','配置沉降阈值并提取沉降区',@() view.Controller.selectTool('dem_difference')), geodem.view.RibbonBuilder.btnSpec('抬升','diff','配置抬升阈值并提取抬升区',@() view.Controller.selectTool('dem_difference')), geodem.view.RibbonBuilder.btnSpec('等级','classmap','生成形变等级分区图',@() view.Controller.selectTool('dem_difference'))})
                    geodem.view.RibbonBuilder.groupSpec('统计', {geodem.view.RibbonBuilder.btnSpec('面积','chart','运行 DEM 作差并统计面积',@() view.Controller.selectTool('dem_difference')), geodem.view.RibbonBuilder.btnSpec('体积','chart','运行 DEM 作差并统计体积',@() view.Controller.selectTool('dem_difference')), geodem.view.RibbonBuilder.btnSpec('极值点','identify','识别最大沉降点',@() view.Controller.selectTool('dem_difference'))})
                    geodem.view.RibbonBuilder.groupSpec('交互', {geodem.view.RibbonBuilder.btnSpec('等值线','contour','生成沉降等值线',@() view.Controller.selectTool('dem_difference')), geodem.view.RibbonBuilder.btnSpec('识别','identify','点击查询像元',@() view.Controller.setActiveMapTool('identify')), geodem.view.RibbonBuilder.btnSpec('测距','measure','点击测距',@() view.Controller.setActiveMapTool('measure')), geodem.view.RibbonBuilder.btnSpec('剖面','profile','选择剖面分析工具并启用地图点击',@() view.Controller.activateProfileAnalysis())})
                })
                geodem.view.RibbonBuilder.tabSpec('制图与三维', {
                    geodem.view.RibbonBuilder.groupSpec('视图', {geodem.view.RibbonBuilder.btnSpec('单图','map','切换到单图二维地图视图',@() view.Controller.setViewMode('map')), geodem.view.RibbonBuilder.btnSpec('四宫格','compare','切换到 DEM/差值/等值线四宫格',@() view.Controller.setViewMode('compare')), geodem.view.RibbonBuilder.btnSpec('差分','diff','显示当前差分专题图',@() view.Controller.showActiveDeformation()), geodem.view.RibbonBuilder.btnSpec('三维','surface3d','切换到三维场景视图',@() view.Controller.setViewMode('scene')), geodem.view.RibbonBuilder.btnSpec('图表','chart','切换到统计图表视图',@() view.Controller.setViewMode('charts'))})
                    geodem.view.RibbonBuilder.groupSpec('地图工具', {geodem.view.RibbonBuilder.btnSpec('全图','fullExtent','缩放至当前图层',@() view.Controller.zoomToLayer()), geodem.view.RibbonBuilder.btnSpec('识别','identify','点击查询像元',@() view.Controller.setActiveMapTool('identify')), geodem.view.RibbonBuilder.btnSpec('测距','measure','点击测距',@() view.Controller.setActiveMapTool('measure')), geodem.view.RibbonBuilder.btnSpec('属性表','attribute','打开当前图层属性表',@() view.Controller.openAttributeTable())})
                    geodem.view.RibbonBuilder.groupSpec('输出', {geodem.view.RibbonBuilder.btnSpec('视图导出','export','导出全部成果图件',@() view.Controller.exportResults()), geodem.view.RibbonBuilder.btnSpec('报告','report','生成分析报告',@() view.Controller.selectTool('generate_report'))})
                })
                geodem.view.RibbonBuilder.tabSpec('成果输出', {
                    geodem.view.RibbonBuilder.groupSpec('工作流', {geodem.view.RibbonBuilder.btnSpec('运行分析','spark','选择一键工作流工具',@() view.Controller.selectTool('workflow_analysis')), geodem.view.RibbonBuilder.btnSpec('一键流','spark','配置并运行完整处理流程',@() view.Controller.selectTool('workflow_analysis')), geodem.view.RibbonBuilder.btnSpec('导出','export','选择成果导出工具',@() view.Controller.selectTool('export_results')), geodem.view.RibbonBuilder.btnSpec('报告','report','选择报告生成工具',@() view.Controller.selectTool('generate_report'))})
                    geodem.view.RibbonBuilder.groupSpec('栅格', {geodem.view.RibbonBuilder.btnSpec('GeoTIFF','geotiff','选择 GeoTIFF 导出工具',@() view.Controller.selectTool('export_geotiff')), geodem.view.RibbonBuilder.btnSpec('矩阵','attribute','导出 DEM/差值矩阵',@() view.Controller.selectTool('export_results'))})
                    geodem.view.RibbonBuilder.groupSpec('矢量', {geodem.view.RibbonBuilder.btnSpec('Shapefile','shape','选择 Shapefile 导出工具',@() view.Controller.selectTool('export_shapefile')), geodem.view.RibbonBuilder.btnSpec('等值线','contour','导出沉降等值线',@() view.Controller.selectTool('export_shapefile'))})
                })
            };
        end

        function spec = tabSpec(titleText, groups)
            spec = struct('Title', titleText, 'Groups', {groups});
        end

        function spec = groupSpec(titleText, buttons)
            spec = struct('Title', titleText, 'Buttons', {buttons});
        end

        function spec = btnSpec(text, iconName, tooltip, callback)
            spec = struct('Text', text, 'Icon', iconName, 'Tooltip', tooltip, 'Callback', callback);
        end
    end
end
