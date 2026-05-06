classdef ChartRenderer
    %CHARTRENDERER Renders statistics charts and profile plots.

    methods (Static)
        function renderCharts(view, project)
            result = project.activeDeformation();
            if isempty(result)
                return;
            end
            dz = result.deltaZ;
            dz = dz(isfinite(dz));
            if numel(dz) > view.MaxChartSamples
                dz = dz(round(linspace(1, numel(dz), view.MaxChartSamples)));
            end
            cla(view.HistogramAxes);
            histogram(view.HistogramAxes, dz, 50, 'FaceColor', [0.18 0.42 0.68], 'EdgeColor', 'none');
            grid(view.HistogramAxes, 'on');
            title(view.HistogramAxes, 'ΔZ 形变量直方图');
            xlabel(view.HistogramAxes, 'ΔZ / m');
            ylabel(view.HistogramAxes, '格网数');

            tbl = result.stats.ClassAreaTable;
            cla(view.ClassBarAxes);
            bar(view.ClassBarAxes, categorical(tbl.ClassName), tbl.Area, 'FaceColor', [0.38 0.50 0.68]);
            grid(view.ClassBarAxes, 'on');
            title(view.ClassBarAxes, '形变等级面积统计');
            ylabel(view.ClassBarAxes, '面积 / m²');
            view.ClassBarAxes.XTickLabelRotation = 25;
        end

        function renderProfile(view, profile)
            view.selectViewMode('charts');
            geodem.view.renderer.RendererSupport.resetPlotAxes(view.HistogramAxes);
            geodem.view.renderer.RendererSupport.resetPlotAxes(view.ClassBarAxes);
            distance = profile.Distance;
            baseZ = profile.BaseDEM;
            monitorZ = profile.MonitorDEM;
            deltaZ = profile.DeltaZ;
            plot(view.HistogramAxes, distance, baseZ, 'Color', [0.10 0.36 0.78], 'LineWidth', 1.3, 'HitTest', 'off');
            hold(view.HistogramAxes, 'on');
            plot(view.HistogramAxes, distance, monitorZ, 'Color', [0.82 0.28 0.16], 'LineWidth', 1.3, 'HitTest', 'off');
            hold(view.HistogramAxes, 'off');
            grid(view.HistogramAxes, 'on');
            xlabel(view.HistogramAxes, '沿线距离 / m');
            ylabel(view.HistogramAxes, '高程 / m');
            title(view.HistogramAxes, 'DEM 高程剖面对比');
            legend(view.HistogramAxes, {'基准 DEM','监测 DEM'}, 'Location', 'best');
            axis(view.HistogramAxes, 'tight');

            plot(view.ClassBarAxes, distance, deltaZ, 'Color', [0.12 0.12 0.12], 'LineWidth', 1.2, 'HitTest', 'off');
            hold(view.ClassBarAxes, 'on');
            yline(view.ClassBarAxes, 0, '-', 'Color', [0.55 0.55 0.55], 'HitTest', 'off');
            hold(view.ClassBarAxes, 'off');
            grid(view.ClassBarAxes, 'on');
            xlabel(view.ClassBarAxes, '沿线距离 / m');
            ylabel(view.ClassBarAxes, 'ΔZ / m');
            title(view.ClassBarAxes, '沿线形变量剖面');
            axis(view.ClassBarAxes, 'tight');

            valid = isfinite(baseZ) & isfinite(monitorZ) & isfinite(deltaZ);
            if ismember('Valid', profile.Properties.VariableNames)
                valid = valid & logical(profile.Valid);
            end
            if any(valid)
                [minDz, minIdx] = min(deltaZ(valid));
                validDistance = distance(valid);
                maxAbs = max(abs(deltaZ(valid)));
                view.setStats([
                    "剖面分析结果"
                    "采样点数：" + string(height(profile))
                    "有效采样比例：" + sprintf('%.1f%%', 100 * sum(valid) / max(height(profile), 1))
                    "最大沉降：" + sprintf('%.3f m，距离 %.2f m', minDz, validDistance(minIdx))
                    "最大绝对形变量：" + sprintf('%.3f m', maxAbs)
                    ]);
            else
                view.setStats(["剖面分析结果"; "剖面线没有有效采样点。"]);
            end
        end
    end
end
