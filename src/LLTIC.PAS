Unit LLTic;

{$I LL.Def}

Interface

Uses MTask, Dos, Crt,

   Crc32,

   MkFile, LLMsg,

   MkString, MkMisc, MkGlobT, MkOpen,

   MkDos,

   MkMsgAbs,

   LLGen, LLExec, LLShell, LLCopy,

   LLGetTic, LLParseS;

Type
     TicType=Record
        SeenBy:AddrListTypeRef;
        LDesc, UnKnown, PathList, Replaces, InvReplaces:DescTypePtr;
        NomeFile, AreaTag, Pw,
           Magic, Desc, AreaDesc:String;
        Crc32, Size, Time:Longint;
        CrcFound:Boolean;
        Origin,From:AddrType;
     End;
     SendMode=(SendOnly,SendDelete);
     TicDupeType=Record
        Name:String[12];
        AreaTag:String[20];
        SentTo:AddrType;
        Size,Time:Longint;
        Received:Boolean
     End;


Procedure Hatch(PathFile,NomeFile,Replace,Magic:String; Descrizione:DescTypePtr;
   EchoNodes:AddrListTypeRef; AreaTag, SecTag:String; TicAddr:AddrType;
   Size, Time:Longint; AreaName: String);
Procedure GetTicInfo;
Procedure GetAree(Node:AddrType; Var Aree:ListaNumRef);
Procedure GetAllAree(Var Aree:ListaNumRef);
Procedure SendFile(Dest:AddrType; NomeFile:String; Flavour:Char;
   Mode:SendMode; PackType:String);


Var Tic:TicType;
    CreatedNewAreas:Boolean;
    GotTicInfo:Boolean;
    MadeHoldTic: Boolean;

Function FileCrc32(N:String):Longint;
Function ReadTic(Var N:String):Boolean;
Function NodeMember(Pnt:AddrListTypeRef; Address:AddrType; Mode:Byte): Boolean;
Function MarkDupeTic(Name,AreaTag:String; SentTo:AddrType;
   Size:Longint; Received:Boolean): Boolean;
Procedure EchoFile(PathCopy:String; EchoNodes:AddrListTypeRef;
  Size:Longint);
Procedure SaveTic(Var N:String);
Procedure TicNotify;
Procedure raid;

Implementation

Function FileCrc32(N:String):Longint;
Const SizeBuf=16384;
Var TempCrc, TempCrc1: Longint;
   F : File;
   P: Pointer;
   {$IFDEF VIRTUALPASCAL}
   Result: Longint;
   {$ELSE}
   Result:Word;
   {$ENDIF}
   I: Word;
   fm: word;
Begin
   Assign(F,N);
   fm := FileMode;
   FileMode := FmReadOnly_DW;
   {$I-}
   Reset(F,1);
   {$I+}
   if IOResult=0 then
   begin
      TempCrc := CrcSeed;
      GetMem(P,SizeBuf);
      While not eof(F) do
      Begin
         BlockRead(F, P^, SizeBuf, Result);
         TempCrc := UpdC32Block(P^, Result, TempCrc);
      End;
      Close(F);
      FreeMem(P,SizeBuf);
      TempCrc := TempCrc XOR CrcSeed;
   End else
      TempCrc := 0;
   FileCrc32 := TempCrc;
   FileMode := Fm;
End {FileCrc32};


Function NodeMember(Pnt:AddrListTypeRef; Address:AddrType; Mode:Byte): Boolean;
Begin
   While (Pnt<>Nil) and not AddrEqual(Pnt^.Node,Address) do
      Pnt := Pnt^.Next;
   if Pnt<>Nil then
   begin
      NodeMember := Pnt^.Mode and Mode <> 0;
   end else
      NodeMember := False;
End {NodeMember};


Procedure GetAree(Node:AddrType; Var Aree:ListaNumRef);
Var I:INteger;
Begin
   Aree := Nil;
   For I := 1 to NTicAreas do
   begin
      if NodeMember(TicAreas[I]^.Nodes,Node,TicSend+TicReceive) then
         PutInListaAree(TicAreas[I]^.Number,TicAreas[I]^.Number,Aree);
   end;
   if Aree=Nil then
      PutInListaAree(-1,-1,Aree);
End {GetAree};


Procedure GetAllAree(Var Aree:ListaNumRef);
Var I:INteger;
Begin
   Aree := Nil;
   For I := 1 to NTicAreas do
   begin
      PutInListaAree(TicAreas[I]^.Number,TicAreas[I]^.Number,Aree);
   end;
   if Aree=Nil then
      PutInListaAree(-1,-1,Aree);
End {GetAllAree};


Function MarkDupeTic(Name,AreaTag:String; SentTo:AddrType;
   Size:Longint; Received:Boolean): Boolean;
Var TicDupe, TempDupe:TicDupeType;
   F : File;
   Result:Word;
   fm : word;
   Sent: longint;
Begin
   Sent := 0;
   fm := FileMode;
   FileMode := Fmreadwrite_DA;
   Assign(F,D0+'Tic.Dup');
   {$I-}
   Reset(F, 1);
   {$I+}
   if IOREsult<>0 then
   begin
      {$I-}
      Rewrite(F, 1);
      {$I+}
      if IOREsult=0 then
      begin
         FillChar(TicDupe,SizeOf(TicDupeType),0);
         TicDupe.Name := '';
         TicDupe.Size := SizeOf(TicDupeType);
         BlockWrite(F,TicDupe,SizeOf(TicDupeType));
         FillChar(TicDupe,SizeOf(TicDupeType),0);
         TicDupe.Name := Name;
         TicDupe.AreaTag := AreaTag;
         TicDupe.SentTo := SentTo;
         TicDupe.Size := Size;
         TicDupe.Time := ActDate;
         TicDupe.Received := Received;
         BlockWrite(F,TicDupe,Sizeof(TicDupeType));
         close(F)
      end;
      MarkDupeTic := True
   end else
   begin

      FillChar(TicDupe,SizeOf(TicDupeType),0);
      TicDupe.Name := Name;
      TicDupe.AreaTag := AreaTag;
      TicDupe.SentTo := SentTo;
      TicDupe.Size := Size;
      TicDupe.Time := ActDate;
      TicDupe.Received := Received;

      {fa uno scan del file, per vedere se e' gia' stato ricevuto}
      while not eof(F) do
      begin
         BlockRead(F,TempDupe,SizeOf(TicDupeType));
         if (TicDupe.Name=TempDupe.Name) and (TicDupe.AreaTag=TempDupe.AreaTag) and
            (TicDupe.Size=TempDupe.Size) then
         begin
            inc(Sent);
         end;
      end;

      {terapia d'urto :) chiudo il file, e faccio un seek alla fine}
      {Seek(F,FileSize(F));}

      BlockWrite(F,TicDupe,SizeOf(TicDupeType));
      close(F);
      {if Sent>0 then
      begin
         Writeln(' * Dupes file (',Sent,')');
         Writeln(LogFile,Prelog(LogError),'Dupes file (',Sent,')');
         Flush(LogFile);
      end;
      }
      MarkDupeTic := Sent = 0;
   end;
   filemode := Fm;
End {MarkDupeTic};


Function GetGroups(Address:AddrType):String;
Var TempStr:String;
   I:Integer;
Begin
   TempStr := '';
   For I := 1 to NTicGroups do
   begin
      if NodeMember(TicGroups[I]^.Nodes,Address,TicSend+TicReceive) then
      begin
         TempStr := TempStr + ' ' + TicGroups[I]^.Tag
      end;
   end;
   if TempStr='' then
      TempStr := ' NONE';
   GetGroups := TempStr
End {GetGroups};


Procedure TicNodeInfo(Var F:Text; N:Integer);
Begin
   Writeln(F);
   Writeln(F,'Info about ',AddrStr(TicNodes[N]^.Node));
   Writeln(F,'Level: ',TicNodes[N]^.TicLevel);
   if TicNodes[N]^.Packer='' then
      Writeln(F,'Packer: NONE')
   else
      Writeln(F,'Packer: ',TicNodes[N]^.Packer);
   Writeln(F,'AutoLink:',GetGroups(TicNodes[N]^.Node));
   if TicNodes[N]^.Notify then
      Writeln(F,'Notify: YES')
   else
      Writeln(F,'Notify: NO');
   if TicNodes[N]^.RemoteMaint then
      Writeln(F,'RemoteMaint: YES')
   else
      Writeln(F,'RemoteMaint: NO');
   if TicNodes[N]^.SendTic then
      Writeln(F,'SendTic: YES')
   else
      Writeln(F,'SendTic: NO');
   if TicNodes[N]^.SendAnnounce then
      Writeln(F,'Announce: YES')
   else
      Writeln(F,'Announce: NO');
   if TicNodes[N]^.TinySeenBy then
      Writeln(F,'TinySeenBy: YES')
   else
      Writeln(F,'TinySeenBy: NO');
   Writeln(F,'MaxFileSize: ',TicNodes[N]^.MaxFileSize);
   Writeln(F);
End {TicNodeInfo};


Procedure TicReport(Var AllFiles:Text);
Const SizeGroup=16;
   Procedure TicReport1(Mode:Byte);
   Var I,J,K,L,M:Integer;
   begin
      for L := 0 to (NTicNodes-1) div SizeGroup do
      begin
         M := (L+1) * SizeGroup;
         if M>NTicNodes then
            M := NticNodes;
         for J := L*SizeGroup+1 to M do
         begin
            TempStr := AddrStr(TicNodes[J]^.Node);
            for I := length(TempStr)+1 to 20 + M -j do
               TempStr := TempStr + '-';
            TempStr := TempStr + '+';
            for I := L*SizeGroup+1 to J-1 do
               TempStr := TempStr + '|';
            Writeln(AllFiles,TempStr);
         end;
         For I := 1 to NTicAreas do
         begin
            Write(AllFiles,TicAreas[I]^.Tag,'':20-length(TicAreas[I]^.Tag));
            for J := M downto L*SizeGroup+1 do
            begin
               if NodeMember(TicAreas[I]^.Nodes,TicNodes[J]^.Node,Mode) then
                  Write(AllFiles,'*')
               else
                  Write(AllFiles,'.')
            end;
            Writeln(AllFiles);
         end;
      end;
   end {TicREport1};
Begin
   Writeln(AllFiles);
   if message[70]=Nil then
      TempStr := 'Global TIC report'
   else
      TempStr := Message[70]^;
   Writeln(AllFiles,TempStr);
   Writeln(AllFiles,'Downlinks');
   TicReport1(TicSend);
   Writeln(AllFiles,'Uplinks');
   TicReport1(TicReceive);
   Writeln(AllFiles);
End {TicReport};


Procedure TicNotify;
Const
    NMaxDupes=1000;
Var I,J,K:Integer;
    F:File;
    T1:DateTime;
    BytesReceived, BytesSent, FilesReceived, FilesSent:
      Array[0..NMaxTicAreas] of Longint;
    TotFilesSent, TotBytesSent, TotBytesReceived, TotFilesReceived:Longint;
    TicDupe:TicDupeType;
    Result:Word;
    StartDate, LastDate:LongInt;
    fm: word;
    NDupes, NDup: Longint;
    T2: dateTime;
    Startdata, enddata: String;

   Procedure ResetCounters;
   Var I:Integer;
   Begin
      for I := 0 to NTicAreas do
      begin
         BytesReceived[I] := 0;
         BytesSent[I] := 0;
         FilesReceived[I] := 0;
         FilesSent[I] := 0;
      end;
      StartDate := ActDate;
      LastDate := ActDate;
      TotBytesSEnt := 0;
      TotBytesReceived := 0;
      TotFilesSent := 0;
      TotFilesReceived := 0;
   End {ResetCounters};
Begin

   Fm := FileMode;
   FileMode := FmReadWrite_DA;

   Assign(F,D0+'Tic.Dup');
   {$I-}
   Reset(F, 1);
   {$I+}
   if IOResult=0 then
   begin
      UnpackTime(ActDate,T2);
      if not eof(F) then
      begin
         BlockRead(F,TicDupe,SizeOf(TicDupeType));
         if TicDupe.Name='' then
         begin
            {$I-}
            seek(F,TicDupe.Size);
            {$I+}
            if (IOResult=0) and not eof(F) then
            begin
               BlockRead(F,TicDupe,SizeOf(TicDupeType));
               UnpackTime(TicDupe.Time,T1);
            end else
               T1.Month := T2.Month;
         end else
         begin
            UnpackTime(TicDupe.Time,T1);
         end;
      end else
         T1.Month := T2.Month;
      if T1.Month <> T2.Month then
      begin
         {e' passato un mese, manda il messaggio con le statistiche ai downlinks}
         Writeln(' * Send TIC report');
         Writeln(LogFile,Prelog(LogStart),'Send TIC report');
         Flush(LogFile);
         For I := 1 to NTicNodes do
         if TicNodes[I]^.Notify then
         Begin
            ResetCounters;
            {il primo contiene un puntatore ?}
            BlockRead(F,TicDupe,SizeOf(TicDupeType));
            if TicDupe.Name='' then
            begin
               {Si', e' proprio il puntatore!}
               Seek(F,TicDupe.Size);
            end else
               seek(F,0);
            While not eof(F) do
            Begin
               BlockRead(F,TicDupe,SizeOf(TicDupeType));
               if AddrEqual(TicDupe.SentTo,TicNodes[I]^.Node) then
               begin
                  J := 1;
                  while (J<=NTicAreas) and (TicAreas[J]^.Tag<>TicDupe.AreaTag) do
                     inc(J);
                  if TicDupe.Time<StartDate then
                     StartDate := TicDupe.Time;
                  if TicDupe.Time>LastDate then
                     LastDate := TicDupe.Time;
                  if (J<=NTicAreas) then
                  begin
                     if TicDupe.Received then
                     begin
                        Inc(FilesSent[J]);
                        Inc(TotFilesSEnt);
                        Inc(BytesSent[J],TicDupe.Size);
                        Inc(TotBytesSEnt,TicDupe.Size);
                     end else
                     begin
                        Inc(FilesReceived[J]);
                        Inc(TotFilesREceived);
                        Inc(BytesReceived[J],TicDupe.Size);
                        Inc(TotBytesReceived,TicDupe.Size);
                     end
                  end else
                  begin
                     if TicDupe.Received then
                     begin
                        Inc(FilesSent[0]);
                        Inc(TotFilesSent);
                        Inc(BytesSent[0],TicDupe.Size);
                        Inc(TotBytesSent,TicDupe.Size)
                     end else
                     begin
                        Inc(FilesReceived[0]);
                        Inc(TotFilesReceived);
                        Inc(BytesReceived[0],TicDupe.Size);
                        Inc(TotBytesReceived,TicDupe.Size);
                     end
                  end;
               end;
            End;
            PathAll := D0 + HexLong(ToUnixDate(GetDosDate)) + AppExt;
            Assign(AllFiles,PathAll);
            Rewrite(AllFiles);
            if IOResult=0 then
            begin
               TicNodeInfo(AllFiles,I);
               UnPackTime(StartDate,T1);
               MyDateStr(T1);
               StartData := Prevdatastr;
               UnpackTime(LastDate,T1);
               MyDateStr(T1);
               Enddata := PrevdataStr;
               if message[69]=Nil then
                  TempStr := 'From %1 to %2'
               else
                  TempStr := Message[69]^;
               SubstPar(TempStr,Startdata,'1');
               SubstPar(TempStr,enddata,'2');
               Writeln(AllFiles,TempStr);
               if message[71]=Nil then
                  TempStr := 'Area                   Sent                      Received'
               else
                  TempStr := Message[71]^;
               Writeln(AllFiles,TempStr);
               Writeln(AllFiles,'=========================================================================');
               For J := 1 to NTicAreas do
               if (FilesSent[J]>0) or (FilesReceived[J]>0) then
               begin
                  Writeln(AllFiles,TicAreas[J]^.Tag,'':21-length(TicAreas[J]^.Tag),
                     BytesStr(BytesSent[J]):12,' in ',FilesSent[J]:4,' files',
                     BytesStr(BytesReceived[J]):12,' in ',FilesReceived[J]:4,' files');
               End;
               if (FilesSent[0]>0) or (FilesReceived[0]>0) then
               begin
                  Writeln(AllFiles,'Unknown areas        ',
                     BytesStr(BytesSent[0]):12,' in ',FilesSent[0]:4,' files',
                     BytesStr(BytesReceived[0]):12,' in ',FilesReceived[0]:4,' files');
               End;
               Writeln(AllFiles,'=========================================================================');
               Writeln(AllFiles,'                     ',
                     BytesStr(TotBytesSent):12,' in ',TotFilesSent:4,' files',
                     BytesStr(TotBytesReceived):12,' in ',TotFilesReceived:4,' files');

               MsgDestAddr := TicNodes[I]^.Node;
               K := 0;
               While (K<=NAka) and (Aka[K].Zone<>MsgDestAddr.Zone) do
                  inc(K);
               if K>NAka then
                  K := 0;
               MsgOrigAddr := Aka[K];
               MsgFrom := 'LLIST ' + versione;
               MsgTo := 'Sysop';
               if message[68]=Nil then
                  MsgSubject := 'TIC report'
               else
                  MsgSubject := Message[68]^;
               Close(AllFiles);
               PostAnnunciNews(NetAreaId);
               if EraseFile(PathAll) then;
            End;
            Seek(F,0);
         End;

         {Report locale per il Sysop}
         ResetCounters;

         BlockRead(F,TicDupe,SizeOf(TicDupeType));
         if TicDupe.Name='' then
         begin
            {Si', e' proprio il puntatore!}
            Seek(F,TicDupe.Size);
         end else
            seek(F,0);

         While not eof(F) do
         Begin
            BlockRead(F,TicDupe,SizeOf(TicDupeType));
            J := 1;
            while (J<=NTicAreas) and (TicAreas[J]^.Tag<>TicDupe.AreaTag) do
               inc(J);
            if TicDupe.Time<StartDate then
               StartDate := TicDupe.Time;
            if TicDupe.Time>LastDate then
               LastDate := TicDupe.Time;
            if (J<=NTicAreas) then
            begin
               if Not TicDupe.Received then
               begin
                  Inc(FilesSent[J]);
                  Inc(TotFilesSEnt);
                  Inc(BytesSent[J],TicDupe.Size);
                  Inc(TotBytesSEnt,TicDupe.Size);
               end else
               begin
                  Inc(FilesReceived[J]);
                  Inc(TotFilesREceived);
                  Inc(BytesReceived[J],TicDupe.Size);
                  Inc(TotBytesReceived,TicDupe.Size);
               end
            end else
            begin
               if Not TicDupe.Received then
               begin
                  Inc(FilesSent[0]);
                  Inc(TotFilesSent);
                  Inc(BytesSent[0],TicDupe.Size);
                  Inc(TotBytesSent,TicDupe.Size)
               end else
               begin
                  Inc(FilesReceived[0]);
                  Inc(TotFilesReceived);
                  Inc(BytesReceived[0],TicDupe.Size);
                  Inc(TotBytesReceived,TicDupe.Size);
               end
            end;
         End;

         {Aggiorna BytesMonth}
         TicCfgModified := True;

         J := 1;
         While (J<=NTicAreas) do
         begin
            if BytesReceived[J]=0 then
            begin
               {Traffico nullo, forse ci sono problemi, ritenta il link}
               I := 1;
               while (I<=NTicGroups) and (TicAreas[J]^.Group<>TicGroups[I]^.Tag) do
                  inc(I);
               if (I<=NTicGroups) and (TicGroups[I]^.UplinkNode>0) and
                  NodeMember(TicAreas[J]^.Nodes,TicNodes[TicGroups[I]^.UplinkNode]^.Node,
                     TicSend+TicReceive) then
               begin
                  {forse l'area era sganciata, la richiede all'uplink}
                  {L := TicAreas[J]^.Tag;
                  PosDesc := 1;
                  PutDescrizione(TicNodes[TicGroups[I]^.UplinkNode]^.RequireTicAreasRef^);
                  TicNodes[TicGroups[I]^.UplinkNode]^.RequireTicAreasRef :=
                     Addr(TicNodes[TicGroups[I]^.UplinkNode]^.
                        RequireTicAreasRef^^.Next);
                  }
               end;
               TicAreas[J]^.BytesMonth :=
                  TicAreas[J]^.BytesMonth div 2 + BytesReceived[J] div 2;
               inc(J)
            end else
            begin
               TicAreas[J]^.BytesMonth :=
                  TicAreas[J]^.BytesMonth div 2 + BytesReceived[J] div 2;
               inc(J)
            end;
         end;

         PathAll := D0 + HexLong(ToUnixDate(GetDosDate)) + AppExt;
         Assign(AllFiles,PathAll);
         Rewrite(AllFiles);
         if IOResult=0 then
         begin
            UnPackTime(StartDate,T1);
            MyDateStr(T1);
            Startdata := prevdataStr;
            UnpackTime(LastDate,T1);
            MyDateStr(T1);
            EndData := PrevdataStr;
            if message[69]=Nil then
               TempStr := 'From %1 to %2'
            else
               TempStr := Message[69]^;
            SubstPar(TempStr,Startdata,'1');
            SubstPar(TempStr,enddata,'2');
            Writeln(AllFiles,TempStr);
            if message[71]=Nil then
               TempStr := 'Area                   Sent                      Received'
            else
               TempStr := Message[71]^;
            Writeln(AllFiles,TempStr);
            Writeln(AllFiles,'=========================================================================');
            For J := 1 to NTicAreas do
            if (FilesSent[J]>0) or (FilesReceived[J]>0) then
            begin
               Writeln(AllFiles,TicAreas[J]^.Tag,'':21-length(TicAreas[J]^.Tag),
                  BytesStr(BytesSent[J]):12,' in ',FilesSent[J]:4,' files',
                  BytesStr(BytesReceived[J]):12,' in ',FilesReceived[J]:4,' files');
            End;
            if (FilesSent[0]>0) or (FilesReceived[0]>0) then
            begin
               Writeln(AllFiles,'Unknown areas        ',
                  BytesStr(BytesSent[0]):12,' in ',FilesSent[0]:4,' files',
                  BytesStr(BytesReceived[0]):12,' in ',FilesReceived[0]:4,' files');
            End;
            Writeln(AllFiles,'=========================================================================');
            Writeln(AllFiles,'                     ',
                  BytesStr(TotBytesSent):12,' in ',TotFilesSent:4,' files',
                  BytesStr(TotBytesReceived):12,' in ',TotFilesReceived:4,' files');

            MsgDestAddr := Aka[0];
            MsgOrigAddr := Aka[0];
            MsgFrom := 'LLIST ' + versione;
            MsgTo := SysopName;
            if message[68]=Nil then
               MsgSubject := 'TIC report'
            else
               MsgSubject := Message[68]^;
            Close(AllFiles);
            PostAnnunciNews(NetAreaId);
            if EraseFile(PathAll) then;
         End;

         {ora bisogna fare un "purge" del file Tic.Dup}
         NDupes := FileSize(F) div SizeOf(TicDupeType);
         if (NDupes>NMaxDupes) then
         begin
            {facciamo una roba "brutale", ricopia i mille record}
            for NDup := 0 to NMaxDupes-1 do
            begin
               Seek(F,(NDupes - NMaxDupes + NDup) * SizeOf(TicDupeType));
               BlockRead(F,TicDupe,SizeOf(TicDupeType));
               Seek(F,NDup * SizeOf(TicDupeType));
               BlockWrite(F,TicDupe,SizeOf(TicDupeType));
            end;
            Truncate(F);
            NDupes := NMaxDupes;
         end;

         {ora aggiorna il puntatore}
         FillChar(TicDupe,SizeOf(TicDupeType),#0);
         TicDupe.Name := '';
         TicDupe.Size := NDupes * SizeOf(TicDupeType);
         seek(F,0);
         BlockWrite(F,TicDupe,SizeOf(TicDupeType));
      end;
      Close(F);
   End;

   FileMode := Fm;

End {TicNotify};


Function ReadTic(Var N:String):Boolean;
Var F:Text;
    f1: File;
    TempStr, TempStr1, PrevN, CreatedBy:String;
    I : Integer;
    DT:DateTime;
    DR:DirStr; NR:NameStr; ER:ExtStr;
    TempReplace:^DescTypePtr;
    {$IFDEF VIRTUALPASCAL}
    Code: Longint;
    {$ENDIF}
Begin
   CreatedBy := '';
   PrevN := N;
   Assign(F1,N);
   TempStr := Copy(N,1,length(N)-3) + 'Bad';
   {$I-}
   Rename(F1,TempStr);
   {$I+}
   if IOResult=0 then
   begin
      N := TempStr;
      Assign(F,N);
      {$I-}
      Reset(F);
      {$I+}
      if IOResult=0 THEN
      begin
         CancellaDescrizione(Tic.UnKnown);
         Tic.UnKnown := Nil;
         CancellaDescrizione(Tic.PathList);
         Tic.PathList := Nil;
         DeleteNodes(Tic.SeenBy);
         Tic.SeenBy := Nil;
         CancellaDescrizione(Tic.LDesc);
         Tic.LDesc := Nil;
         CancellaDescrizione(Tic.Replaces);
         Tic.Replaces := Nil;
         CancellaDescrizione(Tic.InvReplaces);
         Tic.InvReplaces := Nil;
         {Cerca il nome del file}
         Tic.NomeFile := '';
         Tic.Magic := '';
         Tic.AreaDesc := '';
         Tic.CrcFound := False;
         Tic.Crc32 := 0;
         Tic.AreaTag := '';
         Tic.Pw := '';
         Tic.Desc := '';
         Tic.Size := -1;
         Tic.Time := -1;
         FillChar(Tic.Origin,SizeOf(AddrType),0);
         FillChar(Tic.From,SizeOf(AddrType),0);
         while not eof(F) do
         begin
            ReadLn(F,TempStr);
            I := pos(' ',TempStr);
            if I=0 then
            begin
               L := TempStr;
               PosDesc := 1;
               PutDescrizione(Tic.UnKnown)
            end else
            begin
               TempStr1 := Copy(TempStr,1,I-1);
               for I := 1 to length(TempStr1) do
                  TempStr1[I] := UpCase(TempStr1[I]);
               if (TempStr1='CRC') or (TempStr1='CRC:') then
               begin
                  I := length(TempStr1) + 2;
                  Tic.Crc32 := 0;
                  Tic.CrcFound := True;
                  while (I<=length(TempStr)) and (TempStr[I]=' ') do
                     inc(I);
                  while (I<=length(TempStr)) and (TempStr[I]<>' ') do
                  begin
                     Tic.Crc32 := Tic.Crc32 * 16;
                     case(UpCase(TempStr[I])) of
                        '0'..'9':Tic.Crc32 := Tic.Crc32 + ord(TempStr[I]) - ord('0');
                        'A'..'F':Tic.Crc32 := Tic.Crc32 + ord(TempStr[I]) + 10 - ord('A');
                       else
                        begin
                           Tic.Crc32 := 0;
                           I := length(tempStr);
                           Tic.CrcFound := False;
                        end;
                     end;
                     inc(I)
                  end;
               end else
               if (TempStr1='FILE') or (TempStr1='FILE:') then
               begin
                  Delete(TempStr,1,length(TempStr1)+1);
                  StripLeadingSpace(TempStr);
                  I := Pos(' ',TempStr);
                  if I=0 then
                     I := length(TempStr)+1;
                  Tic.NomeFile := Upper(Copy(TempStr,1,I-1));
               end else
               if (TempStr1='REPLACES') or (TempStr1='REPLACES:') then
               begin
                  Delete(TempStr,1,length(TempStr1)+1);
                  StripLeadingSpace(TempStr);
                  I := pos(' ',TempStr);
                  if I=0 then
                     I := Length(TempStr) +1;
                  L := Upper(Copy(TempStr,1,I-1));
                  PosDesc := 1;
                  PutDescrizione(Tic.Replaces);
               end else
               if (TempStr1='AREA') or (TempStr1='AREA:') then
               begin
                  Delete(TempStr,1,length(TempStr1)+1);
                  StripLeadingSpace(TempStr);
                  I := pos(' ',TempStr);
                  if I=0 then
                     I := Length(TempStr) +1;
                  Tic.AreaTag := Upper(Copy(TempStr,1,I-1));
               end else
               if (TempStr1='AREADESC') or (TempStr1='AREADESC:') then
               begin
                  Delete(TempStr,1,length(TempStr1)+1);
                  StripLeadingSpace(TempStr);
                  Tic.AreaDesc := TempStr;
               end else
               if (TempStr1='PW') or (TempStr1='PW:') then
               begin
                  Delete(TempStr,1,length(TempStr1)+1);
                  StripLeadingSpace(TempStr);
                  I := pos(' ',TempStr);
                  if I=0 then
                     I := Length(TempStr) +1;
                  Tic.Pw := Upper(Copy(TempStr,1,I-1));
               end else
               if (TempStr1='ORIGIN') or (TempStr1='ORIGIN:') then
               begin
                  Delete(TempStr,1,length(TempStr1)+1);
                  StripLeadingSpace(TempStr);
                  I := pos(' ',TempStr);
                  if I=0 then
                     I := Length(TempStr) +1;
                  if Not ParseAddr(Copy(TempStr,1,I-1),Tic.Origin,Tic.Origin) then
                  begin
                     Writeln(' * Invalid ORIGIN: ',TempStr);
                     Writeln(LogFile,Prelog(LogError),'Invalid ORIGIN: ',TempStr);
                     Flush(LogFile);
                  end;
               end else
               if (TempStr1='MAGIC') or (TempStr1='MAGIC:') then
               begin
                  Delete(TempStr,1,length(TempStr1)+1);
                  StripLeadingSpace(TempStr);
                  I := pos(' ',TempStr);
                  if I=0 then
                     I := Length(TempStr) +1;
                  Tic.Magic := Copy(TempStr,1,I-1);
               end else
               if (TempStr1='FROM') or (TempStr1='FROM:') then
               begin
                  Delete(TempStr,1,length(TempStr1)+1);
                  StripLeadingSpace(TempStr);
                  I := Pos(' ',TempStr);
                  if I>0 then
                  begin
                     TempStr1 := Copy(TempStr,1,I-1);
                     Delete(TempStr,1,I);
                     StripLeadingSpace(TempStr);
                  end else
                  begin
                     TempStr1 := TempStr;
                     TempStr := ''
                  end;
                  if Not ParseAddr(TempStr1,Tic.From,Tic.From) then
                  begin
                     Writeln(' * Invalid FROM: ',TempStr);
                     Writeln(LogFile,Prelog(LogError),'Invalid FROM: ',TempStr);
                     Flush(LogFile);
                  end;
                  if TempStr<>'' then
                     Tic.Pw := Upper(TempStr);
               end else
               if (TempStr1='PATH') or (TempStr1='PATH:') then
               begin
                  delete(TempStr,1,length(TempStr1)+1);
                  L := TempStr;
                  PosDesc := 1;
                  PutDescrizione(Tic.PathList)
               end else
               if (TempStr1='SEENBY') or (TempStr1='SEENBY:') then
               begin
                  delete(TempStr,1,length(TempStr1)+1);
                  StripLeadingSpace(TempStr);
                  I := Pos(' ',TempStr);
                  if I=0 then
                     I := length(TempStr)+1;
                  if ParseAddr(Copy(TempStr,1,I-1),TempAddr,TempAddr) then
                     if AddNode(Tic.SeenBy,TempAddr,TicSend+TicReceive) then;
               end else
               if (TempStr1='CREATED') or (TempStr1='CREATED:') then
               begin
                  {ignora, rimpiazza con il mio}
                  delete(TempStr,1,length(TempStr1)+1);
                  StripLeadingSpace(TempStr);
                  CreatedBy := TempStr;
               end else
               if (TempStr1='TO') or (TempStr1='TO:') then
               begin
                  {ignora, rimpiazza con il mio}
               end else
               if (TempStr1='DESC') or (TempStr1='DESC:') then
               begin
                  Delete(TempStr,1,length(TempStr1)+1);
                  StripLeadingSpace(TempStr);
                  if TempStr<>'' then
                  begin
                     {Previene Hackeraggi via TICK}
                     {For I := 1 to length(TempStr) do
                        if TempStr[I]<#32 then TempStr[I] := '#';}
                     Tic.Desc := TempStr
                  end
               end else
               if (TempStr1='LDESC') or (TempStr1='LDESC:') then
               begin
                  Delete(TempStr,1,length(TempStr1)+1);
                  StripLeadingSpace(TempStr);
                  if TempStr<>'' then
                  begin
                     {Previene Hackeraggi via TICK}
                     {For I := 1 to length(TempStr) do
                        if TempStr[I]<#32 then TempStr[I] := '#';}
                     L := TempStr;
                     PosDesc := 1;
                     PutDescrizione(Tic.LDesc);
                  end;
               end else
               if (TempStr1='SIZE') or (TempStr1='SIZE:') then
               begin
                  delete(TempStr,1,length(TempStr1)+1);
                  StripLeadingSpace(TempStr);
                  I := pos(' ',TempStr);
                  if I=0 then
                     I := Length(TempStr) +1;
                  Val(Copy(TEmpStr,1,I-1),Tic.Size,Code);
                  if Code<>0 then
                  begin
                     Tic.Size := -1;
                  end;
               end else
               if (TempStr1='DATE') or (TempStr1='DATE:') then
               begin
                  delete(TempStr,1,length(TempStr1)+1);
                  StripLeadingSpace(TempStr);
                  I := pos(' ',TempStr);
                  if I=0 then
                     I := Length(TempStr) +1;
                  Val(Copy(TEmpStr,1,I-1),Tic.Time,Code);
                  if Code=0 then
                  begin
                     UnixtoDT(Tic.Time,DT);
                     PackTime(DT,Tic.Time)
                  end else
                  begin
                     Tic.Time := -1;
                  end;
               end else
               begin
                  L := TempStr;
                  PosDesc := 1;
                  PutDescrizione(Tic.UnKnown);
               end;
            end;
         end;
         Close(F);
         if Tic.Desc='' then
            Tic.Desc := OrfanoStr(Tic.NomeFile);
         {Controllo sui replace}
         TempReplace := Addr(Tic.Replaces);
         While (TempReplace^<>Nil) do
         begin
            TempStr := TempReplace^^.Descrizione^;
            FSplit(TempStr,Dr,Nr,Er);
            if (length(NR)<2) or (Pos(Copy(Nr,1,2),Tic.NomeFile)<>1) then
            begin
               L := TempStr;
               PosDesc := 1;
               PutDescrizione(Tic.InvReplaces);
               FreeMem(TempReplace^^.Descrizione,length(TempReplace^^.Descrizione^)+1);
               GetMem(TempReplace^^.Descrizione,1);
               TempReplace^^.Descrizione^ := '';
            end;
            TempReplace := Addr(TempReplace^^.Next);
         end;
         if (Tic.NomeFile<>'') and (Tic.AreaTag<>'') and
            (Tic.Pw<>'') then
         begin
            Writeln(' * Processing ',PrevN,' from ',AddrStr(Tic.From));
            Writeln(LogFile,Prelog(LogStart),'Processing ',PrevN,' from ',AddrStr(Tic.From));
            if CreatedBy <> '' then
            begin
               Writeln(' *  À ',CreatedBy);
               Writeln(LogFile,Prelog(LogWork),' À ',CreatedBy);
            end;
            Writeln(' * Area: ',Tic.AreaTag);
            Writeln(LogFile,Prelog(LogWork),'Area: ',Tic.AreaTag);
            Writeln(' * File: ',Tic.NomeFile);
            Writeln(LogFile,Prelog(LogWork),'File: ',Tic.NomeFile);
            Writeln(' * Desc: ',Tic.Desc);
            Writeln(LogFile,Prelog(LogWork),'Desc: ',Tic.Desc);
            Flush(LogFile);
            ReadTic := True;
         end else
            ReadTic := False;
      End else
      begin
         ReadTic := False;
      end;
   End else
   begin
      ReadTic := False
   end;
End {ReadTic};

Procedure SaveTic(Var N:String);
Var F:Text;
    F1: File;
   TempDescTypePtr : DescTypePtr;
   TempAddrListTypeRef: AddrListTypeRef;
Begin
   if Not MadeHoldTic then
   begin
      if MakePath(d0 + 'TICS') then;
      MadeHoldTic := True;
   end;
   Randomize;
   N := D0 + 'TICS\' + HexByte(Random(256)) +
      HexByte(Random(256)) + HexByte(Random(256)) + AppExt;
   Assign(F,N);
   {$I-}
   Rewrite(F);
   {$I+}
   if IOResult=0 then
   begin
      Writeln(F,'Area ',Tic.AreaTag);
      Writeln(F,'Origin ',AddrStr(Tic.Origin));
      Writeln(F,'From ',AddrStr(Tic.From));
      if Tic.AreaDesc<>'' then
         Writeln(F,'Areadesc ',Tic.AreaDesc);
      if Tic.Magic<>'' then
         Writeln(F,'Magic ',Tic.Magic);
      Writeln(F,'File ',Tic.NomeFile);
      Writeln(F,'Desc ',Tic.Desc);
      TempDescTypePtr := Tic.LDesc;
      While TempDescTypePtr<>Nil do
      begin
         Writeln(F,'Ldesc ',TempDescTypePtr^.Descrizione^);
         TempDescTypePtr := TempDescTypePtr^.Next
      end;
      Writeln(F,'Crc ',HexLong(Tic.Crc32));
      if Tic.Size>=0 then
         Writeln(F,'Size ',Tic.Size);
      if Tic.Time>=0 then
         Writeln(F,'Date ',ToUnixDate(Tic.Time));
      Writeln(F,'Created by LLIST ',Versione,
         ' - Copyright (C) ',CompYear,' by ',Autore);
      TempDescTypePtr := Tic.Replaces;
      while TempDescTypePtr<>Nil do
      begin
         if TempDescTypePtr^.Descrizione^<>'' then
            Writeln(F,'Replaces ',TempDescTypePtr^.Descrizione^);
         TempDescTypePtr := TempDescTypePtr^.Next
      end;
      TempDescTypePtr := Tic.InvReplaces;
      while TempDescTypePtr<>Nil do
      begin
         if TempDescTypePtr^.Descrizione^<>'' then
            Writeln(F,'Replaces ',TempDescTypePtr^.Descrizione^);
         TempDescTypePtr := TempDescTypePtr^.Next
      end;
      TempDescTypePtr := Tic.UnKnown;
      While TempDescTypePtr<>Nil do
      begin
         Writeln(F,TempDescTypePtr^.Descrizione^);
         TempDescTypePtr := TempDescTypePtr^.Next
      end;
      TempDescTypePtr := Tic.PaThList;
      While TempDescTypePtr<>Nil do
      begin
         Writeln(F,'Path ',TempDescTypePtr^.Descrizione^);
         TempDescTypePtr := TempDescTypePtr^.Next
      end;

      {Seen-By; non mette i numeri di point?}
      TempAddrListTypeRef := Tic.SeenBy;
      while (TempAddrListTypeRef<>Nil) do
      begin
         Writeln(F,'Seenby ',AddrStr(TempAddrListTypeRef^.Node));
         TempAddrListTypeRef := TempAddrListTypeRef^.Next;
      end;
      Writeln(F,'Pw ',Tic.Pw);
      Close(F);

      Assign(F1, N);
      Repeat
         RandoMize;
         N := d0 + 'TICS\' + 'LL' +
            HexByte(Random(256)) + HexByte(Random(256)) +
            HexByte(Random(256)) + '.TIC';
         {$I-}
         Rename(F1,N);
         {$I+}
      until (IOResult=0);

   End else
   begin
      Writeln(' * Can''t save .Tic');
      Writeln(LogFile,Prelog(logError),'Can''t save .Tic');
      Flush(LogFile);
      N := '';
   end;
end {SaveTic};



Procedure GetTicInfo;
Begin
   if Not GotTicInfo then
   begin
      ImportTic;
      GotTicInfo := True;
   end;
End {GetTicInfo};



Procedure SendFile(Dest:AddrType; NomeFile:String; Flavour:Char;
   Mode:SendMode; PackType:String);
Var Hlo:String;
   TempStr:String;
   I:Integer;
   PackedName:String;
   TMsg: AbsMsgPtr;
   MsgWriteError: Integer;
   TempDate: Longint;
   prevSort: SortType;

   Procedure TruncFile(NomeFile:String);
   Var F:File;
       fm: Word;
   Begin
      fm := FileMode;
      FileMode := FmReadWRite_DA;
      Assign(F,NomeFile);
      {$I-}
      Rewrite(F);
      {$I+}
      if IOResult=0 then
      begin
         Close(F)
      end;
      FileMode := Fm;
   End {TruncFile};

Begin
   if MailAttach then
   begin

      if NetAreaId<>'' then
      begin
         if PackType<>'' then
         begin
            I := 1;
            While (I<=NPacker) and (Packer[I]^.Ext<>PackType) do
               inc(I);
            if I>NPacker then
               I := 0;
         end else
            I := 0;

         if I>0 then
         begin

            TempLong := $FFFFFFFF;
            TempLong := UpdC32(Hi(Dest.Zone), TempLong);
            TempLong := UpdC32(Lo(Dest.Zone), TempLong);
            TempLong := UpdC32(Hi(Dest.Net), TempLong);
            TempLong := UpdC32(Lo(Dest.Net), TempLong);
            TempLong := UpdC32(Hi(Dest.Node), TempLong);
            TempLong := UpdC32(Lo(Dest.Node), TempLong);
            TempLong := UpdC32(Hi(Dest.Point), TempLong);
            TempLong := UpdC32(Lo(Dest.Point), TempLong);
            TempLong := TempLong XOR $FFFFFFFF;

            PackedName := HexLOng(TempLong);

            if packer[I]^.Ext[1]<>'T' then
                PackedName := D0 + 'TICS\' + PackedName + '.' + Packer[I]^.Ext[1] + 'IC'
            else
                PackedName := D0 + 'TICS\' + PackedName + '._IC';

            if Compress(PackedName,NomeFile,I) then
            begin
               TruncFile(NomeFile);
               NomeFile := PackedName
            end;

         end;

         MsgWriteError := 0;

         {qui devo togliere il ",2"}
         I := Pos(',',NetAreaId);
         if OpenOrCreateMsgArea(TMsg, Copy(NetAreaId,1,I-1)) then
         Begin
            TMsg^.SetMailType(mmtNetMail);
            {Cerca messaggi di F/A gia' esistenti}
            {Tmsg^.SeekFirst(0);
            while Tmsg^.SeekFound do
            begin
               TMsg^.MsgStartUp;
               if TMsg^.IsFAttach and (Upper(Tmsg^.GetSubj)=NomeFile) then
               begin
                  Tmsg^.GetOrig(TempAddr);
                  if AddrEqual(TempAddr, Dest) then
                     Tmsg^.DeleteMsg;
               end;
               Tmsg^.SeekNext;
            end;}

            TMsg^.StartNewMsg;       {initialize for adding msg}

            repeat
               TempDate := GetDosDate;
               Sleep;
            until (Lower(HexLong(ToUnixDate(Tempdate)))<>PrevMsgId);

            PrevMsgId := Lower(HexLong(ToUnixDate(Tempdate)));

            TMsg^.SetFrom(SysopName);           {Set from name}
            TMsg^.SetTo('Sysop');               {Set to name}
            TMsg^.SetSubj(NomeFile);

            TMsg^.SetDate(DateStr(TempDate));   {Set msg date mm-dd-yy}
            TMsg^.SetTime(TimeStr(TempDate));   {Set msg time hh:mm}
            TMsg^.SetEcho(True);                  {Should msg be echoed}
            TMsg^.SetRefer(0);

            Tmsg^.SetFAttach(True);

            Tmsg^.SetKillSent(True);

            Tmsg^.SetLocal(True);

            if Flavour='C' then
               Tmsg^.SetCrash(True);
            if Flavour='H' then
               Tmsg^.SetHold(True);

            Tmsg^.SetPriv(True);
            TMsg^.SetDest(Dest);

            I := 0;
            while (I<=NAka) and (Aka[I].Zone<>Dest.Zone) do
               inc(I);
            if I>NAka then
               I := 0;
            MsgOrigAddr := Aka[I];

            TMsg^.SetOrig(MsgOrigAddr);

            if Mode=SendDelete then
               Tmsg^.DoKludgeLn(#1 + 'FLAGS KFS');

            TMsg^.DoKludgeLn(#1 + 'MSGID: ' + AddrStr(MsgOrigAddr) + ' ' +
               PrevMsgId);

            TMsg^.DoKludgeLn(#1 + 'PID: LList ' + versione);

            MsgWriteError := Tmsg^.WriteMsg;

            if MsgWriteError=0 then
               NetWritten := True;

            if CloseMsgArea(TMsg) then;

         end;
      end;
   end else
   begin
      if Aka[0].Zone=Dest.Zone then
      begin
         Hlo := OutBound[0]^.OutBound^ + HexStr(Dest.Net) + HexStr(Dest.Node);
      end else
      begin
         I := 1;
         while (I<=NOutBound) and (OutBound[I]^.Zone<>Dest.Zone) do
            inc(I);
         if (I<=NOutBound) then
         begin
            Hlo := OutBound[I]^.OutBound^ + HexStr(Dest.Net) + HexStr(Dest.Node);
         end else
         begin
            Hlo := OutBound[0]^.OutBound^;
            Dec(Hlo[0]);
            I := length(Hlo);
            while (I>0) and (Hlo[I]<>'\') and (Hlo[I]<>'.') do
               dec(I);
            if (I>0) and (Hlo[I]='.') then
               Hlo := Copy(Hlo,1,I-1);
            Hlo := Hlo + '.' + Copy(HexStr(Dest.Zone),2,3) + '\' +
               HexStr(Dest.Net) + HexStr(Dest.Node);
         end;
      end;
      if Dest.Point<>0 then
      begin
         hlo := Hlo + '.PNT\0000' + HexStr(Dest.Point);
      end;

      {A questo punto crea la DIR}
      if MakePath(Copy(Hlo,1,length(Hlo)-9)) then;

      Lock(Hlo);

      if PackType<>'' then
      begin
         I := 1;
         While (I<=NPacker) and (Packer[I]^.Ext<>PackType) do
            inc(I);
         if I>NPacker then
            I := 0;
      end else
         I := 0;

      if I>0 then
      begin
         if packer[I]^.Ext[1]<>'T' then
             PackedName := Hlo + '.' + Packer[I]^.Ext[1] + 'IC'
         else
             PackedName := Hlo + '._IC';
         if Compress(PackedName,NomeFile,I) then
         begin
            TruncFile(NomeFile);
            NomeFile := PackedName
         end;
      end;

      if Mode=SendDelete then
         NomeFile := '^' + NomeFile;

      Prevsort := sort;
      sort := no;
      if AddFBbsLine(Hlo + '.' + Flavour + 'lo',NomeFile,Nil,No,Nil) then;
      sort := prevsort;

      Unlock(Hlo);
   end;
End {SendFile};


Procedure EchoFile(PathCopy:String; EchoNodes:AddrListTypeRef;
  Size:Longint);
Var SendTo, TempAddrLIstREf, TempAddrListRef1:AddrListTypeRef;
   I,J,K:Integer;
Begin
   UnpackTime(actDate,T1);
   {Aggiunge il mio path}
   L := AddrStr(Tic.From) + ' ' + Long2Str(ToUnixDate(ActDate),0) +
      ' ' + DayOfWeekStr(CurrDayOfWeek) + ' ' + MonthStr[T1.Month] +
      ' ' + NStr[T1.Day] +
      ' ' + NStr[T1.Hour] + ':' + NStr[T1.Min] +
      ':' + NStr[T1.Sec] + ' ' + Long2Str(T1.Year,0) +
      ' ' + Tz;
   PosDesc := 1;
   PutDescrizione(Tic.PathList);

   {Manda in Echo agli altri nodi}
   SendTo := Nil;
   {Mette il from nel SeenBy, cosi' non lo rimanda}
   {al mittente}
   if AddNode(Tic.SeenBy,Tic.From,TicSend+TicReceive) then;

   {aggiunge il miei nodi nel seenby}
   for I := 0 to NAka do
   begin
      if (Aka[I].Zone=Tic.From.Zone) then
         if AddNode(Tic.SeenBy,Aka[I],0) then;
   end;

   TempAddrListRef := EchoNodes;
   while TempAddrListRef<>Nil do
   begin
      if (TempAddrListRef^.Mode and TicSend <>0) then
      begin
         if AddNode(Tic.SeenBy,TempAddrListRef^.Node,0) then
         begin
            if AddNode(SendTo,TempAddrListRef^.Node,0) then;
         end;
      end;
      TempAddrListRef := TempAddrListRef^.Next
   end;

   TempAddrListRef := SendTo;
   while TempAddrListRef<>Nil do
   begin
      I := 1;
      While (I<=NTicNodes) and
        ( not AddrEqual(TicNodes[I]^.Node,TempAddrListRef^.Node)
        ) do inc(I);
     if I>NTicNodes then
     begin
        Writeln(' * Unknown tic node ',AddrStr(TempAddrListRef^.Node));
        Writeln(LogFile,Prelog(LogError),'Unknown tic node ',AddrStr(TempAddrListRef^.Node));
        Flush(LogFile);
     end else
     if (TicNodes[I]^.MaxFileSize<>0) and (TicNodes[i]^.MaxFileSize<Size) then
     begin
        Writeln(' * File too long for ',AddrStr(TempAddrListRef^.Node));
        Writeln(LogFile,Prelog(LogError),'File too long for ',AddrStr(TempAddrListRef^.Node));
        Flush(LogFile);
        {avvisa il sysop tramite mail}
        PathAll := D0 + HexLong(ToUnixDate(GetDosDate)) + AppExt;
        Assign(AllFiles,PathAll);
        Rewrite(AllFiles);
        if IOResult=0 then
        begin
           if Message[50]<>Nil then
              TempStr := Message[50]^
           else
              TempStr := 'File %1 in area %2 not sent due to excessive size %3';
           SubstPar(TempStr,Tic.NomeFile,'1');
           SubstPar(TempStr,Tic.Areatag,'2');
           SubstPar(TempStr,long2str(size,0),'3');
           Writeln(AllFiles,Tempstr);
           MsgDestAddr := TicNodes[I]^.Node;
           K := 0;
           While (K<=NAka) and (Aka[K].Zone<>MsgDestAddr.Zone) do
              inc(K);
           if K>NAka then
              K := 0;
           MsgOrigAddr := Aka[K];
           MsgFrom := 'LLIST ' + versione;
           MsgTo := 'Sysop';
           if message[72]=Nil then
              MsgSubject := 'Unsent file'
           else
              MsgSubject := Message[72]^;
           Close(AllFiles);
           PostAnnunciNews(NetAreaId);
           if EraseFile(PathAll) then;
        end;
     end else
     begin
        if MarkDupeTic(Tic.NomeFile,Tic.AreaTag,TicNodes[I]^.Node,Size,
           False) then;
        SendFile(TicNodes[I]^.Node,PathCopy+Tic.NomeFile,TicNodes[I]^.Flavour,
           SendOnly,'');
        if TicNodes[I]^.SendTic then
        begin
           Tic.Pw := TicNodes[I]^.Pw;
           if TicNodes[I]^.TinySeenBy then
           begin
              TempAddrListRef1 := Tic.SeenBy;
              Tic.SeenBy := Nil;
              if AddNode(Tic.SeenBy,Tic.From,TicSend+TicReceive) then;
              {aggiunge il miei nodi nel seenby}
              for J := 0 to NAka do
              begin
                 if (Aka[J].Zone=Tic.From.Zone) then
                    if AddNode(Tic.SeenBy,Aka[J],0) then;
              end;
              if AddNode(Tic.SeenBy,TicNodes[I]^.Node,TicSend+TicReceive) then;
           end;
           SaveTic(TempStr);
           if TempStr<>'' then
           begin
              SendFile(TicNodes[I]^.Node,TempStr,TicNodes[I]^.Flavour,SendDelete,
                 TicNodes[I]^.Packer)
           end;
           if TicNodes[I]^.TinySeenBy then
           begin
              DeleteNodes(Tic.SeenBy);
              Tic.SeenBy := TempAddrListRef1
           end;
        end;
        Writeln(' * Sent to ',AddrStr(TicNodes[I]^.Node));
        Writeln(LogFile,Prelog(LogDone),'Sent to ',AddrStr(TicNodes[I]^.Node));
        Flush(LogFile);
     end;
     TempAddrListRef := TempAddrListRef^.Next
   End;
   DeleteNodes(SendTo);
End {EchoFile};


Procedure Hatch(PathFile,NomeFile,Replace,Magic:String; Descrizione:DescTypePtr;
   EchoNodes:AddrListTypeRef; AreaTag, SecTag:String; TicAddr:AddrType;
   Size, Time: Longint; AreaName: String);
Var TempDesc:DescTypePtr;
    CurrTicArea:Integer;
Begin
   Writeln(' * Hatch ',NomeFile,' in area ',AreaTag);
   Writeln(LogFile,Prelog(LogStart),'Hatch ',NomeFile,' in area ',AreaTag);
   Flush(LogFile);
   if Magic<>'' then
   begin
      {Aggiorna la lista dei Magics}
      TempDesc := Nil;
      L := PathFile + NomeFile + ' ' +
         Descrizione^.Descrizione^;
      PosDesc := 1;
      PutDescrizione(TempDesc);
      if AddFBbsLine(D0+'Magic.Cfg',Upper(Magic),TempDesc,Alfa,Nil) then;
      CancellaDescrizione(TempDesc);
   end;
   CancellaDescrizione(Tic.UnKnown);
   Tic.UnKnown := Nil;
   CancellaDescrizione(Tic.PathList);
   Tic.PathList := Nil;
   DeleteNodes(Tic.SeenBy);
   Tic.SeenBy := Nil;
   CancellaDescrizione(Tic.LDesc);
   Tic.LDesc := Nil;
   CancellaDescrizione(Tic.Replaces);
   Tic.Replaces := Nil;
   CancellaDescrizione(Tic.InvReplaces);
   Tic.InvReplaces := Nil;
   Tic.AreaTag := AreaTag;
   Tic.Size := Size;
   Tic.Time := Time;
   Tic.Magic := Magic;
   Tic.Pw := '';
   Tic.AreaDesc := AreaName;
   FillChar(Tic.From,SizeOf(AddrType),0);
   {Ricava i vari dati};
   Tic.NomeFile := NomeFile;
   if Replace<>'' then
   begin
      L := Replace;
      PosDesc := 1;
      PutDescrizione(Tic.Replaces)
   end;
   Tic.Crc32 := FileCrc32(PathFile + NomeFile);
   Tic.Origin := TicAddr;
   Tic.From := TicAddr;
   Tic.Desc := Descrizione^.Descrizione^;
   TempDesc := Descrizione^.Next;
   while (TempDesc<>Nil) do
   begin
      L := TempDesc^.Descrizione^;
      if Pos(UploaderStr, L)=0 then
      begin
         StripAvt(L);
         PosDesc := 1;
         PutDescrizione(Tic.LDesc);
      end else
      begin
         Delete(L,1,length(Uploaderstr));
         StripLeadingSpace(L);
         if ParseAddr(L, TempAddr, TempAddr) then
            Tic.Origin := TempAddr;
      end;
      TempDesc := TempDesc^.Next
   end;
   if Tic.LDesc=Nil then
   begin
      L := Tic.Desc;
      PosDesc := 1;
      PutDescrizione(Tic.LDesc);
   end;

   PathDown := PathFile;
   EchoFile(PathDown, EchoNodes, Tic.Size);

   if SecTag<>'' then
   begin
      CurrTicArea := 1;
      While (CurrTicArea<=NTicAreas) and
         (TicAreas[CurrTicArea]^.Tag <> SecTag) do
      begin
         inc(CurrTicArea);
      end;
      if CurrTicArea>NTicAreas then
      begin
         Writeln(' * Invalid Secondary Area ',SecTag);
         Writeln(Logfile,Prelog(LogError),'Invalid Secondary Area ',SecTag);
         Flush(LogFile);
      end else
      begin
         Writeln(' * Hatch in Secondary Area ',SecTag);
         Writeln(Logfile,Prelog(LogStart),'Hatch in Secondary Area ',SecTag);
         Flush(LogFile);
         Tic.From := Aka[TicAreas[CurrTicArea]^.Address];
         Tic.AreaTag := SecTag;
         EchoFile(PathDown,TicAreas[CurrTicArea]^.Nodes,Tic.Size)
      end;
   end
End {Hatch};


Function SubNode(Var Pnt:AddrListTypeRef; Address:AddrType): Boolean;
var Temp:AddrListTypeRef;
Begin
   if Pnt<>Nil then
   begin
      if AddrEqual(Pnt^.Node,Address) then
      begin
         Temp := Pnt;
         Pnt := Pnt^.Next;
         Dispose(Temp);
         SubNode := True;
      end else
         SubNode := SubNode(Pnt^.Next,Address);
   end else
      SubNode := False;
end {SubNode};


Function GetChkTime(Days:Word):Longint;
Var Dt:DateTime;
    Temp:Longint;
Begin
   UnpackTime(ActDate,DT);
   JulianToGregorian(GregorianToJulian(DT)-Days,Integer(Dt.Year),
      Integer(Dt.Month),Integer(Dt.Day));
   Dt.Hour := 0;
   Dt.Min := 0;
   Dt.Sec := 0;
   PackTime(Dt,Temp);
   GetChkTime := Temp;
End {GetChkTime};


Procedure Raid;
Var TempAddr:AddrType;
    Found:Boolean;
    {$IFDEF VIRTUALPASCAL}
    Code: Longint;
    {$ENDIF}
    RaidFwd: RaidFwdType;
    RaidFwdFile: File;
    TempLong: Longint;

   Function Mega(Bytes:Longint):String;
   Begin
      Bytes := Bytes div 104858;
      if Bytes=0 then
      begin
         Mega := '----';
      end else
      begin
         if Bytes div 10 > 0 then
         begin
            Mega := Long2Str(Bytes div 10,2) + '.' + Long2Str(Bytes mod 10,0);
         end else
         begin
            Mega := '  .' + Long2Str(Bytes mod 10,0);
         end;
      end;
   End;

   Function Raid1:Boolean;
   Var
       TempAddrListTypeRef: AddrListTypeRef;
       I:INteger;
       ChkTime:Longint;
       RescanDays:Integer;
       Password:String;
       NewLev:Word;
       CurrTicNode:Integer;
       MsgOut: AbsMsgPtr;
       MsgReadError:Integer;
       Last:Longint;
       TempStr, TempStr1:String;
       AnsDone:Boolean;
       RemoteMaint:Boolean;
       MakeList, MakeQuery, MakeRescan:Boolean;
       TempDescTypePtr:DescTypePtr;
       TempNodes:AddrListTypeRef;
       NAreas:Integer;
       RescanAreas: ListaNumRef;
       EmptyStr: String;

      Procedure WriteHelp;
      Var HelpText:Text;
          TempStr:String;
      Begin
         Writeln(AllFiles);
         Assign(HelpText,D0+'Raid.Hlp');
         {$I-}
         Reset(HelpText);
         {$I+}
         if IOResult=0 then
         begin
            while not eof(HelpText) do
            begin
               ReadLn(HelpText,TempStr);
               Writeln(AllFiles,TempStr);
            end;
            close(HelpText);
         end else
         begin
            Writeln(AllFiles,'%HELP    Info about use of RAID');
            Writeln(AllFiles,'%LIST    Index of available file areas');
            Writeln(AllFiles,'%QUERY   Index of linked file areas');
            Writeln(AllFiles,'%UNLINKED Index of unlinked file areas');
            Writeln(AllFiles,'%RESEND <FileName> Resend file that matches <FileName>');
            Writeln(AllFiles,'%RESCAN  Send all files in areas linked after this line');
            Writeln(AllFiles,'%DAYS <n> Max days for rescan');
            Writeln(AllFiles,'%INFO    Some info about your node');
            Writeln(AllFiles,'%AUTOLINK [-]GROUPTAG AutoLink to new created areas of',
              ' selected group');
            Writeln(AllFiles,'%[-]NOTIFY Set Notify status');
            Writeln(AllFiles,'%[-]TINYSEENBY Set TinySeenBy status');
            Writeln(AllFiles,'%[-]ANNOUNCE Set Announce status');
            Writeln(AllFiles,'%[-]SENDTIC Set SendTic status');
            Writeln(allfiles,'%MAXFILESIZE <n> Max size of forwarded files');
            if RemoteMaint then
            begin
               Writeln(AllFiles,'%FROM <Address> Allow remote maintenance for other node');
               Writeln(AllFiles,'%ECHO    Global echo file info');
               Writeln(AllFiles,'%LEVEL <n> Set new level');
            end;
            Writeln(AllFiles,'%PWD <password> Change your TIC password');
            Writeln(AllFiles,'%PACKER <packer> Change your packer');
            Writeln(AllFiles,'%[+]ALL  Add all areas');
            Writeln(AllFiles,'%-ALL    Remove all areas');
            Writeln(AllFiles,'[+]AREATAG Add area AREATAG');
            Writeln(AllFiles,'-AREATAG Remove area AREATAG');
         end;
         Writeln(AllFiles);
      end;

      Procedure UnsubScribeArea(TempStr: String);
      Var
         I:Integer;
         Found: Boolean;
      begin
         if CurrTicNode<>0 then
         begin
            if ParseSubject(TempStr,False,True) then
            begin
               Found := False;
               I := 1;
               repeat
                  while (I<=NTicAreas) and
                    (
                     (TicAreas[I]^.TicLevel > TicNodes[CurrTicNode]^.TicLevel) or
                     (Aka[TicAreas[I]^.Address].Zone <> TicNodes[CurrTicNode]^.Node.Zone) or
                     not IsSearched(TicAreas[I]^.Tag,EmptyStr,1)
                    ) do
                    inc(I);
                  if (I<=NTicAreas) then
                  begin
                     Found := True;
                     if (TicAreas[I]^.TicLevel <= TicNodes[CurrTicNode]^.TicLevel) and
                        SubNode(TicAreas[I]^.Nodes,TicNodes[CurrTicNode]^.Node) then
                     begin
                        if message[56]=nil then
                           TempStr1 := 'Area %1 removed'
                        else
                           TempStr1 := Message[56]^;
                        Substpar(TempStr1,TicAreas[i]^.Tag,'1');
                        writeln(AllFiles,TempStr1);
                        Writeln(' * Area ',TicAreas[I]^.tag,' removed');
                        Writeln(LogFile,Prelog(LogWork),'Area ',TicAreas[I]^.tag,' removed');
                        Flush(LogFile);
                        {TicAreasModified := True;}
                        TicCfgModified := True;
                     end else
                     begin
                        if message[54]=nil then
                           TempStr1 := 'Area %1 was not linked'
                        else
                           TempStr1 := Message[54]^;
                        Substpar(TempStr1,TicAreas[i]^.Tag,'1');
                        writeln(AllFiles,TempStr1);
                     end;
                     inc(i)
                  end;
               until (I>NTicAreas);
               if not found then
               begin
                  if message[55]=nil then
                     TempStr1 := 'Area %1 not found'
                  else
                     TempStr1 := Message[55]^;
                  Substpar(TempStr1,Tempstr,'1');
                  Writeln(AllFiles, TempStr1);
               end;
            end;
         end;
      end {unsubscribeArea};

      Procedure UnsubScribeGroup(TempStr: String);
      Var
         I:Integer;
         Found: Boolean;
      begin
         if CurrTicNode<>0 then
         begin
            if ParseSubject(TempStr,False,True) then
            begin
               Found := False;
               I := 1;
               repeat
                  while (I<=NTicGroups) and
                    (
                     (TicGroups[I]^.TicLevel > TicNodes[CurrTicNode]^.TicLevel) or
                     (Aka[TicGroups[I]^.Address].Zone <> TicNodes[CurrTicNode]^.Node.Zone) or
                     not IsSearched(TicGroups[I]^.Tag,EmptyStr,1)
                    ) do
                    inc(I);
                  if (I<=NTicGroups) then
                  begin
                     Found := True;
                     if (TicGroups[I]^.TicLevel <= TicNodes[CurrTicNode]^.TicLevel) and
                        SubNode(TicGroups[I]^.Nodes,TicNodes[CurrTicNode]^.Node) then
                     begin
                        if message[57]=nil then
                           TempStr1 := 'Group %1 removed'
                        else
                           TempStr1 := Message[57]^;
                        Substpar(TempStr1,TicGroups[i]^.Tag,'1');
                        writeln(AllFiles,TempStr1);
                        Writeln(' * Group ',TicGroups[I]^.tag,' removed');
                        Writeln(LogFile,Prelog(LogWork),'Group ',TicGroups[I]^.tag,' removed');
                        Flush(LogFile);
                        {TicAreasModified := True;}
                        TicAreasModified := True;
                     end else
                     begin
                        if message[58]=nil then
                           TempStr1 := 'Group %1 was not linked'
                        else
                           TempStr1 := Message[58]^;
                        Substpar(TempStr1,TicGroups[i]^.Tag,'1');
                        writeln(AllFiles,TempStr1);
                     end;
                     inc(i)
                  end;
               until (I>NTicGroups);
               if not found then
               begin
                  if message[59]=nil then
                     TempStr1 := 'Group %1 not found'
                  else
                     TempStr1 := Message[59]^;
                  Substpar(TempStr1,Tempstr,'1');
                  Writeln(AllFiles, TempStr1);
               end;
            end;
         end;
      end {unsubscribeGroup};

      Procedure SubscribeArea(TempStr: String);
      Var
         Found: Boolean;
         I: Integer;
      begin
         if CurrTicNode<>0 then
         begin
            If ParseSubject(TempStr,False,True) then
            begin
               Found := False;
               I := 1;
               repeat
                  while (I<=NTicAreas) and
                    (
                     (TicAreas[I]^.TicLevel > TicNodes[CurrTicNode]^.TicLevel) or
                     (Aka[TicAreas[I]^.Address].Zone <> TicNodes[CurrTicNode]^.Node.Zone) or
                     Not IsSearched(TicAreas[I]^.Tag,EmptyStr,1)
                    ) do
                    inc(I);
                  if (I<=NTicAreas) then
                  begin
                     Found := True;
                     if AddNode(TicAreas[I]^.Nodes,TicNodes[CurrTicNode]^.Node,
                         TicAreas[I]^.mode) then
                     begin
                        if message[60]=nil then
                           TempStr1 := 'Area %1 added'
                        else
                           TempStr1 := Message[60]^;
                        Substpar(TempStr1,TicAreas[i]^.Tag,'1');
                        writeln(AllFiles,TempStr1);
                        Writeln(' * Area ',TicAreas[I]^.tag,' added');
                        Writeln(LogFile,Prelog(LogWork),'Area ',TicAreas[I]^.tag,' added');
                        Flush(LogFile);
                        {TicAreasModified := True;}
                        TicCfgModified := True;
                     end else
                     begin
                        if message[61]=nil then
                           TempStr1 := 'Area %1 already linked'
                        else
                           TempStr1 := Message[61]^;
                        Substpar(TempStr1,TicAreas[i]^.Tag,'1');
                        writeln(AllFiles,TempStr1);
                     end;
                     if MakeRescan then
                        PutInListaAree(I,I,RescanAreas);
                     inc(i)
                  end;
               until (I>NTicAreas);
               if TicNodes[CurrTicNode]^.RequireUplink then
               begin
                  {cerca anche tra le aree disponibili sugli uplinks}
                  TempDescTypePtr := AvailableTicAreas;
                  While (NTicAreas<NMaxTicAreas) and (TempDescTypePtr<>Nil) do
                  begin
                     I := pos(' ',TempDescTypePtr^.Descrizione^);
                     TempStr := Copy(TempDescTypePtr^.Descrizione^,1,I-1);
                     if IsSearched(TempStr,EmptyStr,1) then
                     begin
                        Found := True;
                        {Cerca il gruppo}
                        I := 1;
                        while (I<=NTicGroups) and
                          (
                           not ChkGroup(TempStr,TicGroups[I]^.GroupId)
                          ) do inc(I);
                        if (I<=NTicGroups) and (TicGroups[I]^.UplinkNode>0) and
                           (TicGroups[I]^.TicLevel<=TicNodes[CurrTicNode]^.TicLevel) and
                           (Aka[Ticgroups[I]^.Address].Zone=TicNodes[CurrTicNode]^.Node.Zone) then
                        begin
                           {creazione nuova area}
                           CreateFlagFile(D0+'NewAreas.Flg');
                           if message[62]=nil then
                              TempStr1 := 'Area %1 required from uplink'
                           else
                              TempStr1 := Message[62]^;
                           Substpar(TempStr1,TicAreas[i]^.Tag,'1');
                           Writeln(AllFiles,TempStr1);
                           L := TempStr;
                           PosDesc := 1;
                           PutDescrizione(TicNodes[TicGroups[I]^.UplinkNode]^.RequireTicAreasRef^);
                           TicNodes[TicGroups[I]^.UplinkNode]^.RequireTicAreasRef :=
                              Addr(TicNodes[TicGroups[I]^.UplinkNode]^.
                                 RequireTicAreasRef^^.Next);

                           FillChar(RaidFwd, sizeOf(RaidFwdType), 0);
                           RaidFwd.Tag := TempStr;
                           RaidFwd.Received := False;
                           RaidFwd.Node := TicNodes[CurrTicNode]^.Node;
                           RaidFwd.Time := actdate;

                           Assign(RaidFwdFile, d0 + 'RaidFwd.Dup');
                           {$I-}
                           reset(raidFwdFile,1);
                           {$I+}
                           if (IoResult<>0) then
                              rewrite(RaidFwdFile,1);
                           seek(RaidFwdFile, FileSize(RaidFwdFile));
                           blockWrite(RaidFwdFile, RaidFwd, sizeOf(RaidFwdType));
                           close(RaidFwdFile);

                        end
                     end
                  end
               end;
               if Not Found then
               begin
                  if message[55]=nil then
                     TempStr1 := 'Area %1 not found'
                  else
                     TempStr1 := Message[55]^;
                  Substpar(TempStr1,Tempstr,'1');
                  Writeln(AllFiles, TempStr1);
               end;
            end;
         end;
      end {SubscribeArea};

      Procedure SubscribeGroup(TempStr: String);
      Var
         Found: Boolean;
         I: Integer;
      begin
         if CurrTicNode<>0 then
         begin
            If ParseSubject(TempStr,False,True) then
            begin
               Found := False;
               I := 1;
               repeat
                  while (I<=NTicGroups) and
                    (
                     (TicGroups[I]^.TicLevel > TicNodes[CurrTicNode]^.TicLevel) or
                     (Aka[TicGroups[I]^.Address].Zone <> TicNodes[CurrTicNode]^.Node.Zone) or
                     Not IsSearched(TicGroups[I]^.Tag,EmptyStr,1)
                    ) do
                    inc(I);
                  if (I<=NTicGroups) then
                  begin
                     Found := True;
                     if AddNode(TicGroups[I]^.Nodes,TicNodes[CurrTicNode]^.Node,
                         TicSend + TicReceive) then
                     begin
                        if message[63]=nil then
                           TempStr1 := 'Group %1 added'
                        else
                           TempStr1 := Message[63]^;
                        Substpar(TempStr1,TicGroups[i]^.Tag,'1');
                        writeln(AllFiles,TempStr1);
                        Writeln(' * Group ',TicGroups[I]^.tag,' added');
                        Writeln(LogFile,Prelog(LogWork),'Group ',
                           TicGroups[I]^.tag,' added');
                        Flush(LogFile);
                        {TicAreasModified := True;}
                        TicAreasModified := True;
                     end else
                     begin
                        if message[64]=nil then
                           TempStr1 := 'Group %1 already linked'
                        else
                           TempStr1 := Message[64]^;
                        Substpar(TempStr1,TicGroups[i]^.Tag,'1');
                        writeln(AllFiles,TempStr1);
                     end;
                     inc(i)
                  end;
               until (I>NTicGroups);
               if Not Found then
               begin
                  if message[59]=nil then
                     TempStr1 := 'Group %1 not found'
                  else
                     TempStr1 := Message[59]^;
                  Substpar(TempStr1,Tempstr,'1');
                  Writeln(AllFiles, TempStr1);
               end;
            end;
         end;
      end {SubscribeGroup};

      Procedure RescanFileBase;
      Var I:Integer;
      Begin
         if CurrTicNode<>0 then
         for I := 1 to NTicAreas do
         if IsInLista(I,RescanAreas) and
            NodeMember(TicAreas[I]^.Nodes,TicNodes[CurrTicNode]^.Node,TicSend) then
         begin
            if TicAreas[I]^.Number>=0 then
               Lock(D0+'Area' + long2Str(TicAreas[I]^.Number,0));
            Writeln(' * Rescan ',TicAreas[I]^.Tag);
            Writeln(LogFile,Prelog(LogWork),'Rescan ',TicAreas[I]^.Tag);
            Flush(LogFile);
            TempNodes := Nil;
            if AddNode(TempNodes,TicNodes[CurrTicNode]^.Node,TicSend) then;
            PathDown := TicAreas[I]^.DownLoad;
            FindFirst(PathDown+'*.*',Archive+ReadOnly,S);
            While (DosError=0) do
            begin
               if S.Time >= ChkTime then
               begin
                  TempDescTypePtr :=
                     GetDesc(S.Name,TicAreas[I]^.DownLoad+'Files.Bbs');
                  if (TempDescTypePtr<>Nil) then
                  begin
                     if message[65]=nil then
                        TempStr1 := 'Resend %1 in area %2'
                     else
                        TempStr1 := Message[65]^;
                     Substpar(TempStr1,S.Name,'1');
                     Substpar(TempStr1,TicAreas[i]^.tag,'2');
                     Writeln(AllFiles,TempStr1);
                     Hatch(TicAreas[I]^.Download,S.Name,S.Name,'',
                        TempDescTypePtr,
                        TempNodes, TicAreas[I]^.Tag, '',
                        Aka[TicAreas[I]^.Address],S.Size,S.Time,TicAreas[i]^.AreaDesc);
                  end;
                  CancellaDescrizione(TempDescTypePtr);
               end;
               FindNext(S);;
            end;
            DeleteNodes(TempNodes);
            if TicAreas[I]^.Number>=0 then
               UnLock(D0+'Area' + long2Str(TicAreas[I]^.Number,0));
         end;
         RemoveListaNum(RescanAreas);
         RescanAreas := Nil;
      end {RescanFileBase};

      Procedure DisplayAreaList(ShowLinked, ShowUnLinked:Boolean);
      Var I,J,PrevAreas: Integer;
      Begin
         if CurrTicNode<>0 then
         begin
            NAreas := 0;
            Writeln(AllFiles);
            if ShowLinked and ShowUnLinked then
            begin
               if message[73]=nil then
                  Writeln(AllFiles,'Index of available file areas')
               else
                  Writeln(AllFiles,Message[73]^);
            end else
            if ShowLinked then
            begin
               if message[74]=nil then
                  Writeln(AllFiles,'Index of linked file areas')
               else
                  Writeln(AllFiles,Message[74]^);
            end else
            begin
               if message[75]=nil then
                  Writeln(AllFiles,'Index of unlinked file areas')
               else
                  Writeln(AllFiles,Message[75]^);
            end;
            if Message[76]=Nil then
               Writeln(AllFiles,'"*" Linked, "+" linked (can''t be unlinked), "-" can''t be linked')
            else
               Writeln(AllFiles,Message[76]^);
            for I := 1 to NTicAreas do
            if (TicAreas[I]^.Group='') or (TicAreas[I]^.Group[1]='!') then
            begin
               if (Aka[TicAreas[I]^.Address].Zone=TicNodes[CurrTicNode]^.Node.Zone) then
               begin
                  if NodeMember(TicAreas[I]^.Nodes,TicNodes[CurrTicNode]^.Node,
                      TicSend+TicReceive) then
                  begin
                     if ShowLinked then
                     begin
                        if ticAreas[I]^.TicLevel<=TicNodes[CurrTicNode]^.TicLevel then
                           write(AllFiles,'*')
                        else
                           Write(AllFiles,'+');
                        write(AllFiles,TicAreas[I]^.Tag,'':21-length(TicAreas[I]^.Tag),
                           TicAreas[I]^.TicLevel:5,
                           TicMode2String(TicAreas[I]^.Mode):3,' ',
                           Mega(TicAreas[I]^.BytesMonth));
                        if TicAreas[I]^.AreaDesc<>'' then
                           Write(AllFiles,' ',TicAreas[I]^.AreaDesc);
                        writeln(AllFiles);
                        Inc(NAreas);
                     end;
                  end else
                  if ShowUnLinked then
                  begin
                     if TicAreas[I]^.TicLevel>TicNodes[CurrTicNode]^.TicLevel then
                        Write(AllFiles,'-')
                     else
                        Write(AllFiles,' ');
                     write(AllFiles,TicAreas[I]^.Tag,'':21-length(TicAreas[I]^.Tag),
                        TicAreas[I]^.TicLevel:5,
                        TicMode2String(TicAreas[I]^.Mode):3,' ',
                        Mega(TicAreas[I]^.BytesMonth));
                     if TicAreas[I]^.AreaDesc<>'' then
                        Write(AllFiles,' ',TicAreas[I]^.AreaDesc);
                     writeln(AllFiles);
                     Inc(NAreas);
                  end;
               end else
               if ShowLinked and NodeMember(TicAreas[I]^.Nodes,TicNodes[CurrTicNode]^.Node,
                      TicSend+TicReceive) then
               begin
                  write(AllFiles,'-',TicAreas[I]^.Tag,'':21-length(TicAreas[I]^.Tag),
                     TicAreas[I]^.TicLevel:5,
                     TicMode2String(TicAreas[I]^.Mode):3,' ',
                     Mega(TicAreas[I]^.BytesMonth));
                  if TicAreas[I]^.AreaDesc<>'' then
                     Write(AllFiles,' ',TicAreas[I]^.AreaDesc);
                  writeln(AllFiles);
                  Inc(NAreas);
               end;
            end;
            For J:=1 to NTicGroups do
            begin
               Write(AllFiles,'Group: ');
               if NodeMember(TicGroups[J]^.Nodes,TicNodes[CurrTicNode]^.Node,
                   TicSend+TicReceive) then
                  write(AllFiles,'*')
               else
                  Write(AllFiles,' ');
               Writeln(AllFiles,TicGroups[J]^.Tag);
               for I := 1 to NTicAreas do
               if TicAreas[I]^.Group=TicGroups[J]^.Tag then
               begin
                  if (Aka[TicAreas[I]^.Address].Zone=TicNodes[CurrTicNode]^.Node.Zone) then
                  begin
                     if NodeMember(TicAreas[I]^.Nodes,TicNodes[CurrTicNode]^.Node,
                         TicSend+TicReceive) then
                     begin
                        if Showlinked then
                        begin
                           if ticAreas[I]^.TicLevel<=TicNodes[CurrTicNode]^.TicLevel then
                              write(AllFiles,'*')
                           else
                              Write(AllFiles,'+');
                           write(AllFiles,TicAreas[I]^.Tag,'':21-length(TicAreas[I]^.Tag),
                              TicAreas[I]^.TicLevel:5,
                              TicMode2String(TicAreas[I]^.Mode):3,' ',
                              Mega(TicAreas[I]^.BytesMonth));
                           if TicAreas[I]^.AreaDesc<>'' then
                              Write(AllFiles,' ',TicAreas[I]^.AreaDesc);
                           writeln(AllFiles);
                           Inc(NAreas);
                        end
                     end else
                     if showunlinked then
                     begin
                        if TicAreas[I]^.TicLevel>TicNodes[CurrTicNode]^.TicLevel then
                           Write(AllFiles,'-')
                        else
                           Write(AllFiles,' ');
                        write(AllFiles,TicAreas[I]^.Tag,'':21-length(TicAreas[I]^.Tag),
                           TicAreas[I]^.TicLevel:5,
                           TicMode2String(TicAreas[I]^.Mode):3,' ',
                           Mega(TicAreas[I]^.BytesMonth));
                        if TicAreas[I]^.AreaDesc<>'' then
                           Write(AllFiles,' ',TicAreas[I]^.AreaDesc);
                        writeln(AllFiles);
                        Inc(NAreas);
                     end;
                  end else
                  if ShowLinked and NodeMember(TicAreas[I]^.Nodes,TicNodes[CurrTicNode]^.Node,
                         TicSend+TicReceive) then
                  begin
                     write(AllFiles,'-',TicAreas[I]^.Tag,'':21-length(TicAreas[I]^.Tag),
                        TicAreas[I]^.TicLevel:5,
                        TicMode2String(TicAreas[I]^.Mode):3,' ',
                        Mega(TicAreas[I]^.BytesMonth));
                     if TicAreas[I]^.AreaDesc<>'' then
                        Write(AllFiles,' ',TicAreas[I]^.AreaDesc);
                     writeln(AllFiles);
                     Inc(NAreas);
                  end;
               end;
               if ShowUnLinked and (AvailableTicAreas<>Nil) and
                  (TicGroups[J]^.Uplinknode<>-1) then
               begin
                  PrevAreas := NAreas;
                  TempDescTypePtr := AvailableTicAreas;
                  While TempDescTypePtr<>Nil do
                  begin
                     I := pos(' ',TempDescTypePtr^.Descrizione^);
                     TempStr := Upper(Copy(TempDescTypePtr^.Descrizione^,1,I-1));
                     I := 1;
                     while (I<=NTicGroups) and not ChkGroup(TempStr,
                         TicGroups[I]^.GroupId) do
                        inc(I);
                     if I=J then
                     begin
                        if PrevAreas=NAreas then
                           Writeln(AllFiles,' * Following areas are currently available from ',
                              AddrStr(TicNodes[TicGroups[J]^.UplinkNode]^.Node));
                        if TicNodes[CurrTicNode]^.RequireUplink then
                        begin
                           if (TicGroups[I]^.TicLevel <= TicNodes[CurrTicNode]^.TicLevel) and
                               (Aka[TicGroups[I]^.Address].Zone=
                                 TicNodes[CurrTicNode]^.Node.Zone) then
                              Write(AllFiles,' ')
                           else
                              Write(AllFiles,'-');
                        end else
                           Write(AllFiles,'-');
                        Writeln(AllFiles,TempDescTypePtr^.Descrizione^);
                        inc(NAreas);
                     end;
                     TempDescTypePtr := TempDescTypePtr^.Next
                  end;
               end;
            end;
            Writeln(AllFiles,'Total of ',NAreas,' file areas');
            Writeln(AllFiles);
         end;
      end {DisplayAreaList};

   begin

      MsgReadError := 0;

      Writeln(' * Searching RAID Msg...');
      Writeln(LogFile,PreLog(LogStart),'Searching RAID Msg...');
      Flush(LogFile);

      AnsDone := False;

      {devo togliere il ",2"}
      I := pos(',',NetAreaId);

      if Not QuietMode then
         Write(' * Scanning Msg Area ',Copy(NetAreaID,1,I-1));
      Writeln(LogFile,PreLog(LogWork),'Scanning Msg Area ',Copy(NetAreaID,1,I-1));
      Flush(LogFile);

      MsgReadError := 0;

      if OpenMsgArea(MsgOut, Copy(NetAreaId,1,I-1)) then
      begin
         if Not QuietMode then
         begin
            Last := MsgOut^.GetHighMsgNum;
            I := WhereX;
            write(0:8,' / ',Last);
            GotoXY(I,WhereY);
         end;

         MsgOut^.SetMailType(mmtNetMail);
         MsgOut^.SeekFirst(StartingMsg);

         While not AnsDone and MsgOut^.SeekFound Do
         Begin

            MsgOut^.MsgStartUp;

            if not QuietMode then
               Write(MsgOut^.GetMsgDisplayNum:8,#8#8#8#8#8#8#8#8);

            TempStr := Upper(MsgOut^.GetTo);
            if MsgToLlist(TempStr) and not MsgOut^.IsRcvd then
            begin

               MsgOut^.GetDest(TempAddr);

               {e' per me se trovo un aka valido}
               I := 0;
               while (I<=NAka) and
                   (not AddrEqual(TempAddr,Aka[I])) do
                  inc(I);
               if I>NAka then
               begin
                  TempStr := '';
               end else
               begin
                  MsgOrigAddr := Aka[I];
                  MsgOut^.GetOrig(MsgDestAddr);
                  {Nothing to do}
               end;

               if TempStr<>'' then
               begin

                  {Controlla la password}
                  Password := Upper(MsgOut^.GetSubj);

                  MakeList := False;
                  MakeQuery := False;

                  I := pos(' ',Password);
                  if I>0 then
                     Password := Copy(Password,1,I-1);

                  MsgTo := MsgOut^.GetFrom;

                  MsgOut^.MsgTxtStartUp;
                  KludgeReply := '';

                  if not QuietMode then
                     Writeln('':19);

                  Writeln(' * Found request from ',MsgTo,' (',AddrStr(MsgDestAddr),')');
                  Writeln(LogFile,PreLog(LogWork),'Found request from ',MsgTo,' (',AddrStr(MsgDestAddr),')');
                  Flush(LogFile);

                  PathAll := D0 + HexLong(ToUnixDate(GetDosDate)) + AppExt;

                  {controlla innnazitutto se e' partito dal mio nodo}
                  {per la manutenzione remota}
                  I := 0;
                  while (I<=NAka) and not AddrEqual(Aka[I],MsgDestAddr) do
                     inc(I);
                  if I <= NAka then
                  begin
                     if (Upper(SysopName)=Upper(MsgTo)) and
                         ((LocalRaidPwd='') or (LocalRaidPwd=Password)) then
                        CurrTicNode := 0
                     else
                        CurrTicNode := NTicNodes+1;
                  end else
                  begin
                     {Adesso e' il momento di controllare la password}
                     CurrTicNode := 1;
                     while (CurrTicNode<=NTicNodes) and
                        (not AddrEqual(TicNodes[CurrTicNode]^.Node,MsgDestAddr)) do
                           inc(CurrTicNode);
                  end;
                  if (CurrTicNode<=NTicNodes) and
                     ((
                       CurrTicNode=0) or (TicNodes[CurrTicNode]^.Pw=Password)
                     ) then
                  begin
                     MsgOut^.SetRcvd(True);
                     MsgOut^.RewriteHdr;
                     StartIngMsg := MsgOut^.GetMsgNum + 1;
                     AnsDone := True;
                     RemoteMaint := (CurrTicNode=0) or
                        TicNodes[CurrTicNode]^.RemoteMaint;
                     MakeRescan := False;
                     RescanAreas := Nil;
                     EmptyStr := '';
                     RescanDays := NewDays;
                     ChkTime := GetChkTime(RescanDays);

                     assign(AllFiles,PathAll);
                     {$I-}
                     Rewrite(AllFiles);
                     {$I+}
                     if IOResult=0 then
                     begin
                        if message[77]=Nil then
                           TempStr := 'Processing RAID request for %1'
                        else
                           TempStr := Message[77]^;
                        if CurrTicNode<>0 then
                        begin
                           SubstPar(TempStr,AddrStr(TicNodes[CurrTicNode]^.Node),'1');
                        end else
                        begin
                           SubstPar(TempStr,'Sysop','1');
                        end;
                        Writeln(AllFiles,TempStr);
                        Writeln(AllFiles);
                        KludgeReply := '';
                        TempStr1 := MsgOut^.GetString(255);
                        While (Not MsgOut^.EOM) and
                          (pos('--- ',TempStr1)<>1) and (TempStr1<>'---') Do
                        Begin
                           if (TempStr1<>'') and (TempStr1[1]=#1) then
                           begin
                              {Kludge Line}
                              delete(TempStr1,1,1);
                              if pos('MSGID: ',TempStr1)=1 then
                              begin
                                 delete(TempStr1,1,7);
                                 StripLeadingSpace(TempStr1);
                                 KludgeReply := TempStr1;
                              end;
                           end else
                           begin
                              StripLeadingSpace(TempStr1);
                              While (TempStr1<>'') and (TempStr1[length(tempStr1)]=' ') do
                                 dec(TempStr1[0]);
                              TempStr := Upper(TempStr1);
                              if TempStr<>'' then
                              begin
                                 {conversioni per i metacomandi ALL}
                                 if (TempStr='%ALL') or (TempStr='%+ALL') then
                                    TempStr := '*';
                                 if TempStr='%-ALL' then
                                    TempStr := '-*';
                                 if TempStr[1]='%' then
                                 begin
                                    delete(TempStr,1,1);
                                    if (TempStr='LIST') then
                                    begin
                                       if CurrTicNode<>0 then
                                       begin
                                           DisplayAreaList(True,True);
                                       end;
                                    end else
                                    if (TempStr='RESCAN') then
                                    begin
                                       if CurrTicNode<>0 then
                                       begin
                                          MakeRescan := True;
                                          Writeln(AllFiles);
                                          Writeln(AllFiles,'Rescan following areas');
                                          Writeln(AllFiles,'Rescan last ',RescanDays,' days');
                                          Writeln(AllFiles);
                                       end;
                                    end else
                                    if (Pos('AUTOLINK',TempStr)=1) then
                                    begin
                                       if CurrTicNode<>0 then
                                       begin
                                          Delete(TempStr,1,8);
                                          StripLeadingSpace(TempStr);
                                          if TempStr='' then
                                          begin
                                             Writeln(AllFiles);
                                             Writeln(AllFiles,'Index of available file groups');
                                             Writeln(AllFiles,' "*" Linked, "+" linked',
                                                ' (can''t be unlinked), "-" can''t be linked');
                                             for I := 1 to NTicGroups do
                                             begin
                                                If NodeMember(TicGroups[I]^.Nodes,TicNodes[CurrTicNode]^.Node,
                                                    TicSend+TicReceive) then
                                                begin
                                                   if (TicGroups[I]^.TicLevel>TicNodes[CurrTicNode]^.TicLevel) or
                                                      (Aka[TicGroups[I]^.Address].Zone<>
                                                         TicNodes[CurrTicNode]^.Node.Zone) then
                                                     Write(AllFiles,'+')
                                                   else
                                                     Write(AllFiles,'*');
                                                   Writeln(AllFiles,TicGroups[I]^.Tag);
                                                end else
                                                if (Aka[ticGroups[I]^.Address].Zone=TicNodes[CurrTicNode]^.Node.Zone) then
                                                begin
                                                   if (TicGroups[I]^.TicLevel>TicNodes[CurrTicNode]^.TicLevel) then
                                                       Write(AllFiles,'-')
                                                   else
                                                       Write(AllFiles,' ');
                                                   Writeln(AllFiles,TicGroups[I]^.Tag);
                                                end;
                                             end;
                                             Writeln(AllFiles);
                                          end else
                                          begin
                                             While (TempStr<>'') do
                                             begin
                                                I := pos(' ', TempStr);
                                                if I>0 then
                                                begin
                                                   TempStr1 := Copy(TempStr, 1, I-1);
                                                   delete(TempStr,1, I);
                                                   StripLeadingSpace(TempStr);
                                                end else
                                                begin
                                                   TempStr1 := TempStr;
                                                   TempStr := '';
                                                end;
                                                if TempStr1[1]='-' then
                                                begin
                                                   Delete(TempStr1, 1, 1);
                                                   UnSubscribeGroup(TempStr1);
                                                end else
                                                begin
                                                   if tempStr1[1]='+' then
                                                      delete(TempStr1, 1, 1);
                                                   SubScribeGroup(TempStr1);
                                                end;
                                             end;
                                          end;
                                       end;
                                    end else
                                    if (Pos('LEVEL ',TempStr)=1) then
                                    begin
                                       if RemoteMaint and (CurrTicNode<>0) then
                                       begin
                                          Delete(TempStr,1,6);
                                          StripLeadingSpace(TempStr);
                                          Val(TempStr,NewLev,Code);
                                          if (Code=0) and (NewLev<>TicNodes[CurrTicNode]^.TicLevel) then
                                          begin
                                             TicNodes[CurrTicNode]^.TicLevel := NewLev;
                                             Writeln(AllFiles,'New level: ',NewLev);
                                             TicAreasModified := true;
                                          end;
                                       end;
                                    end else
                                    if (Pos('MAXFILESIZE ',TempStr)=1) then
                                    begin
                                       if (CurrTicNode<>0) then
                                       begin
                                          Delete(TempStr,1,12);
                                          StripLeadingSpace(TempStr);
                                          Val(TempStr,TempLong,Code);
                                          if (Code=0) and (NewLev<>TicNodes[CurrTicNode]^.TicLevel) then
                                          begin
                                             TicNodes[CurrTicNode]^.MaxfileSize := TempLong;
                                             Writeln(AllFiles,'Max file size: ',TempLong);
                                             TicAreasModified := true;
                                          end;
                                       end;
                                    end else
                                    if (Pos('DAYS ',TempStr)=1) then
                                    begin
                                       if (CurrTicNode<>0) then
                                       begin
                                          Delete(TempStr,1,5);
                                          StripLeadingSpace(TempStr);
                                          Val(TempStr,TempWord,Code);
                                          if (Code=0) and (TempWord<>RescanDays) then
                                          begin
                                             RescanDays := TempWord;
                                             ChkTime := GetChkTime(RescanDays);
                                             Writeln(AllFiles,'Rescan last ',RescanDays,' days');
                                          end;
                                       end;
                                    end else
                                    if (TempStr='-NOTIFY') then
                                    begin
                                       if CurrTicNode<>0 then
                                       begin
                                          if TicNodes[CurrTicNode]^.Notify then
                                          begin
                                             Writeln(AllFiles,'Notify: NO');
                                             TicNodes[CurrTicNode]^.Notify:= False;
                                             TicAreasModified := true;
                                          end;
                                       end;
                                    end else
                                    if (TempStr='NOTIFY') then
                                    begin
                                       if CurrTicNode<>0 then
                                       begin
                                          if not TicNodes[CurrTicNode]^.Notify then
                                          begin
                                             Writeln(AllFiles,'Notify: YES');
                                             TicNodes[CurrTicNode]^.Notify:= True;
                                             TicAreasModified := true;
                                          end;
                                       end;
                                    end else
                                    if (TempStr='-ANNOUNCE') then
                                    begin
                                       if CurrTicNode<>0 then
                                       begin
                                          if TicNodes[CurrTicNode]^.SendAnnounce then
                                          begin
                                             Writeln(AllFiles,'Announce: NO');
                                             TicNodes[CurrTicNode]^.SendAnnounce:= False;
                                             TicAreasModified := true;
                                          end;
                                       end;
                                    end else
                                    if (TempStr='ANNOUNCE') then
                                    begin
                                       if CurrTicNode<>0 then
                                       begin
                                          if not TicNodes[CurrTicNode]^.SendAnnounce then
                                          begin
                                             Writeln(AllFiles,'Announce: YES');
                                             TicNodes[CurrTicNode]^.SendAnnounce:= True;
                                             TicAreasModified := true;
                                          end;
                                       end;
                                    end else
                                    if (TempStr='-TINYSEENBY') then
                                    begin
                                       if CurrTicNode<>0 then
                                       begin
                                          if TicNodes[CurrTicNode]^.TinySeenBy then
                                          begin
                                             Writeln(AllFiles,'TinySeenBy: NO');
                                             TicNodes[CurrTicNode]^.TinySeenBy:= False;
                                             TicAreasModified := true;
                                          end;
                                       end;
                                    end else
                                    if (TempStr='TINYSEENBY') then
                                    begin
                                       if CurrTicNode<>0 then
                                       begin
                                          if not TicNodes[CurrTicNode]^.TinySeenBy then
                                          begin
                                             Writeln(AllFiles,'TinySeenBy: YES');
                                             TicNodes[CurrTicNode]^.TinySeenBy:= True;
                                             TicAreasModified := true;
                                          end;
                                       end;
                                    end else
                                    if (TempStr='ECHO') then
                                    begin
                                       if RemoteMaint then
                                          TicReport(AllFiles);
                                    end else
                                    if (TempStr='INFO') then
                                    begin
                                       if CurrTicNode<>0 then
                                       begin
                                          TicNodeInfo(AllFiles,CurrTicNode);
                                       end;
                                    end else
                                    if (pos('PWD ',TempStr)=1) then
                                    begin
                                       if CurrTicNode<>0 then
                                       begin
                                          Delete(TempStr,1,4);
                                          StripLeadingSpace(TempStr);
                                          I := pos(' ',TempStr);
                                          if I>0 then
                                             TempStr := Copy(TempStr,1,I-1);
                                          if TempStr<>'' then
                                          begin
                                             TempStr := Upper(TempStr);
                                             if TicNodes[CurrTicNode]^.Pw<>TempStr then
                                             begin
                                                TicNodes[CurrTicNode]^.Pw := TempStr;
                                                Writeln(AllFiles);
                                                Writeln(AllFiles,'Pwd: ',TempStr);
                                                Writeln(AllFiles);
                                                TicAreasModified := True;
                                                TicCfgModified := True;
                                             end;
                                          end;
                                       end;
                                    end else
                                    if (TempStr='PACKER') then
                                    begin
                                       if CurrTicNode<>0 then
                                       begin
                                          Delete(TempStr,1,6);
                                          StripLeadingSpace(TempStr);
                                          I := pos(' ',TempStr);
                                          if I>0 then
                                             TempStr := Copy(TempStr,1,I-1);
                                          TempStr := Upper(TempStr);
                                          if TempStr='NONE' then
                                          begin
                                             if TicNodes[CurrTicNode]^.Packer<>'' then
                                             begin
                                                TicNodes[CurrTicNode]^.Packer := '';
                                                Writeln(AllFiles,'Packer: NONE');
                                                TicAreasModified := True;
                                             end;
                                          end else
                                          begin
                                             I := 1;
                                             while (I<=NPacker) and (Packer[I]^.Ext<>TempStr) do
                                                inc(I);
                                             if I<=NPacker then
                                             begin
                                                if TicNodes[CurrTicNode]^.Packer<>TempStr then
                                                begin
                                                   TicNodes[CurrTicNode]^.Packer := TempStr;
                                                   Writeln(AllFiles,'Packer: ',TempStr);
                                                   TicAreasModified := True;
                                                end;
                                             end else
                                             begin
                                                if TempStr<>'' then
                                                   Writeln(AllFiles,'Invalid packer ',TempStr);
                                                Write(AllFiles,'Available packers: NONE');
                                                for I := 1 to NPacker do
                                                   Write(AllFiles,', ',Packer[I]^.Ext);
                                                Writeln(AllFiles);
                                             end;
                                          end;
                                       end;
                                    end else
                                    if (TempStr='QUERY') then
                                    begin
                                       DisplayAreaList(True,False);
                                    end else
                                    if (TempStr='UNLINKED') then
                                    begin
                                       DisplayAreaList(False,True);
                                    end else
                                    if (TempStr='SENDTIC') then
                                    begin
                                       if CurrTicNode<>0 then
                                       begin
                                          if not TicNodes[CurrTicNode]^.SendTic then
                                          begin
                                             TicAreasModified := True;
                                             TicNodes[CurrTicNode]^.SendTic := TRue;
                                             Writeln(AllFiles,'SendTic: YES')
                                          end;
                                       end;
                                    end else
                                    if (TempStr='-SENDTIC') then
                                    begin
                                       if CurrTicNode<>0 then
                                       begin
                                          if TicNodes[CurrTicNode]^.SendTic then
                                          begin
                                             TicAreasModified := True;
                                             TicNodes[CurrTicNode]^.SendTic := False;
                                             Writeln(AllFiles,'SendTic: NO')
                                          end;
                                       end;
                                    end else
                                    if (pos('RESEND ',TempStr)=1) then
                                    begin
                                       if CurrTicNode<>0 then
                                       begin

                                          delete(TempStr,1,7);
                                          StripLeadingSpace(TempStr);

                                          I := Pos(' ',TempStr);
                                          if I>0 then
                                             TempStr := Copy(TempStr,1,I-1);
                                          if pos('.',TempStr)=0 then
                                             TempStr := TempStr + '.*';

                                          if ((pos('*',TempStr)>0) and (pos('*',TempStr)<4)) or
                                             ((pos('.',TempStr)>0) and (pos('.',TempStr)<4)) then
                                          begin
                                             Writeln(AllFiles,'%RESEND requires filenames longer than ',Tempstr)
                                          end else
                                          begin
                                             TempLong := TicNodes[CurrTicNode]^.MaxFileSize;
                                             TicNodes[CurrTicNode]^.MaxFileSize := 0;
                                             TempNodes := Nil;
                                             if AddNode(TempNodes,TicNodes[CurrTicNode]^.Node,TicSend) then;
                                             I := 1;
                                             while I<=NTicAreas do
                                             begin
                                                if NodeMember(TicAreas[I]^.Nodes,TicNodes[CurrTicNode]^.Node,
                                                    TicSend) then
                                                begin
                                                   PathDown := TicAreas[I]^.DownLoad;
                                                   FindFirst(PathDown+TempStr,Archive+ReadOnly,S);
                                                   Found := False;
                                                   While (DosError=0) do
                                                   begin
                                                      TempDescTypePtr :=
                                                         GetDesc(S.Name,TicAreas[I]^.DownLoad+'Files.Bbs');
                                                      if TempDescTypePtr<>Nil then
                                                      begin
                                                         Found := TRue;
                                                         if message[65]=nil then
                                                            TempStr1 := 'Resend %1 in area %2'
                                                         else
                                                            TempStr1 := Message[65]^;
                                                         Substpar(TempStr1,S.Name,'1');
                                                         Substpar(TempStr1,TicAreas[i]^.tag,'2');
                                                         Writeln(AllFiles,TempStr1);
                                                         Hatch(TicAreas[I]^.Download,S.Name,S.Name,'',TempDescTypePtr,
                                                            TempNodes, TicAreas[I]^.Tag, '',
                                                            Aka[TicAreas[I]^.Address],S.Size,S.Time,
                                                            TicAreas[i]^.AreaDesc);
                                                      end;
                                                      CancellaDescrizione(TempDescTypePtr);
                                                      FindNext(S);;
                                                   end;
                                                end;
                                                inc(I)
                                             end;
                                             DeleteNodes(TempNodes);
                                             TicNodes[CurrTicNode]^.MaxFileSize := TempLong;
                                          end;
                                       end;
                                    end else
                                    if (TempStr='HELP') or (pos('HELP ',TempStr)=1) then
                                    begin
                                       WriteHelp;

                                    end else
                                    if Pos('FROM ',TempStr)=1 then
                                    begin

                                       REscanFileBase;

                                       MakeRescan := False;
                                       if RemoteMaint then
                                       begin
                                          delete(TempStr,1,5);
                                          StripLeadingSpace(TempStr);
                                          if ParseAddr(TempStr,TempAddr,TempAddr) then
                                          begin
                                             I := 1;
                                             while (I<=NTicNodes) and not AddrEqual(TicNodes[I]^.Node,TempAddr) do
                                                inc(I);
                                             if I<=NTicNodes then
                                             begin
                                                CurrTicNode := I;
                                                Writeln(AllFiles);
                                                Writeln(AllFiles,'Remote maintenance for ',
                                                   AddrStr(TicNodes[CurrTicNode]^.Node));
                                                Writeln(AllFiles);
                                                Writeln(' * Remote maintenance for ',
                                                   AddrStr(TicNodes[CurrTicNode]^.Node));
                                                Writeln(LogFile,Prelog(Logwork),'Remote maintenance for ',
                                                   AddrStr(TicNodes[CurrTicNode]^.Node));
                                                Flush(LogFile);
                                             end else
                                             begin
                                                CurrTicNode := 0;
                                                Writeln(AllFiles);
                                                Writeln(AllFiles,'Remote maintenance for ',
                                                   TempStr,' not allowed (unknown node)');
                                                Writeln(AllFiles);
                                             end;
                                          end else
                                          begin
                                             CurrTicNode := 0;
                                             Writeln(AllFiles);
                                             Writeln(AllFiles,'Remote maintenance for ',
                                                TempStr,' not allowed (invalid node)');
                                             Writeln(AllFiles);
                                          end;
                                       end else
                                       begin
                                          CurrTicNode := 0;
                                          Writeln(AllFiles);
                                          Writeln(AllFiles,'Remote maintenance not authorized');
                                          Writeln(AllFiles);
                                       end;
                                    end else
                                    begin
                                       Writeln(AllFiles);
                                       Writeln(AllFiles,'Unknown meta-command %',TempStr);
                                       Writeln(AllFiles);
                                    end;
                                 end else
                                 begin
                                    While (TempStr<>'') do
                                    begin
                                       I := pos(' ', TempStr);
                                       if I>0 then
                                       begin
                                          TempStr1 := Copy(TempStr, 1, I-1);
                                          delete(TempStr,1, I);
                                          StripLeadingSpace(TempStr);
                                       end else
                                       begin
                                          TempStr1 := TempStr;
                                          TempStr := '';
                                       end;
                                       if TempStr1[1]='-' then
                                       begin
                                          Delete(TempStr1, 1, 1);
                                          UnSubscribeArea(TempStr1);
                                       end else
                                       begin
                                          if tempStr1[1]='+' then
                                             delete(TempStr1, 1, 1);
                                          SubScribeArea(TempStr1);
                                       end;
                                    end;
                                 end;
                              end;
                           end;
                           TempStr1 := MsgOut^.GetString(255);
                        End;
                        RescanFileBase;
                        Close(AllFiles);
                     end;
                  end else
                  begin
                     MsgOut^.SeekNext;
                     Writeln(' * Assuming FSEARCH Msg');
                     Writeln(LogFile,Prelog(LogError),'Assuming FSEARCH Msg');
                     I := pos(',', NetAreaId);
                     Writeln(LogFile,PreLog(LogWork),'Scanning Msg Area ',Copy(NetAreaID,1,I-1));
                     if Not QuietMode then
                     begin
                        Write(' * Scanning Msg Area ',Copy(NetAreaID,1,I-1));
                        I := WhereX;
                        write(MsgOut^.GetMsgNum:8,' / ',Last);
                        GotoXY(I,WhereY);
                     end;
                     Flush(LogFile);
                     {avvisa il nodo che non ha accesso a RAID}
                     (*
                     {$I-}
                     Rewrite(AllFiles);
                     {$I+}
                     if IOResult=0 then
                     begin
                        KludgeReply := '';
                        Writeln(AllFiles,'Node ',AddrStr(MsgDestAddr),' is not authorized to use RAID');
                        StartIngMsg := MsgOut^.GetMsgNum + 1;
                        AnsDone := True;
                        Close(AllFiles);
                     end;
                     *)
                  end;
               end else
                  MsgOut^.SeekNext;
            End else
            begin
               MsgOut^.SeekNext;
            end;
         end;

         if not AnsDone and not QuietMode then
            Writeln('':19);
         if CloseMsgArea(MsgOut) then;

      end else
         Writeln;

      Raid1 := AnsDone;

   end {Raid1};
Begin

   MsgFrom := 'LLIST '+ versione;
   MsgSubject := 'Response to RAID request';

   StartingMsg := 1;
   While Raid1 do
   begin
      {posta il messaggio di risposta}
      PostAnnunciNews(NetAreaId);
      if EraseFile(PathAll) then;
   end;

   SaveCfg;

   for I := 1 to NTicNodes do
   if TicNodes[I]^.RequireTicAreas<>Nil then
   begin
      {passa le richieste delle aree non disponibili all'uplink}
      TempDescTypePtr := TicNodes[I]^.RequireTicAreas;
      PathAll := D0 + HexLong(ToUnixDate(GetDosDate)) + AppExt;
      assign(AllFiles,PathAll);
      {$I-}
      Rewrite(AllFiles);
      {$I+}
      if IOResult=0 then
      begin
         {Testo del messaggio}
         While (TempDescTypePtr<>Nil) do
         begin
            Writeln(AllFiles,TempDescTypePtr^.Descrizione^);
            TempDescTypePtr := TempDescTypePtr^.Next;
         end;
         MsgFrom := SysopName;
         J := 0;
         while (J<=NAka) and (Aka[J].Zone<>TicNodes[I]^.Node.Zone) do
            inc(J);
         if J>NAka then
            J := 0;
         MsgOrigAddr := Aka[J];
         MsgTo := 'Raid';
         MsgDestAddr := TicNodes[I]^.Node;
         MsgSubject := TicNodes[I]^.Pw;
         KludgeReply := '';
         Close(AllFiles);
         PostAnnunciNews(NetAreaId);
         if EraseFile(PathAll) then;
      end;
      CancellaDescrizione(TicNodes[I]^.RequireTicAreas);
      TicNodes[I]^.RequireTicAreas := Nil;
      TicNodes[I]^.RequireTicAreasRef :=
         Addr(TicNodes[I]^.RequireTicAreas);
   end;

End {Raid};


Begin

   LastArea := Addr(AvailableTicAreas);
   LastArea^ := Nil;
   GotTicInfo := False;
   Tic.Unknown := Nil;
   Tic.PathList := Nil;
   Tic.LDesc := Nil;
   Tic.SeenBy := Nil;
   Tic.Replaces := Nil;
   Tic.InvReplaces := Nil;
   CreatedNewAreas := False;
   TicAreasModified := False;
   TicCfgModified := False;
   MadeHoldTic := False;

End.

