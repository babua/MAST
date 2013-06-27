%Abstract class from which other data classes inherit

classdef speechData
    
    properties(Abstract = true)
        fs
        data
        sourceFilename
    end
    
    methods
        function obj = read(obj,filePath,precision)
            %Check if precision is recognized
            if( ~obj.isPrecision(precision) )
                error([precision ' is not recognized as a precision (data type)']);
            end
            
            fp = fopen(filePath,'r');
            if(fp < 0)
                error([filePath ' could not be opened']);
            end
            
            obj.data = fread(fp, precision);
            fclose(fp);
            obj.sourceFilename = cell(0);
            obj.sourceFilename{end+1} = filePath;
        end
        
        function write(obj,filePath,precision)
            %Check if precision is recognized
            if( ~obj.isPrecision(precision) )
                error([precision ' is not recognized as a precision (data type)']);
            end
            fp = fopen(filePath,'w');
            if(fp < 0)
                error([filePath ' could not be opened']);
            end
            fwrite(fp, obj.data, precision);
            fclose(fp);
        end
        
        function b = isPrecision(obj,precisionString)
            if( strcmpi(precisionString, 'int8') || strcmpi(precisionString, 'uint8') || strcmpi(precisionString, 'int16') || strcmpi(precisionString, 'uint16') || strcmpi(precisionString, 'int32') || strcmpi(precisionString, 'uint32') || strcmpi(precisionString, 'int64') || strcmpi(precisionString, 'uint64') || strcmpi(precisionString, 'float') || strcmpi(precisionString, 'single') || strcmpi(precisionString, 'double') )
                b = 1;
            else
                b = 0;
            end
        end
        
    end
end