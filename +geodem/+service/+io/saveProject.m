function saveProject(project, projectPath)
if nargin < 2 || isempty(projectPath)
    projectPath = fullfile(project.outputDir, 'GeoDEMPro_project.gdem');
end
projectPath = char(projectPath);
folder = fileparts(projectPath);
if ~isempty(folder) && ~exist(folder, 'dir')
    mkdir(folder);
end
state = project.serializeState();
state.projectPath = projectPath;
save(projectPath, 'state', '-v7.3');
project.projectPath = projectPath;
end
