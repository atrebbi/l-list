
Unit Ra250Fb;

{$I LL.DEF}

{
 Oggetto per maneggiare la filebase di RA 2.50
 permette di estrarre delle linee in formato Files.Bbs
}

Interface

Uses
   LLGen;

Type

{definizioni da Struct.250}

  FILESHDRrecord = record
                     Name           : String[12];
                     Size,
                     CRC32          : LongInt;
                     Uploader       : String[35];
                     UploadDate,
                     FileDate,
                     LastDL         : LongInt;
                     TimesDL        : Word;
                     Attrib         : Byte;
                     Password       : String[15];
                     KeyWord        : Array[1..5] of String[15];
                     Cost           : Word;
                     LongDescPtr    : LongInt;
                     FreeSpace      : Array[1..20] of Byte;
                   end;

          {Attrib - Bit 0 : Deleted
                        1 : Unlisted
                        2 : Free (don't adjust ratio) - Does NOT affect "Cost"
                        3 : Not available (don't allow downloads)
                        4 : Locked (no kill)
                        5 : Missing/offline
                        6 : No time restrictions - always allow DL
          }

  FILESIDXrecord = record
                     Name           : String[12];
                     UploadDate     : LongInt;
                     KeyWordCRC     : Array[1..5] of LongInt;
                     LongDescPtr    : LongInt;
                   end;

{questo e' il mio oggetto}

   FbManagePtr= ^FbManage;
   FbManage=Object
      FbError: Word;
      HdrFile: File Of FilesHdrRecord;
      CurrHdr: FilesHdrRecord;
      HdrOpen: Boolean;
      IdxFile: File of FilesIdxRecord;
      CurrIdx: FilesIdxRecord;
      IdxOpen: Boolean;
      DescFile: File;
      DescOpen: Boolean;
      Constructor Init(Narea: Word);
      Destructor Done;
      Function EOFB: Boolean;
      Function GetFBbsLine: String;
      Procedure FbRewrite;
      Procedure FbClose;
      Procedure FbReset;
      Procedure WriteRec(Nome: String;
         FTime, FSize: Longint; TimesDl: Word; Pnt: DescTypePtr);
      Procedure WriteComment(S: String);
      Procedure SeekEnd;
      Procedure Append;
      Function FbIOResult: Word;
   end;

implementation

Constructor FbManage.Init(NArea: Word);
begin
   assign(HdrFile, LoraDir + '\HDR\FDB' + Long2Str(NArea,0) + '.HDR');
   HdrOpen := False;
   assign(IdxFile, LoraDir + '\IDX\FDB' + Long2Str(NArea,0) + '.IDX');
   IdxOpen := False;
   assign(DescFile, LoraDir + '\TXT\FDB' + Long2Str(NArea,0) + '.TXT');
   DescOpen := False;
   FbError := 0;
end;

Procedure FbManage.FbReset;
Begin
   FbClose;
   {$I-}
   Reset(HdrFile);
   {$I+}
   FbError := IOResult;
   if FbError=0 then
   begin
      HdrOpen := True;
      {$I-}
      Reset(IdxFile);
      {$I+}
      FbError := IOResult;
      if FbError=0 then
      begin
         IdxOpen := True;
         {$I-}
         Reset(DescFile,1);
         {$I+}
         FbError := IOResult;
         if FbError=0 then
         begin
            DescOpen := True;
         end;
      end;
   end;
End;

Procedure FbManage.FbRewrite;
Begin
   FbClose;
   {$I-}
   Rewrite(HdrFile);
   {$I+}
   FbError := IOResult;
   if FbError=0 then
   begin
      HdrOpen := True;
      {$I-}
      Rewrite(IdxFile);
      {$I+}
      FbError := IOResult;
      if FbError=0 then
      begin
         IdxOpen := True;
         {$I-}
         Rewrite(DescFile,1);
         {$I+}
         FbError := IOResult;
         if FbError=0 then
         begin
            DescOpen := True;
         end;
      end;
   end;
End;


Procedure FbManage.FbClose;
Begin
   if HdrOpen then
   begin
      Close(HdrFile);
      HdrOpen := False;
   end;
   if IdxOpen then
   begin
      Close(IdxFile);
      IdxOpen := False
   end;
   if DescOpen then
   begin
      Close(DescFile);
      DescOpen := False
   end;
End;

Destructor FbManage.Done;
begin
   FbClose;
end;

Function FbManage.EOFB: Boolean;
Begin
   EOFB := Eof(HdrFile);
end;

Function FbManage.GetFBbsLine: String;
Var
   TempStr: String;
   {$IFDEF VIRTUALPASCAL}
   NumRead: Longint;
   {$ELSE}
   NumRead: Word;
   {$ENDIF}
   I : Byte;
begin
   Read(HdrFile, CurrHdr);
   Read(IdxFile, CurrIdx);
   Seek(DescFile, CurrHdr.LongDescPtr);
   if CurrHdr.Name<>'' then
   begin
      Str(CurrHdr.TimesDl: DcLen, TempStr);
      TempStr := CurrHdr.Name + ' ' + DlLimit1[1] + TempStr +
         DlLimit2[1];
   end else
      TempStr := ' ';
   BlockRead(DescFile, TempStr[length(TempStr)+1], 255 - length(TempStr),
      NumRead);
   Inc(TempStr[0], NumRead);
   I := pos(#0, TempStr);
   if I>0 then
      TempStr[0] := Chr(i-1);
   GetFBbsLine := TempStr;
end;

Procedure FbManage.WriteComment(S: String);
Var DescFileSize: Longint;
Begin
   {scrive la descrizione}
   S := S + #0;
   DescFileSize := FileSize(DescFile);
   Seek(DescFile, DescFileSize);
   BlockWrite(DescFile, S[1], length(S));
   {Prepara Hdr}
   FillChar(CurrHdr, SizeOf(FilesHdrRecord), 0);
   CurrHdr.LongDescPtr := DescFileSize;
   Write(HdrFile, CurrHdr);
   {Prepara Idx}
   FillChar(CurrIdx, SizeOf(FilesIdxRecord), 0);
   CurrIdx.LongDescPtr := DescFileSize;
   Write(IdxFile, CurrIdx);
end;

Procedure FbManage.WriteRec(Nome: String;
   FTime, FSize: Longint; TimesDl: Word; Pnt: DescTypePtr);
Var
    DescFileSize: Longint;
    TempDesc: DescTypePtr;
    StartDesc: String;
    TempStr: String;
begin
   DescFileSize := FileSize(DescFile);
   Seek(DescFile, DescFileSize);
   {scrive il primo record}
   if Pnt=Nil then
      TempStr := OrfanoStr(Nome) + #0
   else
      TempStr := Pnt^.Descrizione^ + #0;
   BlockWrite(DescFile, TempStr[1],length(TempStr));
   {Prepara Hdr}
   FillChar(CurrHdr, SizeOf(FilesHdrRecord), 0);
   CurrHdr.Name := Nome;
   CurrHdr.Size := FSize;
   CurrHdr.FileDate := FTime;
   CurrHdr.UploadDate := FTime;
   CurrHdr.LastDl := ActDate;
   CurrHdr.TimesDl := TimesDl;
   CurrHdr.LongDescPtr := DescFileSize;
   Write(HdrFile, CurrHdr);
   {Prepara Idx}
   FillChar(CurrIdx, SizeOf(FilesIdxRecord), 0);
   CurrIdx.Name := Nome;
   CurrIdx.UploadDate := FTime;
   CurrIdx.LongDescPtr := DescFileSize;
   Write(IdxFile, CurrIdx);
   {le linee successive le aggiunge come commenti}
   {la prima riga l'ha gia' scritta}
   if Nome<>'' then
      StartDesc := LdChar[1]
   else
      StartDesc := '';
   if Pnt<>Nil then
      Pnt := Pnt^.Next;
   While (Pnt<>Nil) do
   begin
      WriteComment(StartDesc + Pnt^.Descrizione^);
      Pnt := Pnt^.Next
   end;
end;

Procedure FbManage.SeekEnd;
begin
   if IdxOpen then
      Seek(IdxFile, FileSize(IdxFile));
   if HdrOpen then
      Seek(HdrFile, FileSize(HdrFile));
end;

Procedure FbManage.Append;
Begin
   fbReset;
   SeekEnd;
end;

Function FbManage.FbIOResult: Word;
begin
   FbIOResult := FbError;
   FbError := 0
end;

end.
