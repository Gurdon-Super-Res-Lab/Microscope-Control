% example MATLAB script to recieve an image from LabVIEW

% clear everything
clear all; clc

% setup a tcpip object
try
    t = tcpip('0.0.0.0', 30000, 'NetworkRole', 'server');
catch
    error('Error: Please install the instrument control toolbox.');
end

t.InputBufferSize = 2^26;

% wait for a connection
fprintf(1, 'Waiting for connection...');
fopen(t);
fprintf(1, 'CONNECTED\n');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% read image size                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% wait for data, we know labview is going to send an array of type int32
% with three values (rows, columns, num frames) so we expect to get 12
% bytes
while t.BytesAvailable ~= 12
    pause(0.01)
end

% read data image size
imageSize = fread(t, [3, 1], 'int32');

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

% convert the image size to byes, the image will be 16 bit (2 bytes)
imByteSize = 2*prod(imageSize);

fprintf(1, 'Waiting for image...');
% wait for data
while t.BytesAvailable ~= imByteSize
    fprintf(1, 'Bytes: %d\n', t.BytesAvailable);
    pause(0.01)
end
fprintf(1, 'DONE\n');

% read image
fprintf(1, 'Reading image...');
myImage = fread(t, prod(imageSize), 'uint16');
myImage = reshape(myImage, imageSize(3), imageSize(2), imageSize(1));
fprintf(1, 'DONE\n');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% send back number 1, success image read                                  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% data to send
sendData = char('1');

% send the data
fwrite(t, sendData, 'char')