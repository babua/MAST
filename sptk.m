classdef sptk
    properties
        
        sptkDir = '/usr/local/SPTK/bin';
        
        bc = '/usr/bin/bc';
        wc = '/usr/bin/wc';
        tclsh = '/usr/local/bin/tclsh';
        getf0tcl = '/Users/Work/Sources/MATLAB/Toolboxes/getf0.tcl';
        
%         %SPTK Analysis parameters/
%         fs = 48000;
%         frameLength = 1200;
%         frameShift = 240;
%         windowType = 1; % 0: Blackman 1: Hamming 2: Hanning
%         normalize = 1; % 0: none 1: by power 2: by magnitude
%         fftLength = 2048;
%         mgcAlpha = 0.55;
%         mgcGamma = 0;
%         mgcOrder = 34;
%         mgcLsp = 0; %convert MGC coefficients into MGC-LSP form
%         lnGain = 1; %use logarithmic gain instead of linear gain
%         noiseMask = 50; %standard deviation of white noise to mask noises in f0 extraction


        %SPTK Analysis parameters for 16kHz
        fs = 16000;
        frameLength = 400;
        frameShift = 80;
        windowType = 1; % 0: Blackman 1: Hamming 2: Hanning
        normalize = 1; % 0: none 1: by power 2: by magnitude
        fftLength = 512;
        mgcAlpha = 0.42;
        mgcGamma = 0;
        mgcOrder = 24;
        mgcLsp = 0; %convert MGC coefficients into MGC-LSP form
		mgcPeriodogramOffset = 0;
		mgcMinimumDeterminant = 1e-6;
        lnGain = 1; %use logarithmic gain instead of linear gain
        noiseMask = 50; %standard deviation of white noise to mask noises in f0 extraction

        
        mlsadfFilterWithoutGain = 0; %-k option of mgcep
        
        f0Min = 110;
        f0Max = 280;
        thresholdSWIPE = 0.3;
        shift = 3;
        
        precision = 'single'; %used for file i/o
        
        verbose = 0;
        speakAloud = 0; %Set to 1 to display terminal commands in the MATLAB command window
        
    end
    
    properties (Dependent = true);
        
        swab
        x2x
        frame
        window
        mgcep
        lpc2lsp
        step
        merge
        vstat
        nrand
        sopr
        excite
        vopr
        nan
        mlsadf
        pitch
		mgc2mgc
        
        tmpDir
        windowTypeChar
        
    end
    
    methods
        %==Dependent property constructors==
        function swab = get.swab(s)
            swab = [s.sptkDir , '/swab'];
        end
        function x2x = get.x2x(s)
            x2x = [s.sptkDir , '/x2x'];
        end
        function frame = get.frame(s)
            frame = [s.sptkDir , '/frame'];
        end
        function window = get.window(s)
            window = [s.sptkDir , '/window'];
        end
        function mgcep = get.mgcep(s)
            mgcep = [s.sptkDir , '/mgcep'];
        end
        function lpc2lsp = get.lpc2lsp(s)
            lpc2lsp = [s.sptkDir , '/lpc2lsp'];
        end
        function step = get.step(s)
            step = [s.sptkDir , '/step'];
        end
        function merge = get.merge(s)
            merge = [s.sptkDir , '/merge'];
        end
        function vstat = get.vstat(s)
            vstat = [s.sptkDir , '/vstat'];
        end
        function nrand = get.nrand(s)
            nrand = [s.sptkDir , '/nrand'];
        end
        function sopr = get.sopr(s)
            sopr = [s.sptkDir , '/sopr'];
        end
        function excite = get.excite(s)
            excite = [s.sptkDir , '/excite'];
        end
        function vopr = get.vopr(s)
            vopr = [s.sptkDir , '/vopr'];
        end
        function nan = get.nan(s)
            nan = [s.sptkDir , '/nan'];
        end
        function mlsadf = get.mlsadf(s)
            mlsadf = [s.sptkDir , '/mlsadf'];
        end
        function pitch = get.pitch(s)
            pitch = [s.sptkDir , '/pitch'];
		end
		function mgc2mgc = get.mgc2mgc(s)
            mgc2mgc = [s.sptkDir , '/mgc2mgc'];
        end
        
        function tmpDir = get.tmpDir(s) %#ok<MANU>
            if(isunix())
                tmpDir = '/tmp';
            elseif(ispc())
                tmpDir = 'C:\TEMP';
            end
        end
        function wtchar = get.windowTypeChar(s)
            switch s.windowType
                case 0
                    wtchar = 'blackman';
                case 1
                    wtchar = 'hamming';
                case 2
                    wtchar = 'hanning';
            end
        end
        %==Dependent property constructors==
        
        %SPTK Methods
        function mgc = extractMgc(s,tdd)
            %Usage
            %mgc = s.extractMgc(tdd)ex
            
            if(~isa(tdd,'timeDomainData'))
                error('Input must implement class timeDomainData')
            end
            
            %Paths to temporary files
            tmpInput = [s.tmpDir  filesep 'MAST_extractMgc_tmpdata'];
            tmpOutput = [s.tmpDir  filesep 'MAST_extractMgc_tmpdataout'];
            if(s.verbose)
                display('MAST:Extracting MGCs using mgcep...')
            end
            tdd.write(tmpInput,'float');
			
			[status, result] = systemCallMAST(s, [s.frame ' -l ' num2str(s.frameLength) ' -p ' num2str(s.frameShift) ' ' tmpInput ' | ' s.window ' -l ' num2str(s.frameLength) ' -L ' num2str(s.fftLength) ' -w ' num2str(s.windowType) ' -n 1 | ' s.mgcep ' -f ' num2str(s.mgcMinimumDeterminant,'%.16f') ' -e ' num2str(s.mgcPeriodogramOffset,'%.16f') ' -a ' num2str(s.mgcAlpha) ' -m ' num2str(s.mgcOrder) ' -l ' num2str(s.fftLength) ' > ' tmpOutput] );
			if(status)
				display('MAST: Retrying MGC extraction with higher order because: ')
				disp([result])
				display(['MAST: Results will be converted back to the original order'])
				mgcExtractionSuccessful = 0;
				
				newTmpInput = [s.tmpDir  filesep 'MAST_extractMgc_retry_tmpdata'];
				
% 				[statusMove resultMove] = movefile(tmpOutput , newTmpInput);
% 				if(statusMove)
% 					error(resultMove)
% 				end
				
				numberOfTries = 1;
				maxRetries = 5;
				while(numberOfTries <= maxRetries && ~mgcExtractionSuccessful)
					newMgcOrder = s.mgcOrder + numberOfTries;
					[statusRetry, resultRetry] = systemCallMAST(s, [s.frame ' -l ' num2str(s.frameLength) ' -p ' num2str(s.frameShift) ' ' tmpInput ' | ' s.window ' -l ' num2str(s.frameLength) ' -L ' num2str(s.fftLength) ' -w ' num2str(s.windowType) ' -n 1 | ' s.mgcep ' -f ' num2str(s.mgcMinimumDeterminant,'%.16f') ' -e ' num2str(s.mgcPeriodogramOffset,'%.16f') ' -a ' num2str(s.mgcAlpha) ' -m ' num2str(newMgcOrder) ' -l ' num2str(s.fftLength) ' > ' newTmpInput] );
					if(statusRetry)
						numberOfTries = numberOfTries + 1;
					else
						mgcExtractionSuccessful = 1;
						[statusConvert, resultConvert] = systemCallMAST(s, [s.mgc2mgc ' -m ' num2str(newMgcOrder) ' -a ' num2str(s.mgcAlpha) ' -g ' num2str(s.mgcGamma) ' -M ' num2str(s.mgcOrder) ' -A ' num2str(s.mgcAlpha) ' -G ' num2str(s.mgcGamma) ' < ' newTmpInput ' > ' tmpOutput ]);
						if(statusConvert)
							error(resultConvert)
						end
					end
				end
			end
          
            mgc = mgcData(s);
            mgc = mgc.read(tmpOutput,'float');
            %While processing files with this toolbox, proper usage is:
            %mgc.sourceFilename{end+1} = tdd.sourceFilename;
            %But we know this is the origin of this object, so it converges to the next line in this case
            mgc.sourceFilename{1} = tdd.sourceFilename;
            
            %Clean up temporary files
            if(isunix())
                systemCallMAST(s,['rm -f ' tmpInput]);
                systemCallMAST(s,['rm -f ' tmpOutput]);
            elseif(ispc())
                %TODO: For Windows
            end
            if(s.verbose)
                display('MAST:MGC extraction using mgcep complete.')
            end
        end
        
        function tddFiltered = filterMlsadf(s,tdd,mgc,varargin)
            %Usage
            %tddFiltered = s.filterMlsadf(tdd,mgc)
            %tddFiltered = s.filterMlsadf(tdd,mgc,'inverse') or tddFiltered = s.filterMlsadf(tdd,mgc,'i')
            
            
            %Resolve whether filtering without gain is requested
            if(s.mlsadfFilterWithoutGain)
                k = ' -k ';
            else
                k = [];
            end
            
            %Resolve whether inverse filtering is requested
            v = [];
            if(length(varargin) == 0) %#ok<*ISMT>
            elseif(length(varargin) == 1)
                if(isa(varargin{1},'char'))
                    if(strcmpi(varargin{1},'inverse') || strcmpi(varargin{1},'i'))
                        v = ' -v ';
                    else
                        error(['Unrecognized input argument' varargin{1}])
                    end
                else
                    error('Optional input argument must be of type char');
                end
            else
                error('Too many input arguments')
            end
            
            tmpMgc = [s.tmpDir  filesep 'MAST_mlsadf_tmpmgc'];
            tmpExc = [s.tmpDir  filesep 'MAST_mlsadf_tmpexc'];
            tmpSynth = [s.tmpDir filesep 'MAST_mlsadf_tmpsynth'];
            
            tdd.write(tmpExc,'float');
            mgc.write(tmpMgc,'float');
            
            if(s.verbose)
                if(isempty(v))
                    display('MAST:Filtering with mlsadf...')
                else
                    display('MAST:Inverse filtering with mlsadf...')
                end
            end
            
            [status, result] = systemCallMAST(s, [s.mlsadf ' -p ' num2str(s.frameShift) ' -a ' num2str(s.mgcAlpha) ' -m ' num2str(s.mgcOrder) k v ' ' tmpMgc ' ' tmpExc ' > ' tmpSynth] );
            if(status)
                error(result);
            end
            
            tddFiltered = timeDomainData(s,tmpSynth,'float');
            %because sourceFilename{end} will be the temporary file path in tmpSynth,
            %we can directly overwrite it instead of removing it and concatenating our
            %real source file paths
            tddFiltered.sourceFilename{end} = tdd.sourceFilename;
            tddFiltered.sourceFilename{end+1} = mgc.sourceFilename;
            
            %Clean up files
            if(isunix())
                systemCallMAST(s,['rm -f ' tmpMgc]);
                systemCallMAST(s,['rm -f ' tmpExc]);
                systemCallMAST(s,['rm -f ' tmpSynth]);
            elseif(ispc())
                %TODO: For Windows
            end
            
            if(s.verbose)
                if(isempty(v))
                    display('MAST:Filtering with mlsadf complete.')
                else
                    display('MAST:Inverse filtering with mlsadf complete.')
                end
            end
            
        end
        
        function pitch = extractPitchGetF0(s,tdd)
            %speechSignal values are floats in [0,1]

            
            if(~isa(tdd,'timeDomainData'))
                error('Input object is not of type timeDomainData')
            end
            tmp = [s.tmpDir filesep 'sptkExtractPitchRAPTgetf0_tmp'];
            tmpRaw = [s.tmpDir filesep 'sptkExtractPitchRAPTgetf0_tmp.raw'];
            tmpHead = [s.tmpDir filesep 'sptkExtractPitchRAPTgetf0_tmp.head'];
            tmpTail = [s.tmpDir filesep 'sptkExtractPitchRAPTgetf0_tmp.tail'];
            lf0File = [s.tmpDir filesep 'sptkExtractPitchRAPTgetf0_lf0'];
            rawFile = [s.tmpDir filesep 'sptkExtractPitchRAPTgetf0_tmprawfile.raw'];
            
            speechSignal = tdd.data;
            if(size(speechSignal,2)==2)
                warning('Using column 1 of 2-column data') %#ok<WNTAG>
                speechSignal = speechSignal(:,1);
            end
            speechSignal = speechSignal ./ max(abs(speechSignal));
            
            speechSignal = speechSignal .* (precisionScalingFactor('int16')/precisionScalingFactor(class(speechSignal)));
            
            fp = fopen(rawFile,'w');
            fwrite(fp,speechSignal,'int16');
            fclose(fp);
            
            if(s.verbose)
                display('MAST:Pitch extraction using the RAPT algorithm (getf0.tcl)...')
            end
            
            [status, result] = systemCallMAST(s, [ s.step ' -l ' num2str(s.frameShift) ' -v 0.0 | ' s.x2x ' +fs > ' tmpHead ] );
            if(status)
                error(result);
            end
            [status, result] = systemCallMAST(s, [ s.step ' -l ' num2str(s.frameLength) ' -v 0.0 | ' s.x2x ' +fs > ' tmpTail ] );
            if(status)
                error(result);
            end
            
            if(isunix())
                [status, result] = systemCallMAST(s, [ 'cat ' tmpHead ' ' rawFile ' ' tmpTail ' | ' s.x2x ' +sf > ' tmp] );
                if(status)
                    error(result);
                end
                [status, result] = systemCallMAST(s, [  s.x2x ' +fa ' tmp ' | ' s.wc ' -l' ] );
                lineCount = num2str(str2num(result)); %#ok<ST2NM>
                
                if(status)
                    error(result);
                end
            else
                %TODO:For Windows
            end
            
[status, result] = systemCallMAST(s, [ s.nrand ' -l ' lineCount ' | ' s.sopr ' -m ' num2str(s.noiseMask) ' | ' s.vopr ' -a ' tmp ' > ' tmpRaw ] );
            if(status)
                error(result);
            end
            
            fp = fopen(tmpRaw,'r');
            floatData = fread(fp,'float');
            fclose(fp);
            floatData = floatData./(max(abs(floatData)))*32768;
            fp = fopen(tmpRaw,'w');
            fwrite(fp,floatData,'int16');
            fclose(fp);
            
            [status, result] = systemCallMAST(s, [ s.tclsh ' ' s.getf0tcl ' -l -lf0 -H ' num2str(s.f0Max) ' -L ' num2str(s.f0Min) ' -p ' num2str(s.frameShift) ' -r ' num2str(s.fs) ' ' tmpRaw ' | ' s.x2x ' +af > ' lf0File ] );
            if(status)
                error(result);
            end
            
            %Prepare object to be returned
            pitch = pitchData(s);
            pitch = pitch.read(lf0File,'float');
            %Convert from log(Hz) to Hz
            pitch.data = exp(pitch.data);
            pitch.sourceFilename = tdd.sourceFilename;
            pitch.fs = s.fs;
            
            
            %Clean up
            if(isunix())
                [status, result] = systemCallMAST(s,[ 'rm -f ' tmp ' ' tmpRaw ' ' tmpHead ' ' tmpTail ' ' lf0File ' ' rawFile ]); %remove temporary files
                %TODO: For Windows
            end
            if(status)
                error(result)
            end
            
            if(s.verbose)
                display('MAST:Pitch extraction using the RAPT algorithm (getf0.tcl) complete.')
            end
            
        end
        
         function pitch = extractPitchRAPT(s,tdd)
            %speechSignal values are floats in [0,1]

            
            if(~isa(tdd,'timeDomainData'))
                error('Input object is not of type timeDomainData')
            end

            f0File = [s.tmpDir filesep 'sptkExtractPitchRAPT_f0'];
            rawFile = [s.tmpDir filesep 'sptkExtractPitchRAPT_tmprawfile.raw'];
            
            speechSignal = tdd.data;
            if(size(speechSignal,2)==2)
                warning('Using column 1 of 2-column data') %#ok<WNTAG>
                speechSignal = speechSignal(:,1);
            end
            speechSignal = speechSignal ./ max(abs(speechSignal));
			speechSignal = speechSignal .* (precisionScalingFactor('int16')/precisionScalingFactor(class(speechSignal)));

			
			
            fp = fopen(rawFile,'w');
            fwrite(fp,speechSignal,'single');
            fclose(fp);
            
            if(s.verbose)
                display('MAST:Pitch extraction using the RAPT algorithm...')
            end
            
            [status, result] = systemCallMAST(s, [ s.pitch ' -o 1 -a 0 -s ' num2str(s.fs/1000) ' -p ' num2str(s.frameShift) ' -L ' num2str(s.f0Min) ' -H ' num2str(s.f0Max) ' ' rawFile ' > ' f0File] );
            if(status)
                error(result);
            end
            
            %Prepare object to be returned
            pitch = pitchData(s);
            pitch = pitch.read(f0File,'single');
            pitch.sourceFilename = tdd.sourceFilename;
            pitch.fs = s.fs;
            
            
            %Clean up
            if(isunix())
                [status, result] = systemCallMAST(s,[ 'rm -f ' f0File ' ' rawFile ]); %remove temporary files
                %TODO: For Windows
            end
            if(status)
                error(result)
            end
            
            if(s.verbose)
                display('MAST:Pitch extraction using the RAPT algorithm complete.')
            end
            
        end
        
        function pitch = extractPitchSWIPE(s,tdd)
            %speechSignal values are floats in [0,1]

            
            if(~isa(tdd,'timeDomainData'))
                error('Input object is not of type timeDomainData')
            end

            f0File = [s.tmpDir filesep 'sptkExtractPitchSWIPE_f0'];
            rawFile = [s.tmpDir filesep 'sptkExtractPitchSWIPE_tmprawfile.raw'];
            
            speechSignal = tdd.data;
            if(size(speechSignal,2)==2)
                warning('Using column 1 of 2-column data') %#ok<WNTAG>
                speechSignal = speechSignal(:,1);
            end
            speechSignal = speechSignal ./ max(abs(speechSignal));
            
            fp = fopen(rawFile,'w');
            fwrite(fp,speechSignal,'double');
            fclose(fp);
            
            if(s.verbose)
                display('MAST:Pitch extraction using the SWIPE algorithm...')
            end
            
            [status, result] = systemCallMAST(s, [ s.pitch ' -a 1 -t ' num2str(s.thresholdSWIPE) ' -s ' num2str(s.fs/1000) ' -p ' num2str(s.frameShift) ' -L ' num2str(s.f0Min) ' -H ' num2str(s.f0Max) ' ' rawFile ' > ' f0File] );
            if(status)
                error(result);
            end
            
            %Prepare object to be returned
            pitch = pitchData(s);
            pitch = pitch.read(f0File,'double');
            pitch.sourceFilename = tdd.sourceFilename;
            pitch.fs = s.fs;
            
            
            %Clean up
            if(isunix())
                [status, result] = systemCallMAST(s,[ 'rm -f ' f0File ' ' rawFile ]); %remove temporary files
                %TODO: For Windows
            end
            if(status)
                error(result)
            end
            
            if(s.verbose)
                display('MAST:Pitch extraction using the SWIPE algorithm complete.')
            end
            
        end
        
       
        
        
        function pulse = exciteFromPitch(s,pd)
            %Usage 
            %pulse = s.exciteFromPitch(pitch)
            
            tmpPulsePeriodFile = [s.tmpDir filesep 'MAST_exciteFromPitch_tmppulseperiod.pp'];
            tmpPulseFile = [s.tmpDir filesep 'MAST_exciteFromPitch_tmppulse.pulse'];
            
            f0 = pd.data;
            pitchPeriods = (1./f0*s.fs);
            pitchPeriods(pitchPeriods==Inf) = 0;
            fp = fopen(tmpPulsePeriodFile,'w');
            if(fp)
                fwrite(fp,pitchPeriods,s.precision);
            else
                error([tmpPulsePeriodFile ' could not be opened for writing'])
            end
            
            if(s.verbose)
                display('MAST:Preparing pulse excitation from pitch trajectory using excite...')
            end
            
            [status result] = systemCallMAST(s,[s.excite ' -p ' num2str(pd.frameShift) ' -n ' tmpPulsePeriodFile ' > ' tmpPulseFile ]);
            if(status)
                error(result)
            end
            
            pulse = timeDomainData(s,tmpPulseFile);
            
            %Clean up
            [status result] = systemCallMAST(s,['rm ' tmpPulsePeriodFile ' ' tmpPulseFile]);
            if(status)
                error(result)
            end
            if(s.verbose)
                display('MAST:Preparing pulse excitation from pitch trajectory using excite complete')
            end
            
        end
        
        function [status result] = systemCallMAST(s,command)
            [status result] = system(command);
            if(s.speakAloud)
                display(['MAST: ' command])
            end
        end
        
    end
end
