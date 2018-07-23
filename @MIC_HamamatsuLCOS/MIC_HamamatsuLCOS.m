classdef MIC_HamamatsuLCOS < MIC_Abstract
    % MIC_HamamatsuLCOS: Matlab Instrument Control of Hamamatsu LCOS SLM
    %
    % This class controls a phase SLM connected through a DVI interface.
    % Pupil diameter is 2*NA*f, f=M/180 for olympus objectives
    %
    % Example: obj = MIC_HamamatsuLCOS();
    % Functions: delete, gui, exportState, setupImage, displayImage,
    %            calcZernikeImage, calcOptimPSFImage, calcPrasadImage,
    %            calcZernikeStack, calcDisplayImage, calcBlazeImage,
    %            displayCheckerboard
    %
    % REQUIREMENTS:
    %   MIC_Abstract.m
    %   MATLAB software version R2016b or later
    %   Data Acquisition Toolbox
    %
    % CITATION: Marjoleing Meddens, Lidkelab, 2017.
    
    properties
        HorPixels=1272      %SLM Horizontal Pixels
        VerPixels=1024      %SLM Vertical Pixels
        PixelPitch=12.5     %Pixel Pitch (micron)
        Lambda=.69;         %Wavelength (micron)
        File_Correction='CAL_LSH0801531_690nm.bmp'     %Wavelength dependent phase correction file
        ScaleFactor=218/256;    %Input required for 2pi phase (default for 690 nm)
        
        Image_Correction    %Phase correction image (0-255, scales to 0-2pi phase)
        Image_Blaze=0       %A Blaze Image in radians
        Image_OptimPSF=0    %Phase for optimized abberation free PSF (radians)
        Image_Pattern=0     %Desired phase (Image without Correction or Blaze, in radians)
        Image_Display       %Pattern to be diplayed on SLM (scale factor corrected and phase wrapped)
        Image_ZernikeStack  %Pre-calculated Zernike Images
        
        PupilCenter         %Location of pupil center (SLM Pixels)
        PupilRadius         %Pupil Radius (SLM Pixels)
        ZernikeCoefOptimized % Zernike coeficients for optimized PSF
        ZernikeCoef         %Zernike coefficients used to create Pattern
        
        Fig_Pattern         %Pattern Figure Object
        PrimaryDispSize;    %Number of pixels of primary display [Hor Ver]
        
        StartGUI=0;
    end
    
    properties (SetAccess=protected)
        InstrumentName='LCOS'; %Descriptive name of instrument.  Must be a valid Matlab varible name. 
    end
    
    
    
    
    methods
        function obj=MIC_HamamatsuLCOS()
            % Object constructor
            obj = obj@MIC_Abstract(~nargout);
            
            %Load in correction file
            obj.Image_Correction=double(imread(obj.File_Correction));
            
            %Setup SLM Figure window
            obj.setupImage();
            
            %Set default pattern to correction image
            obj.calcDisplayImage();
            
            %Diplay the correction image
            obj.displayImage();
            
        end
        
        function delete(obj)
            % Deletes object
            delete(obj.Fig_Pattern);
        end
        
        function gui()
            % Sets up gui
        end
        
        
        function [Attributes,Data,Children]=exportState(obj)
            %Export all important Attributes, Data and Children
            Attributes.HorPixels=obj.HorPixels;
            Attributes.VerPixels=obj.VerPixels;
            Attributes.PixelPitch = obj.PixelPitch;
            Attributes.Lambda = obj.Lambda;
            Attributes.File_Correction=obj.File_Correction;
            Attributes.ScaleFactor=obj.ScaleFactor;
            Attributes.Image_Correction=obj.Image_Correction;
            Attributes.Image_Blaze=obj.Image_Blaze;
            Attributes.Image_OptimPSF=obj.Image_OptimPSF;
            Attributes.Image_Pattern=obj.Image_Pattern;
            Attributes.Image_Display=obj.Image_Display;
            Attributes.ZernikeCoef=obj.ZernikeCoef;
            Attributes.PupilCenter=obj.PupilCenter;
            Attributes.PupilRadius=obj.PupilRadius;
            
            Data=[];
            
            Children=[];
        end
        
        function setupImage(obj)
            %Create the figure that will display on the SLM
            ScrSz=get(0,'screensize');
            obj.PrimaryDispSize=ScrSz(3:4);
            delete(obj.Fig_Pattern);
            obj.Fig_Pattern=figure('Position',...
                [obj.PrimaryDispSize(1)+1 obj.PrimaryDispSize(2)-obj.VerPixels...
                obj.HorPixels obj.VerPixels],...
                'MenuBar','none','ToolBar','none','resize','off');
            colormap(gray(256));
            %Prevent closing after a 'close' or 'close all'
            axis off
            set(gca,'position',[0 0 1 1],'Visible','off');
            obj.Fig_Pattern.HandleVisibility='off'; 
        end
        
        function displayImage(obj)
            % Displays Image_Pattern full screen on DVI output
            
            if ~ishandle(obj.Fig_Pattern)
                obj.setupImage();
            end
            obj.Fig_Pattern.HandleVisibility='on';
            figure(obj.Fig_Pattern);
            image(obj.Image_Display);
            set(gca,'position',[0 0 1 1],'Visible','off');
            obj.Fig_Pattern.HandleVisibility='off';
            drawnow();
        end
        
        function calcZernikeImage(obj)
            %Calculates and displays Pattern based on ZernikeCoef
            
            % use SMA_PSF function to generate sum of zernike images
            NMax = numel(obj.ZernikeCoef); % number of zernike coefficients
            [ZStruct]=SMA_PSF.createZernikeStruct(obj.PupilRadius*2,obj.PupilRadius,NMax);
            [Image]=SMA_PSF.zernikeSum(obj.ZernikeCoef,ZStruct);
            % flip and tranpose image to correct for mirror and camera
            % transposition
            Image = Image(:,end:-1:1)';
            obj.Image_Pattern = zeros(obj.VerPixels,obj.HorPixels);
            obj.Image_Pattern(obj.PupilCenter(1)-obj.PupilRadius:obj.PupilCenter(1)+obj.PupilRadius-1,...
                    obj.PupilCenter(2)-obj.PupilRadius:obj.PupilCenter(2)+obj.PupilRadius-1)=...
                    gather(Image);
            obj.calcDisplayImage();
            obj.displayImage();
        end
        
        function calcOptimPSFImage(obj)
            %Calculates image based on ZernikeCoefOptimized
            
            % use SMA_PSF function to generate sum of zernike images
            NMax = numel(obj.ZernikeCoefOptimized); % number of zernike coefficients
            [ZStruct]=SMA_PSF.createZernikeStruct(obj.PupilRadius*2,obj.PupilRadius,NMax);
            [Image]=SMA_PSF.zernikeSum(obj.ZernikeCoefOptimized,ZStruct);
            % flip and tranpose image to correct for mirror and camera
            % transposition
            Image = Image(:,end:-1:1)';
            obj.Image_OptimPSF = zeros(obj.VerPixels,obj.HorPixels);
            obj.Image_OptimPSF(obj.PupilCenter(1)-obj.PupilRadius:obj.PupilCenter(1)+obj.PupilRadius-1,...
                    obj.PupilCenter(2)-obj.PupilRadius:obj.PupilCenter(2)+obj.PupilRadius-1)=...
                    gather(Image);
        end
        
        function calcPrasadImage(obj,L)
            %
            % INPUT
            %   L:      number of zones
            
            D = obj.PupilRadius*2;
            [XGrid,YGrid]=meshgrid((-D/2:D/2-1),(-D/2:D/2-1));
            R=sqrt(gpuArray(XGrid.^2+YGrid.^2));
            Mask=R<obj.PupilRadius;
            R=R/obj.PupilRadius;
            Pupil_Phase=gpuArray(zeros(D,D,'single'));
            Theta=(gpuArray(atan2(YGrid,XGrid))); %CHECK!
            
            Alpha=1/2;
            for ll=1:L
                M=(R>=((ll-1)/L).^Alpha)&(R<(ll/L).^Alpha);
                Pupil_Phase(M)=mod((2*(ll-1)+1)*Theta(M),2*pi); %make hole
            end
            %Pupil_Phase = (Pupil_Phase/(2*pi))*256;
            obj.Image_Pattern = zeros(obj.VerPixels,obj.HorPixels);
            obj.Image_Pattern(obj.PupilCenter(1)-obj.PupilRadius:obj.PupilCenter(1)+obj.PupilRadius-1,...
                    obj.PupilCenter(2)-obj.PupilRadius:obj.PupilCenter(2)+obj.PupilRadius-1)=...
                    gather(Pupil_Phase);
            obj.calcDisplayImage();
            obj.displayImage();
            
        end
        
        function calcZernikeStack(obj)
            %Calculate a stack of images (still being implemented)
        end
        
        function calcDisplayImage(obj)
            %Pattern images is in radians.
            %Correction image and blaze image is input 0-255
            %Images are all scaled to 0-255, meaning 0-2pi phase and then 
            %summed. The result is wrapped modulo 256 and scaled with the
            %scale factor
            PatternIm255 = (obj.Image_Pattern/(2*pi))*255;
            OptimPSFIm255 = (obj.Image_OptimPSF/(2*pi))*255;
            sumIm = obj.Image_Correction + obj.Image_Blaze +...
                PatternIm255 + OptimPSFIm255;
            sumImWrapped = mod(sumIm,256);
            obj.Image_Display=sumImWrapped*obj.ScaleFactor;
        end
        
        function calcBlazeImage(obj,BlazeAngle,ROI)
            %Calculates Pattern using a blaze angle
            % obj.calcBlazePattern(ROI,BlazeAngle)
            
            %ROI is [YStart XStart YWidth XWidth]
            
            if nargin<3 %make full image blaze
                ROI=[1 1 obj.VerPixels obj.HorPixels];
            end

            %Make empty image
            obj.Image_Blaze=zeros(obj.VerPixels,obj.HorPixels);
            L_SubIm=ROI(4)*obj.PixelPitch;
            Delay=L_SubIm*tan(BlazeAngle);
            Delay_Phase=Delay/obj.Lambda*256;
            
            SubIm=meshgrid(linspace(0,Delay_Phase,ROI(4)),1:ROI(3));
            obj.Image_Blaze(ROI(1):ROI(1)+ROI(3)-1,ROI(2):ROI(2)+ROI(4)-1)...
                =SubIm;
            obj.calcDisplayImage();
            obj.displayImage();
        end
        
        function displayCheckerboard(obj)
            % Displays checkboard image for scattering
            % This can be used for alignment to see beam scatter off SLM
            % It displays a checkerboard image with alternating pixels
            % between 0 and pi phase
            
            % Make checkerboard image
            N = 1; %number of pixels per tile
            P = obj.HorPixels/2;
            Q = obj.VerPixels/2;
            I = checkerboard(N,P,Q);
            Ibin = I>0;
            Ifinal = Ibin*255*obj.ScaleFactor/2;
            if ~ishandle(obj.Fig_Pattern)
                obj.setupImage();
            end
            obj.Fig_Pattern.HandleVisibility='on';
            figure(obj.Fig_Pattern);
            image(Ifinal);
            set(gca,'position',[0 0 1 1],'Visible','off');
            obj.Fig_Pattern.HandleVisibility='off';
            drawnow();
        end
        
    end
    
    methods (Static=true)
        function unitTest()
            % Tests the functionality of the class/instrument
        end        
    end
    
end

