Unit LLSETVAR;

{$I LL.def}

Interface

Procedure GetLListStatus;

Implementation

Uses
   MTask, Dos, Crt, Crc32, MkString, MkGlobT,

   MkFile,

   MkMisc, LLParseS,

   LLERRMSG, LLGEN, LLTEND, LLVIEW, LLTEXT, LLMOUSE, LLCOLORS;


Var D:DirStr; N:NameStr; E:ExtStr;
    PrmOffset: Word;

    {$IFDEF VIRTUALPASCAL}
    TempWord: Longint;
    {$ENDIF}

Type
StartRA250CONFIGrecord = record
    VersionID           : Word;
    xCommPort           : Byte;
    xBaud               : LongInt;
    xInitTries          : Byte;
    xInitStr,
    xBusyStr            : String[70];
    xInitResp,
    xBusyResp,
    xConnect300,
    xConnect1200,
    xConnect2400,
    xConnect4800,
    xConnect9600,
    xConnect19k,
    xConnect38k         : String[40];
    xAnswerPhone        : Boolean;
    xRing,
    xAnswerStr          : String[20];
    xFlushBuffer        : Boolean;
    xModemDelay         : Integer;

    MinimumBaud,
    GraphicsBaud,
    TransferBaud        : word;
    SlowBaudTimeStart,
    SlowBaudTimeEnd,
    DownloadTimeStart,
    DownloadTimeEnd     : String[5];

    PageStart           : Array[0..6] of String[5];
    PageEnd             : Array[0..6] of String[5];

    SeriNum,
    CustNum             : String[22];
{}  FreeSpace1          : Array[1..24] of Byte;
    PwdExpiry           : Word;

    MenuPath,
    TextPath,
    AttachPath,
    NodelistPath,
    MsgBasePath,
    SysPath,
    ExternalEdCmd       : String[60];

    Address             : Array[0..9] of AddrType;
    SystemName          : String[30];

    NewSecurity         : Word;
    NewCredit           : Word;
    NewFlags            : FlagType;

    OriginLine          : String[60];
    QuoteString         : String[15];
    Sysop               : String[35];
    {[...]   Altri campi, li ignoro... }
end;

Function ExpandD0(S:String):String;
Var I,J:Integer;
begin
   if S='' then
   begin
      ExpandD0 := S;
   end else
   begin
      {variabili di environment}
      I := pos('%',S);
      while I>0 do
      begin
         J := I+1;
         while (J<=length(S)) and (S[J]<>'%') and (S[J]<>'.') do
            inc(J);
         if (J<length(S)) and (S[J]='%') then
            delete(S,J,1);
         S := Copy(S,1,I-1) + GetEnv(Copy(S,I+1,J-I-1)) +
            Copy(S,J,length(S)-J+1);
         I := pos('%',S)
      end;
      if (S<>'') and (S[1]='\') then
      begin
         ExpandD0 := D0[1] + D0[2] + S
      end else
      if (Length(S)>1) and (S[2]<>':') then
      begin
         ExpandD0 := D0 + S
      end else
      begin
         ExpandD0 := S
      end
   end;
end {ExpandD0};



Procedure CompilaDataPattern;
var I,P:Byte;
    Temp:^SetDataTypeRef;
begin
   I := 1;
   PrevDataStr := '';
   SetData := Nil;
   Temp := Addr(SetData);

   while DataPattern[I]<>#0 do
   begin
      if (DataPattern[I]='%') and (DataPattern[I+1]<>#0) then
      begin
         inc(I);
         case UpCase(DataPattern[I]) of
            'D':begin {Day}
                   New(Temp^);
                   Temp^^.DataType := 1;
                   Temp^^.Position := length(PrevdataStr) + 1;
                   Temp^^.Next := Nil;
                   Temp := Addr(Temp^^.Next);
                   PrevDataStr := PrevDataStr + '..';
                end;
            'B':begin {Month}
                   New(Temp^);
                   Temp^^.DataType := 2;
                   Temp^^.Position := length(PrevdataStr) + 1;
                   Temp^^.Next := Nil;
                   Temp := Addr(Temp^^.Next);
                   PrevDataStr := PrevDataStr + '..';
                end;
            'C':begin {MonthStr}
                   New(Temp^);
                   Temp^^.DataType := 3;
                   Temp^^.Position := length(PrevdataStr) + 1;
                   Temp^^.Next := Nil;
                   Temp := Addr(Temp^^.Next);
                   PrevDataStr := PrevDataStr + '...';
                end;
            'Y':begin {Year}
                   New(Temp^);
                   Temp^^.DataType := 4;
                   Temp^^.Position := length(PrevdataStr) + 1;
                   Temp^^.Next := Nil;
                   Temp := Addr(Temp^^.Next);
                   PrevDataStr := PrevDataStr + '..';
                end
             else
                dec(I);
                PrevDataStr := PrevDataStr + DataPattern[I];
             end;
         inc(I);
      end else
      begin
         PrevDataStr := PrevDataStr + DataPattern[I];
         inc(I);
      end;
   end;
end {CompiladataPattern};


Function ParseAreaId(TempStr:String; Var AreaId:PathStr; Var Tipo:Integer): Boolean;
Var I:Integer;
    {$IFDEF VIRTUALPASCAL}
    Code: Longint;
    {$ELSE}
    Code: Word;
    {$ENDIF}
begin
   I := pos(',',TempStr);
   if (I=0) then
   begin
      AreaId:=TempStr;
      Tipo := 1;
   end else
   begin
      AreaId:=Copy(TempStr,1,I-1);
      delete(TempStr,1,I);
      if TempStr<>'' then
         val(TempStr,I,Code)
      else
         Code := 1;
      if (Code=0) and (I>=0) and (I<=2) then
         Tipo := I
      else
         Tipo := 1;
   end;
   ParseAreaId := AreaId <> '';
end {ParseAreaId};


procedure Istruzioni;

var I:integer;
    Ch:Char;
begin

   Writeln;
   Write('Usage   : LLIST ');
   case LListStatus of
      FileIdx: Write('FILEIDX ');
      FixFBbs: Write('FIXFBBS ');
      MakeListSum: Write('FILELIST ');
      Announce: Write('ANNOUNCE ');
      MakeSearch: Write('SEARCH ');
      TicProcess: Write('TIC ');
   end;
   writeln('[commands] [-Q] [-B] [-M]');
   Writeln;

   Case LListStatus of
      Unselected:
      begin
         Writeln('Commands are : FILELIST        - Generates file lists');
         Writeln('               CDLIST          - Generates CD file lists');
         Writeln('               ANNOUNCE        - Generates new file announcements');
         Writeln('               TIC             - Processes .Tic files');
         Writeln('               RAID            - Processes Raid msg only');
         Writeln('               HATCH <file> <area> [<desc>] - Hatch a file');
         Writeln('               FIXFBBS         - Rewrite Files.Bbs');
         Writeln('               FILEIDX         - Makes FILEIDX list');
         Writeln('               SEARCH          - Processes FSEARCH Msgs');
      end;
      FixFBBs:
      begin
         Writeln('FIXFBBS sub-commands are:');
         Writeln('               AREA <n>|<n1-n2> [<n>|<n1-n2>]');
         Writeln('               ,READFILE_ID    - Read File_Id.Diz from every file');
         Writeln('               ,REPACK[:<Packer>] - Recompress archives to <Packer>');
         Writeln('               ,CHECK          - Check for virus');
         Writeln('sub-command preceeded by "," must be spedified immediately after');
         Writeln('FIXFBBS, with no blank');
      end;
      else
      begin
         Writeln('No sub commands available');
      end;
   End;

   Writeln('               -Q              - Quiet mode');
   Writeln('               -B              - Bios screen writes');
   Writeln('               -M              - Monochrome color set');

   Writeln;
   Writeln('Please refer to the documentation for a more complete command summary');
   Writeln;

   halt(1);

end {Istruzioni};



Function ParseArea(Var Aree:ListaNumRef; TempStr:String):Boolean;
Var I:Integer;
    {$IFDEF VIRTUALPASCAL}
    Code:Longint;
    {$ELSE}
    Code: Word;
    {$ENDIF}
   Procedure ParseArea1(TempStr:String);
   Var J,First,Last:Integer;
   Begin
      J := Pos('-',TempStr);
      if J>0 then
      begin
         val(copy(TempStr,1,J-1),First,Code);
         if (Code = 0) then
         begin
            if (First<0) or (First>MaxInt) then
            begin
               first := -1;
               code := 1
            end else
            begin
               val(copy(TempStr,J+1,Length(TempStr)-J),Last,Code);
               If (Last<First) or (Last>MaxInt) then
               begin
                  first := -1;
                  last := -1;
                  code := 1;
               end else
                  PutInListaAree(First,Last,Aree);
            end;
         end;
      end else
      begin
         val(TempStr,First,Code);
         if Code=0 then
            PutInListaAree(First,First,Aree);
      end;
   end;
begin
   Code := 0;
   while (Code=0) and (TempStr<>'') do
   begin
      I := pos(' ',TempStr);
      if I>0 then
      begin
         ParseArea1(Copy(TempStr,1,I-1));
         delete(TempStr,1,I);
         stripLeadingSpace(TempStr);
      end else
      begin
         ParseArea1(TempStr);
         TempStr := '';
      end;
   end;
   ParseArea := Code = 0;
end {ParseArea};

Procedure Config;
Var CfgBin: File;
    TempStr: String;
    I: Integer;
    MouInfo: MinfoRecType;
begin
   Repeat
      TextAttr := StartAttr;
      ClrScr;
      GotoXY(1,1);
      textAttr := NormVideoCol;
      Writeln('Test <N>orm Video');
      TextAttr := LowVideoCol;
      Writeln('Test <L>ow Video');
      TextAttr := HighVideoCol;
      Writeln('Test <H>igh Video');
      TextAttr := InvVideoCol;
      Writeln('Test <I>nv Video');
      TextAttr := StartAttr;
      writeln('<CR> to accept');

      waitevent;

      if KeyPressed then
      begin
         Ch := Readkey;
         case upcase(ch) of
            'N': begin
                    I := GetColor;
                    if I<>-1 then
                       NormVideoCol := I;
                 end;
            'I': begin
                    I := GetColor;
                    if I<>-1 then
                       InvVideoCol := I;
                 end;
            'L': begin
                    I := GetColor;
                    if I<>-1 then
                       LowVideoCol := I;
                 end;
            'H': begin
                    I := GetColor;
                    if I<>-1 then
                       HighVideoCol := I;
                 end;
         end;
      end else
      begin
         MouGet(MouInfo);
         if Mouinfo.IsDouble then
         begin
            if MouInfo.Cy=4 then
            begin
               if (MouInfo.Cx=1) or (MouInfo.Cx=2) then
                  ch := #13;
            end else
            if MouInfo.Cx=6 then
            begin
               Case MouInfo.Cy of
                  0: KbdBuffer := 'N';
                  1: KbdBuffer := 'L';
                  2: KbdBuffer := 'H';
                  3: KbdBuffer := 'I';
               end;
            end;
         end;
      end;
   until (ch=#13);

   if Ch=#13 then
   begin
      Assign(CfgBin, D0 + 'Colors.Cfg');
      {$I-}
      Rewrite(CfgBin, 1);
      {$I+}
      if IOResult=0 then
      begin
         TempStr := 'LLIST Colors' + ^Z;
         BlockWrite(CfgBin, TempStr[1], length(TempStr));;
         ch := #0;
         for I := length(TempStr) + 1 to 256 do
            BlockWrite(CfgBin, ch, 1);
         {la vera cfg comincia dopo i primi 256 bytes}
         BlockWrite(CfgBin, NormVideoCol, 1);
         BlockWrite(CfgBin, LowVideoCol, 1);
         BlockWrite(CfgBin, HighVideoCol, 1);
         BlockWrite(CfgBin, InvVideoCol, 1);
         BlockWrite(CfgBin, ActDate, 4);
         close(CfgBin);
      end;
   end;
   ClrScr;
   GotoXY(1,10);
end;

Procedure NewExit; Far;  { MUST be far! }
Var I:Word;
    Elapsed:Longint;
begin

  ExitProc := OldExit;

  if EchoWritten then
     CreateFlagFile(PathEchoFlag);

  if NetWritten then
     CreateFlagFile(PathNetFlag);

  Elapsed := Timer - StartTime;

  While Elapsed < 0 do
  begin
     {Cambio data, compensazione}
     Elapsed := Elapsed + 182 * 6 {Ticks in un minuto}
        * 60 * 24;
  end;

  {converte in secondi}
  Elapsed := Round(Elapsed / 18.2);

  if Elapsed >= 60 then
  begin
     if Elapsed mod 60 >= 10 then
     begin
        TempStr := Long2Str(Elapsed div 60,0) + '''' +
           Long2Str(Elapsed mod 60,0) + ''''''
     end else
     begin
        TempStr := Long2Str(Elapsed div 60,0) + '''0' +
           Long2Str(Elapsed mod 60,0) + ''''''
     end
  end else
  begin
     TempStr := Long2Str(Elapsed mod 60,0) + ''''''
  end;
  Writeln(' * Execution time ',TempStr);
  Writeln(LogFile,Prelog(LogDone),'Execution time ',TempStr);
  Flush(LogFile);

  if not Registrato then
  begin
     writeln(' * ',Serie);
     writeln(LogFile,Prelog(LogError),Serie);
     Flush(LogFile);
     I := TextAttr;
     TextAttr := TextAttr or Blink;
     write(' * Please register now, support shareware!');
     TextAttr := I;
     writeln;
     writeln(LogFile,Prelog(LogError),'Please register now, support shareware!');
     Flush(LogFile);
  end;

  ChDir(DirIn);
  if DirIn[length(DirIn)]=':' then
     ChDir('\');

  if ErrorAddr <> nil then
  begin
    {-Display custom run-time error message }
    Writeln;
    Writeln;
    Writeln(' * Please report to ',Autore,':');
    writeln(' * Runtime error ',ExitCode:3,' at ',
       HexStr(seg(ErrorAddr^)),':',HexStr(ofs(ErrorAddr^)),'.');
    writeln(' * ',ErrorMsg(ExitCode));
    writeln(LogFile,PreLog(LogError),'Please report to ',Autore,':');
    writeln(LogFile,PreLog(LogError),'Runtime error ',ExitCode:3,' at ',
       HexStr(seg(ErrorAddr^)),':',HexStr(ofs(ErrorAddr^)),'.');
    writeln(LogFile,Prelog(LogError),ErrorMsg(ExitCode));
    ErrorAddr := Nil;
  end;

  Writeln(LogFile,PreLog(LogDone),'End');
  Writeln(' * End');

  {separa i file di log delle varie sessioni}
  Writeln(LogFile);

  Close(LogFile);

  TextAttr := StartAttr;

end {NewExit};


Procedure ParseCommandLine;
Var I,J:Integer;
    {$IFDEF VIRTUALPASCAL}
    Code: Longint;
    {$ELSE}
    Code: Word;
    {$ENDIF}
begin
   {Interpreta parametri sulla linea di comando}
   I := 1;
   While I<=ParamCount do
   begin
      TempStr := Upper(ParamStr(I));
      if TempStr='AREA' then
      begin
         if (LlistStatus=FixFBbs) and (I<ParamCount) then
         begin
            inc(I);
            if ParseArea(Aree,ParamStr(I)) then
            begin
               inc(I);
               while (I<=ParamCount) and ParseArea(Aree,ParamStr(I)) do
                  inc(I);
               dec(I);
            end else
               Istruzioni;
         end else
            Istruzioni;
      end else
      if (TempStr='NEWDAYS') then
      begin
         if I<ParamCount then
         begin
            inc(I);
            val(paramStr(I),J,Code);
            if (Code=0) then
            begin
               if (J>=0) and (j<=180) then
               begin
                  NewDays := J
               end;
            end else
               Istruzioni
         end else
            Istruzioni;
      end else
      if TempStr='-Q' then
         QuietMode := True
      else
      if tempstr='-M' then
      begin
         LowVideoCol := 7;
         InvVideoCol := 112;
         HighVideoCol := 15;
         NormVideoCol := 7;
      end
      else if TempStr='FILEIDX' then
      begin
         OtherOptions := OtherOptions + [FileIdx];
      end else
      if TempStr='FILELIST' then
      begin
         J := 1;
         while (J<=NFileList) and FileList[J]^.CD do
            inc(J);
         if J<=NFileList then
            OtherOptions := OtherOptions + [MakeListSum]
         else
            Istruzioni;
      end else
      if TempStr='CDLIST' then
      begin
         J := 1;
         while (J<=NFileList) and not FileList[J]^.CD do
            inc(J);
         if J<=NFileList then
            OtherOptions := OtherOptions + [CDMakeListSum]
         else
            Istruzioni;
      end else
      if TempStr='TIC' then
      begin
         OtherOptions := OtherOptions + [RaidProcess];
         OtherOptions := OtherOptions + [TicProcess];
      end else
      if TempStr='RAID' then
      begin
         OtherOptions := OtherOptions + [RaidProcess];
      end else
      if TempStr='HATCH' then
      begin
         if LListStatus<>Unselected then
            Istruzioni;
         LLIstStatus := HatchFile;
         inc(I);
         if I>paramcount then
            istruzioni;
         HatchName := Upper(FExpand(ParamStr(I)));
         inc(I);
         if I>paramcount then
            istruzioni;
         HatchArea := Upper(ParamStr(I));
         inc(I);
         if I<=Paramcount then
         begin
            HatchDesc := ParamStr(I);
            inc(I);
            while (I<=ParamCount) do
            begin
               HatchDesc := HatchDesc + ' ' + ParamStr(I);
               inc(I)
            end;
         end else
         begin
            HatchDesc := '';
         end;
      end else
      if Copy(TempStr,1,7)='FIXFBBS' then
      begin
         if LListStatus<>Unselected then
            Istruzioni;
         LLIstStatus := FixFBbs;
         Delete(TempStr,1,7);
         while (TempStr<>'') do
         begin
            if Pos(',READFILE_ID',TempStr)=1 then
            begin
               ReadFile_Id := True;
               Delete(TempStr,1,12);
            end else
            if Pos(',REPACK',TempStr)=1 then
            begin
               MakeRepack := True;
               Delete(TempStr,1,7);
               if (TempStr<>'') and (TempStr[1]=':') then
               begin
                  delete(TempStr,1,1);
                  if length(TempStr)<3 then
                     Istruzioni
                  else
                  begin
                     Repack := Copy(TempStr,1,3);
                     Delete(TempStr,1,3);
                  end;
               end;
            end else
            if Pos(',CHECK',TempStr)=1 then
            begin
               CheckFiles := True;
               Delete(TempStr,1,6);
            end else
               Istruzioni
         end;
      end else
      if TempStr='ANNOUNCE' then
      begin
         OtherOptions := OtherOptions + [Announce];
      end else
      if TempStr='-B' then
      begin
         {ignora, e' gia' stato processato prima}
      end else
      if TempStr='SEARCH' then
      begin
         OtherOptions := OtherOptions + [raidProcess];
         OtherOptions := OtherOptions + [MakeSearch];
      end else
      if (TempStr='L43') or (TempStr='L50') then
      begin
         {$IFNDEF NO4350}
         ModeFont8x8 := True;
         {$ENDIF}
      end else
      if TempStr='CONFIG' then
      begin
         Config;
      end else
      if TempStr='L25' then
         {$IFNDEF NO4350}
         ModeFont8x8 := False
         {$ENDIF}
      else
         Istruzioni;
      inc(I);
   end;
end {ParseCommandLine};


procedure ParseCfg;
Const NMaxFileParsed=16;
var
    I,J,K,FileParsed:Integer;
    TempStr1:String;
    {Fm:Word;}
    Include:String;
    IncludeList,TempFileNameRef:DescTypePtr;
    Linea:Integer;
    ParsedTicAreas: Boolean;
    TempInt:Integer;
    {$IFDEF VIRTUALPASCAL}
    Code: Longint;
    {$ELSE}
    Code: Word;
    {$ENDIF}
    CfgBin: File;

       Procedure ParseAnnounceMsg;
       Var I,J:INteger;
       Begin
          if NAnnounce<NMaxAnnounce then
          begin
             inc(NAnnounce);
             new(Annunci[NAnnounce]);
             Annunci[NAnnounce]^.MsgFrom := '';
             Annunci[NAnnounce]^.MsgTo := '';
             Annunci[NAnnounce]^.MsgSubject := '';
             Annunci[NAnnounce]^.MsgOrigin := '';
             Annunci[NAnnounce]^.KludgeFdn := '';
             Annunci[NAnnounce]^.Aree := Nil;
             Annunci[NAnnounce]^.NoIbm := False;
             Annunci[NAnnounce]^.Prefix := Nil;
             Annunci[NAnnounce]^.Suffix := Nil;
             Annunci[NAnnounce]^.Vc := False;
             Annunci[NAnnounce]^.FirstTime := True;
             Annunci[NAnnounce]^.CC := Nil;
             Annunci[NAnnounce]^.XC := Nil;
             Annunci[NAnnounce]^.Filter := Nil;
             while not eof(variText) and (TempStr<>'END') do
             begin
                readln(variText,TempStr);
                inc(Linea);
                I := Pos(';',TempStr);
                if I>0 then
                   TempStr[0] := chr(I-1);
                while (TempStr<>'') and (TempStr[length(TempStr)]=' ') do
                   dec(TempStr[0]);
                StripLeadingSpace(TempStr);
                I := 1;
                while (I<=length(TempStr)) and (TempStr[I]<>' ') do
                begin
                   TempStr[I] := UpCase(TempStr[I]);
                   inc(I)
                end;
                if TempStr<>'' then
                begin
                   if Pos('FDN ',TempStr)=1 then
                   begin
                      delete(TempStr,1,4);
                      stripLeadingSpace(TempStr);
                      Annunci[NAnnounce]^.KludgeFdn:=Upper(TempStr);
                   end else
                   if Pos('FROM ',TempStr)=1 then
                   begin
                      delete(TempStr,1,5);
                      stripLeadingSpace(TempStr);
                      Annunci[NAnnounce]^.MsgFrom:=TempStr;
                   end else
                   if Pos('TO ',TempStr)=1 then
                   begin
                      delete(TempStr,1,3);
                      stripLeadingSpace(TempStr);
                      Annunci[NAnnounce]^.MsgTo:=TempStr;
                   end else
                   if Pos('SUBJECT ',TempStr)=1 then
                   begin
                      delete(TempStr,1,8);
                      stripLeadingSpace(TempStr);
                      Annunci[NAnnounce]^.MsgSubject:=TempStr;
                   end else
                   if Pos('ORIGIN ',TempStr)=1 then
                   begin
                      delete(TempStr,1,7);
                      stripLeadingSpace(TempStr);
                      Annunci[NAnnounce]^.MsgOrigin:=TempStr;
                   end else
                   if Pos('AREAID ',TempStr)=1 then
                   begin
                      delete(TempStr,1,7);
                      stripLeadingSpace(TempStr);
                      L := Upper(TempStr);
                      PosDesc := 1;
                      PutDescrizione(Annunci[NAnnounce]^.XC);
                   end else
                   if Pos('AREATAG ',TempStr)=1 then
                   begin
                      delete(TempStr,1,8);
                      stripLeadingSpace(TempStr);
                      L := 'T' + Upper(TempStr);
                      PosDesc := 1;
                      PutDescrizione(Annunci[NAnnounce]^.XC);
                   end else
                   if Pos('PREFIX ',TempStr)=1 then
                   begin
                      delete(TempStr,1,7);
                      stripleadingSpace(TempStr);
                      L := ExpandD0(TempStr);
                      PosDesc := 1;
                      PutDescrizione(Annunci[NAnnounce]^.Prefix)
                   end else
                   if Pos('NOIBM',TempStr)=1 then
                   begin
                       Annunci[NAnnounce]^.NoIbm := True;
                   end else
                   if Pos('VC',TempStr)=1 then
                   begin
                       Annunci[NAnnounce]^.Vc := True;
                   end else
                   if Pos('SUFFIX ',TempStr)=1 then
                   begin
                      delete(TempStr,1,7);
                      stripleadingspace(TempStr);
                      L := ExpandD0(TempStr);
                      PosDesc := 1;
                      PutDescrizione(Annunci[NAnnounce]^.Suffix)
                   end else
                   if pos('AREA ',TempStr)=1 then
                   begin
                      delete(TempStr,1,5);
                      StripLeadingSpace(TempStr);
                      if ParseArea(Annunci[NAnnounce]^.Aree,TempStr) then;
                   end else
                   if pos('CC ',TempStr)=1 then
                   begin
                      delete(TempStr,1,3);
                      StripLeadingSpace(TempStr);
                      L := TempStr;
                      PosDesc := 1;
                      PutDescrizione(Annunci[NAnnounce]^.CC);
                   end else
                   if Pos('FILTER ',TempStr)=1 then
                   begin
                      delete(TempStr,1,7);
                      stripLeadingSpace(TempStr);
                      ExpandWildcards(TempStr);
                      L := TempStr;
                      PosDesc := 1;
                      PutDescrizione(Annunci[NAnnounce]^.Filter);
                   end else
                   if TempStr='END' then
                   begin
                      {fine dell'area}

                   end else
                   begin
                      writeln(' * Error in line ',Linea);
                      Writeln(LOgFile,Prelog(LogError),'Error in line ',Linea);
                      Flush(LogFile);
                   end;
                end;
             end;
             If (Annunci[NAnnounce]^.CC=Nil) and
                 (Annunci[NAnnounce]^.XC=Nil) then
             begin
                writeln(' * Invalid AnnounceMsg');
                writeln(LogFile,Prelog(LogError),'Invalid AnnounceMsg');
                Flush(LogFile);
                RemoveListaNum(Annunci[NAnnounce]^.Aree);
                CancellaDescrizione(Annunci[NAnnounce]^.Suffix);
                CancellaDescrizione(Annunci[NAnnounce]^.Prefix);
                CancellaDescrizione(Annunci[NAnnounce]^.CC);
                CancellaDescrizione(Annunci[NAnnounce]^.XC);
                Dispose(Annunci[NAnnounce]);
                dec(NAnnounce);
             end;
          end else
          begin
             writeln(' * Too Many AnnounceMsg');
             writeln(LogFile,Prelog(LogError),'Too Many AnnounceMsg');
             Flush(LogFile);
             while (TempStr<>'END') and not eof(VariText) do
             begin
                readln(VariText,TempStr);
                inc(linea);
                I := pos(';',TempStr);
                if I>0 then
                   TempStr := Copy(TempStr,1,I-1);
                StripLeadingSpace(TempStr);
                while (TempStr<>'') and (TempStr[length(TempStr)]=' ') do
                   dec(TempStr[0]);
                for I:=1 to length(TempStr) do
                   TempStr[I] := UpCase(TempStr[I]);
             end;
          end;
          if TempStr<>'END' then
          begin
             writeln(' * Missing End of AnnounceMsg');
             writeln(LogFile,Prelog(LogError),'Missing End of AnnounceMsg');
             Flush(LOgFile);
          End;
       End {ParseAnnounceMsg};

       Procedure ParseFileList;
       Var I,J:INteger;
       Begin
          if NFileList<NMaxFileList then
          begin
             inc(NFileList);
             new(FileList[NFileList]);
             FileList[NFileList]^.KludgeFdn := '';
             FileList[NFileList]^.Aree := Nil;
             FileList[NFileList]^.PathNew := '';
             FileList[NFileList]^.PathAll := '';
             FileList[NFileList]^.PathAvail := '';
             FileList[NFileList]^.PathBdl := '';
             FileList[NFileList]^.MaxBest1 := 10;
             FileList[NFileList]^.CD := False;
             FileList[NFileList]^.RemoveUncompressed  := False;
             FileList[NFileList]^.PathFtr := Nil;
             FileList[NFileList]^.PathHdr := Nil;
             while not eof(variText) and (TempStr<>'END') do
             begin
                readln(variText,TempStr);
                inc(Linea);
                I := Pos(';',TempStr);
                if I>0 then
                   TempStr[0] := chr(I-1);
                while (TempStr<>'') and (TempStr[length(TempStr)]=' ') do
                   dec(TempStr[0]);
                StripLeadingSpace(TempStr);
                I := 1;
                while (I<=length(TempStr)) and (TempStr[I]<>' ') do
                begin
                   TempStr[I] := UpCase(TempStr[I]);
                   inc(I)
                end;
                if TempStr<>'' then
                begin
                   if Pos('FDN ',TempStr)=1 then
                   begin
                      delete(TempStr,1,4);
                      stripLeadingSpace(TempStr);
                      FileList[NFileList]^.KludgeFdn:=Upper(TempStr);
                   end else
                   if pos('AREA ',TempStr)=1 then
                   begin
                      delete(TempStr,1,5);
                      StripLeadingSpace(TempStr);
                      if ParseArea(FileList[NFileList]^.Aree,TempStr) then;
                   end else
                   if Pos('NEWFILES ',TempStr)=1 then
                   begin
                      delete(TempStr,1,9);
                      StripLeadingSpace(TempStr);
                      if (TempStr<>'') and (pos(' ',TempStr)=0) then
                         FileList[NFileList]^.PathNew := ExpandD0(TempStr);
                   end else
                   if Pos('ALLFILES ',TempStr)=1 then
                   begin
                      delete(TempStr,1,9);
                      StripLeadingSpace(TempStr);
                      if (TempStr<>'') and (pos(' ',TempStr)=0) then
                         FileList[NFileList]^.PathAll := ExpandD0(TempStr);
                   end else
                   if Pos('OKFILE ',TempStr)=1 then
                   begin
                      delete(TempStr,1,7);
                      StripLeadingSpace(TempStr);
                      if (TempStr<>'') and (pos(' ',TempStr)=0) then
                         FileList[NFileList]^.PathAvail := ExpandD0(TempStr);
                   end else
                   if Pos('BDL ',TempStr)=1 then
                   begin
                      delete(TempStr,1,4);
                      StripLeadingSpace(TempStr);
                      if (TempStr<>'') and (pos(' ',TempStr)=0) then
                         FileList[NFileList]^.PathBdl := ExpandD0(TempStr);
                   end else
                   if Pos('BDLNUM ',TempStr)=1 then
                   begin
                      delete(TempStr,1,7);
                      StripLeadingSpace(TempStr);
                      Val(TempStr,TempWord,Code);
                      if (Code=0) and (TempWord<=MaxBest) then
                      if (TempStr<>'') and (pos(' ',TempStr)=0) then
                         FileList[NFileList]^.MaxBest1 := TempWord;
                   end else
                   if TempStr='REMOVEUNCOMPRESSED' then
                   begin
                      FileList[NFileList]^.RemoveUncompressed := True;
                   end else
                   if TempStr='CD' then
                   begin
                      FileList[NFileList]^.CD := True;
                   end else
                   if Pos('HEADER ',TempStr)=1 then
                   begin
                      delete(TempStr,1,7);
                      StripLeadingSpace(TempStr);
                      L := ExpandD0(TempStr);
                      PosDesc := 1;
                      PutDescrizione(FileList[Nfilelist]^.PathHdr)
                   end else
                   if Pos('FOOTER ',TempStr)=1 then
                   begin
                      delete(TempStr,1,7);
                      StripLeadingSpace(TempStr);
                      L := ExpandD0(TempStr);
                      PosDesc := 1;
                      PutDescrizione(Filelist[Nfilelist]^.PathFtr)
                   end else
                   if TempStr='END' then
                   begin
                      {fine dell'area}

                   end else
                   begin
                      writeln(' * Error in line ',Linea);
                      Writeln(LOgFile,Prelog(LogError),'Error in line ',Linea);
                      Flush(LOgFile);
                   end;
                end;
             end;
             If (FileList[NFileList]^.PathAll='') then
             begin
                writeln(' * Invalid FileList');
                writeln(LogFile,Prelog(LogError),'Invalid FileList');
                Flush(LOgFile);
                RemoveListaNum(FileList[NFileList]^.Aree);
                Dispose(FileList[NFileList]);
                dec(NFileList);
             end
          end else
          begin
             writeln(' * Too Many FileList');
             writeln(LogFile,Prelog(LogError),'Too Many FileList');
             Flush(LogFile);
             while (TempStr<>'END') and not eof(VariText) do
             begin
                readln(VariText,TempStr);
                inc(linea);
                I := pos(';',TempStr);
                if I>0 then
                   TempStr := Copy(TempStr,1,I-1);
                StripLeadingSpace(TempStr);
                while (TempStr<>'') and (TempStr[length(TempStr)]=' ') do
                   dec(TempStr[0]);
                for I:=1 to length(TempStr) do
                   TempStr[I] := UpCase(TempStr[I]);
             end;
          end;
          if TempStr<>'END' then
          begin
             writeln(' * Missing End of FileList');
             writeln(LogFile,Prelog(LogError),'Missing End of FileList');
             Flush(LogFile);
          End;
       End {ParseFileList};

       Procedure ParsePacker;
       Var I,J:Integer;
       Begin
          if NPacker<NMaxPackers then
          begin
             delete(TempStr,1,7);
             stripLeadingSpace(TempStr);
             if length(TempStr)<>3 then
                TempStr := ''
             else
             for J:=1 to length(TempStr) do
                TempStr[J] := UpCase(TempStr[J]);
             inc(NPacker);
             New(Packer[NPacker]);
             Packer[NPacker]^.Ext := TempStr;
             Packer[NPacker]^.Pack := '';
             Packer[NPacker]^.UnPack := '';
             Packer[NPacker]^.Delete := '';
             Packer[NPacker]^.Id := '';
             Packer[NPacker]^.OffSet := 0;
             while not eof(variText) and (TempStr<>'END') do
             begin
                readln(variText,TempStr);
                inc(Linea);
                I := Pos(';',TempStr);
                if I>0 then
                   TempStr[0] := chr(I-1);
                while (TempStr<>'') and (TempStr[length(TempStr)]=' ') do
                   dec(TempStr[0]);
                StripLeadingSpace(TempStr);
                I := 1;
                while (I<=length(TempStr)) and (TempStr[I]<>' ') do
                begin
                   TempStr[I] := UpCase(TempStr[I]);
                   inc(I)
                end;
                if TempStr<>'' then
                begin
                   if Pos('DOSPACK ',TempStr)=1 then
                   begin
                      {$IFDEF OS2}
                      if Packer[NPacker]^.Pack='' then
                      begin
                         delete(TempStr,1,8);
                         stripLeadingSpace(TempStr);
                         Packer[NPacker]^.Pack := TempStr;
                      end;
                      {$ELSE}
                      delete(TempStr,1,8);
                      stripLeadingSpace(TempStr);
                      Packer[NPacker]^.Pack := TempStr;
                      {$ENDIF}
                   end else
                   if Pos('DOSDELETE ',TempStr)=1 then
                   begin
                      {$IFDEF OS2}
                      if Packer[NPacker]^.Delete='' then
                      begin
                         delete(TempStr,1,10);
                         stripLeadingSpace(TempStr);
                         Packer[NPacker]^.Delete := TempStr;
                      end;
                      {$ELSE}
                      delete(TempStr,1,10);
                      stripLeadingSpace(TempStr);
                      Packer[NPacker]^.Delete := TempStr;
                      {$ENDIF}
                   end else
                   if Pos('DOSUNPACK ',TempStr)=1 then
                   begin
                      {$IFDEF OS2}
                      if Packer[NPacker]^.UnPack='' then
                      begin
                         delete(TempStr,1,10);
                         stripLeadingSpace(TempStr);
                         Packer[NPacker]^.UnPack := TempStr;
                      end;
                      {$ELSE}
                      delete(TempStr,1,10);
                      stripLeadingSpace(TempStr);
                      Packer[NPacker]^.UnPack := TempStr;
                      {$ENDIF}
                   end else
                   if Pos('OS2PACK ',TempStr)=1 then
                   begin
                      {$IFDEF OS2}
                      delete(TempStr,1,8);
                      stripLeadingSpace(TempStr);
                      Packer[NPacker]^.Pack := TempStr;
                      {$ENDIF}
                   end else
                   if Pos('OS2DELETE ',TempStr)=1 then
                   begin
                      {$IFDEF OS2}
                      delete(TempStr,1,10);
                      stripLeadingSpace(TempStr);
                      Packer[NPacker]^.Delete := TempStr;
                      {$ENDIF}
                   end else
                   if Pos('OS2UNPACK ',TempStr)=1 then
                   begin
                      {$IFDEF OS2}
                      delete(TempStr,1,10);
                      stripLeadingSpace(TempStr);
                      Packer[NPacker]^.UnPack := TempStr;
                      {$ENDIF}
                   end else
                   if Pos('ID ',TempStr)=1 then
                   begin
                      delete(TempStr,1,3);
                      stripLeadingSpace(TempStr);
                      Packer[NPacker]^.Id := '';
                      while (TempStr<>'') do
                      begin
                          if length(TempStr)=1 then
                          begin
                             TempStr := '';
                             Packer[NPacker]^.Id := '';
                          end else
                          begin
                             Ch := UpCase(TempStr[1]);
                             if Ch in ['A'..'F','0'..'9'] then
                             begin
                                if Ch in ['0'..'9'] then
                                   TempWord := ord(Ch) - ord('0')
                                else
                                   TempWord := Ord(ch) - ord('A') + 10;
                                Ch := UpCase(TempStr[2]);
                                if Ch in ['A'..'F','0'..'9'] then
                                begin
                                   if Ch in ['0'..'9'] then
                                      TempWord := TempWord * 16 + ord(Ch) - ord('0')
                                   else
                                      TempWord := TempWord * 16 + Ord(ch) - ord('A') + 10;
                                   Packer[NPacker]^.Id := Packer[NPacker]^.Id + Chr(TempWord);
                                   Delete(TempStr,1,2);
                                end else
                                begin
                                   TempStr := '';
                                   Packer[NPacker]^.Id := '';
                                end;
                             end else
                             begin
                                TempStr := '';
                                Packer[NPacker]^.Id := '';
                             end;
                          end;
                      end;
                   end else
                   if Pos('OFFSET ',TempStr)=1 then
                   begin
                      delete(TempStr,1,7);
                      stripleadingspace(TempStr);
                      if (TempStr<>'') and (pos(' ',TempStr)=0) then
                      begin
                         val(TempStr,TempWord,Code);
                         if (Code=0) and (TempWord>=0) then
                            Packer[NPacker]^.OffSet := TempWord;
                      end;
                   end else
                   if TempStr='END' then
                   begin
                      {fine dell'area}

                   end else
                   begin
                      writeln(' * Error in line ',Linea);
                      Writeln(LOgFile,Prelog(LogError),'Error in line ',Linea);
                      Flush(LogFile);
                   end;
                end;
             end;

             I := 1;
             while (I<NPacker) and (Packer[i]^.ext<>Packer[NPacker]^.ext) do
                inc(I);
             if (I<NPacker) then
             begin
                if Packer[NPacker]^.Pack<>'' then
                   Packer[I]^.Pack := Packer[NPacker]^.Pack;
                if Packer[NPacker]^.Unpack<>'' then
                   Packer[I]^.Unpack := Packer[NPacker]^.Unpack;
                Dispose(Packer[NPacker]);
                dec(NPacker);
             end else
             If (Packer[NPacker]^.Pack='') or (Packer[NPacker]^.UnPack='')
                or (Packer[NPacker]^.Id='') or (Packer[NPacker]^.Ext='')
                or (Packer[NPacker]^.Offset + length(Packer[NPacker]^.Id) >= 128) then
             begin
                writeln(' * Invalid Packer (',Packer[Npacker]^.Ext,')');
                writeln(LogFile,Prelog(LogError),'Invalid Packer (',Packer[NPacker]^.Ext,')');
                Flush(LogFile);
                Dispose(Packer[NPacker]);
                Dec(NPacker);
             end;

          end else
          begin
             writeln(' * Too Many Packers');
             writeln(LogFile,Prelog(LogError),'Too Many Packers');
             Flush(LogFile);
             while (TempStr<>'END') and not eof(VariText) do
             begin
                readln(VariText,TempStr);
                inc(linea);
                I := pos(';',TempStr);
                if I>0 then
                   TempStr := Copy(TempStr,1,I-1);
                StripLeadingSpace(TempStr);
                while (TempStr<>'') and (TempStr[length(TempStr)]=' ') do
                   dec(TempStr[0]);
                TempStr := Upper(TempStr);
             end;
          end;
       end {ParsePacker};

       Procedure ParseSearch;
       Var I,J : Integer;
       Begin
          if NSearch<NMsgAree then
          begin
             inc(NSearch);
             New(MsgArea[NSearch]);
             MsgArea[NSearch]^.AreaId1 := '';
             MsgArea[NSearch]^.AreaId2 := '';
             MsgArea[NSearch]^.Aree := Nil;
             MsgArea[NSearch]^.NoIbm := False;
             MsgArea[NSearch]^.MsgOrigin := '';
             MsgArea[NSearch]^.Suffix := Nil;
             MsgArea[NSearch]^.Prefix := Nil;
             MsgArea[NSearch]^.SearchDb := False;
             MsgArea[NSearch]^.MaxBytesUUEncode := MaxBytesUUEncode1;
             while not eof(variText) and (TempStr<>'END') do
             begin
                readln(variText,TempStr);
                inc(Linea);
                I := Pos(';',TempStr);
                if I>0 then
                   TempStr[0] := chr(I-1);
                while (TempStr<>'') and (TempStr[length(TempStr)]=' ') do
                   dec(TempStr[0]);
                StripLeadingSpace(TempStr);
                I := 1;
                while (I<=length(TempStr)) and (TempStr[I]<>' ') do
                begin
                   TempStr[I] := UpCase(TempStr[I]);
                   inc(I)
                end;
                if TempStr<>'' then
                begin
                   if Pos('AREAID ',TempStr)=1 then
                   begin
                      delete(TempStr,1,7);
                      stripLeadingSpace(TempStr);
                      TempStr := Upper(TempStr);
                      MsgArea[NSearch]^.AreaId1 := TempStr;
                   end else
                   if Pos('AREATAG ',TempStr)=1 then
                   begin
                      delete(TempStr,1,8);
                      stripLeadingSpace(TempStr);
                      TempStr := Upper(TempStr);
                      MsgArea[NSearch]^.AreaId1 := 'T' + TempStr;
                   end else
                   if Pos('AREATAGANS ',TempStr)=1 then
                   begin
                      delete(TempStr,1,11);
                      stripLeadingSpace(TempStr);
                      TempStr := Upper(TempStr);
                      MsgArea[NSearch]^.AreaId2 := 'T' + TempStr;
                   end else
                   if Pos('AREAIDANS ',TempStr)=1 then
                   begin
                      delete(TempStr,1,10);
                      stripLeadingSpace(TempStr);
                      TempStr := Upper(TempStr);
                      MsgArea[NSearch]^.AreaId2 := TempStr;
                   end else
                   if Pos('ORIGIN ',TempStr)=1 then
                   begin
                      delete(TempStr,1,7);
                      stripLeadingSpace(TempStr);
                      MsgArea[NSearch]^.MsgOrigin:=TempStr;
                   end else
                   if Pos('PREFIX ',TempStr)=1 then
                   begin
                      delete(TempStr,1,7);
                      stripleadingSpace(TempStr);
                      L := ExpandD0(TempStr);
                      PosDesc := 1;
                      PutDescrizione(MsgArea[NSearch]^.Prefix)
                   end else
                   if Pos('SUFFIX ',TempStr)=1 then
                   begin
                      delete(TempStr,1,7);
                      stripleadingSpace(TempStr);
                      L := ExpandD0(TempStr);
                      PosDesc := 1;
                      PutDescrizione(MsgArea[NSearch]^.Suffix)
                   end else
                   if Pos('MAXBYTESUUENCODE ',TempStr)=1 then
                   begin
                      delete(TempStr,1,17);
                      stripleadingspace(TempStr);
                      if (TempStr<>'') and (pos(' ',TempStr)=0) then
                      begin
                         val(TempStr,TempWord,Code);
                         if (Code=0) and (TempWord>=0) and (TempWord<=MaxInt) then
                            MsgArea[NSearch]^.MaxBytesUUEncode := TempWord;
                      end;
                   end else
                   if pos('AREA ',TempStr)=1 then
                   begin
                      delete(TempStr,1,5);
                      StripLeadingSpace(TempStr);
                      if ParseArea(MsgArea[NSearch]^.Aree,TempStr) then;
                   end else
                   if Pos('NOIBM',TempStr)=1 then
                   begin
                       MsgArea[NSearch]^.NoIbm := True;
                   end else
                   if Pos('SEARCHDB',TempStr)=1 then
                   begin
                       MsgArea[NSearch]^.SearchDb := True;
                   end else
                   if TempStr='END' then
                   begin
                      {fine dell'area}

                   end else
                   begin
                      writeln(' * Error in line ',Linea);
                      Writeln(LOgFile,Prelog(LogError),'Error in line ',Linea);
                      Flush(LogFile);
                   end;
                end;
             end;
             If (MsgArea[NSearch]^.AreaId1='') then
             begin
                writeln(' * Invalid Search');
                writeln(LogFile,Prelog(LogError),'Invalid Search');
                Flush(LogFile);
                RemoveListaNum(MsgArea[NSearch]^.Aree);
                CancellaDescrizione(MsgArea[NSearch]^.Prefix);
                CancellaDescrizione(MsgArea[NSearch]^.Suffix);
                Dispose(MsgArea[NSearch]);
                Dec(NSearch);
             end;
          end else
          begin
             writeln(' * Too Many Search');
             writeln(LogFile,Prelog(LogError),'Too Many Search');
             Flush(LOgFile);
             while (TempStr<>'END') and not eof(VariText) do
             begin
                readln(VariText,TempStr);
                inc(linea);
                I := pos(';',TempStr);
                if I>0 then
                   TempStr := Copy(TempStr,1,I-1);
                StripLeadingSpace(TempStr);
                while (TempStr<>'') and (TempStr[length(TempStr)]=' ') do
                   dec(TempStr[0]);
                for I:=1 to length(TempStr) do
                   TempStr[I] := UpCase(TempStr[I]);
             end;
          end;
       end {ParseSearch};

begin

   Lock(D0 + 'Start');

   Assign(CfgBin, D0 + 'Colors.Cfg');
   {$I-}
   Reset(CfgBin, 1);
   {$I+}
   if IOResult=0 then
   begin
      Seek(CfgBin, 256);
      BlockRead(CfgBin, NormVideoCol, 1);
      BlockRead(CfgBin, LowVideoCol, 1);
      BlockRead(CfgBin, HighVideoCol, 1);
      BlockRead(CfgBin, InvVideoCol, 1);
      close(CfgBin);
   end;

   IncludeList := Nil;
   Include := D0 + 'Llist.Cfg';
   FileParsed := 1;
   ParsedTicAreas := False;

   while Include<>'' do
   begin
      if shOpenTextFile(VariText, Include) then
      begin
         SetTextBuf(VariText,VariBuf^,SizeTxtBuf);
         Linea := 0;
         writeln(' * Parsing ',Include);
         writeln(LogFile,Prelog(LogStart),'Parsing ',Include);
         Flush(LogFile);
         while not eof(variText) do
         begin
            readln(variText,TempStr);
            inc(Linea);
            I := Pos(';',TempStr);
            if I>0 then
               TempStr[0] := chr(I-1);
            while (TempStr<>'') and (TempStr[length(TempStr)]=' ') do
               dec(TempStr[0]);
            StripLeadingSpace(TempStr);
            if TempStr<>'' then
            begin
               I := 1;
               While (I<=Length(TempStr)) and (TempStr[I]<>' ') do
               begin
                  TempStr[I] := UpCase(TempStr[I]);
                  inc(I)
               end;
               if (TempStr='ANNOUNCEMSG') or (pos('ANNOUNCEMSG ',TempStr)=1) then
               begin
                  {il "pos" e' per il vecchio formato, con il tag}
                  ParseAnnounceMsg;
               end else
               if TempStr='SEARCH' then
               begin
                  ParseSearch;
               end else
               if TempStr='FILELIST' then
               begin
                  ParseFileList;
               end else
               if (Pos('PACKER ',TempStr)=1) then
               begin
                  ParsePacker;
               end else
               if Pos('MAXLEV ',TempStr)=1 then
               begin
                  delete(TempStr,1,7);
                  stripleadingspace(TempStr);
                  if (TempStr<>'') and (pos(' ',TempStr)=0) then
                  begin
                     val(TempStr,TempWord,Code);
                     if (Code=0) and (TempWord>=0) and (TempWord<=ML) then
                     begin
                        MaxLev := TempWord;
                        Ml := MaxLev
                     end
                  end;
               end else
               if Pos('BBSDIR ',TempStr)=1 then
               begin
                  delete(TempStr,1,7);
                  StripLeadingSpace(TEmpStr);
                  if (TempStr<>'') and (pos(' ',TempStr)=0) then
                  begin
                     LoraDir := ExpandD0(TempStr);
                     if LoraDir[length(LoraDir)]<>'\' then
                        LoraDir := LoraDir + '\'
                  end;
               end else
               if Pos('INBOUND ',TempStr)=1 then
               begin
                  delete(TempStr,1,8);
                  StripLeadingSpace(TEmpStr);
                  if (TempStr<>'') and (pos(' ',TempStr)=0) then
                  begin
                     L := WithBackSlash(Upper(ExpandD0(TempStr)));
                     PosDesc := 1;
                     PutDescrizione(Inbound);
                  end;
               end else
               if Pos('OUTBOUND ',TempStr)=1 then
               begin
                  delete(TempStr,1,9);
                  StripLeadingSpace(TEmpStr);
                  if (TempStr<>'') and (pos(' ',TempStr)=0) then
                  begin
                     TempStr := ExpandD0(TempStr);
                     if TempStr[length(TempStr)]<>'\' then
                        TempStr := TempStr + '\';
                     if OutBound[0]=Nil then
                     begin
                        New(OutBound[0]);
                        GetMem(OutBound[0]^.OutBound,length(TempStr)+1);
                        OutBound[0]^.OutBound^ := TempStr
                     end;
                  end;
               end else
               if Pos('ZONE ',TempStr)=1 then
               begin
                  delete(TempStr,1,5);
                  StripLeadingSpace(TEmpStr);
                  {Controlla il numero di zona}
                  I := pos(' ',TempStr);
                  if (I>0) then
                  begin
                     Val(Copy(TempStr,1,I-1),TempWord,Code);
                     if (Code=0) then
                     begin
                        delete(TempStr,1,I);
                        StripLeadingSpace(TempStr);
                        if (TempStr<>'') and (pos(' ',TempStr)=0) then
                        begin
                           TempStr := ExpandD0(TempStr);
                           if TempStr[length(TempStr)]<>'\' then
                              TempStr := TempStr + '\';
                           if (NOutBound<NMaxOutBound) then
                           begin
                              Inc(NoutBound);
                              New(OutBound[NOutBound]);
                              GetMem(OutBound[NOutBound]^.OutBound,length(TempStr)+1);
                              OutBound[NOutBound]^.OutBound^ := TempStr;
                              OutBound[NOutBound]^.Zone := TempWord;
                           end;
                        end;
                     end;
                  end;
               end else
               if Pos('DIRNEWAREAS ',TempStr)=1 then
               begin
                  delete(TempStr,1,12);
                  StripLeadingSpace(TEmpStr);
                  if (TempStr<>'') and (pos(' ',TempStr)=0) then
                  begin
                     DirNewAreas := ExpandD0(TempStr);
                     if DirNewAreas[length(DirNewAreas)]<>'\' then
                        DirNewAreas := DirNewAreas + '\'
                  end;
               end else
               if Pos('BADFILES ',TempStr)=1 then
               begin
                  delete(TempStr,1,9);
                  StripLeadingSpace(TEmpStr);
                  if (TempStr<>'') and (pos(' ',TempStr)=0) then
                  begin
                     DirBadFiles := Upper(ExpandD0(TempStr));
                     if DirBadFiles[length(DirBadFiles)]<>'\' then
                        DirBadFiles := DirBadFiles + '\'
                  end;
               end else
               if Pos('INFECTEDFILES ',TempStr)=1 then
               begin
                  delete(TempStr,1,14);
                  StripLeadingSpace(TEmpStr);
                  if (TempStr<>'') and (pos(' ',TempStr)=0) then
                  begin
                     DirInfectedFiles := Upper(ExpandD0(TempStr));
                     if DirInfectedFiles[length(DirInfectedFiles)]<>'\' then
                        DirInfectedFiles := DirInfectedFiles + '\'
                  end;
               end else
               if Pos('ECHORSN ',TempStr)=1 then
               begin
                  delete(TempStr,1,8);
                  StripLeadingSpace(TempStr);
                  if (TempStr<>'') and (pos(' ',TempStr)=0) then
                     PathEchoFlag := ExpandD0(TempStr);
               end else
               if Pos('NETAREAID ',TempStr)=1 then
               begin
                  delete(TempStr,1,10);
                  StripLeadingSpace(TempStr);
                  if (TempStr<>'') and (pos(' ',TempStr)=0) then
                  begin
                     I := pos(',',TempStr);
                     if I>0 then
                        TempStr := Chr(i-1);
                     if TempStr<>'' then
                        NetAreaId := TempStr + ',2';
                  end;
               end else
               if Pos('HUDSON ',TempStr)=1 then
               begin
                  delete(TempStr,1,7);
                  StripLeadingSpace(TempStr);
                  if (TempStr<>'') and (pos(' ',TempStr)=0) then
                     PathHudson := ExpandD0(TempStr);
               end else
               if Pos('AREASBBS ',TempStr)=1 then
               begin
                  delete(TempStr,1,9);
                  StripLeadingSpace(TempStr);
                  if (TempStr<>'') and (pos(' ',TempStr)=0) then
                     PathAreasBbs := ExpandD0(TempStr);
               end else
               if Pos('NETRSN ',TempStr)=1 then
               begin
                  delete(TempStr,1,7);
                  StripLeadingSpace(TempStr);
                  if (TempStr<>'') and (pos(' ',TempStr)=0) then
                     PathNetFlag := ExpandD0(TempStr);
               end else
               if Pos('FILEIDX ',TempStr)=1 then
               begin
                  delete(TempStr,1,8);
                  StripLeadingSpace(TempStr);
                  if (TempStr<>'') and (pos(' ',TempStr)=0) then
                     PathIdx := ExpandD0(TempStr);
               end else
               if Pos('ADDRESS ',TempStr)=1 then
               begin
                  delete(TempStr,1,8);
                  StripLeadingSpace(TempStr);
                  if ParseAddr(TempStr,TempAddr,TempAddr) then
                  begin
                     Aka[0] := TempAddr;
                  end else
                  begin
                     Writeln(' * Invalid Address: ',TempStr);
                     Writeln(LogFile,Prelog(LogError),'Invalid Address: ',TempStr);
                     flush(LOgFile);
                  end;
               end else
               if Pos('AKA ',TempStr)=1 then
               begin
                  delete(TempStr,1,4);
                  StripLeadingSpace(TempStr);
                  if (TempStr<>'') and (pos(' ',TempStr)=0) and (NAka<NMaxAka) then
                  begin
                     if ParseAddr(TempStr,TempAddr,TempAddr) then
                     begin
                        if AddAka(TempAddr)=0 then;
                     end else
                     begin
                        Writeln(' * Invalid Address: ',TempStr);
                        Writeln(LogFile,Prelog(LogError),'Invalid Address: ',TempStr);
                        Flush(LogFile);
                     end;
                  end;
               end else
               if Pos('OKFILEPWD ',TempStr)=1 then
               begin
                  delete(TempStr,1,10);
                  StripLeadingSpace(TempStr);
                  if (TempStr<>'') then
                  begin
                     I := pos(' ',TempStr);
                     if I=0 then
                        OkFilePwd := TempStr
                     else
                     begin
                        OkFilePwd := copy(TempStr,1,I-1);
                        delete(TempStr,1,I);
                        stripleadingspace(TempStr);
                        val(TempStr,LevPwd,Code);
                        if code<>0 then
                        begin
                           OkFilePwd := '';
                           LevPwd := - MaxInt;
                        end;
                     end;
                  end;
               end else
               if pos('OKLINE ',TempStr)=1 then
               begin
                  delete(TempStr,1,7);
                  stripleadingspace(TempStr);
                  if TempStr<>'' then
                  begin
                     L := TempStr;
                     PosDesc := 1;
                     PutDescrizione(OkLines)
                  end;
               end else
               if pos('DESCFILE ',TempStr)=1 then
               begin
                  delete(TempStr,1,9);
                  stripleadingspace(TempStr);
                  if TempStr<>'' then
                  begin
                     TempStr := Upper(TempStr) + ' ';
                     I := pos(' ', TempStr);
                     while (I>0) do
                     begin
                        if pos(Copy(TempStr,1,I-1), DescFiles)=0 then
                           DescFiles := DescFiles + ' ' + copy(TempStr,1,i-1);
                        delete(tempStr,1,I);
                        stripleadingspace(TempStr);
                        I := pos(' ',TempStr);
                     end;
                  end;
               end else
               if pos('AREAHEADERLINE ',TempStr)=1 then
               begin
                  delete(TempStr,1,15);
                  stripleadingspace(TempStr);
                  if TempStr<>'' then
                  begin
                     L := TempStr;
                     PosDesc := 1;
                     PutDescrizione(AreaHeaderLines)
                  end;
               end else
               if pos('MSGAREAHEADERLINE ',TempStr)=1 then
               begin
                  delete(TempStr,1,18);
                  stripleadingspace(TempStr);
                  if TempStr<>'' then
                  begin
                     L := TempStr;
                     PosDesc := 1;
                     PutDescrizione(MsgAreaHeaderLines)
                  end;
               end else
               if Pos('LDCHAR ',TempStr)=1 then
               begin
                  delete(TempStr,1,6);
                  StripLeadingSpace(TempStr);
                  for I := 1 to length(TempStr) do
                     if pos(TempStr[I],LdChar)=0 then
                         LdChar := LdChar + TempStr[I];
               end else
               if Pos('SCANVIRUS ',TempStr)=1 then
               begin
                  delete(TempStr,1,10);
                  StripLeadingSpace(TempStr);
                  VirusCheck := TempStr;
               end else
               if Pos('REPACK ',TempStr)=1 then
               begin
                  delete(TempStr,1,7);
                  StripLeadingSpace(TempStr);
                  for I := 1 to length(TempStr) do
                     TempStr[I] := UpCase(TempStr[I]);
                  if TempStr='NONE' then
                     RePack := ''
                  else
                     RePack := TempStr;
               end else
               if Pos('HEADER ',TempStr)=1 then
               begin
                  delete(TempStr,1,7);
                  StripLeadingSpace(TempStr);
                  L := ExpandD0(TempStr);
                  PosDesc := 1;
                  PutDescrizione(PathHdr)
               end else
               if Pos('FOOTER ',TempStr)=1 then
               begin
                  delete(TempStr,1,7);
                  StripLeadingSpace(TempStr);
                  L := ExpandD0(TempStr);
                  PosDesc := 1;
                  PutDescrizione(PathFtr)
               end else
               if Pos('OFFLINESTR ',TempStr)=1 then
               begin
                  delete(TempStr,1,11);
                  StripLeadingSpace(TempStr);
                  if (TempStr<>'') then
                     OffLineStr := TempStr;
               end else
               if Pos('ORPHANSTR ',TempStr)=1 then
               begin
                  delete(TempStr,1,10);
                  StripLeadingSpace(TempStr);
                  if (TempStr<>'') then
                     DefaultOrfanoStr := TempStr;
               end else
               if Pos('DESCRIBE ',TempStr)=1 then
               begin
                  if (NDescribe<NMaxDescribe) then
                  begin
                     delete(TempStr,1,9);
                     StripLeadingSpace(TempStr);
                     I := pos(' ', TempStr);
                     if I>0 then
                     begin
                        Inc(NDescribe);
                        New(Describe[NDescribe]);
                        Describe[NDescribe]^.Name := Copy(TempStr,1,I-1);
                        ExpandWildCards(Describe[NDescribe]^.Name);
                        Delete(TempStr,1,I);
                        StripLeadingSpace(TempStr);
                        Describe[NDescribe]^.Desc := TempStr;
                     end;
                  end;
               end else
               if Pos('FIRSTLINE ',TempStr)=1 then
               begin
                  delete(TempStr,1,10);
                  StripLeadingSpace(TempStr);
                  if (TempStr<>'') then
                     Int := TempStr;
               end else
               if Pos('DATEPATTERN ',TempStr)=1 then
               begin
                  delete(TempStr,1,12);
                  StripLeadingSpace(TempStr);
                  if (TempStr<>'') then
                  begin
                     if length(tempStr)>18 then
                        TempStr := Copy(TempStr,1,18);
                     TempStr := TempStr + #0;
                     Move(TempStr[1],datapattern,length(TempStr));
                  end;
               end else
               if Pos('DCLIMITS ',TempStr)=1 then
               begin
                  delete(TempStr,1,9);
                  StripLeadingSpace(TempStr);
                  if (length(TempStr)=2) then
                  begin
                     if pos(TempStr[1],DlLImit1)=0 then
                        DlLimit1 := DlLimit1 + TempStr[1];
                     if pos(TempStr[2],DlLimit2)=0 then
                        DlLimit2 := DlLimit2 + TempStr[2];
                  end;
               end else
               if Pos('BBSNAME ',TempStr)=1 then
               begin
                  delete(TempStr,1,8);
                  StripLeadingSpace(TempStr);
                  if (TempStr<>'') then
                     BBSName := TempStr;
               end else
               if Pos('UPLOADERSTR ',TempStr)=1 then
               begin
                  delete(TempStr,1,12);
                  StripLeadingSpace(TempStr);
                  if (TempStr<>'') then
                     UpLoaderStr := TempStr;
               end else
               if Pos('SYSOPNAME ',TempStr)=1 then
               begin
                  delete(TempStr,1,10);
                  StripLeadingSpace(TempStr);
                  if (TempStr<>'') then
                     SysopName := TempStr;
               end else
               if Pos('LLISTALIAS ',TempStr)=1 then
               begin
                  delete(TempStr,1,11);
                  StripLeadingSpace(TempStr);
                  if (TempStr<>'') and (nllistalias<nmaxllistalias) then
                  begin
                     inc(nllistalias);
                     llistalias[nllistalias] := upper(tempstr);
                  end;
               end else
               if Pos('CONFIG ',TempStr)=1 then
               begin
                  delete(TempStr,1,7);
                  StripLeadingSpace(TempStr);
                  if (TempStr<>'') and (pos(' ',TempStr)=0) then
                     ConfigFile := TempStr;
               end else
               if Pos('INCLUDE ',TempStr)=1 then
               begin
                  delete(TempStr,1,8);
                  StripLeadingSpace(TempStr);
                  if (TempStr<>'') and (pos(' ',TempStr)=0) then
                  begin
                     if FileParsed<NMaxFileParsed then
                     begin
                        L := ExpandD0(TempStr);
                        PosDesc := 1;
                        PutDescrizione(IncludeList);
                        Inc(FileParsed);
                     end else
                     begin
                        Writeln(' * Too many INCLUDE');
                        Writeln(LogFile,Prelog(LogError),'Too many INCLUDE');
                        Flush(LogFile);
                     End;
                  end;
               end else
               if pos('KEY ',TempStr)=1 then
               begin
                  delete(TempStr,1,4);
                  StripLeadingSpace(TempStr);
                  KeyStr := TempStr;
               end else
               if Pos('FIXFBBSSORT ',TempStr)=1 then
               begin
                  delete(TempStr,1,12);
                  stripleadingspace(TempStr);
                  for I:=1 to Length(TempStr) do
                     TempStr[I] := UpCase(TempStr[I]);
                  If TempStr='SORT' then
                     FixFBbsSort := Alfa
                  else If TempStr='SORTDATE' then
                     FixFBbsSort := Date
               end else
               if TempStr='FIXFBBSHEADER' then
               begin
                  FixFBbsHeader := True
               end else
               if TempStr='AREAHEADERREQINFO' then
               begin
                  AreaHeaderReqInfo := True
               end else
               if TempStr='INDENTDC' then
               begin
                  IndentDC := True
               end else
               if TempStr='TICSTOPDUP' then
               begin
                  TicStopDup := True
               end else
               if Pos('OFFLINE ',TempStr)=1 then
               begin
                  delete(TempStr,1,8);
                  StripLeadingSpace(TempStr);
                  If TempStr<>'' then
                  begin
                     TempStr[1] := UpCase(TempStr[1]);
                     if (TempStr[1]='Y') or (TempStr[1]='S') then
                        OffLine := True
                     else
                     if TempStr[1]='N' then
                        OffLine := False
                  end
               end else
               if Pos('NEWDAYS ',TempStr)=1 then
               begin
                  delete(TempStr,1,8);
                  stripleadingspace(TempStr);
                  if (TempStr<>'') and (pos(' ',TempStr)=0) then
                  begin
                     val(TempStr,TempWord,Code);
                     if (Code=0) and (TempWord>=0) and (TempWord<=180) then
                        NewDays := TempWord;
                  end;
               end else
               if Pos('MAXBYTESUUENCODE ',TempStr)=1 then
               begin
                  delete(TempStr,1,17);
                  stripleadingspace(TempStr);
                  if (TempStr<>'') and (pos(' ',TempStr)=0) then
                  begin
                     val(TempStr,TempWord,Code);
                     if (Code=0) and (TempWord>=0) and (TempWord<=MaxInt) then
                        MaxBytesUUEncode1 := TempWord;
                  end;
               end else
               if Pos('MAXFILE_IDLINES ',TempStr)=1 then
               begin
                  delete(TempStr,1,16);
                  stripleadingspace(TempStr);
                  if (TempStr<>'') and (pos(' ',TempStr)=0) then
                  begin
                     val(TempStr,TempWord,Code);
                     if (Code=0) and (TempWord>0) and (TempWord<=50) then
                        MaxFile_IdLines := TempWord;
                  end;
               end else
               if Pos('MAXLENDESC ',TempStr)=1 then
               begin
                  delete(TempStr,1,11);
                  stripleadingspace(TempStr);
                  if (TempStr<>'') and (pos(' ',TempStr)=0) then
                  begin
                     val(TempStr,TempWord,Code);
                     if (Code=0) and (TempWord>0) and (TempWord<=255) then
                        MaxLenDesc := TempWord;
                  end;
               end else
               if Pos('SEARCHMAXFILES ',TempStr)=1 then
               begin
                  delete(TempStr,1,15);
                  stripleadingspace(TempStr);
                  if (TempStr<>'') and (pos(' ',TempStr)=0) then
                  begin
                     val(TempStr,TempWord,Code);
                     if (Code=0) and (TempWord>=0) and (TempWord<=MaxInt) then
                        SearchMaxFiles1 := TempWord;
                  end;
               end else
               if Pos('SEARCHMINLEN ',TempStr)=1 then
               begin
                  delete(TempStr,1,13);
                  stripleadingspace(TEmpStr);
                  if (TempStr<>'') and (pos(' ',TempStr)=0) then
                  begin
                     val(TempStr,TempWord,Code);
                     if (Code=0) and (TempWord>=0) and (TempWord<=MaxInt) then
                        MinLenSearchStr := TempWord;
                  end;
               end else
               if Pos('DCLEN ',TempStr)=1 then
               begin
                  delete(TempStr,1,6);
                  stripleadingspace(TEmpStr);
                  if (TempStr<>'') and (pos(' ',TempStr)=0) then
                  begin
                     val(TempStr,TempWord,Code);
                     if (Code=0) and (TempWord>=0) and (TempWord<=5) then
                        DcLen := TempWord;
                  end;
               end else
               if Pos('EXTDESCPOS ',TempStr)=1 then
               begin
                  delete(TempStr,1,11);
                  stripleadingspace(TEmpStr);
                  if (TempStr<>'') and (pos(' ',TempStr)=0) then
                  begin
                     val(TempStr,TempWord,Code);
                     if (Code=0) and (TempWord>0) and (TempWord<=255) then
                        ExtDescPos := TempWord-1;
                  end;
               end else
               if Pos('FBBSLEN ',TempStr)=1 then
               begin
                  delete(TempStr,1,8);
                  stripleadingspace(TEmpStr);
                  if (TempStr<>'') and (pos(' ',TempStr)=0) then
                  begin
                     val(TempStr,TempWord,Code);
                     if (Code=0) and (TempWord>=79) and (TempWord<=255) then
                        FBbsLen := TempWord;
                  end;
               end else
               if Pos('EXCLUDE ',TempStr)=1 then
               begin
                  delete(TempStr,1,8);
                  StripLeadingSpace(TempStr);
                  if (TempStr<>'') and (pos(' ',TempStr)=0) and (Nexclude<NMaxExclude) then
                  begin
                     for I := 1 to length(TempStr) do
                        TempStr[I] := UpCase(TempStr[I]);
                     ExpandWildCards(TempStr);
                     inc(Nexclude);
                     PathExclude[NExclude] := TempStr;
                  end;
               end else
               if Pos('ANNOUNCEEXCLUDE ',TempStr)=1 then
               begin
                  delete(TempStr,1,16);
                  StripLeadingSpace(TempStr);
                  if (TempStr<>'') and (pos(' ',TempStr)=0) and (NexcludeAnnounce<NMaxExclude) then
                  begin
                     for I := 1 to length(TempStr) do
                        TempStr[I] := UpCase(TempStr[I]);
                     ExpandWildCards(TempStr);
                     inc(NexcludeAnnounce);
                     PathExcludeAnnounce[NExcludeAnnounce] := TempStr;
                  end;
               end else
               if TempStr='NODLPATH' then
               begin
                  NoDlPath := True;
               end else
               if TempStr='NOFIRSTLINE' then
               begin
                  NoFirstLine := True;
               end else
               if pos('LOCALRAIDPWD ',TempStr)=1 then
               begin
                  delete(TempStr,1,13);
                  stripleadingspace(TempStr);
                  LocalRaidPwd := Upper(TempStr);
               end else
               if pos('HIDELEVEL ',TempStr)=1 then
               begin
                  delete(TempStr,1,10);
                  stripleadingspace(TempStr);
                  if TempStr<>'' then
                  begin
                     L := Upper(TempStr);
                     PosDesc := 1;
                     PutDescrizione(HideLevels);
                  end;
               end else
               if Pos('ALTF',TempStr)=1 then
               begin
                  Delete(TempStr,1,4);
                  I := pos(' ',TempStr);
                  if I>0 then
                  begin
                     Val(Copy(TempStr,1,I-1),J,Code);
                     if (Code=0) and (J>=1) and (J<=10) then
                     begin
                        Delete(TempStr,1,I);
                        StripLeadingSpace(TempStr);
                        ExternalShell[J] := TempStr;
                     end;
                  end;
               end else
               if Pos('CTRLF',TempStr)=1 then
               begin
                  Delete(TempStr,1,5);
                  I := pos(' ',TempStr);
                  if I>0 then
                  begin
                     Val(Copy(TempStr,1,I-1),J,Code);
                     if (Code=0) and (J>=1) and (J<=10) then
                     begin
                        Delete(TempStr,1,I);
                        StripLeadingSpace(TempStr);
                        Macro[J] := TempStr;
                     end;
                  end;
               end else
               if Pos('LLISTDB ',TempStr)=1 then
               begin
                  delete(TempStr,1,8);
                  StripLeadingSpace(TempStr);
                  L := ExpandD0(TempStr);
                  PosDesc := 1;
                  PutDescrizione(llistdb)
               end else
               if TempStr='FIXCRCTIC' then
               begin
                  FixCrcTic := True
               end else
               if TempStr='NOANNOUNCEAFTERTIC' then
               begin
                  NoAnnounceAfterTic := True
               end else
               if TempStr='NOPACKFILE_ID' then
               begin
                  NoPackFile_Id := True
               end else
               if TempStr='FIXSIZETIC' then
               begin
                  FixSizeTic := True
               end else
               if TempStr='TICREPLACE' then
               begin
                  TicReplace := True
               end else
               if TempStr='NOTICUPDATE' then
               begin
                  TicUpdate := False
               end else
               if TempStr='SHORTSIZE' then
               begin
                  ShortSize := True
               end else
               if TempStr='0DC' then
               begin
                  ZeroDc := True
               end else
               if TempStr='WRITEPCBFBBS' then
               begin
                  SavePcb := True
               end else
               if TempStr='TICUSEDESC' then
               begin
                  TicUseDesc := True;
                  TicUseLdesc := False;
               end else
               if TempStr='TICUSELDESC' then
               begin
                  TicUseLDesc := True;
                  TicUseDesc := False;
               end else
               if TempStr='LONGSUMMARY' then
               begin
                  LongSummary := True
               end else
               if TempStr='MAILATTACH' then
               begin
                  MailAttach := True
               end else
               if TempStr='REPACKOPTIMIZE' then
               begin
                  RepackPerc := 0
               end else
               if TempStr='NOANNOUNCEREADFILE_ID' then
               begin
                  NoAnnounceReadFile_Id := True
               end else
               if Pos('REPACKOPTIMIZE ',TempStr)=1 then
               begin
                  Delete(TempStr,1,15);
                  StripLeadingSpace(TempSTR);
                  Val(TempStr,RepackPerc,Code);
                  if (Code<>0) or (RepackPerc<0) or (RepackPerc>100) then
                     RepackPerc := -1
               end else
               if TempStr='FONT8X8' then
               begin
                  {$IFDEF NO4350}
                  {$ELSE}
                  ModeFont8x8 := True;
                  {$ENDIF}
               end else
               begin
                  I := pos(' ',TempStr);
                  if I>0 then
                     val(Copy(tempStr,1,i-1),tempword,code)
                  else
                     code := 1;
                  if (code=0) and (TempWord>0) and (TempWord<=MAXMESSAGE) then
                  begin
                     delete(TempStr,1,I);
                     stripleadingspace(Tempstr);
                     getmem(Message[tempword],length(TempStr)+1);
                     message[TempWord]^:=TempStr;
                  end else
                  begin
                     Writeln(' * Error in line ',Linea);
                     Writeln(LOgFile,Prelog(LogError),'Error in line ',Linea);
                     Flush(LogFile);
                  end;
               end;
            end;
         end;
         close(VariText);
      end else
      begin
         Writeln(' * ',Include,' not found');
         Writeln(LogFile,Prelog(LogError),Include,' not found');
         Flush(LogFile);
      end;
      if IncludeList<>Nil then
      begin
         TempFileNameRef := IncludeList;
         Include := IncludeList^.Descrizione^;
         IncludeList := IncludeList^.Next;
         FreeMem(TempFileNameRef^.Descrizione,Length(TempFileNameRef^.Descrizione^)+1);
         Dispose(TempFileNameREf);
      end else
      begin
         Include := ''
      end;
   end;

   (*

      Il formato T<AreaTag> per la AreaId e' ora supportato dalla MkOpen
      modificata da me, quindi non c'e' bisogno di questo passaggio

   if UseTags then
   begin
      assign(VariText,PathAreasBbs);
      SetTextBuf(VariText,VariBuf^,SizeTxtBuf);
      {$I-}
      Reset(VariText);
      {$I+}
      if IOREsult=0 then
      begin
         writeln(' * Parsing ',PathAreasBbs);
         writeln(LogFile,Prelog(LogStart),'Parsing ',PathAreasBbs);
         Flush(LogFile);
         while not eof(VariText) do
         begin
            readln(VariText,TempStr);
            I := pos(';',TempStr);
            if I>0 then
               TempStr[0] := chr(I-1);
            StripLeadingSpace(TempStr);
            I := pos(' ',TempStr);
            if I>0 then
            begin
               TempStr1 := Upper(Copy(TempStr,1,I-1));
               delete(TempStr,1,I);
               StripLeadingSpace(TempStr);
               Val(TempStr1,I,Code);
               if (Code=0) then
               begin
                  if (I>0) and (I<=200) then
                  begin
                     while length(TempStr1)<3 do
                        TempStr1 := '0' + TempStr1;
                     TempStr1 := 'H' + TempStr1 + PathHudson
                  end else
                     TempStr1 := '';
               end else
               if TempStr1[1]='$' then
               begin
                  {Area Squish}
                  TempStr1[1] := 'S'
               end else
               if (TempStr1[1]='J') and (TempStr1[2]<>':') then
               begin
                  {Area Jam}
                  {va gia' bene, Non deve essere modificato}
               end else
               if (TempStr1[1]='G') and (TempStr1[2]<>':') then
               begin
                  {Area Gold, non supportata}
                  TempStr1 := '';
               end else
               begin
                  {Fido Area}
                  TempStr1 := 'F' + TempStr1;
                  if TempStr1[length(tempStr1)]<>'\' then
                     TempStr1 := TempStr1 + '\';
               end;
               I := pos(' ',TempStr);
               if I>0 then
                  TempStr[0] := chr(I-1);
               for I := 1 to length(TempStr) do
                  TempStr[I] := UpCase(TempStr[I]);
               if (TempStr<>'') and (TempStr1<>'') then
               begin
                  TempStr := 'T' + TempStr;
                  {Individuato TAG e AREAID, procede alla sostituzione}
                  for I := 1 to NAnnounce do
                  begin
                     if Annunci[I]^.AreaId=TempStr then
                     begin
                        Annunci[I]^.AreaId := TempStr1;
                        Annunci[I]^.Tipoarea := 1;
                     end;
                  end;
                  for I := 0 to NSearch do
                  begin
                     if MsgArea[I]^.AreaId1=TempStr then
                     begin
                        MsgArea[I]^.AreaId1 := TempStr1;
                        MsgArea[I]^.Tipo1 := 1;
                     end;
                     if MsgArea[I]^.AreaId2=TempStr then
                     begin
                        MsgArea[I]^.AreaId2 := TempStr1;
                        MsgArea[I]^.Tipo2 := 1;
                     end;
                  end;
               end
            end;
         end;
         close(VariText);
      end else
      begin
         Writeln(' * ',PathAreasBbs,' not found');
         Writeln(LogFile,Prelog(LogError),PathAreasBbs,' not found');
         Flush(LogFile);
      end;
      I := 1;
      while I <= NAnnounce do
      begin
         if Annunci[I]^.AreaId='T' then
         begin
            Delete(Annunci[I]^.AreaId,1,1);
            Writeln(' * Invalid Area Tag ',Annunci[I]^.AreaId);
            Writeln(LogFile,Prelog(LogError),'Invalid Area Tag ',Annunci[I]^.AreaId);
            Flush(LOgFile);
            RemoveListaNum(Annunci[I]^.Aree);
            Dispose(Annunci[I]);
            dec(NAnnounce);
            for J := I to NAnnounce do
               Annunci[J] := Annunci[J+1]
         end else
            inc(I)
      end;
      I := 0;
      while I <= NSearch do
      begin
         if MsgArea[I]^.AreaId1[1]='T' then
         begin
            Delete(MsgArea[I]^.AreaId1,1,1);
            Writeln(' * Invalid Area Tag ',MsgArea[I]^.AreaId1);
            Writeln(LogFile,Prelog(LogError),'Invalid Area Tag ',MsgArea[I]^.AreaId1);
            Flush(LogFile);
            RemoveListaNum(MsgArea[I]^.Aree);
            Dispose(MsgArea[I]);
            dec(NSearch);
            for J := I to NSearch do
               MsgArea[J] := MsgArea[J+1]
         end else
            inc(I)
      end;
      I := 0;
      while I <= NSearch do
      begin
         if (MsgArea[I]^.AreaId2<>'') and (MsgArea[I]^.AreaId2[1]='T') then
         begin
            Delete(MsgArea[I]^.AreaId2,1,1);
            Writeln(' * Invalid Area Tag ',MsgArea[I]^.AreaId2);
            Writeln(LogFile,Prelog(LogError),'Invalid Area Tag ',MsgArea[I]^.AreaId2);
            Flush(LogFile);
            RemoveListaNum(MsgArea[I]^.Aree);
            Dispose(MsgArea[I]);
            dec(NSearch);
            for J := I to NSearch do
               MsgArea[J] := MsgArea[J+1]
         end else
            inc(I)
      end;
   end;
   *)

   Include := D0 + 'Magic.Cfg';
   if shOpenTextFile(variText,Include) then
   begin
      SetTextBuf(VariText,VariBuf^,SizeTxtBuf);
      Linea := 0;
      writeln(' * Parsing ',Include);
      writeln(LogFile,Prelog(LogStart),'Parsing ',Include);
      Flush(LOgFile);
      while not eof(variText) do
      begin
         readln(variText,TempStr);
         inc(Linea);
         I := Pos(';',TempStr);
         if I>0 then
            TempStr[0] := chr(I-1);
         while (TempStr<>'') and (TempStr[length(TempStr)]=' ') do
            dec(TempStr[0]);
         StripLeadingSpace(TempStr);
         if TempStr<>'' then
         begin
            I := 1;
            While (I<=Length(TempStr)) and (TempStr[I]<>' ') do
            begin
               TempStr[I] := UpCase(TempStr[I]);
               inc(I)
            end;
            {Nome del Magic maiuscolo}
            I := 1;
            while (I<=length(TempStr)) and (TempStr[I]<>' ') do
            begin
               TempStr[I] := UpCase(TempStr[I]);
               inc(I);
            end;
            if Pos('FILES ',TempStr)=1 then
            begin
               New(Magic[1]);
               Magic[1]^ := TempStr
            end else
            if Pos('ABOUT ',TempStr)=1 then
            begin
               New(Magic[2]);
               Magic[2]^ := TempStr
            end else
            if (Nmagic<NMaxMagic) then
            begin
               inc(NMagic);
               New(Magic[NMagic]);
               Magic[NMagic]^ := TempStr;
            end;
         end
      end;
      close(VariText);
   end else
   begin
      Writeln(' * ',Include,' not found');
      Writeln(LogFile,Prelog(LogError),Include,' not found');
      Flush(LOgFile);
   end;

   Unlock(D0 + 'Start');

end {ParseCfg};


Procedure CheckKey;
var T:DateTime;
    F:File;
    Result:Word;
    TempDate:Longint;

   Function CheckRegInfo(P:Pointer; Size:Word):LongInt;
   Type CharPtr=Array[1..1] of Char;
   var I:Integer;
       Temp:LongInt;
   begin
      Temp := 0;
      for I := 1 to Size do
         Temp := Temp + i * Byte(UpCase(CharPtr(P^)[i]));
      CheckRegInfo := Temp;
   end {CheckRegInfo};

var I:Integer;
    TempLong,Key:LongInt;
    Ch,Ch1:Char;
    {$IFDEF VIRTUALPASCAL}
    Code: Longint;
    {$ELSE}
    Code: Word;
    {$ENDIF}

begin

    Val(KeyStr,TempLong,Code);
    if (Code=0) then
    begin
       Key := TempLong mod 10000;
       TempLong := TempLong div 10000;
       if CheckRegInfo(Addr(SysopName[1]),Length(SysopName))+Key<>TempLong then
          Key := 0;
    end else
       Key := 0;

    Registrato := Key <> 0;

    if Registrato then
    begin
       Versione := Versione + '+ ' + Long2Str(Key,0);
       Serie := '';
    end else
    begin

       Serie := '[Evaluation copy]';
       Versione := Versione + ' UNREG';
       Write(' * ');
       RandoMize;
       for I := 1 to length(Serie) do
       begin
          Write(Serie[I]);
          if (Serie[I]<>' ') and (Random(5)=0) then
             Beep;
       end;
       Beep; Beep; Beep;
       if KeyPressed then
       begin
          While Keypressed do
             Ch := Readkey;
          Randomize;
          Ch1 := Chr(59 + random(10));
          Write(' Press [F',Byte(Ch1)-58,']');
          Ch := ReadKey;
          if Ch=#0 then
          begin
             Ch := ReadKey;
             if Ch<>Ch1 then
             begin
                Writeln;
                halt(1);
             end;
          end else
          begin
             Writeln;
             halt(1);
          end;
       end;
       Write(#13,'':79,#13);
       if RegisteredOnly then
       begin
          Writeln(' * This release of L-LIST works for registered users only');
          Writeln(LogFile, Prelog(LogError),'This release of L-LIST works for registered users only');
          halt(1);
       end;
    end;

end {CheckKey};


Procedure GetLListStatus;
Const I:Integer=1;
      MenuItems = 8;
      Menu:Array[1..menuitems] of string =
      ('Edit Files.Bbs', 'Make File lists',
       'Make Announces', 'Process TIC',
       'Make file searchs', 'Make File Index',
       'Rewrite Files.Bbs', 'Make CD File lists');

Var
   Ch:Char;

   J : INteger;
   AreeStr: String;
   FirstLine: Byte;
   MouInfo: MInfoRectype;

   Procedure ChoiceScreen;
   Var J: Integer;
   begin
      ShowCursor;
      FillScreen;
      HideCursor;
      GotoXY(19,FirstLine);
      Write(FrameChars[3], FrameChars[1], Button);
      for J := 6 to 41 do
         Write(FrameChars[1]);
      Write(FrameChars[4]);
      For J := 1 to menuitems div 2 do
      begin
         GotoXY(19,FirstLine+J);
         Write(FrameChars[2],Menu[J*2-1],'':20-length(Menu[J*2-1]),
            Menu[J*2],'':20-length(Menu[J*2]),Framechars[2]);
      end;
      GotoXY(19,FirstLine + menuitems div 2 + 1);
      Write(FrameChars[5]);
      for J := 2 to 41 do
         Write(FrameChars[1]);
      Write(FrameChars[6]);
   end {choicescreen};

   Procedure FixFBbsOpt;
   var I: Integer;
   begin
      GotoXY(19,FirstLine);
      Write(FrameChars[3], FrameChars[1], Button);
      for I := 6 to 41 do
         Write(FrameChars[1]);
      Write(FrameChars[4]);
      GotoXY(19,FirstLine+1);
      Write(FrameChars[2],' Area ');
      HighVideo;
      Write(AreeStr);
      NormVideo;
      for I := WhereX to 58 do
         Write('°');
      Write(' ', frameChars[2]);
      GotoXY(19,FirstLine+2);
      Write(FrameChars[2],' Repack ');
      if MakeRepack then
      begin
         HighVideo;
         write(Repack);
         NormVideo;
      end else
         write('°°°');
      write(FrameChars[2]: 30);
      GotoXY(19,FirstLine+3);
      Write(FrameChars[2],' ReadFile_Id [');
      if ReadFile_Id then
      begin
         HighVideo;
         write('þ');
         NormVideo;
      end else
         write('°');
      write(']', frameChars[2]: 25);
      GotoXY(19,FirstLine+4);
      Write(FrameChars[2], '       Check [');
      if CheckFiles then
      begin
         HighVideo;
         write('þ');
         NormVideo;
      end else
         write('°');
      write(']', FrameChars[2]: 25);
      GotoXY(19,FirstLine+5);
      Write(FrameChars[5]);
      for I := 2 to 41 do
         Write(FrameChars[1]);
      Write(FrameChars[6]);
   end;

Begin

   for J := 1 to 8 do
   begin
      if message[99+j]<>nil then
      begin
         menu[j] := message[99+j]^;
         freemem(message[99+j],length(message[99+j]^)+1);
         message[99+j]:=nil;
         if length(menu[j])>20 then
            menu[j]:=copy(menu[j],1,20);
      end;
   end;

   {$IFDEF NO4350}
   {$ELSE}
   if ModeFont8x8 then
      TextMode(Font8x8 + Co80);
   {$ENDIF}

   FirstLine := (Hi(WindMax) - Hi(WindMin) + 1) div 2 - 3;

   HideCursor;

   Choicescreen;

   Repeat
      GotoXY(20+20*((I-1) mod 2),FirstLine + 1 + (I-1) div 2);
      InvVideo;
      Write(Menu[I],'':20-length(Menu[I]));

      waitevent;

      GotoXY(20+20*((I-1) mod 2),FirstLine + 1 + (I-1) div 2);
      NormVideo;
      Write(Menu[I],'':20-length(Menu[I]));
      if keyPressed then
      begin
         Ch := ReadKey;
         if Ch=#0 then
         begin
            ch := ReadKey;
            Case Ch of
               #72:if I>2 then
                  dec(I,2);
               #80:if I<menuitems - 1 then
                  inc(I,2);
               #75:if I>1 then
                  dec(I);
               #77:if I<menuitems then
                  inc(I);
               #59:{F1, help}
                  begin
                     View(D0+'LLIST.DOC');
                     choicescreen
                  end;
               else
                  ch := #0
            end
         end;
      end else
      begin
         MouGet(MouInfo);
         if (mouInfo.ButtonStat <> 0) and
             (mouInfo.cx >= 19) and (mouinfo.cx <= 58) and
            (mouinfo.cy >= firstline -1) and
            (mouinfo.cy <= firstline + menuitems div 2 -1 ) then
         begin
            if MouInfo.cy = firstline -1 then
            begin
               if mouinfo.cx = 21 then
                  ch := #27
               else
                  ch := #0;
            end else
            begin
               I := (mouinfo.cy + 1 - firstline) * 2;
               if mouinfo.cx < 39 then
                  dec(i);
               if MouInfo.IsDouble then
                  ch := #13
               else
                  ch := #0;
            end;
         end else
            ch := #0;
      end;
      if (Ch=#13) and (I=2) then
      begin
         {controlla che ci sia almeno una lista HD}
         J := 1;
         while (J<=NFileList) and (FileList[J]^.Cd) do
             inc(J);
         if (J>NFileList) then
            Ch := #0;
      end;
      if (Ch=#13) and (I=8) then
      begin
         {controlla che ci sia almeno una lista HD}
         J := 1;
         while (J<=NFileList) and (not FileList[J]^.Cd) do
             inc(J);
         if (J>NFileList) then
            Ch := #0;
      end;
      if (ch=#13) and (I=7) then
      begin
         {deve richiedere anche le varie opzioni}
         AreeStr := '';

         ShowCursor;
         FillScreen;
         HideCursor;

         Repeat
            FixFBbsOpt;

            waitevent;

            if Keypressed then
            begin
               Ch := ReadKey;
               case upcase(Ch) of
                  'R':begin
                         MakeRepack := True;
                         TempStr := Repack;
                         ShowCursor;
                         ReadBox('Packer',3,TempStr);
                         FillScreen;
                         HideCursor;
                         if length(TempStr)=3 then
                         begin
                            Repack := TempStr;
                         end else
                         begin
                            MakeRepack := False;
                         end;
                      end;
                  'V':CheckFiles := not CheckFiles;
                  'I':ReadFile_Id := not ReadFile_Id;
                  'A':begin
                         ShowCursor;
                         Repeat
                            ReadBox('Area',32,AreeStr);
                            RemoveListaNum(Aree);
                            Aree := Nil;
                         until ParseArea(Aree,AreeStr);
                         FillScreen;
                         HideCursor;
                      end;
               end;
            end else
            begin
               mouget(mouinfo);
               if (MouInfo.cx = 21) and (MouInfo.cy = FirstLine -1 ) then
               begin
                  ch := #27
               end else
               if (MouInfo.cx = 33) and (MouInfo.cy = FirstLine +3 ) then
               begin
                  if MouInfo.IsDouble then
                  begin
                     KbdBuffer := 'V';
                  end;
                  Ch := #0;
               end else
               if (MouInfo.cx = 33) and (MouInfo.cy = FirstLine +2 ) then
               begin
                  if MouInfo.IsDouble then
                  begin
                     KbdBuffer := 'I';
                  end;
                  Ch := #0;
               end else
               if (MouInfo.cx >= 27) and (MouInfo.cx <= 29) and
                  (MouInfo.cy = FirstLine +1 ) then
               begin
                  if MouInfo.IsDouble then
                  begin
                     KbdBuffer := 'R';
                  end;
                  Ch := #0;
               end else
               if (MouInfo.cx >= 25) and (MouInfo.cx <= 57) and
                  (MouInfo.cy = FirstLine ) then
               begin
                  if MouInfo.IsDouble then
                  begin
                     KbdBuffer := 'A';
                  end;
                  Ch := #0;
               end else
                  ch := #0;
            end;
         until (Ch=#13) or (ch=#27);
         if (Ch=#27) then
         begin
            ChoiceScreen;
            ch := #0;
         end;
      end;
   until (Ch=#13) or (Ch=#27);

   ShowCursor;

   if i<>7 then
   begin
      MakeRepack := False;
      CheckFiles := False;
      ReadFile_Id := False;
   end;

   if Ch=#13 then
   case I of
      1:LlistStatus := EditFilesbbs;
      2:LListStatus := MakeListSum;
      3:LListStatus := Announce;
      4:begin
          LlistStatus := RaidProcess;
          OtherOptions := [ TicProcess ];
        end;
      5:begin
          LlistStatus := RaidProcess;
          OtherOptions := [ MakeSearch ];
        end;
      6:LListStatus := FileIdx;
      7:begin
           LListStatus := FixFBbs;
        end;
      8:LListStatus := CDMakeListSum;
   end else
      LListStatus := LListEnd;
   TextAttr := StartAttr;

   {$IFDEF NO4350}
   {$ELSE}
   if ModeFont8x8 then
      TextMode(Co80);
   {$ENDIF}

end {GetLListStatus};

begin

   StartTime := Timer;
   StartMode := LastMode;

   I := 1;
   while DirectVideo and (I<=ParamCount) do
   begin
      DirectVideo := Upper(ParamStr(I))<>'-B';
      inc(I)
   end;

   Randomize;
   AppExt := '.' + Long2Str(Random(1000),0);

   {$IFDEF OS2}
   Versione := Versione + '-OS2';
   {$ELSE}
      {$IFDEF DPMI}
      Versione := Versione + '-DPMI';
      {$ELSE}
      Versione := Versione + '-DOS';
      {$ENDIF}
   {$ENDIF}

   Writeln;
   Writeln('LLIST; File-Base utility, Version ',Versione);
   Writeln('       Copyright (C) ',CompYear,' by ',Autore,', All Rights Reserved');
   Writeln;

   CdRoms := '';

   Registrato := True;

   Nexclude := 0;
   NExcludeAnnounce := 0;
   Nidx1 := 0;
   NewDays := 90;
   FirstArea := True;
   Orfani := False;
   OffLine := True;
   OtherFiles := True;
   SysopName := '';
   BBSName := '';
   HdrStyle := 1;
   QuietMode := False;
   UseEMS := True;
   NoFirstLine := False;

   PosListBdl := -1;
   SearchStr := '';

   AllFilesSize := 0;

   FileAreaList := Nil;
   FileAreaListRef := @FileAreaList;

   DirBadFiles := '';
   DirInfectedFiles := '';

   SearchDb := True;

   MakeRepack := False;

   NMagic := 2;

   Magic[1] := Nil;
   Magic[2] := Nil;

   OkFilePwd := '';
   LevPwd := -MaxInt;

   PathAnnunci := '';
   ConfigFile := 'CONFIG.DAT';
   LoraDir := '';
   DcLen := 3;
   PrevMsgId := '';
   Copied := 0;
   PosListSum := -1;

   ShortSize := False;
   NewKey := False;

   for I:=1 to NMaxSearch do
      Search[I] := Nil;

   InBound := Nil;

   NTicNodes := 0;
   NTicAreas := 0;
   NTicGroups := 0;

   CheckFiles := False;

   OkLines := Nil;
   LongSummary := False;

   LLIstStatus := Unselected;
   Sort := No;
   FixFBbsSort := No;
   MaxLev := ML;
   Int:='F I L E    L I S T';
   DefaultOrfanoStr := '(* Description Missing *)';
   OffLineStr:='(Stored OffLine)';
   KeyStr:='0000000000000000';
   PathHdr := Nil;
   PathFtr := Nil;
   Colonne:=80;
   ModDc := NoMod;
   DelDupFBBS := False;
   Prefix := Nil;
   Suffix := Nil;
   DataPattern[1] := #0;
   NAka := 0;
   MsgFrom := '';
   MsgTo := '';
   MsgSubject := '';
   MsgOrigin := '';
   KludgeFdn := '';
   KludgeReplyTo := '';
   KludgeReplyAddr := '';
   KludgeReply := '';
   PostIBM := True;
   CurrMsgArea := -1;
   for I:=0 to NMsgAree do
      MsgArea[I] := Nil;
   Aree := Nil;
   UpDateFileIdx := Nil;
   MaxBest1 := 10;
   NoDlPath := False;
   NoSearchExt := False;
   LdChar := '';
   UpLoaderStr := '';
   NetAreaId := '';

   IndentDC := False;
   ZeroDc := False;

   SavePcb := False;
   DirFiles := Nil;
   DirFilesPtr := Nil;
   MailAttach := False;

   ChangeArea := -1;
   DirNewAreas := '';

   PathCopy := 'A:\';
   pathCopyFBbs := 'A:\Files.Bbs';

   for I := 1 to 10 do
      ExternalShell[I] := '';
   for I := 1 to 10 do
      Macro[I] := '';

   ExternalShell[1] := 'Shez';

   RePackPerc := -1;
   {$IFDEF OS2}
   {$ELSE}
      {$IFDEF DPMI}
      {$ELSE}
   ModeFont8x8 := False;
      {$ENDIF}
   {$ENDIF}

   FixCrcTic := False;
   FixSizeTic := False;
   TicReplace := False;
   TicStopDup := False;
   TicUpdate := True;
   TicUseDesc := False;
   TicUseLDesc := False;
   NoAnnounceAfterTic := False;

   UUEncodeFound := False;
   XXEncodeFound := False;
   MaxBytesUUEncode1 := 8192;

   NOutBound := 0;
   Outbound[0]:=NIl;
   StartingMsg := 1;
   NAnnounce := 0;
   CurrAnnounce := 0;

   DlLimit1 := '';
   DlLimit2 := '';

   Linea := 0;
   MinLenSearchStr := 4;
   SearchMaxFiles1 := 50;
   MsgHdrStyle := 2;
   FixFBbsHdrStyle := 0;
   ViewContents := VcNo;
   NStringSearch := 0;
   NAree := 0;
   NSearch := -1;
   PathHudson := '';
   PathAreasBBs := '';
   NPacker := 0;

   NFileList := 0;

   AreaHeaderLines := Nil;
   MsgAreaheaderLines := Nil;
   AreaheaderReqInfo := False;

   ExtDescPos := 1; {deve essere ridotto di 1, in realta' corrisponde alla}
                    {seconda colonna}

   HideLevels := Nil;

   FixFBbsHeader := False;

   LocalRaidPwd := '';

   Tz := GetEnv('TZ');
   if Tz='' then
      Tz := 'GMT';

   ReadFile_Id := False;

   VirusCheck := 'Scan /SUB /NOMEM /NOEXPIRE';

   PrevNumero := -1;

   Aka[0].Zone  := 0;
   Aka[0].Net   := 0;
   Aka[0].Node  := 0;
   Aka[0].Point := 0;

   NumCol[ColDef]   := TextAttr;
   NumCol[ColFrame] := Cyan;
   NumCol[ColBdlFRame] := Cyan;
   NumCol[ColFrameIn] := Yellow;
   NumCol[ColName]  := White;
   NumCol[ColSizeU] := LightRed;
   NumCol[ColSizeC] := LightCyan;
   NumCol[ColInfo]  := LightGreen;

   EchoWritten := False;
   PathEchoFlag := '';
   NetWritten := False;
   PathNetFlag := '';

   MaxFile_IdLines := 50;
   MaxLenDesc := 45;

   NoAnnounceREadFile_Id := False;
   NoPackFile_Id := False;
   NDescribe := 0;

   GetDate(T1.Year,T1.Month,T1.Day,TempWord);
   CurrDayOfWeek := TempWord;
   GetTime(T1.Hour,T1.Min,T1.Sec,TempWord);
   PackTime(T1,ActDate);

   {Lettura del file di configurazione}
   GetMem(VariBuf,SizeTxtBuf);
   GetDir(0,DirIn);
   if DirIn[length(DirIn)]='\' then
      delete(DirIn,Length(DirIn),1);
   DosModePath := DirIn + '\';
   D0 := FExpand(ParamStr(0));
   while(D0<>'') and (D0[length(D0)]<>'\') do
      dec(D0[0]);

   {Nomi di default per i vari files creati}
   PathNew := D0 + 'NewFiles.Txt';
   PathAll := D0 + 'AllFiles.Txt';
   PathIdx := D0 + 'LFiles.Idx';
   PathAvail := D0 + 'OkFile.Lst';
   PathBdl := D0 + 'Bdl.Txt';
   PathAreasBBs := D0 + 'Areas.Bbs';

   OtherOptions := [];

   {Prepara file di log}
   TempStr := GetEnv('LLISTLOG');
   if TempStr='' then
      TempStr := 'LList.Log';
   TempStr := ExpandD0(TempStr);
   Assign(LogFile,TempStr);

   {$I-}
   Append(LogFile);
   {$I+}
   if IOResult<>0 then
   begin
      {$I-}
      Rewrite(LogFile);
      {$I+}
      if IOREsult<>0 then
      begin
          Writeln(' * Can''t create log file ',TempStr);
          Halt(1);
      end;
   end;
   Writeln(LogFile,'--- LLIST ',Versione,' ',CompDate);
   if ParamCount>0 then
   begin
      Write(LogFile,'Command line:');
      for I := 1 to ParamCount do
         Write(LogFile,' ',Paramstr(I));
      Writeln(LogFile);
   end;
   Flush(LogFile);

   OldExit  := ExitProc;
   ExitProc := @NewExit;

   {definisce i compattatori}
   inc(NPacker);
   New(Packer[NPacker]);
   Packer[NPacker]^.Ext := 'ZIP';
   {$IFDEF OS2}
   Packer[NPacker]^.Pack := 'ZIP -rk9E';
   Packer[NPacker]^.Unpack := 'UNZIP -Cdxo';
   Packer[NPacker]^.Delete := 'ZIP -d';
   {$ELSE}
   Packer[NPacker]^.Pack := 'PKZIP -a -r -p -wHS -)';
   Packer[NPacker]^.Delete := 'PKZIP -d -a -r -p -wHS -)';
   Packer[NPacker]^.UnPack := 'PKUNZIP -d -)';
   {$ENDIF}
   Packer[NPacker]^.Id := #$50#$4B#$03#$04;
   Packer[NPacker]^.OffSet := 0;

   inc(NPacker);
   New(Packer[NPacker]);
   Packer[NPacker]^.Ext := 'ARJ';
   {$IFDEF OS2}
   Packer[NPacker]^.Pack := 'ARJ a -a+ -r+ -y+ -jm1';
   Packer[NPacker]^.UnPack := 'ARJ x -y+ -jg+';
   Packer[NPacker]^.Delete := 'ARJ d -y+ -jg+';
   {$ELSE}
   Packer[NPacker]^.Pack := 'ARJ a -a+ -r+ -y+ -jm1';
   Packer[NPacker]^.UnPack := 'ARJ x -y+ -jg+';
   Packer[NPacker]^.Delete := 'ARJ d -y+ -jg+';
   {$ENDIF}
   Packer[NPacker]^.Id := #$60#$EA;
   Packer[NPacker]^.OffSet := 0;

   inc(NPacker);
   New(Packer[NPacker]);
   Packer[NPacker]^.Ext := 'LZH';
   {$IFDEF OS2}
   Packer[NPacker]^.Pack := 'LH a';
   Packer[NPacker]^.Delete := 'LH d';
   Packer[NPacker]^.UnPack := 'LH x';
   {$ELSE}
   Packer[NPacker]^.Pack := 'LHA a /a+ /r+ /x+';
   Packer[NPacker]^.UnPack := 'LHA x /a+';
   Packer[NPacker]^.Delete := 'LHA d /a+';
   {$ENDIF}
   Packer[NPacker]^.Id := #$2D#$6C#$68;
   Packer[NPacker]^.OffSet := 2;

   inc(NPacker);
   New(Packer[NPacker]);
   Packer[NPacker]^.Ext := 'RAR';
   {$IFDEF OS2}
   Packer[NPacker]^.Pack := 'RAR a -r -y -s -std';
   Packer[NPacker]^.UnPack := 'RAR x -r -y -std';
   Packer[NPacker]^.Delete := 'RAR d -r -y -std';
   {$ELSE}
   Packer[NPacker]^.Pack := 'RAR a -r -y -s -std';
   Packer[NPacker]^.UnPack := 'RAR x -r -y -std';
   Packer[NPacker]^.Delete := 'RAR d -r -y -std';
   {$ENDIF}
   Packer[NPacker]^.Id := #$52#$61#$72#$21#$1A;
   Packer[NPacker]^.OffSet := 0;

   inc(NPacker);
   New(Packer[NPacker]);
   Packer[NPacker]^.Ext := 'UC2';
   {$IFDEF OS2}
   Packer[NPacker]^.Pack := 'UC a -s';
   Packer[NPacker]^.UnPack := 'UC x -s -f';
   Packer[NPacker]^.Delete := 'UC d -s -f';
   {$ELSE}
   Packer[NPacker]^.Pack := 'UC a -s';
   Packer[NPacker]^.UnPack := 'UC x -s -f';
   Packer[NPacker]^.Delete := 'UC d -s -f';
   {$ENDIF}
   Packer[NPacker]^.Id := #$55#$43#$32#$1A;
   Packer[NPacker]^.OffSet := 0;

   Repack := 'ZIP';

   {Esclude FILES.BBS}
   inc(Nexclude);
   TempStr := 'FILES.BBS';
   ExpandWildCards(TempStr);
   PathExclude[NExclude] := TempStr;

   {Esclude *.Bak}
   inc(Nexclude);
   TempStr := '*.BAK';
   ExpandWildCards(TempStr);
   PathExclude[NExclude] := TempStr;

   NLlistAlias := 1;
   llistAlias[1] := 'LLIST';

   llistdb := Nil;

   DosMode:=false;
   DosFileAreaList:=NIL;

   DescFiles := 'FILE_ID.DIZ';

   for i := 1 to maxmessage do
      message[i] := Nil;

   ParseCfg;
   Bbs := UnKnown;

   {subito la lista di default, che se no la parsecommand line}
   {esce con errore se non c'e' nessuna lista definita}
   if NFileList=0 then
   begin
      {Area di default}
      Inc(NFileList);
      New(FileList[NFileList]);
      FileList[NFileList]^.PathAll := D0 + 'AllFiles.Zip';
      FileList[NFileList]^.PathNew := D0 + 'NewFiles.Zip';
      FileList[NFileList]^.PathBdl := D0 + 'Bdl.Txt';
      FileList[NFileList]^.PathAvail := D0 + 'OkFile.Lst';
      FileList[NFileList]^.RemoveUncompressed := False;
      FileList[NFileList]^.CD := False;
      FileList[NFileLIst]^.KludgeFdn := '';
      FileList[NFileLIst]^.Aree := Nil;
      FileList[NFileList]^.MaxBest1 := 10;
      FileList[NFileList]^.PathHdr := Nil;
      FileList[NFileList]^.PathFtr := Nil;
   end;

   ParseCommandLine;

   if AreaHeaderLines=Nil then
   begin
      PosDesc := 1;
      L := 'ÉÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»';
      PutDescrizione(AreaHeaderLines);
      L := 'º # :^N ³ ^A    ^L º';
      PutDescrizione(AreaHeaderLines);
      L := 'ÇÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¶';
      PutDescrizione(AreaHeaderLines);
      L := 'º °°°°°±±±±±²²²²²ÛÛÛÛÛ ³   ^B in ^F Files   ³ ÛÛÛÛÛ²²²²²±±±±±°°°°° º';
      PutDescrizione(AreaHeaderLines);
      L := 'ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼';
      PutDescrizione(AreaHeaderLines);
   end;

   if MsgAreaHeaderLines=Nil then
   begin
      PosDesc := 1;
      L := '> ±±±±±±±±±± #^N ^*±^A±±±±±±±±';
      PutDescrizione(MsgAreaHeaderLines);
      PosDesc := 1;
      L := '>     **    ^F Files in this Area (^B)';
      PutDescrizione(MsgAreaHeaderLines);
   end;

   if DirNewAreas='' then
      DirNewAreas := D0 + 'FNEWAREA\';

   if pos('+',LdChar)=0 then
      LdChar := LdChar + '+';
   if pos('|',LdChar)=0 then
      LdChar := LdChar + '|';
   if pos('>',LdChar)=0 then
      LdChar := LdChar + '>';

   {Guarda per varie environment variables}
   {per determinare Bbs e LoraDir}
   {ordine inverso di importanza}
   TempStr := GetEnv('PCBDAT');
   if TempStr<>'' then
   begin
      FSplit(TempStr,D,N,E);
      LoraDir := D;
      Bbs := Pcboard;
      BbsConfigName[Bbs] := N+E;
   end;
   TempStr := GetEnv('MAXIMUS');
   if TempStr<>'' then
   begin
      FSplit(TempStr,D,N,E);
      LoraDir := D;
      ConfigFile := N+E;
      Bbs := Max;
   end;
   TempStr := GetEnv('RA');
   if TempStr<>'' then
   begin
      LoraDir := TempStr;
      Bbs := Ra250
   end;
   TempStr := GetEnv('LORA');
   if TempStr<>'' then
   begin
      LoraDir := TempStr;
      Bbs := Lora
   end;


   if LoraDir='' then
      LoraDir := D0
   else if LoraDir[1]='\' then
      LoraDir := D0[1] + D0[2] + LoraDir
   else if LoraDir[2]<>':' then
      LoraDir := D0 + LoraDir;

   if (LoraDir[length(LoraDir)]='\') then
      dec(LoraDir[0]);

   {$I-}
   ChDir(LoraDir);
   {$I+}
   if IOResult<>0 then
   begin
      writeln(' * Invalid BbsDir ',LoraDir);
      writeln(LogFile,PreLog(LogError),'Invalid BbsDir ',LoraDir);
      Flush(LogFile);
      halt(1);
   end;

   if LoraDir[length(LoraDir)]=':' then
   begin
      ChDir('\');
   end;

   {Memorizza il valore di quietmode}
   QuietMode1 := QuietMode;

   if Bbs=Max then
   begin
      {controlla se e' MAX3}
      FindFirst(BbsConfigName[Max300],Archive+ReadOnly,S);
      if DosError=0 then
      begin
         Bbs := Max300;
         {$IFDEF OS2}
         FindClose(S);
         {$ENDIF}
      end;
   end else
   if Bbs=Unknown then
   begin
      Bbs := Lora;
      Flag := False;
      repeat
         FindFirst(BbsConfigName[Bbs],Archive+ReadOnly,S);
         if DosError=0 then
         begin
            {$IFDEF OS2}
            Findclose(S);
            {$ENDIF}
            Flag := True;
            if Bbs=Max300 then
               ConfigFile := 'Max.Prm';
         end else
            inc(Bbs);
      until Flag or (Bbs=UnKnown);
   end;

   Dec(Colonne,23);

   {Apre Config.Dat, per ottenere varie Informazioni}
   if Bbs=Lora then
   begin
      TempWord := FileMode;
      FileMode := FmReadOnly_DN;
      assign(f1,ConfigFile);
      {$I-}
      Reset(F1,1);
      {$I+}
      FileMode := TempWord;
      if IOResult=0 then
      begin
         seek(F1,$A3);
         BlockRead(F1,L[1],39,TempWord);
         L[0] := Chr(TempWord);
         if pos (#0,L)>0 then
            byte(L[0]) := pos(#0,L)-1;
         if L<>'' then
         begin
            L := WithBackSlash(Upper(L));
            if L[1]='\' then
            begin
               L := LoraDir[1] + LoraDir[2] + L
            end else
            if L[2]<>':' then
            begin
               L := LoraDir + '\' + L
            end;
            PosDesc := 1;
            PutDescrizione(Inbound);
         End;
         seek(F1,$CB);
         BlockRead(F1,L[1],39,TempWord);
         L[0] := Chr(TempWord);
         if pos (#0,L)>0 then
            byte(L[0]) := pos(#0,L)-1;
         if L<>'' then
         begin
            L := WithBackSlash(Upper(L));
            if L[1]='\' then
            begin
               L := LoraDir[1] + LoraDir[2] + L
            end else
            if L[2]<>':' then
            begin
               L := LoraDir + '\' + L
            end;
            PosDesc := 1;
            PutDescrizione(Inbound);
         End;
         seek(F1,$F3);
         BlockRead(F1,L[1],39,TempWord);
         L[0] := Chr(TempWord);
         if pos (#0,L)>0 then
            byte(L[0]) := pos(#0,L)-1;
         if L<>'' then
         begin
            L := WithBackSlash(Upper(L));
            if L[1]='\' then
            begin
               L := LoraDir[1] + LoraDir[2] + L
            end else
            if L[2]<>':' then
            begin
               L := LoraDir + '\' + L
            end;
            PosDesc := 1;
            PutDescrizione(Inbound);
         End;
         if (Outbound[0]=Nil) then
         begin
            seek(F1,$11B);
            BlockRead(F1,TempStr[1],SizeOf(TempStr)-1,TempWord);
            TempStr[0] := Chr(TempWord);
            if pos (#0,TempStr)>0 then
               byte(TempStr[0]) := pos(#0,TempStr)-1;
            if TempStr<>'' then
            begin
               if TempStr[length(TempStr)]<>'\' then
                  TempStr := TempStr + '\';
               if TempStr[1]='\' then
               begin
                  TempStr := LoraDir[1] + LoraDir[2] + TempStr
               end else
               if TempStr[2]<>':' then
               begin
                  TempStr := LoraDir + '\' + TempStr
               end;
               New(OutBound[0]);
               GetMem(OutBound[0]^.OutBound,length(TempStr)+1);
               OutBound[0]^.OutBound^ := TempStr
            End;
         end;
         if (NetAreaId='') then
         begin
            seek(F1,$143);
            BlockRead(F1,NetAreaId[1],SizeOf(NetAreaId)-1,TempWord);
            NetAreaId[0] := Chr(TempWord);
            if pos (#0,NetAreaId)>0 then
               byte(NetAreaId[0]) := pos(#0,NetAreaId)-1;
            if NetAreaId<>'' then
            begin
               if NetAreaId[length(NetAreaId)]<>'\' then
                  NetAreaId := NetAreaId + '\';
               if NetAreaId[1]='\' then
               begin
                  NetAreaId := LoraDir[1] + LoraDir[2] + NetAreaId
               end else
               if NetAreaId[2]<>':' then
               begin
                  NetAreaId := LoraDir + '\' + NetAreaId
               end;
               NetAreaId := 'F' + NetAreaId + ',2';
            End;
         end;
         if (SysopName='') then
         begin
            seek(f1,$B2B);
            BlockRead(f1,SysopName[1],36,TempWord);
            SysopName[0] := Chr(TempWord);
            if pos (#0,SysopName)>0 then
               byte(SysopName[0]) := pos(#0,SysopName)-1;
         end;
         if (BBSName='') then
         begin
            seek(f1,$B4F);
            BlockRead(f1,BBSName[1],36,TempWord);
            BBSName[0] := Chr(TempWord);
            if pos (#0,BBSName)>0 then
               byte(BBSName[0]) := pos(#0,BBSName)-1;
         end;
         {Indirizzo principale}
         seek(f1,$C05);
         BlockRead(f1,Aka[0],SizeOf(Aka[0]),TempWord);
         {Ulteriori Aka, fino a 19}
         for I:=1 to 19 do
         begin
            if NAka<NMaxAka then
            begin
               seek(F1,$C05+14*I);
               blockRead(F1,Aka[NAka+1],SizeOf(Aka[NAka]),TempWord);
               inc(NAka);
               if (Aka[NAka].Zone=0) and (Aka[NAka].Net=0) and
                   (Aka[NAka].Node=0) and (Aka[NAka].Point=0) then
                  dec(NAka);
            end;
         end;
         {Formato Data}
         if (DataPattern[1]=#0) then
         begin
            seek(f1,$D9E);
            BlockRead(f1,DataPattern[1],19,TempWord);
         end;
         {DownLoad delimiters}
         seek(f1,$1743);
         BlockRead(f1,TempStr[1],2,TempWord);
         TempStr[0] := Chr(TempWord);
         if length(TempStr)=2 then
         begin
            {ora diventa il principale}
            I := pos(TempStr[1],DlLimit1);
            if I>0 then
               Delete(DlLimit1,I,1);
            DlLImit1 := TempStr[1] + DlLimit1;
            I := pos(TempStr[2],DlLimit2);
            if I>0 then
               Delete(DlLimit2,I,1);
            DlLimit2 := TempStr[2] + DlLimit2;
         end;
         close(f1);
      end else
      begin
         writeln(' * ',ConfigFile,' not found');
         writeln(LogFile,PreLog(LogError),ConfigFile,' not found');
         Flush(LogFile);
      end;
   end else
   if Bbs=Max300 then
   begin
      if ConfigFile<>'' then
      begin
         TempWord := FileMode;
         FileMode := FmReadOnly_DN;
         assign(f1,ConfigFile);
         {$I-}
         Reset(F1,1);
         {$I+}
         FileMode := TempWord;
         if IOResult=0 then
         begin
            {nome del sysop}
            seek(f1,2);
            BlockRead(F1,PrmOffset,SizeOf(PrmOffset),TempWord);
            Seek(F1,PrmOffset+1);
            {e qua dovrebbe esserci nome della bbs e del sysop}
            TempStr[0] := #79;
            BlockRead(F1,TempStr[1],Byte(TempStr[0]),TempWord);
            TempStr[0] := Chr(Pos(#0,TempStr)-1);
            if (BbsName='') then
               BbsName := TempStr;
            Seek(F1,PrmOffset + 1 + Length(TempStr) + 1);
            TempStr[0] := #79;
            BlockRead(F1,TempStr[1],Byte(TempStr[0]),TempWord);
            TempStr[0] := Chr(Pos(#0,TempStr)-1);
            if (SysopName='') then
               SysopName := TempStr;
            {indirizzi}
            seek(F1,$89);
            blockRead(F1,Aka[0],SizeOf(Aka[0]),TempWord);
            for I:=1 to 14 do
            begin
               if NAka<NMaxAka then
               begin
                  seek(F1,$89+8*I);
                  blockRead(F1,Aka[NAka+1],SizeOf(Aka[NAka]),TempWord);
                  inc(NAka);
                  if (Aka[NAka].Zone=0) and (Aka[NAka].Net=0) and
                      (Aka[NAka].Node=0) and (Aka[NAka].Point=0) then
                     dec(NAka);
               end;
            end;

            close(F1);
         end;
      end;
   end else
   if bbs=Ra250 then
   begin
      ConfigFile := 'Config.Ra';
      TempWord := FileMode;
      FileMode := FmReadOnly_DN;
      assign(f1,ConfigFile);
      {$I-}
      Reset(F1,1);
      {$I+}
      FileMode := TempWord;
      if IOResult=0 then
      begin
         BlockRead(F1,Varibuf^,SizeOf(StartRA250ConfigRecord),TempWord);
         if SysopName='' then
            SysopName := StartRA250ConfigRecord(VariBuf^).Sysop;
         if BbsName='' then
            BbsName := StartRA250ConfigRecord(VariBuf^).SystemName;
         Aka[0] := StartRA250ConfigRecord(VariBuf^).Address[0];
         For I := 1 to 9 do
            if AddAka(StartRA250ConfigRecord(VariBuf^).Address[I])<>0 then;
         close(f1);
      end else
      begin
         writeln(' * ',ConfigFile,' not found');
         writeln(LogFile,PreLog(LogError),ConfigFile,' not found');
         Flush(LogFile);
      end;
   end;

   if SysopName='' then
   begin
      SysopName := 'Sysop';
   end;

   {aggiunge i DlLimit standard}
   if pos('[',DlLimit1)=0 then
      DlLimit1 := DlLImit1 + '[';
   if pos('<',DlLimit1)=0 then
      DlLimit1 := DlLImit1 + '<';
   if pos('{',DlLimit1)=0 then
      DlLimit1 := DlLImit1 + '{';
   if pos('(',DlLimit1)=0 then
      DlLimit1 := DlLImit1 + '(';
   if pos(']',DlLimit2)=0 then
      DlLimit2 := DlLImit2 + ']';
   if pos('>',DlLimit2)=0 then
      DlLimit2 := DlLImit2 + '>';
   if pos('}',DlLimit2)=0 then
      DlLimit2 := DlLImit2 + '}';
   if pos(')',DlLimit2)=0 then
      DlLimit2 := DlLImit2 + ')';

   if DataPattern[1]=#0 then
   begin
      TempStr := '%d/%b/%y'#0;
      Move(TempStr[1],DataPattern[1],length(TempStr));
   end;
   CompilaDataPattern;

   If BbsName='' then
      BbsName := SysOpName + '''s BBS';

   {Aggiunge l'area NetMail tra le Search}
   if (NSearch=0) then
   begin
      inc(NSearch);
      New(MsgArea[NSearch]);
      MsgArea[NSearch]^.AreaId1 := NetAreaId;
      MsgArea[NSearch]^.AreaId2 := '';
      MsgArea[NSearch]^.Aree := Nil;
      MsgArea[NSearch]^.NoIbm := False;
      MsgArea[NSearch]^.MsgOrigin := '';
      MsgArea[NSearch]^.Suffix := Nil;
      MsgArea[NSearch]^.Prefix := Nil;
      MsgArea[NSearch]^.SearchDb := False;
      MsgArea[NSearch]^.MaxBytesUUEncode := MaxBytesUUEncode1;
   End;


   if NAnnounce=0 then
   begin
      inc(NAnnounce);
      new(Annunci[NAnnounce]);
      Annunci[NAnnounce]^.MsgFrom := SysopName;
      Annunci[NAnnounce]^.MsgTo := 'Sysop';
      Annunci[NAnnounce]^.MsgSubject := 'New files on '+BbsName;
      Annunci[NAnnounce]^.MsgOrigin := BbsName;
      Annunci[NAnnounce]^.KludgeFdn := '';
      Annunci[NAnnounce]^.Aree := Nil;
      Annunci[NAnnounce]^.NoIbm := False;
      Annunci[NAnnounce]^.Prefix := Nil;
      Annunci[NAnnounce]^.Suffix := Nil;
      Annunci[NAnnounce]^.Vc := False;
      Annunci[NAnnounce]^.FirstTime := True;
      Annunci[NAnnounce]^.CC := Nil;
      L := SysopName + ', ' + AddrStr(Aka[0]);
      PosDesc := 1;
      PutDescrizione(Annunci[NAnnounce]^.CC);
      Annunci[NAnnounce]^.XC := Nil;
      Annunci[NAnnounce]^.Filter := Nil;
   end;

   CheckKey;

   if Bbs=Max300 then
   begin
      I := Pos('+',LdChar);
      if I<>0 then
         delete(LdChar,I,1);
      LdChar := '+' + LdChar;
   end else
   if Bbs=LOra then
   begin
      I := Pos('>',LdChar);
      if I<>0 then
         delete(LdChar,I,1);
      LdChar := '>' + LdChar;
   end else
   if Bbs=PcBoard then
   Begin
      FBbsLen := 79;
      SavePCB := True;
      I := Pos('|',LdChar);
      if I<>0 then
         delete(LdChar,I,1);
      LdChar := '|' + LdChar;
      ColorId := '@X';

      {Cerca i nomi delle directory dei files}
      Assign(VariText,BbsConfigName[BBs]);
      {$I-}
      Reset(VariText);
      {$I+}
      if IOResult=0 then
      begin
         I := 0;
         while not eof(VariText) and (I<30) do
         begin
            ReadLn(VariText,TempStr);
            Inc(I);
            if (I=2) and (SysopName='') then
               SysopName := TempStr;
         end;
         if not eof(VariText) then
         begin
            ReadLn(VariText,TempStr)
         end else
         begin
            TempStr := '';
         end;
         Close(VariText);
         if TempStr<>'' then
         begin
            {Ora punta al file CNames, ricava i vari Dir.Lst}
            Assign(VariText,TempStr);
            {$I-}
            Reset(VariText);
            {$I+}
            if IOResult=0 then
            begin
               while not eof(VariText) do
               begin
                  I := 0;
                  while not eof(VariText) and (I<30) do
                  begin
                     ReadLn(VariText,TempStr);
                     Inc(I);
                  end;
                  if not eof(VariText) then
                  begin
                     {31^ riga, contiene il path del Dir.Lst}
                     ReadLn(VariText,L);
                     PosDesc := 1;
                     if (L<>'') then
                     begin
                        PutDescrizione(DirFiles);
                     end;
                  end;
                  {ora salta due righe}
                  if not eof(VariText) then
                     ReadLn(VariText,TempStr);
                  if not eof(VariText) then
                     ReadLn(VariText,TempStr);
               end;
               Close(VariText);
            end;
         end;
      end;
      if DirFiles=Nil then
      begin
         Halt(1)
      end;
      DirFilesPtr := DirFiles;
   end;

end.


