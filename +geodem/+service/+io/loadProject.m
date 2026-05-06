function project = loadProject(projectPath)
if ~isfile(projectPath)
    error('GeoDEM:ProjectNotFound', 'Project file not found: %s', projectPath);
end
loaded = load(projectPath, 'state');
if ~isfield(loaded, 'state')
    error('GeoDEM:InvalidProjectFile', 'MAT file does not contain GeoDEM project state.');
end
state = loaded.state;
projectRoot = fileparts(projectPath);
project = geodem.model.ProjectState(projectRoot);
project.deserializeState(state);
project.projectPath = projectPath;
end
