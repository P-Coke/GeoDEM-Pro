classdef GeoDemApplication < handle
    %GEODEMAPPLICATION Application facade used by the public startup script.

    properties (SetAccess = private)
        Controller
    end

    properties (Dependent)
        ProjectRoot
        Project
        View
        SelectedToolId
    end

    methods
        function obj = GeoDemApplication(projectRoot)
            obj.Controller = geodem.controller.AppController(projectRoot);
        end

        function value = get.ProjectRoot(obj)
            value = obj.Controller.ProjectRoot;
        end

        function value = get.Project(obj)
            value = obj.Controller.Project;
        end

        function set.Project(obj, value)
            obj.Controller.Project = value;
        end

        function value = get.View(obj)
            value = obj.Controller.View;
        end

        function value = get.SelectedToolId(obj)
            value = obj.Controller.SelectedToolId;
        end

        function set.SelectedToolId(obj, value)
            obj.Controller.SelectedToolId = value;
        end

        function varargout = updateView(obj, varargin)
            [varargout{1:nargout}] = obj.Controller.updateView(varargin{:});
        end

        function varargout = importCloud(obj, varargin)
            [varargout{1:nargout}] = obj.Controller.importCloud(varargin{:});
        end

        function varargout = importLasCloud(obj, varargin)
            [varargout{1:nargout}] = obj.Controller.importLasCloud(varargin{:});
        end

        function varargout = importDem(obj, varargin)
            [varargout{1:nargout}] = obj.Controller.importDem(varargin{:});
        end

        function varargout = renderLayer(obj, varargin)
            [varargout{1:nargout}] = obj.Controller.renderLayer(varargin{:});
        end

        function varargout = selectTool(obj, varargin)
            [varargout{1:nargout}] = obj.Controller.selectTool(varargin{:});
        end

        function varargout = runSelectedTool(obj, varargin)
            [varargout{1:nargout}] = obj.Controller.runSelectedTool(varargin{:});
        end

        function varargout = subsref(obj, s)
            try
                [varargout{1:nargout}] = builtin('subsref', obj, s);
            catch ME
                if strcmp(ME.identifier, 'MATLAB:noSuchMethodOrField') && ~isempty(obj.Controller)
                    [varargout{1:nargout}] = subsref(obj.Controller, s);
                else
                    rethrow(ME);
                end
            end
        end
    end
end
