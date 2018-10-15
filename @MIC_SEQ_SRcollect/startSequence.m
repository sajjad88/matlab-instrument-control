 function startSequence(obj, RefStruct, LabelID)
    %Collects and saves a SR data Set

    % Setup directories/filenames as needed.
    obj.StatusString = 'Preparing directories...';
    DirectoryName = fullfile(obj.TopDir, obj.CoverslipName, ...
        sprintf('Cell_%2.2d', RefStruct.CellIdx), ...
        sprintf('Label_%2.2d', LabelID));
    mkdir(DirectoryName);
    CurrentTime = clock;
    DateString = [num2str(CurrentTime(1)), '-', ...
        num2str(CurrentTime(2)),  '-', num2str(CurrentTime(3)), '-', ...
        num2str(CurrentTime(4)), '-', num2str(CurrentTime(5)), '-', ...
        num2str(round(CurrentTime(6)))];
    if obj.IsBleach
        % Indicate that this is a photobleaching sequence if necessary.
        FileName = sprintf('Data_%s_bleaching.h5', DateString);
    else
        FileName = sprintf('Data_%s.h5', DateString);
    end
    FileName = fullfile(DirectoryName, FileName);

    % Prepare for .h5 file writing.
    % NOTE: For now, obj.SaveFileType must be 'h5'.
    switch obj.SaveFileType
        case 'h5'
            FileH5 = FileName;
            MIC_H5.createFile(FileH5);
            MIC_H5.createGroup(FileH5, 'Channel01');
            MIC_H5.createGroup(FileH5, 'Channel01/Zposition001');
        otherwise
            error('StartSequence:: unknown file save type')
    end

    % Attempt to move to the cell of interest.
    obj.StageStepper.moveToPosition(1, ...
        RefStruct.StepperPos(2) + obj.CoverSlipOffset(2));
    obj.StageStepper.moveToPosition(2, ...
        RefStruct.StepperPos(1) + obj.CoverSlipOffset(1));
    obj.StageStepper.moveToPosition(3, ...
        RefStruct.StepperPos(3) + obj.CoverSlipOffset(3));
    obj.StagePiezoX.center();
    obj.StagePiezoY.center();
    obj.StagePiezoZ.center();
    
    % Attempt to align the cell to the reference image in brightfield.
    obj.StatusString = ...
        'Attempting initial brightfield alignment of cell...';
    obj.Lamp660.setPower(obj.Lamp660Power);
    pause(obj.LampWait);
    obj.CameraSCMOS.ExpTime_Capture = obj.ExposureTimeCapture; 
    obj.CameraSCMOS.AcquisitionType = 'capture';
    obj.CameraSCMOS.ROI = obj.SCMOS_ROI_Collect;
    obj.CameraSCMOS.setup_acquisition();
    obj.AlignReg.Image_Reference=RefStruct.Image;
    try 
        obj.AlignReg.align2imageFit(RefStruct);
    catch
        % We don't want to throw an error since there are still other cells
        % to be measured from here on.
        warning('Problem with AlignReg.align2imageFit()')
        return
    end
    obj.Lamp660.setPower(0);

    % Setup Active Stabilization (if desired).
    if obj.UseActiveReg
        obj.ActiveReg = MIC_ActiveReg3D_Seq(...
            obj.CameraIR,obj.StagePiezoX,obj.StagePiezoY,obj.StagePiezoZ); 
        obj.Lamp850.on; 
        obj.Lamp850.setPower(obj.Lamp850Power);
        obj.IRCamera_ExposureTime=obj.CameraIR.ExpTime_Capture;
        obj.ActiveReg.takeRefImageStack(); % takes 21 reference images
        obj.ActiveReg.Period=obj.StabPeriod;
        obj.ActiveReg.start();
    end

    % Setup the main sCMOS to acquire the sequence.
    obj.StatusString = 'Preparing for acquisition...';
    obj.CameraSCMOS.ExpTime_Sequence = obj.ExposureTimeSequence;
    obj.CameraSCMOS.SequenceLength = obj.NumberOfFrames;
    obj.CameraSCMOS.ROI = obj.SCMOS_ROI_Collect;
    obj.CameraSCMOS.AcquisitionType = 'sequence';
    obj.CameraSCMOS.setup_acquisition();

    % Send the 647 nm laser to the sample.  If requested, also send the 
    % 405 nm laser to the sample.
    obj.FlipMount.FilterOut(); % removes ND filter from optical path
    if obj.Use405
        obj.Laser405.setPower(obj.LaserPower405Activate);
    end
    if obj.IsBleach
        obj.Laser405.setPower(obj.LaserPower405Bleach);
    end

    % Begin the acquisition.
    fprintf('Collecting data.......................................... \n')
    for ii = 1:obj.NumberOfSequences
        % Use periodic registration after NSeqBeforePeriodicReg
        % sequences have been collected.
        if obj.UsePeriodicReg && ~mod(ii, obj.NSeqBeforePeriodicReg)
            obj.StatusString = 'Attempting periodic registration...';
            obj.Lamp660.setPower(obj.Lamp660Power);
            pause(obj.LampWait);
            obj.CameraSCMOS.ExpTime_Capture = obj.ExposureTimeCapture;
            obj.CameraSCMOS.AcquisitionType = 'capture';
            obj.CameraSCMOS.ROI = obj.SCMOS_ROI_Collect;
            obj.CameraSCMOS.setup_acquisition();
            obj.AlignReg.Image_Reference = RefStruct.Image;
            try
                obj.AlignReg.align2imageFit(RefStruct);
            catch
                % If the alignment fails, don't stop auto collect for
                % other cells.
                warning('Problem with AlignReg.align2imageFit()')
                return
            end
            obj.Lamp660.setPower(0);
        end
        
        % Turn on the 405 nm laser (if needed) and open the shutter to
        % allow the 647 nm laser to reach the sample.
        if obj.Use405
            obj.Laser405.on();
        end
        obj.Shutter.open();
        
        % Collect the sequence.
        obj.StatusString = 'Acquiring data...';
        obj.CameraSCMOS.AcquisitionType = 'sequence';
        obj.CameraSCMOS.ExpTime_Sequence = obj.ExposureTimeSequence;
        obj.CameraSCMOS.setup_acquisition();
        Sequence = obj.CameraSCMOS.start_sequence();
        switch obj.SaveFileType
            % For now, we will stick to saving data to a .h5 file.
            case 'h5'
                SequenceName = sprintf('Data%04d', ii);
                MIC_H5.writeAsync_uint16(FileH5, ...
                    'Channel01/Zposition001', SequenceName, Sequence);
            otherwise
                error('StartSequence:: unknown SaveFileType')
        end
        obj.Shutter.close(); % block 647 nm from reaching sample
        if obj.Use405
            % Turn off the 405 nm laser.
            obj.Laser405.off();
        end
    end
    obj.StatusString = '';
    fprintf('Data collection complete \n')
    
    % Ensure that the lasers are not reaching the sample.
    obj.Shutter.close(); % close shutter instead of turning off the laser
    obj.FlipMount.FilterIn();
    if obj.Use405
        obj.Laser405.setPower(0);
        obj.Laser405.off();
    end
    
    % If it was used, end the active stabilization process.
    if obj.UseActiveReg
        obj.ActiveReg.stop();
    end
    
    % Save the acquisition data.
    fprintf('Saving exportables from exportState().................... \n')
    switch obj.SaveFileType
        % For now, we will stick to saving data to a .h5 file.
        case 'h5'
            SequenceName = 'Channel01/Zposition001';
            MIC_H5.createGroup(FileH5, SequenceName);
            obj.save2hdf5(FileH5, SequenceName);
        otherwise
            error('StartSequence:: unknown SaveFileType')
    end
    fprintf('Saving exportables from exportState() complete \n')
 end