% example MATLAB script to recieve an image from LabVIEW

% clear everything
clear all; clc

% setup a tcpip object
try
    t = tcpip('0.0.0.0', 30000, 'NetworkRole', 'server');
catch
    error('Error: Please install the instrument control toolbox.');
end

% setup the buffer size to be about 33MB
t.InputBufferSize = 2^25;

% wait for a connection
fprintf(1, 'Waiting for connection...');
fopen(t);
fprintf(1, 'CONNECTED\n');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% read image size                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% wait for data, labview is going to send an array of type int32 with three
% values (rows, columns, number of frames) so we expect to get 12 bytes
while t.BytesAvailable ~= 12
    pause(0.01)
end

% read data image size
imageSize = fread(t, [3, 1], 'int32');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% preallocate and set parameters before sending the ready signal          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% convert the image size to byes, the image will be 16 bit (2 bytes) so we
% have the total number of pixels times two
imByteSize = 2*prod(imageSize);

% array to store image
myImage = zeros(imByteSize, 1, 'uint8');

% track total bytes received
totalBytes = 0;

fprintf(1, 'Downloading image...');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% send back number 1, ready for image                                     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% data to send
sendData = char('1');

% send the data
fwrite(t, sendData, 'char')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% read image data                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% use try / catch to ensure connection is closed even if there is an error
try
    
    while totalBytes < imByteSize
        
        readBytes = t.BytesAvailable;
        
        if readBytes > 0
            
            % read image data
            myImage(totalBytes + 1:totalBytes + readBytes, 1) = fread(t, readBytes, 'uint8');
            
            % update total bytes received
            totalBytes = totalBytes + readBytes;
            
        end
        
    end
    
    fprintf(1, 'DONE\n');
    
    % convert the image to 16 bit, for some reason the 8 bit elements are
    % in the reverse order expected by the typecast function so we flip
    % them before conversion and then flip back
    myImage = flip(myImage, 1);
    myImage = typecast(myImage, 'uint16');
    myImage = flip(myImage, 1);
    
    % fix the image size array to match the image
    imageSize = [imageSize(3), imageSize(2), imageSize(1)];
    
    % reshape into an image stack
    myImage = reshape(myImage, imageSize(1), imageSize(2), imageSize(3));
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % send back number 1 to indicate success                              %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % data to send
    sendData = char('1');
    
    % send the data
    fwrite(t, sendData, 'char')
    
catch MExc
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % send back number 0 to indicate failure                              %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % print error information
    warning('Download Error.')
    fprintf(1,'Error ID: %s\n', MExc.identifier);
    fprintf(1,'Error Message: %s\n', MExc.message);
    
    % data to send
    sendData = char('0');
    
    % send the data
    fwrite(t, sendData, 'char')
    
end

% close the connection
fclose(t);

clear curPixels imByteSize numPixels readBytes sendData totalBytes t

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% display the first frame                                                 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

imagesc(myImage(:, :, 1)); axis image; colormap gray