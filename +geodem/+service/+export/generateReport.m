function reportFiles = generateReport(project, reportSpec)
%GENERATEREPORT Generate Chinese HTML and DOCX analysis reports.

if nargin < 2 || isempty(reportSpec)
    reportSpec = struct();
end
outputDir = geodem.util.getField(reportSpec, 'outputDir', project.outputDir);
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

exportSpec = struct('outputDir', outputDir, 'imageFormats', {{'png'}}, 'data', true, 'images', true);
outputs = geodem.service.export.exportResults(project, exportSpec);
figureFiles = outputs.FigureFiles;

htmlPath = fullfile(outputDir, 'GeoDEMPro_analysis_report.html');
writeHtmlReport(project, htmlPath, figureFiles);

docxPath = fullfile(outputDir, 'GeoDEMPro_analysis_report.docx');
docxOk = writeDocxReport(project, docxPath, figureFiles);
if docxOk
    reportFiles = struct('HTML', htmlPath, 'DOCX', docxPath, 'Exports', outputs);
else
    reportFiles = struct('HTML', htmlPath, 'DOCX', "", 'Exports', outputs);
end
end

function writeHtmlReport(project, htmlPath, figureFiles)
fid = fopen(htmlPath, 'w', 'n', 'UTF-8');
if fid < 0
    error('GeoDEM:ReportWriteFailed', 'Cannot write report: %s', htmlPath);
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '<!doctype html><html lang="zh-CN"><head><meta charset="utf-8"><title>GeoDEM Pro 分析报告</title>');
fprintf(fid, '<style>body{font-family:Microsoft YaHei,Arial,sans-serif;max-width:1100px;margin:28px auto;line-height:1.65;color:#222}h1,h2{color:#17324d}table{border-collapse:collapse;width:100%%;margin:12px 0}td,th{border:1px solid #ccd3dd;padding:6px 8px;text-align:right}th{text-align:center;background:#eef3f8}img{max-width:100%%;border:1px solid #d5dce5;margin:10px 0}.meta{color:#667}</style>');
fprintf(fid, '</head><body>');
fprintf(fid, '<h1>GeoDEM Pro 点云 DEM 形变分析报告</h1>');
fprintf(fid, '<p class="meta">生成时间：%s</p>', char(datetime('now', 'Format', geodem.config.AppConfig.DateTimeFormat)));
fprintf(fid, '<h2>1. 项目概况</h2>');
fprintf(fid, '<p>本报告基于两期 XYZ 点云数据，完成点云质量检查、共同覆盖区提取、DEM 构建、DEM 差分、沉降等值线、形变分区、面积体积统计和三维可视化。</p>');
writeCloudSummary(fid, project);
writeDemSummary(fid, project);
writeStoredAnalysisTables(fid, project);
writeDeformationSummary(fid, project);
writeToolHistory(fid, project);
fprintf(fid, '<h2>7. 成果图</h2>');
for i = 1:numel(figureFiles)
    [~, name, ext] = fileparts(figureFiles{i});
    rel = erase(figureFiles{i}, [project.outputDir filesep]);
    rel = strrep(rel, filesep, '/');
    fprintf(fid, '<h3>%s%s</h3><img src="%s" alt="%s">', name, ext, rel, name);
end
fprintf(fid, '<h2>8. 结论</h2>');
conclusion = geodem.service.deformation.summarizeDeformation(project.activeDeformation());
fprintf(fid, '<p>%s</p>', conclusion);
fprintf(fid, '<p>系统在统一共同覆盖区和统一格网分辨率下完成两期 DEM 差分，可有效避免覆盖范围不一致造成的边缘误差。沉降、抬升和稳定区通过阈值分类表达，最大沉降中心与体积统计可作为地形变化解释的重要依据。</p>');
fprintf(fid, '</body></html>');
end

function writeCloudSummary(fid, project)
fprintf(fid, '<h2>2. 点云数据质量检查</h2>');
fprintf(fid, '<table><tr><th>期次</th><th>点数</th><th>X范围</th><th>Y范围</th><th>Z范围</th><th>平均高程</th><th>点密度</th></tr>');
clouds = selectedClouds(project);
for i = 1:numel(clouds)
    c = clouds(i).Cloud;
    fprintf(fid, '<tr><td style="text-align:center">%s</td><td>%d</td><td>%.3f - %.3f</td><td>%.3f - %.3f</td><td>%.3f - %.3f</td><td>%.3f</td><td>%.4f</td></tr>', ...
        clouds(i).Label, c.bounds.PointCount, c.bounds.XMin, c.bounds.XMax, c.bounds.YMin, c.bounds.YMax, c.bounds.ZMin, c.bounds.ZMax, c.zStats.Mean, c.qualityReport.Density);
end
fprintf(fid, '</table>');
end

function writeDemSummary(fid, project)
fprintf(fid, '<h2>3. DEM 构建参数与质量</h2>');
fprintf(fid, '<p>默认插值方法：%s；格网分辨率：%.3f m。</p>', project.parameters.interpolationMethod, project.parameters.gridResolution);
fprintf(fid, '<table><tr><th>DEM</th><th>行数</th><th>列数</th><th>有效格网</th><th>空洞比例</th><th>最小值</th><th>最大值</th><th>平均值</th></tr>');
dems = selectedDems(project);
for i = 1:numel(dems)
        d = dems(i).Dem;
        m = d.qualityMetrics;
        fprintf(fid, '<tr><td style="text-align:center">%s</td><td>%d</td><td>%d</td><td>%d</td><td>%.2f%%</td><td>%.3f</td><td>%.3f</td><td>%.3f</td></tr>', ...
            dems(i).Label, m.Rows, m.Cols, m.ValidCellCount, 100 * m.NanRatio, m.Min, m.Max, m.Mean);
end
fprintf(fid, '</table>');
end

function writeDeformationSummary(fid, project)
fprintf(fid, '<h2>5. DEM 差分与形变统计</h2>');
result = project.activeDeformation();
if isempty(result)
    fprintf(fid, '<p>尚未生成形变分析结果。</p>');
    return;
end
s = result.stats;
v = result.volumeStats;
p = result.maxSubsidencePoint;
fprintf(fid, '<p>差分方向固定为 ΔZ = 监测 DEM - 基准 DEM。ΔZ 小于 %.3f m 判定为沉降，大于 %.3f m 判定为抬升。</p>', ...
    result.thresholds.subsidence, result.thresholds.uplift);
fprintf(fid, '<table><tr><th>最大沉降/m</th><th>最大抬升/m</th><th>平均变形/m</th><th>沉降面积/m²</th><th>抬升面积/m²</th><th>稳定比例</th><th>沉降体积/m³</th><th>净体积变化/m³</th></tr>');
fprintf(fid, '<tr><td>%.3f</td><td>%.3f</td><td>%.3f</td><td>%.2f</td><td>%.2f</td><td>%.2f%%</td><td>%.2f</td><td>%.2f</td></tr>', ...
    s.MaxSubsidence, s.MaxUplift, s.MeanChange, s.SubsidenceArea, s.UpliftArea, 100 * s.StableRatio, v.SubsidenceVolume, v.NetVolumeChange);
fprintf(fid, '</table>');
fprintf(fid, '<p>最大沉降中心：X=%.3f，Y=%.3f，ΔZ=%.3f m。</p>', p.X, p.Y, p.DeltaZ);
fprintf(fid, '<h3>形变等级面积统计</h3>');
fprintf(fid, '<table><tr><th>等级</th><th>格网数</th><th>面积/m²</th><th>比例</th></tr>');
tbl = s.ClassAreaTable;
for i = 1:height(tbl)
    fprintf(fid, '<tr><td style="text-align:center">%s</td><td>%d</td><td>%.2f</td><td>%.2f%%</td></tr>', tbl.ClassName(i), tbl.CellCount(i), tbl.Area(i), 100 * tbl.Ratio(i));
end
fprintf(fid, '</table>');
end

function clouds = selectedClouds(project)
clouds = struct('Label', {}, 'Cloud', {});
names = project.layerNamesByType("pointcloud");
for i = 1:numel(names)
    try
        clouds(end + 1) = struct('Label', names(i), 'Cloud', project.getCloudByLayer(names(i))); %#ok<AGROW>
    catch
    end
end
end

function dems = selectedDems(project)
dems = struct('Label', {}, 'Dem', {});
names = project.layerNamesByType("dem");
for i = 1:numel(names)
    try
        dem = geodem.tool.ToolRegistry.getDemByLayer(project, names(i));
        dems(end + 1) = struct('Label', names(i), 'Dem', dem); %#ok<AGROW>
    catch
    end
end
end

function writeStoredAnalysisTables(fid, project)
fprintf(fid, '<h2>4. 质量体检与精度评价</h2>');
hasAny = false;
if isfield(project.parameters, 'qualityReports')
    keys = fieldnames(project.parameters.qualityReports);
    for i = 1:numel(keys)
        fprintf(fid, '<h3>点云质量体检：%s</h3>', keys{i});
        writeGenericTable(fid, project.parameters.qualityReports.(keys{i}));
        hasAny = true;
    end
end
if isfield(project.parameters, 'demAccuracy')
    keys = fieldnames(project.parameters.demAccuracy);
    for i = 1:numel(keys)
        fprintf(fid, '<h3>DEM 精度评价：%s</h3>', keys{i});
        writeGenericTable(fid, project.parameters.demAccuracy.(keys{i}));
        hasAny = true;
    end
end
if ~hasAny
    fprintf(fid, '<p>当前工程尚未运行独立的点云质量体检或 DEM 精度评价工具。</p>');
end
end

function writeGenericTable(fid, tbl)
if ~istable(tbl) || height(tbl) == 0
    fprintf(fid, '<p>无表格结果。</p>');
    return;
end
vars = tbl.Properties.VariableNames;
fprintf(fid, '<table><tr>');
for j = 1:numel(vars)
    fprintf(fid, '<th>%s</th>', vars{j});
end
fprintf(fid, '</tr>');
for i = 1:height(tbl)
    fprintf(fid, '<tr>');
    for j = 1:numel(vars)
        value = tbl{i, j};
        if isnumeric(value)
            if isscalar(value)
                text = sprintf('%.4g', value);
            else
                text = mat2str(value);
            end
        else
            text = char(string(value));
        end
        fprintf(fid, '<td>%s</td>', text);
    end
    fprintf(fid, '</tr>');
end
fprintf(fid, '</table>');
end

function writeToolHistory(fid, project)
fprintf(fid, '<h2>6. 作业历史与可复现性</h2>');
if ~isprop(project, 'toolHistory') || isempty(project.toolHistory)
    fprintf(fid, '<p>当前工程暂无工具运行历史记录。</p>');
    return;
end
fprintf(fid, '<table><tr><th>工具</th><th>状态</th><th>开始时间</th><th>耗时/s</th><th>输出图层</th></tr>');
for i = 1:numel(project.toolHistory)
    rec = project.toolHistory(i);
    outputs = strjoin(rec.OutputLayers, ", ");
    fprintf(fid, '<tr><td style="text-align:center">%s</td><td style="text-align:center">%s</td><td style="text-align:center">%s</td><td>%.2f</td><td style="text-align:left">%s</td></tr>', ...
        rec.ToolName, rec.Status, rec.StartTime, rec.DurationSeconds, outputs);
end
fprintf(fid, '</table>');
end

function ok = writeDocxReport(project, docxPath, figureFiles)
ok = false;
try
    if exist('mlreportgen.dom.Document', 'class') ~= 8
        return;
    end
    import mlreportgen.dom.*
    doc = Document(docxPath, 'docx');
    open(doc);
    append(doc, Heading1('GeoDEM Pro 点云 DEM 形变分析报告'));
    append(doc, Paragraph(['生成时间：' char(datetime('now', 'Format', geodem.config.AppConfig.DateTimeFormat))]));
    append(doc, Heading2('1. 项目概况'));
    append(doc, Paragraph('本报告由 GeoDEM Pro 自动生成，内容包括点云质量检查、共同覆盖区提取、DEM 构建、DEM 差分、沉降等值线、形变分区、面积体积统计和三维可视化。'));
    append(doc, Heading2('2. 核心结果'));
    result = project.activeDeformation();
    if ~isempty(result)
        s = result.stats;
        v = result.volumeStats;
        p = result.maxSubsidencePoint;
        append(doc, Paragraph(sprintf('最大沉降 %.3f m，最大抬升 %.3f m，平均变形 %.3f m。', s.MaxSubsidence, s.MaxUplift, s.MeanChange)));
        append(doc, Paragraph(sprintf('沉降面积 %.2f m²，抬升面积 %.2f m²，稳定区比例 %.2f%%。', s.SubsidenceArea, s.UpliftArea, 100 * s.StableRatio)));
        append(doc, Paragraph(sprintf('沉降体积 %.2f m³，抬升体积 %.2f m³，净体积变化 %.2f m³。', v.SubsidenceVolume, v.UpliftVolume, v.NetVolumeChange)));
        append(doc, Paragraph(sprintf('最大沉降中心：X=%.3f，Y=%.3f，ΔZ=%.3f m。', p.X, p.Y, p.DeltaZ)));
    end
    append(doc, Heading2('3. 作业历史'));
    if isprop(project, 'toolHistory') && ~isempty(project.toolHistory)
        for i = 1:numel(project.toolHistory)
            rec = project.toolHistory(i);
            append(doc, Paragraph(sprintf('%s：%s，耗时 %.2f s，输出 %s。', rec.ToolName, rec.Status, rec.DurationSeconds, strjoin(rec.OutputLayers, ', '))));
        end
    else
        append(doc, Paragraph('当前工程暂无工具运行历史记录。'));
    end
    append(doc, Heading2('4. 成果图'));
    for i = 1:numel(figureFiles)
        append(doc, Paragraph(erase(string(getFileName(figureFiles{i})), ".png")));
        img = Image(figureFiles{i});
        img.Width = '6.2in';
        append(doc, img);
    end
    append(doc, Heading2('5. 结论'));
    append(doc, Paragraph('系统在统一共同覆盖区和统一格网分辨率下进行 DEM 差分，能够稳定输出沉降等值线、形变等级分区、统计表和报告成果。'));
    close(doc);
    ok = true;
catch
    ok = false;
end
end

function name = getFileName(path)
[~, name, ext] = fileparts(path);
name = [name ext];
end

