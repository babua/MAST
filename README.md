MAST
====

Matlab Toolbox for SPTK


==DESCRIPTION==

MAST is a small MATLAB toolbox that attempts to alleviate the pain of using SPTK in conjunction with MATLAB. It consists of a set of objects to interface with the local SPTK installation and tries to be as intuitive as possible using object-oriented paradigms.

It's in very early stages of development, with the philosophy of building a small set of functionality with as much forward-thinking as possible, and iteratively increase the functionality and scope based on user feedback and experience.


==USAGE INSTRUCTIONS==

[Windows is not supported yet, sorry! Let me know if you need it!]

At the heart of the toolbox is the sptk class. It serves both as a static file to set the environment variables, and (as an object) the interface to the transparent system calls made to the local SPTK binaries.
To use the toolbox, you should first open sptk.m and make sure the path properties are set correctly for your system. The defaults should mostly serve on a regular UNIX system, but if you want to use pitch extraction using the HTS method, make sure you point getf0tcl to your copy of getF0.tcl. (Note that the RAPT option in SPTK's pitch binary is the same algorithm used in getF0.tcl)
Analysis parameters are set to be consistent for analysis at 48kHz. For convenient access to parameters for 16kHz, look at the end of this file.

The data classes in the toolbox, by inheritance order, with their methods (some of which are overloaded) are:
speechData : read(), write(), isPrecision()
  |=> timeDomainData : plot(), length(), extract(), min(), max(), minmax()
		|=> pitchData : plot()
	|=> freqDomainData : read(), plot(), min(), max(), minmax()
		|=> mgcData : plot(), read()
		
Processing of the data is done through methods of the sptk class. Currently available processing methods are:
sptk
	|=> extractMgc()
	|=> filterMlsadf()
	|=> extractPitchGetF0()
  |=> extractPitchRAPT()
  |=> extractPitchSWIPE()
	|=> exciteFromPitch()
	
	
Some examples that might be encountered in a typical workflow are demonstrated instead of an extensive manual:
>> s = sptk;
>> speech = timeDomainData(s,rawFile,'int16');
>> speech.plot %alternatively plot(speech)
>> mgc = s.extractMgc(speech);
>> residual = s.filterMlsadf(speech,mgc,'inverse');
>> residual.write(residualPath);
>> pitch = s.extractPitchHts(speech);
>> pulse = s.exciteFromPitch(pitch);
>> synth = s.filterMlsadf(pulse,mgc);
>> synth.plot
>> synth.write(synthPath,'int16');


There are some more features, and the user is invited to explore the code and get further information from comments.


==TO-DO LIST==

-Better documentation
-Add .wav reading method to timeDomainData (same syntax, detect from extension and/or MIME type)
-Add getters and setters to sptk to ensure the analysis parameters are meaningful and consistent with each other
-Integrate mglsadf calls into sptk.filterMlsadf()
-Get user feedback, polish and expand the feature set :)


==ACKNOWLEDGMENTS==
Big thanks to Alexis Moinet for his design suggestions. They immediately snapped things into focus in my head and saved me days of wallowing in messy code. 


==================================================================
MAST is written by Onur Babacan at the TCTS Lab in University of Mons, Belgium, in 2012-2013.











=====Replace the block in sptk.m with this one for processing at 16kHz 

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
        lnGain = 1; %use logarithmic gain instead of linear gain
        noiseMask = 50; %standard deviation of white noise to mask noises in f0 extraction
