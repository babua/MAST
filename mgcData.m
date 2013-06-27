%Usage: 
%m = mgcData(s)
%m = mgcData(fs,frameLength,frameShift,numberOfBins,order,alpha,gamma,windowTypeString)
%
%This usage only works with an instance of mgcData (i.e. it's not static)
%m = m.read(filePath,precision)

classdef mgcData < freqDomainData
    
    properties
        order
        alpha
        gamma
    end
    
    methods
        function obj = mgcData(varargin)
            obj = obj@freqDomainData();
            if(isempty(varargin))
                
            elseif(length(varargin) == 1 && isa(varargin{1},'sptk'))
                s = varargin{1};
                obj = mgcData(s.fs,s.frameLength,s.frameShift,s.fftLength,s.mgcOrder,s.mgcAlpha,s.mgcGamma,s.windowTypeChar);
            elseif(length(varargin) == 8)
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
                    error('Number of bins must be a single value');
                end
                if(length(varargin{5})==1)
                    obj.order = varargin{5};
                else
                    error('Order must be a single value');
                end
                if(length(varargin{6})==1)
                    obj.alpha = varargin{6};
                else
                    error('Alpha must be a single value');
                end
                if(length(varargin{7})==1)
                    obj.gamma = varargin{7};
                else
                    error('Gamma must be a single value');
                end
                if(isa(varargin{8},'char'))
                    obj.windowType = varargin{8};
                else
                    error('Window type must be a char, and one of the known window handles (see help window)');
                end
                obj.data = zeros(obj.order+1,1);
                obj.maxColorValue = []; 
            else
                error('Unrecognized input argument pattern')
            end
        end

        
        function plot(obj,varargin)
            if(length(obj) > 0) %#ok<ISMT>
                if(isempty(varargin))
                    t = (1:obj.length)*(obj.frameShift/obj.fs);
                elseif(length(varargin)==2)
                    boundaries = varargin{2};
                    if(boundaries(1)>0 && boundaries(2)<obj.length)
                        t = (boundaries(1):boundaries(2))*(1/obj.fs)*obj.frameShift;
                    end
                end
                
                image(obj.data)
                
                set(gca,'YDir','normal');
                
                set(gca,'XTick',1:100:obj.length);
                set(gca,'XTickLabel',t(1:100:obj.length));
                
                y = 0:obj.order;
                set(gca,'YTick', 0:obj.order);
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
                ylabel('Mel-cepstral coefficients');
            end
        end
        
        
        function obj = read(obj,filePath,precision)
            
            if( ~obj.isPrecision(precision) )
                error([precision ' is not recognized as a precision (data type)']);
            end
            fp = fopen(filePath,'r');
            if(fp < 0)
                error([filePath ' could not be opened']);
            end
            obj.data = fread(fp, precision);
            obj.data = reshape( obj.data,obj.order+1,length(obj.data)/(obj.order+1) );
            fclose(fp);
            obj.sourceFilename = cell(0);
            obj.sourceFilename{end+1} = filePath;
        end
        
        %No need to overload write() because fwrite() called from speechData.write
        %implements the exact complement of mgcData.read();
        
    end
    
    
    
    
end