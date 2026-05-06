function text = summarizeDeformation(result)
%SUMMARIZEDEFORMATION Produce a short Chinese conclusion for a deformation result.

if isempty(result)
    text = "尚未生成形变分析结果。";
    return;
end
s = result.stats;
p = result.maxSubsidencePoint;
dominant = "稳定";
areas = [s.SubsidenceArea, s.UpliftArea, s.StableArea];
[~, idx] = max(areas);
if idx == 1
    dominant = "沉降";
elseif idx == 2
    dominant = "抬升";
end
ratio = 100 * s.SubsidenceArea / max(s.TotalValidArea, eps);
text = sprintf(['本区域整体以%s为主，最大沉降值为 %.3f m，位于 X=%.3f, Y=%.3f。' ...
    '沉降面积约 %.2f m²，占有效分析面积 %.2f%%；净体积变化为 %.2f m³。'], ...
    dominant, s.MaxSubsidence, p.X, p.Y, s.SubsidenceArea, ratio, result.volumeStats.NetVolumeChange);
text = string(text);
end
