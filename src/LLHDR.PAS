Unit LLHdr;

{$I LL.Def}

Interface

Uses
   MkFile,
   MkGlobt,
   MkString, llshell, LLGEN, Dos, Crt;

Procedure ImportFile(FileName:DescTypePtr);
Procedure WriteHeader;
Procedure WriteCopyright;
Procedure WriteFooter;
Procedure ImportBin(FName:String; SeekPos:Longint);

Implementation

Procedure WriteHeader;
Var T:DateTime;
    TempStr:String;
begin
   UnpackTime(ActDate,T);
   MyDateStr(T);
   {Info sul sistema e ora}
   Writeln(AllFiles);
   WriteLn(AllFiles,RepeatStr(' ',40-length(Int) Div 2),Int);
   Writeln(AllFiles);
   inc(AllFilesSize,4);
   inc(AllFilesSize,40-length(Int) div 2 + length(Int) +2);
   Writeln(AllFiles,BBSName,', ',AddrStr(Aka[0]),'':77-Length(BBSName)-Length(AddrStr(Aka[0]))-length(PrevDataStr),
      PrevDataStr);
   Inc(AllfilesSize, 81);
   {
   Writeln(AllFiles,HdrStr);
   WriteLn(AllFiles,'º        This is a complete list of all files available on this system        º');
   Writeln(AllFiles,FtrStr);
   inc(AllFilesSize,81*2);
   }
   if (NewDays>0) and (PathNew<>'') then
   begin
      Writeln(NewFiles);
      WriteLn(NewFiles,RepeatStr(' ',40-length(Int) Div 2)+Int);
      Writeln(NewFiles);
      Writeln(NewFiles,BBSName,', ',AddrStr(Aka[0]),'':77-Length(BBSName)-Length(AddrStr(Aka[0]))-length(PrevDataStr),
         PrevDataStr);
      {
      Writeln(NewFiles,HdrStr);
      WriteLn(NewFiles,'º        This is a complete list of new files available on this system        º');
      Writeln(NewFiles,FtrStr);
      }
   end;
end {WriteHeader};

Procedure WriteCopyright;
Var TempStr:String;
begin
   TempStr := 'LLIST ' + Versione +' - Copyright (C) '+CompYear+' by '+Autore+ ' 2:332/901';
   If length(TempStr) mod 2 = 1 then
      TempStr := TempStr + ' ';
   Writeln(AllFiles,HdrStr);
   Writeln(AllFiles,'º','':39-length(TempStr) div 2,
      TempStr,'':38-length(TempStr) div 2,'º');
   WriteLn(AllFiles,FtrStr);
   Inc(AllFilesSize,81*3);
   if (NewDays>0) and (PathNew<>'') then
   begin
      Writeln(NewFiles,HdrStr);
      Writeln(NewFiles,'º','':39-length(TempStr) div 2,
         TempStr,'':38-length(TempStr) div 2,'º');
      WriteLn(NewFiles,FtrStr);
   end;
end {WriteCopyright};


Procedure WriteFooter;
var Fmt:Integer;
    TempStr, TempStr1 : String;
    I:Integer;
    Str1, Str2: String;
begin
   if (LListStatus=MakeSearch) or (LListStatus=Announce) then
      Fmt := 38
   else
      Fmt := 39;

   if message[2]=Nil then
      TempStr1 := 'Found a total of %1 files on this system (%2)'
   else
      TempStr1 := message[2]^;

   TempStr := TempStr1;
   substpar(TempStr,long2str(NTotFiles,0),'1');
   substpar(tempstr,bytesstr(TotSize),'2');

   Writeln(AllFiles);
   WriteLn(AllFiles,AnsiCol[ColFrame]+StripChar(HdrStr));
   Writeln(AllFiles,AnsiCol[ColFrame]+'º'+AnsiCol[ColFrameIn]+
      RepeatStr(' ',39-length(TempStr) Div 2)+TempStr+AnsiCol[ColFrame]+
      RepeatStr(' ',Fmt-length(TempStr)+length(TempStr) Div 2-1)+'º');
   Writeln(AllFiles,AnsiCol[ColFrame]+StripChar(FtrStr)+AnsiCol[ColDef]);
   if (NewDays>0) and (PathNew<>'') then
   begin
      TempStr := TempStr1;
      substpar(TempStr,long2str(NTotNewFiles,0),'1');
      substpar(tempstr,bytesstr(TotNewSize),'2');
      Writeln(NewFiles);
      WriteLn(NewFiles,AnsiCol[ColFrame]+StripChar(HdrStr));
      Writeln(NewFiles,AnsiCol[ColFrame]+'º'+AnsiCol[ColFrameIn]+
         RepeatStr(' ',39-length(TempStr) Div 2)+TempStr+AnsiCol[ColFrame]+
         RepeatStr(' ',Fmt-length(TempStr)+length(TempStr) Div 2-1)+'º');
      Writeln(NewFiles,AnsiCol[ColFrame]+StripChar(FtrStr)+AnsiCol[ColDef]);
   end;
end {WriteFooter};



Procedure ImportFile(FileName:DescTypePtr);
Var TempStr:String;
begin
   while FileName<>Nil do
   begin
      assign(VariText,FileName^.Descrizione^);
      SetTextBuf(VariText,VariBuf^,SizeTxtBuf);
      {$I-}
      Reset(VariText);
      {$I+}
      if IOREsult=0 then
      begin
         while not eof(VariText) do
         begin
            readln(VariText,TempStr);
            Writeln(AllFiles,TempStr);
            if (NewDays>0) and (PathNew<>'') then
            begin
               Writeln(NewFiles,TempStr)
            end;
            inc(AllFilesSize,length(TempStr)+2);
         end;
         close(VariText);
      end;
      FileName := FileName^.Next
   end;
end {ImportFile};

Procedure ImportBin(FName:String; SeekPos:Longint);
Var F,F1,F2: File;
    Buf:Pointer;
    {$IFDEF VIRTUALPASCAL}
    Result, Result1: Longint;
    {$ELSE}
    Result,Result1:Word;
    {$ENDIF}
    fm: Word;
    ImportAll, ImportNew: Boolean;
Begin
   fm := FileMode;
   FileMode := FmReadWrite_DA;
   Assign(F,PathAll);
   {$I-}
   Reset(F,1);
   {$I+}
   ImportAll := IOResult=0;
   if ImportAll then
      seek(F,SeekPos);
   if (NewDays>0) and (PathNew<>'') then
   begin
      Assign(F1,PathNew);
      {$I-}
      Reset(F1,1);
      {$I+}
      ImportNew := IOResult=0;
      if ImportNew then
         seek(F1,SeekPos);
   end else
      ImportNew := False;
   assign(F2,FName);
   {$I-}
   Reset(F2,1);
   {$I+}
   if IOREsult=0 then
   begin
      GetMem(Buf,1024);
      while not eof(F2) do
      begin
         BlockRead(F2,Buf^,1024,result);
         if ImportAll then
            BlockWrite(F,Buf^,Result,Result1);
         if ImportNew then
            BlockWrite(F1,Buf^,Result,Result1);
      end;
      Close(F2);
      FreeMem(Buf,1024);
   end;
   if ImportNew then
      Close(F1);
   if ImportAll then
      Close(F);
   filemode := Fm;
End {ImportBin};

end.
