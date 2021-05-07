Unit LLTic1;

{$I LL.Def}

Interface

Uses Dos, Crt,

   MkString, MkMisc, MkGlobT, MkDos, MkFile,

   LLGen, LLExec, LLShell, LLCopy, LLTic, LLMgIdx, llFileid, llmsg,
   llGetTic;

Function CheckTic:Boolean;

Implementation

Procedure CheckPath(Var P: String);
Var D: DirStr;
    Esiste, First: Boolean;
Begin
   First := True;
   GetDir(0,D);
   Repeat
      {$I-}
      ChDir(P);
      {$I+}
      Esiste := IoResult=0;
      if Esiste then
      begin
         if First then
         begin
            P[length(P)] := '0';
         end else
         if (P[length(P)]='9') then
         begin
            P[length(P)] := 'A';
         end else
         if P[length(P)]='F' then
         begin
            {a questo punto lo prende comunque per buono}
            Esiste := False;
         end else
         begin
            inc(P[length(P)]);
         end;
      end;
      First := False;
   until not esiste;
   ChDir(D);
End;


Function CheckTic:Boolean;
Var S,S1:SearchRec;
   TempStr:String;
   MainArea:Integer;
   TempCrc:Longint;
   TempDescTypePtr, TempDescTypePtr1,
      TempDescTypePtr2, TempDescTypePtr3, TempDescTypePtr4:DescTypePtr;
   CurrTicNode, CurrTicArea:Integer;
   TicModified, OneTicProcessed:Boolean;
   TempAddrListRef:AddrListTypeRef;
   TempF:File;
   T1,T2:dateTime;
   TicDupe:TicDupeType;
   Result:Word;
   ToMove:Boolean;
   Comp:Byte;
   Flag:Boolean;
   I:integer; TempExt:ExtStr;
   TempInbound, TempInbound1: DescTypePtr;
   fm: Word;
   Rec: IdxType;
   raidFwd: raidFwdType;
   RaidFwdFile: File;

   Procedure CheckTic1(TicInbound:String);
   Var TicList, TicList1: DescTypePtr;
       I:INteger;
       TicProcessed: Boolean;
       AlreadyReceived : Boolean; {per il controlo dupes, va fatto prima del repack e copy}
                                  {che possono comportare un cambio del nome}
       FSize, FTime: Longint;
       OldName: String;
       OldSize: Longint;
   Begin
      TicList := Nil;
      FindFirst(TicInbound + '*.?IC', Archive, S);
      While DosError=0 do
      begin
         L := TicInbound + S.Name;
         PosDesc := 1;
         PutDescrizione(TicList);
         FindNext(S);
      end;
      While TicList<>Nil do
      begin
         TicProcessed := False;
         if Copy(TicList^.Descrizione^,length(TicList^.Descrizione^)-2,1)<>'T' then
         begin
            Assign(TempF,TicList^.Descrizione^);
            I := -1;
            Repeat
               inc(I);
               TempExt := Long2Str(i,0);
               while length(TempExt)<3 do
                  TempExt := '0' + TempExt;
               {$I-}
               Rename(TempF,TicInbound+'Bad_Tic.'+TempExt);
               {$I+}
            until IOResult=0;
            Comp := 0;
            if Uncompress(TicInbound+'Bad_Tic.'+TempExt,'*.TIC',Comp) then
            begin
               CheckTic1(TempDir);
               FindFirst(TempDir+'*.BAD',Archive+Readonly,S);
               if (DosError=0) then
               begin
                  TicProcessed := False;
                  {$IFDEF OS2}
                  Findclose(S);
                  {$ENDIF}
               end else
                  TicProcessed := True;
            end;
         end else
         if ReadTic(TicList^.Descrizione^) then
         begin
            TempStr := PathDown + Tic.NomeFile;
            FindFirst(TempStr,Archive+ReadOnly,S);
            if DosError=0 then
            begin
               FSize := S.Size;
               FTime := S.Time;
               {$IFDEF OS2}
               Findclose(S);
               {$ENDIF}
               if FixSizeTic and (Tic.Size>=0) and (Tic.Size<>FSize) then
               begin
                  Tic.Size := FSize;
               end;
               if (Tic.Size>=0) and (Tic.Size<>FSize) then
               begin
                  Writeln(' * ',Tempstr,' failed SIZE ',FSize,' / ',Tic.Size);
                  Writeln(LogFile,Prelog(LogError),Tempstr,' failed SIZE ',FSize,' / ',Tic.Size);
                  Flush(LogFile);
               end else
               begin
                  TicModified := False;
                  TempCrc := FileCrc32(TempStr);
                  if not Tic.CrcFound then
                     Tic.Crc32 := TempCrc;
                  if FixCrcTic and (TempCrc<>Tic.Crc32) then
                  begin
                     Tic.Crc32 := TempCrc;
                     TicModified := True;
                  end;
                  if TempCrc<>Tic.Crc32 then
                  begin
                     Writeln(' * ',Tempstr,' failed CRC ',HexLong(TempCrc),' / ',HexLong(Tic.Crc32));
                     Writeln(LogFile,Prelog(LogError),Tempstr,' failed CRC ',HexLong(TempCrc),' / ',HexLong(Tic.Crc32));
                     Flush(LogFile);
                  end else
                  begin
                     {Cerca il from tra i tic nodes per verificare la password}
                     CurrTicNode := 1;
                     while (CurrTicNode<=NTicNodes) and
                       (
                         not AddrEqual(Tic.From,TicNodes[CurrTicNode]^.Node)
                       ) do inc(CurrTicNode);
                     if CurrTicNode <= NTicNodes then
                     begin
                        {FROM e' stato trovato nell'insieme dei nodi}
                        {Ora verifica la Password}
                        if TicNodes[CurrTicNode]^.Pw=Tic.Pw then
                        begin
                           {Anche la password e' valida}
                           {Ora deve cercare l'area TIC}
                           CurrTicArea := 1;
                           While (CurrTicArea<=NTicAreas) and (TicAreas[CurrTicArea]^.Tag<>Tic.AreaTag) do
                              inc(CurrTicArea);
                           if (CurrTicArea>NTicAreas) and
                              (NTicAreas<NMaxTicAreas) then
                           begin
                              {Individua il gruppo}
                              {Cerca se l'area appartiene a qualche gruppo}
                              I := 1;
                              while (I<=NTicGroups) and
                                (
                                 not ChkGroup(Tic.AreaTag,TicGroups[I]^.GroupId)
                                ) do inc(I);

                              if (I<=NTicGroups) and (TicGroups[I]^.UplinkNode=CurrTicNode) then
                              begin
                                 {mette la descrizione nel file NewRaid.Cfg}
                                 if Tic.AreaDesc<>'' then
                                 begin
                                    Assign(AllFiles, D0 + 'NewRaid.Cfg');
                                    {$I-}
                                    Append(AllFiles);
                                    {$I+}
                                    if IOResult<>0 then
                                       Rewrite(AllFiles);
                                    Writeln(AllFiles);
                                    Writeln(AllFiles,'Area ',Tic.AreaTag,
                                        '0     !      ',Tic.AreaDesc);
                                    close(Allfiles);
                                 end;
                                 {Creazione nuova area}
                                 CreateFlagFile(D0 + 'NewAreas.Flg');
                                 Inc(NTicAreas);
                                 New(TicAreas[NTicAreas]);
                                 TicAreas[NTicAreas]^.Number := LastNumero;
                                 Inc(LastNumero);
                                 TicAreas[NTicAreas]^.Tag := Tic.AreaTag;
                                 TicAreas[NTicAreas]^.Nodes := Nil;
                                 TicAreas[NTicAreas]^.TicLevel := TicNodes[CurrTicNode]^.TicLevel + 1;
                                 TicAreas[NTicAreas]^.Mode := TicSend;
                                 TicAreas[NTicAreas]^.Repack := '';
                                 TicAreas[NTicAreas]^.AreaDesc := '';
                                 TicAreas[NTicAreas]^.SecTag := '';
                                 TicAreas[NTicAreas]^.BytesMonth := BytesMonthDefault;
                                 if AddNode(TicAreas[NTicAreas]^.Nodes,TicNodes[CurrTicNode]^.Node,
                                    TicReceive) then;
                                 TicAreas[NTicAreas]^.PathFBbs := '';
                                 TicAreas[NTicAreas]^.TicLevel := TicGroups[I]^.TicLevel;
                                 TicAreas[NTicAreas]^.Address := TicGroups[I]^.Address;
                                 TicAreas[NTicAreas]^.Group := TicGroups[I]^.Tag;
                                 TicAreas[NTicAreas]^.readFile_id := false;
                                 PutInListaAree(TicAreas[NTicAreas]^.Number,
                                    TicAreas[NTicAreas]^.Number,TicGroups[I]^.Aree);
                                 {mette il nome nell'AreaDesc}
                                 if Tic.AreaDesc<>'' then
                                    TempStr := Tic.AreaDesc
                                 else
                                    TempStr := TicAreas[NTicAreas]^.Group + ': ' +
                                       TicAreas[NTicAreas]^.Tag;
                                 TicAreas[NTicAreas]^.AreaDesc := TempStr;
                                 {notifica il sysop della creazione nuova area}
                                 PathAll := D0 + HexLong(ToUnixDate(GetDosDate)) + AppExt;
                                 Assign(AllFiles,PathAll);
                                 Rewrite(AllFiles);
                                 if IOResult=0 then
                                 begin
                                    MsgDestAddr := Aka[TicAreas[NTicAreas]^.Address];
                                    MsgOrigAddr := Aka[TicAreas[NTicAreas]^.Address];
                                    MsgFrom := 'LLIST ' + versione;
                                    MsgTo := SysopName;
                                    if message[66]=Nil then
                                       MsgSubject := 'New TIC Areas'
                                    else
                                       MsgSubject := Message[66]^;
                                    if message[67]=Nil then
                                       TempStr := 'Linked TIC area %1'
                                    else
                                       TempStr := Message[67]^;
                                    SubstPar(TempStr,TicAreas[NTicAreas]^.Tag,'1');
                                    Writeln(AllFiles, TempStr);
                                    if Tic.areaDesc<>'' then
                                       Writeln(AllFiles,Tic.AreaDesc);
                                    Close(AllFiles);
                                    PostAnnunciNews(NetAreaId);
                                    if EraseFile(PathAll) then;
                                 End;
                                 TempAddrListRef := TicGroups[I]^.Nodes;
                                 while TempAddrListREf<>Nil do
                                 begin
                                    if AddNode(TicAreas[NTicAreas]^.Nodes,TempAddrListREf^.Node,TicSend) then
                                    begin
                                       Assign(AllFiles,PathAll);
                                       Rewrite(AllFiles);
                                       if IOResult=0 then
                                       begin
                                          MsgDestAddr := TempAddrListRef^.Node;
                                          MsgOrigAddr := Aka[TicAreas[NTicAreas]^.Address];
                                          MsgFrom := 'LLIST ' + versione;
                                          MsgTo := 'Sysop';
                                          if message[66]=Nil then
                                             MsgSubject := 'New TIC Areas'
                                          else
                                             MsgSubject := Message[66]^;
                                          if message[67]=Nil then
                                             TempStr := 'Linked TIC area %1'
                                          else
                                             TempStr := Message[67]^;
                                          SubstPar(TempStr,TicAreas[NTicAreas]^.Tag,'1');
                                          Writeln(AllFiles, TempStr);
                                          if Tic.areaDesc<>'' then
                                             Writeln(AllFiles, Tic.AreaDesc);
                                          Close(AllFiles);
                                          PostAnnunciNews(NetAreaId);
                                          if EraseFile(PathAll) then;
                                       End;
                                    end;
                                    TempAddrListRef := TempAddrListRef^.Next;
                                 end;

                                 Assign(RaidFwdFile, D0 + 'RaidFwd.Dup');
                                 {$I-}
                                 Reset(RaidFwdFile,1);
                                 {$I+}
                                 if IOResult=0 then
                                 begin
                                    while not eof(RaidFwdFile) do
                                    begin
                                       Blockread(RaidFwdFile, raidFwd, sizeOf(RaidFwdType));
                                       if not RaidFwd.Received and (RaidFwd.Tag=TicAreas[NTicAreas]^.Tag) then
                                       begin
                                          RaidFwd.received := True;
                                          Seek(RaidFwdFile, FilePos(raidFwdFile) - sizeOf(RaidFwdType));
                                          BlockWrite(RaidFwdFile, raidFwd, SizeOf(RaidFwdType));
                                          if AddNode(TicAreas[NTicAreas]^.Nodes,raidFwd.Node,TicSend) then
                                          begin
                                             Assign(AllFiles,PathAll);
                                             Rewrite(AllFiles);
                                             if IOResult=0 then
                                             begin
                                                MsgDestAddr := RaidFwd.Node;
                                                MsgOrigAddr := Aka[TicAreas[NTicAreas]^.Address];
                                                MsgFrom := 'LLIST ' + versione;
                                                MsgTo := 'Sysop';
                                                if message[66]=Nil then
                                                   MsgSubject := 'New TIC Areas'
                                                else
                                                   MsgSubject := Message[66]^;
                                                if message[67]=Nil then
                                                   TempStr := 'Linked TIC area %1'
                                                else
                                                   TempStr := Message[67]^;
                                                SubstPar(TempStr,TicAreas[NTicAreas]^.Tag,'1');
                                                Writeln(AllFiles, TempStr);
                                                if Tic.areaDesc<>'' then
                                                   Writeln(AllFiles, Tic.AreaDesc);
                                                Close(AllFiles);
                                                PostAnnunciNews(NetAreaId);
                                                if EraseFile(PathAll) then;
                                             End;
                                          end;
                                       end;
                                    end;
                                    close(raidFwdFile);
                                 end;

                                 TicAreas[NTicAreas]^.Download := DirNewAreas +
                                    DosValidName(TicAreas[NTicAreas]^.Group) + '\' +
                                    DosValidName(TicAreas[NTicAreas]^.Tag);
                                 CheckPath(TicAreas[NTicAreas]^.Download);

                                 L := TicAreas[NTicAreas]^.Download;
                                 PosDesc := 1;
                                 PutDescrizione(FileAreaListRef^);
                                 FileAreaListRef := Addr(FileAreaListRef^^.Next);

                                 if MakePath(TicAreas[NTicAreas]^.Download) then;
                                 TicAreas[NTicAreas]^.DownLoad := TicAreas[NTicAreas]^.Download + '\';

                                 Writeln(' * Created area ',TicAreas[NTicAreas]^.Tag);
                                 Writeln(LogFile,Prelog(LogDone),'Created area ',TicAreas[NTicAreas]^.Tag);
                                 Flush(LogFile);
                                 CreatedNewAreas := true;
                                 {TicAreasModified := True;}
                                 TicCfgModified := True;
                              end;
                           end;
                           if CurrTicArea <= NTicAreas then
                           begin
                              if NodeMember(TicAreas[CurrTicArea]^.Nodes,Tic.From,TicReceive) then
                              begin
                                 if AddNode(Tic.SeenBy,Tic.From,0) then;
                                 PathCopy := TicAreas[CurrTicArea]^.DownLoad;
                                 if TicAreas[CurrTicArea]^.PathFBbs='' then
                                    PathCopyFBbs := PathCopy + 'Files.Bbs'
                                 else
                                    PathCopyFBbs := TicAreas[CurrTicArea]^.PathFBbs;
                                 TempDescTypePtr := Nil;
                                 if TicAreas[CurrTicArea]^.ReadFile_Id then
                                 begin
                                    if ImportDesc(PathDown + Tic.NomeFile, 0,
                                       TempDescTypePtr) then
                                      Packdesc(TempDescTypePtr, false);
                                 end;
                                 if TempDescTypePtr=Nil then
                                 begin
                                    {utilizza la descrizione nel *.TIC}
                                    if TicUseDesc or (Tic.LDesc=Nil) then
                                    begin
                                       L := Tic.Desc;
                                       PosDesc := 1;
                                       PutDescrizione(TempDescTypePtr);
                                    end else
                                    begin
                                       if not TicUseLDesc and
                                          (Tic.Desc<>Tic.LDesc^.Descrizione^) then
                                       begin
                                          L := Tic.Desc;
                                          PosDesc := 1;
                                          PutDescrizione(TempDescTypePtr);
                                       end;
                                       TempDescTypePtr1 := Tic.LDesc;
                                       while (TempDescTypePtr1<>Nil) do
                                       begin
                                          L := TempDescTypePtr1^.Descrizione^;
                                          PutDescrizione(TempDescTypePtr);
                                          TempDescTypeptr1 := TempDescTypePtr1^.Next;
                                       end;
                                    end;
                                 end;
                                 if UploaderStr<>'' then
                                 begin
                                    L := UploaderStr + AddrStr(Tic.Origin);
                                    Posdesc := 1;
                                    Putdescrizione(tempDescTypePtr);
                                 end;
                                 if TicUpdate then
                                    FTime := ActDate
                                 else
                                 if (Tic.Time<>0) then
                                    FTime := FromUnixDate(Tic.Time);
                                 {altrimenti lascia la data cosi' com'e'}
                                 OldSize := FSize;
                                 OldName := Tic.NomeFile;
                                 if (TicAreas[CurrTicArea]^.Repack<>'') then
                                 begin
                                    Repack := TicAreas[CurrTicArea]^.Repack;
                                    Comp := 0;
                                    if ChangeToRepack(PathDown,Tic.NomeFile,Comp,FSize,FTime) then
                                    begin
                                       Tic.Crc32 := FileCrc32(PathDown+Tic.NomeFile);
                                       if (Tic.Size>=0) then
                                          Tic.Size := FSize;
                                       TicModified := True;
                                    end;
                                 end;
                                 if TicAreas[CurrTicArea]^.Number >= 0 then
                                    Lock(D0+'Area'+Long2Str(TicAreas[CurrTicArea]^.Number,0));
                                 TempDescTypePtr1 := Tic.Replaces;
                                 While (TempDescTypePtr1<>Nil) do
                                 begin
                                    if (TempDescTypePtr1^.Descrizione^<>'') then
                                    begin
                                        TempDescTypePtr3 := Nil;
                                        FindFirst(PathCopy+TempDescTypePtr1^.Descrizione^,Archive,S1);
                                        While DosError=0 do
                                        begin
                                           L := S1.Name;
                                           PosDesc := 1;
                                           PutDescrizione(TempDescTypePtr3);
                                           FindNext(S1);
                                        end;
                                        TempDescTypePtr4 := TempDescTypePtr3;
                                        while (TempDescTypePtr4<>Nil) do
                                        begin
                                           TempDescTypePtr2 := GetDesc(TempDescTypePtr4^.Descrizione^,PathCopy+'Files.Bbs');
                                           if TempDescTypePtr2<>Nil then
                                           begin
                                              if EraseFile(PathCopy+TempDescTypePtr4^.Descrizione^) then
                                              begin
                                                 Writeln(' * Deleted ',PathCopy,TempDescTypePtr4^.Descrizione^,' ',
                                                    TempDescTypePtr2^.Descrizione^);
                                                 Writeln(LogFile,Prelog(LogWork),'Deleted ',PathCopy,
                                                    TempDescTypePtr4^.Descrizione^,
                                                    ' ',TempDescTypePtr2^.Descrizione^);
                                                 Flush(LogFile);
                                              end;
                                              CancellaDescrizione(TempDescTypePtr2);
                                           end;
                                           TempDescTypePtr4 := TempDescTypePtr4^.Next;
                                        end;
                                        CancellaDescrizione(TempDescTypePtr3);
                                    end;
                                    TempDescTypePtr1 := TempDescTypePtr1^.Next;
                                 end;
                                 {Always Replace}
                                 if TICREplace then
                                 begin
                                    if EraseFile(PathCopy+Tic.NomeFile) then
                                    begin
                                       Writeln(' * Deleted ',PathCopy,Tic.NomeFile);
                                       Writeln(LogFile,Prelog(LogWork),'Deleted ',PathCopy,Tic.NomeFile);
                                       Flush(LOgFile);
                                    end;
                                 end;

                                 Tomove := true;
                                 TempStr := CopyFile(Tic.NomeFile,FSize,FTime,TempDescTypePtr,ToMove,Tic.Replaces,
                                    TicAreas[CurrTicArea]^.Number);
                                 if TicAreas[CurrTicArea]^.Number >= 0 then
                                    Unlock(D0+'Area'+Long2Str(TicAreas[CurrTicArea]^.Number,0));
                                 if TempStr<>'' then
                                 begin
                                    {mosso/copiato correttamente}
                                    {lo mette nell'indice per annunciarlo}
                                    if TicAreas[CurrTicArea]^.Number >= 0 then
                                    begin
                                       FillChar(Rec,SizeOf(Rec),0);
                                       Move(TempStr[1],Rec.Nome[1],Byte(TempStr[0]));
                                       Rec.Area := TicAreas[CurrTicArea]^.Number;
                                       AddAnnounceIdx(Rec);
                                    end;
                                    if Tic.Magic<>'' then
                                    begin
                                       {Aggiorna la lista dei Magics}
                                       TempDescTypePtr1 := Nil;
                                       L := PathCopy + TempStr + ' ' +
                                          Tic.Desc;
                                       PosDesc := 1;
                                       PutDescrizione(TempDescTypePtr1);
                                       if AddFBbsLine(D0+'Magic.Cfg',Upper(Tic.Magic),TempDescTypePtr1,Alfa,Nil) then;
                                       I := 1;
                                       While (I<=NMagic) and
                                          ((Magic[I]=Nil) or (Pos(Tic.Magic+' ',Magic[I]^)<>1)) do
                                         inc(I);
                                       if (I<=NMagic) then
                                       begin
                                          FreeMem(Magic[I],length(Magic[I]^)+1)
                                       end;
                                       if I<=NMaxMagic then
                                       begin
                                          if I>NMagic then
                                             NMagic := I;
                                          GetMem(Magic[I],length(Tic.Magic)+1+length(TempDescTypePtr1^.Descrizione^)+1);
                                          Magic[I]^ := Tic.Magic + ' ' + TempDescTypePtr1^.Descrizione^
                                       end;
                                       CancellaDescrizione(TempDescTypePtr1);
                                    end;

                                    {il nome da cambiare solo dopo MarkDupeTic}
                                    {sarebbe meglio am e' un casino :( }
                                    Tic.NomeFile := TempStr;

                                    {Controlla se rimpiazza se stesso}
                                    {Flag := False;
                                    TempDescTypePtr1 := Tic.Replaces;
                                    TempStr1 := Tic.NomeFile;
                                    ExpandWildCards(TempStr1);
                                    while not flag and (TempDescTypePtr1<>Nil) do
                                    begin
                                       TempStr := TempDescTypePtr1^.Descrizione^;
                                       ExpandWildCards(TempStr);
                                       Flag := MatchFileSpec(TempStr1,TempStr);
                                       TempDescTypePtr1 := TempDescTypePtr1^.Next
                                    end;
                                    }
                                    inc(NTotFiles);
                                    TicProcessed := True;
                                    OneTicProcessed := True;

                                    AlreadyReceived := not MarkDupeTic(OldName,Tic.AreaTag,Tic.From,OldSize,
                                       True) {or Flag};

                                    if AlreadyReceived then
                                    begin
                                       Writeln(' *  Dupes file');
                                       Writeln(LogFile,Prelog(LogError),'Dupes file');
                                       Flush(LOgFile);
                                    end;

                                    if not AlreadyReceived or not TicStopDup then
                                    begin
                                       Tic.From := Aka[TicAreas[CurrTicArea]^.Address];

                                       EchoFile(TicAreas[CurrTicArea]^.DownLOad,TicAreas[CurrTicArea]^.Nodes,S.Size);
                                       TempStr := TicAreas[CurrTicArea]^.SecTag;
                                       if TempStr<>'' then
                                       begin
                                          MainArea := CurrTicArea;
                                          CurrTicArea := 1;
                                          While (CurrTicArea<=NTicAreas) and
                                             (TicAreas[CurrTicArea]^.Tag <> TempStr) do
                                          begin
                                             inc(CurrTicArea);
                                          end;
                                          if CurrTicArea>NTicAreas then
                                          begin
                                             Writeln(' * Invalid Secondary Area ',TempStr);
                                             Writeln(Logfile,Prelog(LogError),'Invalid Secondary Area ',TempStr);
                                             Flush(LOgFile);
                                          end else
                                          begin
                                             Writeln(' * Hatch in Secondary Area ',TempStr);
                                             Writeln(Logfile,Prelog(LogStart),'Hatch in Secondary Area ',TempStr);
                                             Flush(LOgFile);
                                             Tic.From := Aka[TicAreas[CurrTicArea]^.Address];
                                             Tic.AreaTag := TempStr;
                                             Tic.AreaDesc := TicAreas[CurrTicArea]^.AreaDesc;
                                             EchoFile(TicAreas[MainArea]^.DownLOad,TicAreas[CurrTicArea]^.Nodes,S.Size)
                                          end;
                                       end
                                    end else
                                    begin
                                       Writeln(' *  File not echoed to downlinks');
                                       Writeln(LogFile,Prelog(LogError),'File not echoed to downlinks');
                                       Flush(LOgFile);
                                    end;
                                 end;
                                 CancellaDescrizione(TempDescTypePtr);
                              end else
                              begin
                                 Writeln(' * ',AddrStr(Tic.From),' not active in area ',Tic.AreaTag);
                                 Writeln(LogFile,Prelog(LogError),AddrStr(Tic.From),' not active in area ',Tic.AreaTag);
                                 Flush(LOgFile);
                              end;
                           End else
                           begin
                              Writeln(' * Unknown area ',Tic.AreaTag);
                              Writeln(LogFile,Prelog(LogError),'Unknown area ',Tic.AreaTag);
                              Flush(LOgFile);
                           end;
                        End else
                        Begin
                           Writeln(' * Invalid password ',Tic.Pw,' / ',TicNodes[CurrTicNode]^.Pw);
                           Writeln(LogFile,Prelog(LogError),'Invalid password ',Tic.Pw,' / ',TicNodes[CurrTicNode]^.Pw);
                           Flush(LOgFile);
                        End;
                     End else
                     begin
                        Writeln(' * Unknown FROM node ',AddrStr(Tic.From));
                        Writeln(LogFile,Prelog(LogError),'Unknown FROM node ',AddrStr(Tic.From));
                        Flush(LOgFile);
                     end;
                  End;
               End;
               if TicModified and not TicProcessed then
                  SaveTic(TicList^.Descrizione^);
            End else
            begin
               Writeln(' * ',Tempstr,' not found');
               Writeln(LogFile,Prelog(LogError),Tempstr,' not found');
               Flush(LOgFile);
            End;
         end else
         begin
            Writeln(' * ',TicList^.Descrizione^, ' is bad');
            Writeln(LogFile,Prelog(LogError),TicList^.Descrizione^,' is bad');
            Flush(LOgFile);
         end;
         if TicProcessed then
         begin
            {Cancella}
            if EraseFile(TicList^.Descrizione^) then;
         end;
         TicList1 := TicList^.Next;
         FreeMem(TicList^.Descrizione,Length(TicList^.Descrizione^)+1);
         Dispose(TicList);
         TicList := TicList1;
      End;
   End {CheckTic1};

Begin

   FirstShell := False;

   TicNotify;

   Writeln(' * Processing TIC');
   Writeln(LogFile,Prelog(LogStart),'Processing TIC');
   Flush(LOgFile);

   UnpackTime(actDate,T1);
   {Day of week e' gia' contenuto in CurrDayOfWeek}

   OneTicProcessed := False;
   TempInbound := Inbound;

   if TempInbound=Nil then
   begin
      Writeln(' * Undefined INBOUND directory');
      Writeln(LogFile,Prelog(LogError),'Undefined INBOUND directory');
      Flush(LOgFile);
   end else
   While TempInbound<>Nil do
   begin
      if TempInbound^.Descrizione<>Nil then
      begin
         PathDown := TempInbound^.Descrizione^;
         TempInbound1 := TempInbound^.Next;
         While (TempInbound1<>Nil) do
         begin
            if (TempInbound1^.Descrizione<>Nil) and
               (TempInbound1^.Descrizione^=PathDown) then
            begin
               {duplicato, rimuovere}
               FreeMem(TempInbound1^.Descrizione, length(TempInbound1^.Descrizione^)+1);
               TempInbound1^.Descrizione := Nil;
            end;
            TempInbound1 := TempInbound1^.Next;
         end;
         Writeln(' * Scanning ',PathDown);
         Writeln(LogFile,Prelog(LogStart),'Scanning ',PathDown);
         Flush(LOgFile);
         CheckTic1(PathDown);
      End;
      TempInbound := TempInbound^.Next
   End;

   SaveCfg;
   CheckTic := OneTicProcessed;

End {CheckTic};

End.
