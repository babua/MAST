%
%Constructor:
%t = timeDomainData(s)
%t = timeDomainData(s,samples)
%t = timeDomainData(s,filePath)
%Additional non-sptk-struct options for flexibility
%t = timeDomainData(fs)
%t = timeDomainData(fs,samples)
%t = timeDomainData(fs,filePath,precision)
%
%Public Properties:
%fs - Sampling frequency
%data - Numeric array of data data
%
%Overloaded methods: plot(),length(),min(),max()
%
%To crop data:
%objCropped = obj.extract(int beginSamplePoint , int endSamplePoint)
%
%Plot a portion of data w/o cropping
%plot(obj,[int beginSamplePoint, int endSamplePoint])


classdef timeDomainData < speechData
    properties
        fs
        data
        sourceFilename
    end
    
    
    methods
        %==Constructor==
        function obj = timeDomainData(varargin)
            obj = obj@speechData();
            if(isempty(varargin))
                
            elseif(length(varargin)==1)
                if(isa(varargin{1},'sptk'))
                    obj.fs = varargin{1}.fs;
                elseif(length(varargin{1}==1) && isnumeric(varargin{1}) ) %#ok<ISMT>
                    obj.fs = varargin{1};
                else
                    error('Sampling frequency fs must either be a single value, or an instance of sptk() must be passed as input');
                end
                
            elseif(length(varargin)==2)
                %Get sampling frequency from input
                if(isa(varargin{1},'sptk'))
                    obj.fs = varargin{1}.fs;
                elseif(length(varargin{1}==1) && isnumeric(varargin{1})) %#ok<ISMT>
                    obj.fs = varargin{1};
                else
                    error('Sampling frequency fs must either be a single value, or an instance of sptk() must be passed as input');
                end
                
                %Get either the data directly from a numeric array, or read from file
                %pointed to by a file path
                if (isa(varargin{2},'numeric'))
                    obj.data = varargin{2};
                    obj.sourceFilename{end+1} = [];
                    
                elseif(isa(varargin{2},'char'))
                    if(exist(varargin{2},'file'))
                        obj = obj.read(varargin{2},varargin{1}.precision);
                    else
                        error([varargin{2} ' cannot be accessed or is not a file'])
                    end
                else
                    error('Second argument must either be a numeric array or a path to a file on disk');
                end
                
            elseif(length(varargin)==3)
                if(isa(varargin{1},'sptk'))
                    obj.fs = varargin{1}.fs;
                elseif(length(varargin{1}==1)) %#ok<ISMT>
                    obj.fs = varargin{1};
                else
                    error('Sampling frequency fs must be a single value');
                end
                
                if(isa(varargin{2},'char'))
                    if(exist(varargin{2},'file'))
                        filePath =  varargin{2};
                    else
                        error([varargin{2} ' cannot be accessed or is not a file'])
                    end
                end
                
                if(isa(varargin{2},'char'))
                    if(obj.isPrecision(varargin{3}))
                        precision = varargin{3};
                    else
                        error([varargin{3} ' is not recognized as a precision (data type)']);
                    end
                end
                
                obj = obj.read(filePath,precision);
            else
                error('Unrecognized input argument pattern')
            end
        end
        %==Constructor==
        
        
        function newObj = extract(obj,beginPoint,endPoint)
            %Returns a new timeDomainData object containing the data between beginPoint
            %and endPoint
            if( (beginPoint > 0) && endPoint < obj.length)
                tmpdata = obj.data(beginPoint:endPoint);
                newObj = timeDomainData(obj.fs,tmpdata);
                newObj.sourceFilename = obj.sourceFilename;
			else
				error('Index out of bounds')
			end
        end
        
        %Overload plot()
        function plot(obj,varargin)
            if(obj.length > 0)
                t = (1:obj.length)/obj.fs;
                
                if isempty(varargin)
                    plot(t,obj.data);
                    xlabel('Time (s)')
                    ylabel('Amplitude')
                    
                    %Recursively find the last filename in the sourceFilename "tree"
					if(~isempty(obj.sourceFilename))
                    c = obj.sourceFilename{end};
                    while(iscell(c))
                        c = c{end};
                    end
                    h = title(c);
                    set(h,'interpreter','none');
					end
                else
                    if(length(varargin) == 1)
                        boundaries = varargin{1};
                        plot( t(boundaries(1):boundaries(2)) , obj.data(boundaries(1):boundaries(2)) );
                    else
                        error('One start point and one end point must be given');
                    end
                    
                end
                
            else
                error('There is no data in the object');
            end
        end
        
        %Overload length()
        function l = length(obj)
            l = length(obj.data);
        end
        
        %Overload min() and max()
        function m = min(obj)
            m = min(obj.data);
        end
        function m = max(obj)
            m = max(obj.data);
        end
        
        function m = minmax(obj)
            a = min(obj);
            b = max(obj);
            m = [a,b];
        end
        
        %Play sound
        function play(obj)
            display(['MAST: Playing sound...'])
			
			if(ismac())
			y = obj.data;
			y = 0.99*y./max(abs(y));
			wavwrite(y,obj.fs,'/tmp/MAST_tmpPlayFile.wav');
			!afplay '/tmp/MAST_tmpPlayFile.wav'
			else
            soundsc(obj.data,obj.fs)
			end
            display(['MAST: Finished playing sound.']);
        end
        
        %Overload operators
        %TODO
        
    end
    
end
