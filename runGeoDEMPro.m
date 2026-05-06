function app = runGeoDEMPro()
%RUNGEODEMPRO Launch the GeoDEM Pro MATLAB application.

projectRoot = fileparts(mfilename('fullpath'));
if isempty(projectRoot)
    projectRoot = pwd;
end
configureSourceEncoding();
initializeProjectPath(projectRoot);
app = geodem.app.GeoDemApplication(projectRoot);
end

function initializeProjectPath(projectRoot)
%INITIALIZEPROJECTPATH Put the GeoDEM Pro package root on the MATLAB path.

projectRoot = char(projectRoot);
if isempty(projectRoot) || ~exist(projectRoot, 'dir')
    projectRoot = pwd;
end
if ~exist(fullfile(projectRoot, '+geodem'), 'dir')
    error('GeoDEM:InvalidProjectRoot', '未找到 GeoDEM Pro 包目录：%s', fullfile(projectRoot, '+geodem'));
end
addpath(projectRoot, '-begin');
end

function configureSourceEncoding()
if exist('slCharacterEncoding', 'file') == 2
    try
        slCharacterEncoding('UTF-8');
    catch
    end
end
end
