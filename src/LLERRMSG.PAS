Unit LLErrMsg;

{$I LL.Def}

Interface

FUNCTION ErrorMsg( ErrorCode: INTEGER ): STRING;

Implementation

FUNCTION ErrorMsg( ErrorCode: INTEGER ): STRING;
BEGIN
     CASE ErrorCode OF
          $00 : ErrorMsg := 'No Error';
          $01 : ErrorMsg := 'Invalid DOS Function Number';
          $02 : ErrorMsg := 'File not found';
          $03 : ErrorMsg := 'Path not found';
          $04 : ErrorMsg := 'Too many open files';
          $05 : ErrorMsg := 'File access denied';
          $06 : ErrorMsg := 'Invalid file handle';
          $07 : ErrorMsg := 'Memory Control Block Destroyed';
          $08 : ErrorMsg := 'Not Enough Memory';
          $09 : ErrorMsg := 'Invalid Memory Block Address';
          $0A : ErrorMsg := 'Environment Scrambled';
          $0B : ErrorMsg := 'Bad Program EXE File';
          $0C : ErrorMsg := 'Invalid file access mode';
          $0D : ErrorMsg := 'Invalid Data';
          $0E : ErrorMsg := 'Unknown Unit';
          $0F : ErrorMsg := 'Invalid drive number';
          $10 : ErrorMsg := 'Cannot remove current directory';
          $11 : ErrorMsg := 'Cannot rename across drives';
          $12 : ErrorMsg := 'Disk Read/Write Error';
          $13 : ErrorMsg := 'Disk Write-Protected';
          $14 : ErrorMsg := 'Unknown Unit';
          $15 : ErrorMsg := 'Drive Not Ready';
          $16 : ErrorMsg := 'Unknown Command';
          $17 : ErrorMsg := 'Data CRC Error';
          $18 : ErrorMsg := 'Bad Request Structure Length';
          $19 : ErrorMsg := 'Seek Error';
          $1A : ErrorMsg := 'Unknown Media Type';
          $1B : ErrorMsg := 'Sector Not Found';
          $1C : ErrorMsg := 'Printer Out Of Paper';
          $1D : ErrorMsg := 'Disk Write Error';
          $1E : ErrorMsg := 'Disk Read Error';
          $1F : ErrorMsg := 'General Failure';
          $20 : ErrorMsg := 'Sharing Violation';
          $21 : ErrorMsg := 'Lock Violation';
          $22 : ErrorMsg := 'Invalid Disk Change';
          $23 : ErrorMsg := 'File Control Block Gone';
          $24 : ErrorMsg := 'Sharing Buffer Exceeded';
          $32 : ErrorMsg := 'Unsupported Network Request';
          $33 : ErrorMsg := 'Remote Machine Not Listening';
          $34 : ErrorMsg := 'Duplicate Network Name';
          $35 : ErrorMsg := 'Network Name NOT Found';
          $36 : ErrorMsg := 'Network BUSY';
          $37 : ErrorMsg := 'Device No Longer Exists On NETWORK';
          $38 : ErrorMsg := 'NetBIOS Command Limit Exceeded';
          $39 : ErrorMsg := 'Adapter Hardware ERROR';
          $3A : ErrorMsg := 'Incorrect Response From NETWORK';
          $3B : ErrorMsg := 'Unexpected NETWORK Error';
          $3C : ErrorMsg := 'Remote Adapter Incompatible';
          $3D : ErrorMsg := 'Print QUEUE FULL';
          $3E : ErrorMsg := 'No space For Print File';
          $3F : ErrorMsg := 'Print File Cancelled';
          $40 : ErrorMsg := 'Network Name Deleted';
          $41 : ErrorMsg := 'Network Access Denied';
          $42 : ErrorMsg := 'Incorrect Network Device Type';
          $43 : ErrorMsg := 'Network Name Not Found';
          $44 : ErrorMsg := 'Network Name Limit Exceeded';
          $45 : ErrorMsg := 'NetBIOS session limit exceeded';
          $46 : ErrorMsg := 'Filer Sharing temporarily paused';
          $47 : ErrorMsg := 'Network Request Not Accepted';
          $48 : ErrorMsg := 'Print or Disk File Paused';
          $50 : ErrorMsg := 'File Already Exists';
          $52 : ErrorMsg := 'Cannot Make Directory';
          $53 : ErrorMsg := 'Fail On Critical Error';
          $54 : ErrorMsg := 'Too Many Redirections';
          $55 : ErrorMsg := 'Duplicate Redirection';
          $56 : ErrorMsg := 'Invalid Password';
          $57 : ErrorMsg := 'Invalid Parameter';
          $58 : ErrorMsg := 'Network Device Fault';
          $59 : ErrorMsg := 'Function Not Supported By NETWORK';
          $5A : ErrorMsg := 'Required Component NOT Installed';

          (* Pascal Errors *)
           94 : ErrorMsg := 'EMS Memory Swap Error';
           98 : ErrorMsg := 'Disk Full';
          100 : ErrorMsg := 'Disk read error';
          101 : ErrorMsg := 'Disk write error';
          102 : ErrorMsg := 'File not assigned';
          103 : ErrorMsg := 'File not open';
          104 : ErrorMsg := 'File not open for input';
          105 : ErrorMsg := 'File not open for output';
          106 : ErrorMsg := 'Invalid numeric format';
          150 : ErrorMsg := 'Disk is write_protected';
          151 : ErrorMsg := 'Unknown unit';
          152 : ErrorMsg := 'Drive not ready';
          153 : ErrorMsg := 'Unknown command';
          154 : ErrorMsg := 'CRC error in data';
          155 : ErrorMsg := 'Bad drive request structure length';
          156 : ErrorMsg := 'Disk seek error';
          157 : ErrorMsg := 'Unknown media type';
          158 : ErrorMsg := 'Sector not found';
          159 : ErrorMsg := 'Printer out of paper';
          160 : ErrorMsg := 'Device write fault';
          161 : ErrorMsg := 'Device read fault';
          162 : ErrorMsg := 'Hardware Failure';
          163 : ErrorMsg := 'Sharing Confilct';
          200 : ErrorMsg := 'Division by zero';
          201 : ErrorMsg := 'Range check error';
          202 : ErrorMsg := 'Stack overflow error';
          203 : ErrorMsg := 'Heap overflow error';
          204 : ErrorMsg := 'Invalid pointer operation';
          205 : ErrorMsg := 'Floating point overflow';
          206 : ErrorMsg := 'Floating point underflow';
          207 : ErrorMsg := 'Invalid floating point operation';

          208 : ErrorMsg := 'Overlay manager not installed';
          209 : ErrorMsg := 'Overlay file read error';
          210 : ErrorMsg := 'Object not initialized';
          211 : ErrorMsg := 'Call to abstract method';
          212 : ErrorMsg := 'Stream registration error';
          213 : ErrorMsg := 'Collection index out of range';
          214 : ErrorMsg := 'Collection overflow error';
          215 : ErrorMsg := 'Arithmetic overflow error';
          216 : ErrorMsg := 'General Protection fault';

          390 : ErrorMsg := 'Serial Port TIMEOUT';
          399 : ErrorMsg := 'Serial Port NOT Responding';
         1008 : ErrorMsg := 'EMS Memory Swap Error'
          ELSE
                ErrorMsg := 'Unknown Error';
    END; { CASE }
END;

End.
