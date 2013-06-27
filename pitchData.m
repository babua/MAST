%A simple class for storing pitch trajectories

classdef pitchData < timeDomainData
    
    properties
        frameShift
        frameLength
    end
    
    methods
        
        function obj = pitchData(varargin)
            obj = obj@timeDomainData();
            if(length(varargin) ~= 1 || ~isa(varargin{1},'sptk'))
                error('Class pitchData must be instantiated only with one sptk object')
            end
            obj.fs = varargin{1}.fs;
            obj.data = [];
            obj.sourceFilename = [];
            obj.frameShift = varargin{1}.frameShift;
            obj.frameLength = varargin{1}.frameLength;
        end
        
                    %Overload plot()
            function [varargin] = plot(obj,varargin)
                if(obj.length > 0)
                    t = (1:obj.length)*obj.frameShift/obj.fs;
    
                    if isempty(varargin)
                        p = plot(t,obj.data);
                        xlabel('Time (s)')
                        ylabel('Pitch (Hz)')
                        
                        %Recursively find the last filename in the sourceFilename "tree"
                        c = obj.sourceFilename{end};
                        while(iscell(c))
                            c = c{end};
                        end
                        h = title(c);
                        set(h,'interpreter','none');
                    else
                        if(length(varargin) == 1)
                            boundaries = varargin{1};
                            plot( t(boundaries(1):boundaries(2)) , obj.data(boundaries(1):boundaries(2)) );
                        else
                            error('One start point and one end point must be given');
                        end
                        
                    end
                    varargin{1} = p;
                else
                    error('There is no data in the object');
                end
            end
    end
    
    
    
    
    

    
    
    
end
