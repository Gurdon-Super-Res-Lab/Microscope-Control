classdef imageJ_TIF
    
    properties
        filePath
        totalFrames
        numZsteps
        framesPerStep
        zStepSize
        exposureTime
        pxWidth
        pxHeight
        pxWidth_um
        pxHeight_um
        bitsPerSample;
    end
    
    properties (Access = private)
        offset_to_image
        size_of_frame
        fid
        byteOrder
    end
    
    properties(Dependent)
        % none for now
    end
    
    methods
        
        % Constructor (int values)
        function obj = imageJ_TIF(pathIn)
            
            if nargin > 0
                
                % set initial values
                obj.filePath = pathIn;
                obj.totalFrames = 0;
                obj.numZsteps = 0;
                obj.framesPerStep = 0;
                obj.zStepSize = 0;
                obj.exposureTime = 0;
                obj.pxWidth = 0;
                obj.pxHeight = 0;
                obj.pxWidth_um = 0;
                obj.pxHeight_um = 0;
                obj.bitsPerSample = 0;
                obj.offset_to_image = 0;
                obj.size_of_frame = 0;
                
                % open the file to read header information
                fid = fopen(pathIn);
                obj.fid = fid; % store the file handle to close in the destructor method
                
                % BYTES 0-1: get the bit order for the file
                fseek(fid, 0, -1);
                byteOrder = char(fread(fid, 2, 'char'));
                
                % confirm that the byeOrder makes sense
                if and(byteOrder(1) == byteOrder(2), byteOrder(1) == 'I')
                    byteOrder = 'l';
                    obj.byteOrder = byteOrder;
                elseif and(byteOrder(1) == byteOrder(2), byteOrder(1) == 'M')
                    byteOrder = 'b';
                    obj.byteOrder = byteOrder;
                else
                    error('Error: byte order unknown.');
                end
                
                % BYTES 2-3: get confirmation this is a TIFF image
                fseek(fid, 2, -1);
                tifCon = fread(fid, 1, 'uint16', byteOrder);
                
                if tifCon ~= 42
                    error('Error: this is not a TIF image.')
                else
                    clear tifCon
                end
                
                % BYTES 4-7: get offset to first IFD
                fseek(fid, 4, -1);
                IFDoffset = fread(fid, 1, 'uint32', byteOrder);
                
                % Number of IFD Entries
                fseek(fid, IFDoffset, -1);
                numberOfIFD = fread(fid, 1, 'uint16', byteOrder);
                
                % READ IFDs
                for i = 1:numberOfIFD
                    
                    if fseek(fid, IFDoffset + 2 + (i - 1)*12, -1)
                        % couldn't move this location in file, do nothing
                    else
                        fieldTag = fread(fid, 1, 'uint16', byteOrder);
                        
                        fieldType = fread(fid, 1, 'uint16', byteOrder);
                        
                        if fieldType == 1
                            fieldType = 'uint8';
                        elseif fieldType == 2
                            fieldType = 'char';
                        elseif fieldType == 3
                            fieldType = 'uint16';
                        elseif fieldType == 4
                            fieldType = 'uint32';
                        elseif fieldType == 5
                            fieldType = 'uint64';
                        else
                            error('Error: Field Tag %d - Data type not supported.\n', fieldTag);
                        end
                        
                        fieldCount = fread(fid, 1, 'uint32', byteOrder);
                        
                        % populate the specific image information
                        if fieldTag == 256 % Image width (in pixels)
                            
                            obj.pxWidth = fread(fid, fieldCount, fieldType, byteOrder);
                            
                        elseif fieldTag == 257 % Image height (in pixels)
                            
                            obj.pxHeight = fread(fid, fieldCount, fieldType, byteOrder);
                            
                        elseif fieldTag == 258 % Bits Per Sample (e.g. 16 bit)
                            
                            obj.bitsPerSample = fread(fid, fieldCount, fieldType, byteOrder);
                            
                        elseif fieldTag == 270 % Image Description
                            
                            % read in the image description
                            fieldOffsetValue = fread(fid, 1, 'uint32', byteOrder);
                            fseek(fid, fieldOffsetValue, -1);
                            ijData = fread(fid, fieldCount, fieldType, byteOrder);
                            
                            % convert the image char array to a string
                            ijData = sprintf('%s', char(ijData));
                            
                            % find the locations of space charaters
                            spaceLocations = find(isspace(ijData));
                            
                            % break the description into a cell array
                            imageData = {};
                            imageData{1} = ijData(1:spaceLocations(1));
                            
                            for i = 2:size(spaceLocations, 2)
                                imageData{i} = ijData(spaceLocations(i - 1):spaceLocations(i));
                            end
                            
                            % check for the image data
                            % images - total images
                            % slices - number of z steps
                            % frames - number of frames
                            % finterval - exposure time
                            % spacing - either the pixel size or the z step size
                            
                            imageItems = {'images', 'slices', 'frames', 'finterval', 'spacing'};
                            itemIndex = zeros(length(imageItems), 1);
                            
                            for i = 1:length(imageItems)
                                strIdx = strfind(imageData, imageItems{i});
                                tempIndex = find(not(cellfun('isempty', strIdx)));
                                
                                if isempty(tempIndex)
                                   itemIndex(i) = 0; 
                                else
                                    itemIndex(i) = tempIndex;
                                end
                                
                            end
                            
                            % set total number of images
                            if itemIndex(1)
                                eqIndex = strfind(imageData{itemIndex(1)}, '=');
                                obj.totalFrames = str2double(imageData{itemIndex(1)}(eqIndex+1:end));
                            end
                            
                            % set number of z steps
                            if itemIndex(2)
                                eqIndex = strfind(imageData{itemIndex(2)}, '=');
                                obj.numZsteps = str2double(imageData{itemIndex(2)}(eqIndex+1:end));
                            end
                            
                            % set number of frames per step
                            if itemIndex(3)
                                eqIndex = strfind(imageData{itemIndex(3)}, '=');
                                obj.framesPerStep = str2double(imageData{itemIndex(3)}(eqIndex+1:end));
                            end
                            
                            % set exposure time
                            if itemIndex(4)
                                eqIndex = strfind(imageData{itemIndex(4)}, '=');
                                obj.exposureTime = str2double(imageData{itemIndex(4)}(eqIndex+1:end));
                            end
                            
                            % set z step size
                            if itemIndex(5)
                                eqIndex = strfind(imageData{itemIndex(5)}, '=');
                                obj.zStepSize = str2double(imageData{itemIndex(5)}(eqIndex+1:end));
                            end
                            
                        elseif fieldTag == 273 % Strip offset(s) - Offset to first image
                            
                            obj.offset_to_image = fread(fid, fieldCount, fieldType, byteOrder);
                            
                        elseif fieldTag == 277 % Samples Per Pixel (3 for RGB, 1 for gray scale)
                            
                            if fread(fid, fieldCount, fieldType, byteOrder) > 1
                                error('Error: Not a grey scale image.')
                            end
                            
                        elseif fieldTag == 279 % Strip Byte Counts (size of one frame in bytes)
                            
                            obj.size_of_frame = fread(fid, fieldCount, fieldType, byteOrder);
                            
                        elseif fieldTag == 282 % X Resolution
                            
                            fieldOffsetValue = fread(fid, 1, 'uint32', byteOrder);
                            fseek(fid, fieldOffsetValue, -1);
                            resFrac = fread(fid, 2, 'uint32', byteOrder);
                            obj.pxWidth_um = resFrac(1)/resFrac(2);
                            
                        elseif fieldTag == 283 % Y Resolution
                            
                            fieldOffsetValue = fread(fid, 1, 'uint32', byteOrder);
                            fseek(fid, fieldOffsetValue, -1);
                            resFrac = fread(fid, 2, 'uint32', byteOrder);
                            obj.pxHeight_um = resFrac(1)/resFrac(2);
                            
                        else
                            % unsed Tag, do nothing
                        end
                    end
                end
                
            else
                % if no file path is specified set everything to zero
                obj.totalFrames = 0;
                obj.numZsteps = 0;
                obj.framesPerStep = 0;
                obj.zStepSize = 0;
                obj.exposureTime = 0;
                obj.pxWidth = 0;
                obj.pxHeight = 0;
                obj.pxWidth_um = 0;
                obj.pxHeight_um = 0;
                obj.bitsPerSample = 0;
                obj.offset_to_image = 0;
                obj.size_of_frame = 0;
            end
            
        end
        
        % destructor method
        function delete(obj)
            fclose(obj.fid); % close the open file
        end
        
        % return an image
        function r = getFrame(obj, frameNum)
            
            if obj.bitsPerSample == 8
                r = uint8(zeros(obj.pxHeight, obj.pxWidth));
                
                if frameNum < obj.totalFrames
                    
                    fseek(obj.fid, obj.offset_to_image + obj.size_of_frame*(frameNum-1), -1);
                    r = uint8(fread(obj.fid, [obj.pxHeight, obj.pxWidth], 'uint8', obj.byteOrder));
                    
                end
                
            elseif obj.bitsPerSample == 16
                r = uint16(zeros(obj.pxHeight, obj.pxWidth));
                
                if frameNum < obj.totalFrames
                    
                    fseek(obj.fid, obj.offset_to_image + obj.size_of_frame*(frameNum-1), -1);
                    r = uint16(fread(obj.fid, [obj.pxHeight, obj.pxWidth], 'uint16', obj.byteOrder));
                    
                end
                
            else
                r = zeros(obj.pxHeight, obj.pxWidth);
            end
            
        end
        
                % return ALL images
        function r = getALLframes(obj)
            
            fprintf(1, 'Reading All Frames...');
            
            if obj.bitsPerSample == 8
                    
                fseek(obj.fid, obj.offset_to_image, -1);
                r = uint8(fread(obj.fid, obj.pxHeight*obj.pxWidth*obj.totalFrames, 'uint8', obj.byteOrder));
                r = reshape(r, [obj.pxHeight, obj.pxWidth, obj.totalFrames]);
                
            elseif obj.bitsPerSample == 16
                
                fseek(obj.fid, obj.offset_to_image, -1);
                r = uint16(fread(obj.fid, obj.pxHeight*obj.pxWidth*obj.totalFrames, 'uint16', obj.byteOrder));
                r = reshape(r, [obj.pxHeight, obj.pxWidth, obj.totalFrames]);
                
            else
                r = zeros(obj.pxHeight, obj.pxWidth);
            end
            
            fprintf(1, 'DONE\n');
            
        end
        
    end
    
end