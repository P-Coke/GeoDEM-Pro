function [file, path] = uigetfile(varargin) %#ok<INUSD>
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
hits = dir(fullfile(root, '**', 'cloud_merged_6.csv'));
if isempty(hits)
    file = 0;
    path = 0;
    return;
end
path = hits(1).folder;
file = {'cloud_merged_6.csv', 'cloud_merged_12.txt'};
end
