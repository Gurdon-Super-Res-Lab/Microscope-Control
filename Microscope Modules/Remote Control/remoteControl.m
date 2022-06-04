classdef remoteControl < handle
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % START: properties          %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties(Access = private)
        private_portNum
        private_ipAddress
        private_tcpObject
        private_connectionStatus
    end
    
    properties(Dependent)
        portNumber
        ipAddress
    end
    
    properties
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % END: properties            %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % START: Methods             %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        
        % START: Constructor
        function obj = remoteControl(ipAddress, portNum)
            
            if nargin < 1
                
                obj.private_portNum = 30000;
                obj.private_ipAddress = 'localhost';
                
            elseif nargin < 2
                
                obj.private_portNum = portNum;
                
            else
                obj.private_ipAddress = ipAddress;
                obj.private_portNum = portNum;
            end
            
            % set connection status
            obj.private_connectionStatus = 0;
            
        end
        % END: Constructor
        
        % START: Destructor
        function delete(obj)
            quitRemote(obj);
        end
        % END: Destructor
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % START: Dependent Properties  %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % retun port number
        function r = get.portNumber(obj)
            r = obj.private_portNum;
        end
        
        % return IP address
        function r = get.ipAddress(obj)
            r = obj.private_ipAddress;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % END: Dependent Properties    %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % START: General Methods       %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % set mirror control values %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function success = setCtrlValues(obj, ctrlArray)
           success = 0;
           
           % check number of inputs
           if nargin < 2
               error('Error: Control values missing.');
           end
           
           % send set command
           cmdSuccess = sendCmd(obj, 'set ctrl values');
           
           % send control values
           if cmdSuccess
               
               % get network object
               t = obj.private_tcpObject;
               
               % get control value array size
               ctrlSize = size(ctrlArray, [1, 2, 3]);
               
               % reshape control array
               ctrlArray = reshape(ctrlArray, prod(ctrlSize), 1);
               
               % send array size
               write(t, int32(ctrlSize), 'int32');
               
               if ~checkReply(obj)
                   return
               end
               
               % send array
               write(t, ctrlArray, 'double')
               
               if ~checkReply(obj)
                   return
               end
               
               % set success
               success = 1;
               
           else
              warning('Failed to update control values.') 
           end
           
        end
        
        % get mirror control values %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function ctrlValues = getCtrlValues(obj)
            ctrlValues = 0;
            
            % send get command
            cmdSuccess = sendCmd(obj, 'get ctrl values');
            
            if ~cmdSuccess
                return
            end
            
            % get network object
            t = obj.private_tcpObject;
            
            % wait for data
            success = waitForBytes(obj, 12);
            
            if ~success
                return
            end
            
            % read array size
            arraySize = read(t, 3, 'int32');
            
            % reply with confirmation
            write(t, int32(1), 'int32');
            
            % wait for array
            numEle = prod(arraySize);
            arrayByteSize = numEle*8; % 8 bytes per double
            
            success = waitForBytes(obj, arrayByteSize);
            
            if ~success
                return
            end
            
            % read control values
            ctrlValues = read(t, numEle, 'double');
            
            % reshape values
            ctrlValues = reshape(ctrlValues, arraySize(3), arraySize(2), arraySize(1));
            ctrlValues = permute(ctrlValues, [2, 1, 3]);
            
        end
        
        % start live preview %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function success = startLive(obj)
            
            success = 0;
            
            % send get command
            cmdSuccess = sendCmd(obj, 'start live');
            
            if ~cmdSuccess
                return
            end
            
            % confirm live preview
            success = checkReply(obj);
            
        end
        
        % stop live preview %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function success = stopLive(obj)
            
            success = 0;
            
            % send get command
            cmdSuccess = sendCmd(obj, 'stop live');
            
            if ~cmdSuccess
                return
            end
            
            % confirm live preview
            success = checkReply(obj);
            
        end
        
        % get image %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [success, imageData] = getImage(obj)
            success = 0;
            imageData = [];
            
            % send get command
            cmdSuccess = sendCmd(obj, 'get image');
            
            if ~cmdSuccess
                return
            end
            
            % get network object
            t = obj.private_tcpObject;
            
            % wait for array size
            waitSuccess = waitForBytes(obj, 12);
            
            if ~waitSuccess
                return
            end
            
            % read array size
            arraySize = read(t, 3, 'int32');
            
            % array size in bytes
            imByteSize = 2*prod(arraySize);
            
            % array to store image
            imageData = zeros(imByteSize, 1, 'uint8');
            
            % track total bytes received
            totalBytes = 0;
            
            % send back 1, ready for image
            write(t, int32(1), 'int32');
            
            % read image data as it becomes available
            while totalBytes < imByteSize
                
                readBytes = t.BytesAvailable;
                
                if readBytes > 0
                    
                    % read image data
                    imageData(totalBytes + 1:totalBytes + readBytes, 1) = read(t, readBytes, 'uint8');
                    
                    % update total bytes received
                    totalBytes = totalBytes + readBytes;
                    
                end
                
            end
            
            % convert the image to 16 bit. 8 bit elements are in the
            % reverse order expected by the typecast function so we flip
            % them before conversion and then flip back
            imageData = flip(imageData, 1);
            imageData = typecast(imageData, 'uint16');
            imageData = flip(imageData, 1);
            
            % reshape into an image stack
            imageData = reshape(imageData, arraySize(3), arraySize(2), arraySize(1));
            success = 1;
            
        end
        
        % reset connection %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function success = resetConnection(obj)
            
            % set connection flag
            obj.private_connectionStatus = 0;
            
            % open new connection
            success = openConnection(obj);
            
        end
        
        % quit remote %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function success = quitRemote(obj)
            
            fprintf(1, 'Quiting remote...')
            
            % send quit command
            success = sendCmd(obj, 'Quit');
            obj.private_connectionStatus = 0;
            
            % output result
            if success
                msg = 'DONE\n';
            else
                msg = 'FAILED\n';
            end
            
            fprintf(1, msg);
            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % END: General Methods         %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % END: Methods               %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % START: Protected Methods   %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods(Access = protected)
        
        % check connection and open if required %%%%%%%%%%%%%%%%%%%%%%%%%%%
        function success = openConnection(obj)
            success = 0;
            
            if obj.private_connectionStatus
                success = 1;
                return
            else
                
                try
                    % open network connection
                    fprintf(1, 'Opening Connection...');
                    t = tcpclient(obj.private_ipAddress , obj.private_portNum, 'Timeout', 10);
                    t.ByteOrder = 'big-endian';
                    
                    % store connection and set status
                    obj.private_tcpObject = t;
                    obj.private_connectionStatus = 1;
                    
                    % set result
                    success = 1;
                    fprintf(1, 'DONE\n');
                    
                catch
                    fprintf(1, 'FAILED\n');
                    warning('Could not establish connection.')
                end
            end
            
        end
        
        % send command message %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function success = sendCmd(obj, cmd)
            
            % set default success value
            success = 0;
            
            if nargin < 2
                warning('Command missing.')
                return
            end
            
            % check connection
            if openConnection(obj)
                t = obj.private_tcpObject;
            else
                return
            end
            
            % set command and size of command
            sendData = char(cmd);
            sendDataSize = int32(strlength(sendData));
            
            % send size of data
            write(t, sendDataSize, 'int32');
            
            if ~checkReply(obj)
                return
            end
            
            % send message
            write(t, sendData, 'char');
            
            if ~checkReply(obj)
                return
            end
            
            % set success
            success = 1;
            
        end
        
        % wait for number of bytes at port %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function success = waitForBytes(obj, numBytes)
            
            % get network object
            t = obj.private_tcpObject;
            
            % wait for reply or timeout
            x = 0;
            while t.BytesAvailable < numBytes && x < 500
                x = x + 1;
                pause(0.01)
            end
            
            % set result
            if x < 500
                success = 1;
            else
                warning('Connection Timeout.');
                success = 0;
            end
            
        end
        
        % check reply from LabView is 1 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function success = checkReply(obj)
            t = obj.private_tcpObject;
            
            % wait for reply or timeout
            x = 0;
            while t.BytesAvailable < 1 && x < 500
                x = x + 1;
                pause(0.01)
            end
            
            % read data
            if x < 500
                success = str2double(char(t.read(1)));
            else
                warning('Connection Timeout.');
                success = 0;
            end
        end
        
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % END: Protected Methods     %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
end