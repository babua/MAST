%Usage
%f = freqDomainData(s)
%f = freqDomainData(fs)
%f = freqDomainData(fs,frameLength,frameShift,nBins,windowTypeChar)
classdef freqDomainData < speechData
    
    properties
        fs
        data
        
        frameLength
        frameShift
        nBins %number of bins used in FFT, "FFT length"
        
        windowType
        
        maxColorValue
        sourceFilename
    end
    
    methods
        %==Constructor==
        function obj = freqDomainData(varargin)
            obj = obj@speechData();
            if(isempty(varargin))
            elseif(length(varargin)==1)
                
                if(isa(varargin{1},'sptk'))
                    s = varargin{1};
                    obj = freqDomainData(s.fs,s.frameLength,s.frameShift,s.fftLength,s.windowTypeChar);
                elseif(length(varargin{1}==1) && isnumeric(varargin{1}) ) %#ok<ISMT>
                    obj.fs = varargin{1};
                else
                    error('Sampling frequency must be a single value');
                end
                
            elseif(length(varargin)==5)
                if(length(varargin{1})==1)
                    obj.fs = varargin{1};
                else
                    error('Sampling frequency must be a single value');
                end
                if(length(varargin{2})==1)
                    obj.frameLength = varargin{2};
                else
                    error('Frame length must be a single value');
                end
                if(length(varargin{3})==1)
                    obj.frameShift = varargin{3};
                else
                    error('Frame shift must be a single value');
                end
                if(length(varargin{4})==1)
                    obj.nBins = varargin{4};
                else
                    error('Number of bins (nBins) must be a single value');
                end
                if(isa(varargin{5},'char'))
                    obj.windowType = varargin{5};
                else
                    error('Window type must be a char, and one of the known window handles (see help window)');
                end
                %Initialize data with dummy values
                obj.data = zeros(obj.nBins,1);
                %Leave this to the user
                obj.maxColorValue = [];
                
            else
                error('Unrecognized input argument pattern')
            end
        end
        %==Constructor==
        
        function obj = read(obj,filePath,precision)
            
            if( ~obj.isPrecision(precision) )
                error([precision ' is not recognized as a precision (data type)']);
            end
            fp = fopen(filePath,'r');
            if(fp < 0)
                error([filePath ' could not be opened']);
            end
            obj.data = fread(fp, precision);
            obj.data = reshape( obj.data,obj.nBins+1,length(obj.data)/(obj.nBins+1) );
            fclose(fp);
            obj.sourceFilename = cell(0);
            obj.sourceFilename{end+1} = filePath;
        end
        
        %No need to overload write() because fwrite() called from speechData.write
        %implements the exact complement of freqDomainData.read();
        
        
        %Overload plot()
        function plot(obj,varargin)
            if(length(obj) > 0)
                if(isempty(varargin))
                    t = (1:obj.length)*(1/obj.fs)*obj.frameShift;
                elseif(length(varargin)==2)
                    boundaries = varargin{2};
                    if(boundaries(1)>0 && boundaries(2)<obj.length)
                        t = (boundaries(1):boundaries(2))*(1/obj.fs)*obj.frameShift;
                    end
                end
                image(obj.data)
                set(gca,'YDir','normal');
                
                set(gca,'XTickLabel',t);
                
                y = (0:0.5:1)*(obj.fs/2);
                set(gca,'YTick', [1,obj.nBins/2,obj.nBins]);
                set(gca,'YTickLabel',y);

                if(isempty(obj.maxColorValue))
                    if(max(max(obj.data)))
                        colormap(jet( ceil(max(max(obj.data))) ));
                    else
                        colormap(jet(512));
                    end
                else
                    colormap(jet(obj.maxColorValue))
                end
                
                xlabel('Time (s)');
                ylabel('Frequency (Hz)');
            end
        end
        
        %Overload length()
        function l = length(obj)
            l = size(obj.data,2);
        end
        
        %Overload max()
        function m = max(obj,varargin)
            %Returns the maximum value in each column if no additional
            %arguments are specified.
            %Returns the maximum value from the whole matrix with:
            %maxVals = max(freqDomainData,'whole)
            if(isempty(varargin))
                m = max(obj.data);
            elseif(length(varargin) == 1)
                if(isa(varargin{1},char))
                    if(strcmpi(varargin{1},'whole'))
                        m = max(max(obj.data));
                    end
                else
                    error('Second argument must be of type char')
                end
                error('Too many input arguments')
            end
        end
        
        %Overload min()
        function m = min(obj,varargin)
            %Returns the minimum value in each column if no additional
            %arguments are specified.
            %Returns the minimum value from the whole matrix with:
            %maxVals = min(freqDomainData,'whole)
            if(isempty(varargin))
                m = min(obj.data);
            elseif(length(varargin) == 1)
                if(isa(varargin{1},char))
                    if(strcmpi(varargin{1},'whole'))
                        m = min(min(obj.data));
                    end
                else
                    error('Second argument must be of type char')
                end
                error('Too many input arguments')
            end
        end
        
        function m = minmax(obj)
            a = min(obj,'whole');
            b = max(obj,'whole');
            m = [a,b];
        end
        
    end
    
end