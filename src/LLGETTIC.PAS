Unit LLGetTic;

{$I LL.DEF}

Interface

Uses MkFile, MkGlobT, MkString, LLGEN;

Procedure ImportTic;
Procedure SaveCfg;

implementation

Uses
   LLText;

Procedure SaveCfg;
Const SizeBuf=8192;
Var I:Integer;
    Buf:Pointer;
   F:Text;

   Procedure WriteTic;
   Var Cfg:Text;
       I, J : Integer;
       Pw:String;
       TempAddrList:AddrListTypeRef;
       TempDescTypePtr:DescTypePtr;
   Begin
      {elimina il vecchio *.Bak}
      if EraseFile(D0 + 'Tic.Bak') then;
      {crea nuovo backup}
      Assign(Cfg,D0+'Tic.Cfg');
      {$I-}
      Rename(Cfg,D0 + 'Tic.Bak');
      {$I+}
      if Ioresult<>0 then;
      {ed ora salva la nuova versione}
      GetMem(Buf,SizeBuf);
      if shMakeTextFile(Cfg,D0+'Tic.Cfg') then
      begin
         SetTextBuf(Cfg,Buf^,SizeBuf);
         {informazioni globali}
         Writeln(Cfg,'; Created by L-List ',versione);
         for I := 1 to NTicAreas do
         Begin
            Writeln(CFg);
            if TicAreas[i]^.AreaDesc<>'' then
               Writeln(cfg, '; ', TicAreas[I]^.AreaDesc);
            Write(Cfg,'AREA ',TicAreas[I]^.Download,' ',TicAreas[I]^.Tag);
            if TicAreas[I]^.SecTag<>'' then
               Write(Cfg,' ',TicAreas[I]^.SecTag);
            Writeln(Cfg);
            {linee "Local" di LLIST}
            if TicAreas[I]^.Mode<>TicSend then
            begin
               if TicAreas[I]^.Mode=TicReceive then
                  Writeln(cfg,#9'Local LLIST Flag *&')
               else
                  Writeln(cfg,#9'Local LLIST Flag *');
            end;
            if TicAreas[I]^.Repack<>'' then
               Writeln(cfg,#9'Local LLIST Repack ',TicAreas[i]^.Repack);
            Writeln(cfg,#9'Local LLIST Address ',AddrStr(Aka[TicAreas[i]^.Address]));
            if TicAreas[i]^.TicLevel>0 then
               Writeln(cfg,#9'Local LLIST Level ',TicAreas[i]^.TicLevel);
            if TicAreas[i]^.Group<>'' then
               Writeln(cfg,#9'Local LLIST Group ',TicAreas[i]^.Group);
            Writeln(cfg,#9'Local LLIST Bytes ',TicAreas[i]^.BytesMonth);
            if TicAreas[i]^.ReadFile_id then
               Writeln(cfg,#9'Local LLIST ReadFile_Id');
            TempAddrList := TicAreas[I]^.Nodes;
            While (TempAddrList<>Nil) do
            begin
               J := 1;
               while (J<=NTicNodes) and not AddrEqual(TicNodes[J]^.Node,TempAddrList^.Node) do
                   inc(J);
               if J<=NTicNodes then
               begin
                  Write(Cfg,#9,AddrStr(TempAddrList^.Node),' ',TicNodes[J]^.Pw);
               End else
               begin
                  Write(Cfg,#9,AddrStr(TempAddrList^.Node),' UNKNOWN');
               End;
               if TempAddrList^.Mode=TicSend then
                  Writeln(Cfg)
               else
               if TempAddrList^.Mode=TicReceive then
                  Writeln(Cfg,' *&')
               else
                  Writeln(Cfg,' *');
               TempAddrList := TempAddrList^.Next;
            End;
         End;
         Close(Cfg);
         Writeln(' * Save updated Tic.Cfg');
         Writeln(logfile,prelog(LogWork),'Save updated Tic.Cfg');
         flush(logFile);
      End;
      FreeMem(Buf,SizeBuf);
   End {WriteTicCfg};

   Procedure SaveNode1(N:Integer);
   Begin
      Writeln(F);
      Writeln(F,'TicNode ',AddrStr(TicNodes[N]^.Node));
      Writeln(F,#9'Pw ',TicNodes[N]^.Pw);
      if TicNodes[N]^.TicLevel>0 then
         Writeln(F,#9'Level ',TicNodes[N]^.TicLevel);
      case TicNodes[N]^.Flavour of
         'C':Writeln(F,#9'Crash');
         'H':Writeln(F,#9'Hold')
      end;
      if TicNodes[N]^.Notify then
         Writeln(F,#9'Notify');
      if not TicNodes[N]^.SendTic then
         Writeln(F,#9'NoTIC');
      if TicNodes[N]^.RemoteMaint then
         Writeln(F,#9'RemoteMaint');
      if TicNodes[N]^.TinySeenBy then
         Writeln(F,#9'TinySeenBy');
      if TicNodes[N]^.SendAnnounce then
         Writeln(F,#9'Announce');
      if TicNodes[N]^.RequireUpLink then
         Writeln(F,#9'RequireUpLink');
      if TicNodes[N]^.Packer<>'' then
         Writeln(F,#9'Packer ',TicNodes[N]^.Packer);
      if TicNodes[N]^.MaxfileSize>0 then
         Writeln(F,#9'MaxFileSize ',TicNodes[N]^.MaxFileSize);
      Writeln(F,'End');
   End {SaveNode1};

   ProceDure SaveGroup1(N:Integer);
   Var TempNode:AddrListTypeRef;
       TempDescTypePtr:DescTypePtr;
   Begin
      Writeln(F);
      Writeln(F,'TicGroup ',TicGroups[N]^.Tag);
      TempNode := TicGroups[N]^.Nodes;
      if TicGroups[N]^.TicLevel<>0 then
         Writeln(F,#9'Level ',TicGroups[N]^.TicLevel);
      Writeln(F,#9'Address ',AddrStr(Aka[TicGroups[N]^.Address]));
      if ticGroups[N]^.UplinkNode>0 then
         Writeln(F,#9'Uplink ',AddrStr(Ticnodes[TicGroups[N]^.UplinkNode]^.Node));
      TempDescTypePtr := TicGroups[N]^.GroupId;
      while TempDescTypePtr<>Nil do
      begin
         Writeln(F,#9'GroupId ',TempDescTypePtr^.Descrizione^);
         TempDescTypePtr := TempDescTypePtr^.Next
      end;
      While TempNode<>Nil do
      begin
         Writeln(F,#9'Node ',AddrStr(TempNode^.Node));
         TempNode := TempNode^.Next
      end;
      Writeln(F,'End');
   End {SaveGroup1};

Begin

   if TicAreasModified then
   begin
      if EraseFile(D0 + 'LLTic.Bak') then;
      Assign(F,D0+'LLTic.Cfg');
      {$I-}
      Rename(F,D0 + 'LLTic.Bak');
      {$I+}
      if IOResult<>0 then;
      GetMem(Buf,SizeBuf);
      if shMakeTextFile(F,D0+'LLTic.Cfg') then
      begin
         SetTextBuf(F,Buf^,SizeBuf);
         Writeln(F,'; Created by L-List ',versione);
         for I := 1 to NTicNodes do
            SaveNode1(I);
         for I := 1 to NTicGroups do
            SaveGroup1(I);
         {le aree sono salvate nel solo Tic.Cfg}
         {le info aggiuntive per LLIST vengono scritte nelle linee}
         {che iniziano con "Local LLIST"}
         close(F);
         Writeln(' * Save updated LLTic.Cfg');
         Writeln(logfile,prelog(LogWork),'Save updated LLTic.Cfg');
         flush(logFile);
         TicAreasModified := False;
      end;
      FreeMem(Buf,SizeBuf);
   end;
   if TicCfgModified then
   begin
      WriteTic;
      TicCfgModified := False;
   end;
end {SaveCfg};


Procedure ImportTic;
Const SizeBuf=8192;
Var Cfg:Text;
    I:Integer;
    Found:Boolean;
    TempAddr:AddrType;
    TicMode:Byte;
    Buf:Pointer;
    Linea:Integer;
    TempWord:Word;
    NewTicMode:Byte;
    {$IFDEF VIRTUALPASCAL}
    Code: Longint;
    {$ENDIF}

       Procedure GetAreaNumbers;
       Var I:Integer;
       Begin
          ResetAreaFile;
          While GetNextArea do
          Begin
             for I := 1 to NTicAreas do
             if (TicAreas[I]^.Number<0) and (TicAreas[I]^.Download = PathDown) then
             begin
                TicAreas[I]^.Number := Numero;
                TicAreas[I]^.PathFBbs := PathFBbs;
                {mette il nome dell'area}
                if TicAreas[I]^.Tag<>Nome then
                begin
                   TicAreas[I]^.AreaDesc := Nome;
                end;
             end
          End;
          {Questo servira' per il numero delle nuove aree}
          LastNumero := Numero;
          {Aree orfane}
          For I := 1 to NTicAreas do
          if TicAreas[I]^.Number=-1 then
          begin
             TicAreas[I]^.Number := Numero;
             inc(Numero);
             L := Copy(TicAreas[I]^.Download,1,length(TicAreas[I]^.DownLoad)-1);
             PosDesc := 1;
             PutDescrizione(FileAreaListRef^);
             FileAreaListRef := Addr(FileAreaListRef^^.Next);
          end;
       End {GetAreaNumbers};

       Procedure ParseTicNode;
       Var I,J:INteger;
           TempLong: Longint;
       Begin
          if NTicNodes<NMaxTicNodes then
          begin
             {verifica NODE}
             delete(TempStr,1,8);
             stripLeadingSpace(TempStr);
             inc(NTicNodes);
             New(TicNodes[NTicNodes]);
             if ParseAddr(TempStr,TicNodes[NTicNodes]^.Node,
                TicNodes[NTicNodes]^.Node) then;
             TicNodes[NTicNodes]^.Pw := '';
             TicNodes[NTicNodes]^.TicLevel := 0;
             TicNodes[NTicNodes]^.Flavour := 'F';
             TicNodes[NTicNodes]^.SendTic := True;
             TicNodes[NTicNodes]^.RemoteMaint := False;
             TicNodes[NTicNodes]^.Notify := False;
             TicNodes[NTicNodes]^.TinySeenBy := False;
             TicNodes[NTicNodes]^.SendAnnounce := False;
             TicNodes[NTicNodes]^.Packer := '';
             TicNodes[NTicNodes]^.RequireUplink := False;
             TicNodes[NTicNodes]^.RequireTicAreas := Nil;
             TIcNodes[NTicNodes]^.RequireTicAreasRef := Addr(TicNodes[NTicNodes]^.RequireTicAreas);
             TicNodes[NTicNodes]^.MaxFileSize := 0;
             while not eof(Cfg) and (TempStr<>'END') do
             begin
                readln(Cfg,TempStr);
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
                   if Pos('PW ',TempStr)=1 then
                   begin
                      delete(TempStr,1,3);
                      stripLeadingSpace(TempStr);
                      For I := 1 to length(TempStr) do
                         TempStr[I] := UpCase(TempStr[I]);
                      TicNodes[NTicNodes]^.Pw := TempStr;
                   end else
                   if Pos('LEVEL ',TempStr)=1 then
                   begin
                      delete(TempStr,1,6);
                      stripLeadingSpace(TempStr);
                      Val(TempStr,TempWord,Code);
                      if Code=0 then
                         TicNodes[NTicNodes]^.TicLevel := TempWord;
                   end else
                   if Pos('MAXFILESIZE ',TempStr)=1 then
                   begin
                      delete(TempStr,1,12);
                      stripLeadingSpace(TempStr);
                      Val(TempStr,TempLong,Code);
                      if Code=0 then
                         TicNodes[NTicNodes]^.MaxFileSize := TempLong;
                   end else
                   if Pos('PACKER ',TempStr)=1 then
                   begin
                      delete(TempStr,1,7);
                      StripLeadingSpace(TempStr);
                      if length(TempStr)=3 then
                         TicNodes[NTicNodes]^.Packer := Upper(TempStr);
                   end else
                   if TempStr='ANNOUNCE' then
                   begin
                      TicNodes[NTicNodes]^.SendAnnounce := True;
                   end else
                   if TempStr='NOTIFY' then
                   begin
                      TicNodes[NTicNodes]^.Notify := True;
                   end else
                   if TempStr='NOTIC' then
                   begin
                      TicNodes[NTicNodes]^.SendTic := False;
                   end else
                   if TempStr='REQUIREUPLINK' then
                   begin
                      TicNodes[NTicNodes]^.RequireUpLink := True;
                   end else
                   if TempStr='REMOTEMAINT' then
                   begin
                      TicNodes[NTicNodes]^.RemoteMaint := True;
                   end else
                   if TempStr='TINYSEENBY' then
                   begin
                      TicNodes[NTicNodes]^.TinySeenBy := True;
                   end else
                   if TempStr='CRASH' then
                   begin
                      TicNodes[NTicNodes]^.Flavour := 'C'
                   end else
                   if TempStr='HOLD' then
                   begin
                      TicNodes[NTicNodes]^.Flavour := 'H'
                   end else
                   if TempStr='END' then
                   begin
                      {fine dell'area}

                   end else
                   begin
                      Writeln(' * Error in line ',Linea);
                      Writeln(LogFile,Prelog(LogError),'Error in line ',Linea);
                      Flush(LogFile);
                   End;
                end;
             end;
             If (TicNodes[NTicNodes]^.Pw='') then
             begin
                Dispose(TicNodes[NTicNodes]);
                Dec(NTicNodes);
             end else
             begin
                I := 1;
                while (I<NTicNodes) and not AddrEqual(TicNodes[I]^.Node,TicNodes[NTicNodes]^.Node) do
                   inc(I);
                if I<NTicNodes then
                begin
                   Dispose(TicNodes[NTicNodes]);
                   dec(NTicNodes);
                end;
             end;
          end else
          begin
             Writeln(' * Too many TicNodes');
             Writeln(LogFile,Prelog(LogError),'Too many TicNodes');
             Flush(LogFile);
             while (TempStr<>'END') and not eof(Cfg) do
             begin
                readln(Cfg,TempStr);
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
       End {ParseTicNode};


       Procedure ParseTicGroup;
       Var I,J:INteger;
          TempTicGroup:TicGroupType;
          TicMode:Byte;
       Begin
          if NTicGroups<NMaxTicGroups then
          begin
             {verifica TAG}
             delete(TempStr,1,9);
             stripLeadingSpace(TempStr);
             inc(NTicGroups);
             New(TicGroups[NTicGroups]);
             For I := 1 to length(TempStr) do
                TempStr[I] := UpCase(TempStr[I]);
             TicGroups[NTicGroups]^.Address := 0;
             TicGroups[NTicGroups]^.Tag := TempStr;
             TicGroups[NTicGroups]^.Nodes := Nil;
             TicGroups[NTicGroups]^.GroupId := Nil;
             TicGroups[NTicGroups]^.TicLevel := 0;
             TicGroups[NTicGroups]^.Aree := Nil;
             TicGroups[NTicGroups]^.UplinkNode := -1;
             while not eof(Cfg) and (TempStr<>'END') do
             begin
                readln(Cfg,TempStr);
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
                   if Pos('LEVEL ',TempStr)=1 then
                   begin
                      delete(TempStr,1,6);
                      stripLeadingSpace(TempStr);
                      Val(TempStr,TempWord,Code);
                      if Code=0 then
                         TicGroups[NTicGroups]^.TicLevel := TempWord;
                   end else
                   if Pos('ADDRESS ',TempStr)=1 then
                   begin
                      delete(TempStr,1,8);
                      stripLeadingSpace(TempStr);
                      if ParseAddr(TempStr,TempAddr,TempAddr) then
                      begin
                         TicGroups[NTicGroups]^.Address := AddAka(TempAddr);
                      end;
                   end else
                   if Pos('NODE ',TempStr)=1 then
                   begin
                      delete(TempStr,1,5);
                      stripLeadingSpace(TempStr);
                      if ParseAddr(TempStr,TempAddr,TempAddr) then
                         if AddNode(TicGroups[NTicGroups]^.Nodes,TempAddr,TicSend+TicReceive) then;
                   end else
                   if Pos('UPLINK ',TempStr)=1 then
                   begin
                      delete(TempStr,1,7);
                      stripLeadingSpace(TempStr);
                      if (TicGroups[NTicGroups]^.UplinkNode=-1) and ParseAddr(TempStr,TempAddr,TempAddr) then
                      begin
                         TicGroups[NTicGroups]^.UplinkNode := 1;
                         while (TicGroups[NTicGroups]^.UplinkNode<=NTicNodes) and not
                             AddrEqual(TicNodes[TicGroups[NTicGroups]^.UplinkNode]^.Node,TempAddr) do
                            inc(TicGroups[NTicGroups]^.UplinkNode);
                         if TicGroups[NTicGroups]^.UplinkNode>NticNodes then
                            TicGroups[NTicGroups]^.UplinkNode := -1;
                      end;
                   end else
                   if Pos('GROUPID ',TempStr)=1 then
                   begin
                      DElete(TempStr,1,8);
                      StripLeadingSpace(TempStr);
                      TempStr := Upper(TempStr);
                      while TempStr<>'' do
                      begin
                         J := Pos(' ',TempStr);
                         if J=0 then
                            J := length(tempStr)+1;
                         L := copy(TempStr,1,J-1);
                         PosDesc := 1;
                         PutDescrizione(TicGroups[NTicGroups]^.GroupId);
                         Delete(TempStr,1,J-1);
                         StripLeadingSpace(TempStr)
                      end;
                   end else
                   if TempStr='END' then
                   begin
                      {fine dell'area}

                   end else
                   begin
                      Writeln(' * Error in line ',Linea);
                      Writeln(LogFile,Prelog(LogError),'Error in line ',Linea);
                      Flush(LOgFile);
                   End;
                end;
             end;
             If (TicGroups[NTicGroups]^.Tag='') or (TicGroups[NTicGroups]^.Tag[1]='!') or
                (TicGroups[NTicGroups]^.GroupId=Nil) then
             begin
                Dispose(TicGroups[NTicGroups]);
                Dec(NTicGroups);
             end else
             begin
                I := 1;
                While (I<NTicGroups) and (TicGroups[I]^.Tag<TicGroups[NTicGroups]^.Tag) do
                   inc(I);
                if (I<NTicGroups) then
                begin
                   TempTicGroup := TicGroups[NTicGroups]^;
                   for J := NTicGroups downto I+1 do
                      TicGroups[J]^ := TicGroups[J-1]^;
                   TicGroups[I]^ := TempTicGroup
                end
             end;
          end else
          begin
             Writeln(' * Too many TicGroups');
             Writeln(LogFile,Prelog(LogError),'Too many TicGroups');
             Flush(LogFile);
             while (TempStr<>'END') and not eof(Cfg) do
             begin
                readln(Cfg,TempStr);
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
       End {ParseTicGroup};

Begin

   GetMem(Buf,SizeBuf);

   if shOpenTextFile(Cfg,D0 + 'LLTic.Cfg') then
   begin
      SetTextBuf(cfg,Buf^,SizeBuf);
      Writeln(' * Parsing ',D0,'LLTic.Cfg');
      Writeln(LogFile,Prelog(LogStart),'Parsing ',D0,'LLTic.Cfg');
      Flush(LOgFile);
      Linea := 0;
      while not eof(Cfg) do
      begin
         readln(Cfg,TempStr);
         inc(linea);
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
            if Pos('TICNODE ',TempStr)=1 then
            begin
               ParseTicNode;
            end else
            if Pos('TICGROUP ',TempStr)=1 then
            begin
               ParseTicGroup;
            end else
            begin
               Writeln(' * Error in line ',Linea);
               Writeln(LogFile,Prelog(logError),'Error in line ',Linea);
               Flush(LOgFile);
            end;
         end;
      end;
      close(Cfg);
   end else
   begin
      Writeln(' * ',D0,'LLTic.Cfg not found');
      Writeln(LOgFile,Prelog(logError),D0,'LLTic.Cfg not found');
      Flush(LogFile);
   end;

   if shOpenTextFile(Cfg,D0 + 'Tic.Cfg') then
   begin
      SetTextBuf(Cfg,Buf^,SizeBuf);
      Linea := 0;
      Writeln(' * Parsing ',D0,'Tic.Cfg');
      Writeln(LogFile,Prelog(LogStart),'Parsing ',D0,'Tic.Cfg');
      Flush(LOgFile);
      TempStr := '';
      While ((TempStr<>'') or not eof(Cfg)) and (NTicAreas < NMaxTicAreas) do
      Begin
         if TempStr='' then
         begin
            ReadLn(Cfg,TempStr);
            inc(linea);
         end;
         StripLeadingSpace(TempStr);
         I := 1;
         While (I<=Length(TempStr)) and (TempStr[I]<>' ') do
         begin
            TempStr[I] := UpCase(TempStr[I]);
            Inc(I);
         End;
         if (pos('AREA ',TempStr)=1) then
         begin
            {Trovata un'area TIC}
            Delete(TempStr,1,5);
            StripLeadingSpace(TempStr);
            TempStr := Upper(TempStr);
            I := pos(' ',TempStr);
            if I=0 then
               I := length(TempStr)+1;
            inc(NTicAreas);
            New(TicAreas[NTicAreas]);
            TicAreas[NTicAreas]^.Download := WithbackSlash(Upper(Copy(TempStr,1,I-1)));
            if I<=length(TempStr) then
               Delete(TempStr,1,I)
            else
               TempStr := '';
            StripLeadingSpace(TempStr);
            I := pos(' ',TempStr);
            If I=0 then
               I := length(TempStr)+1;
            TicAreas[NTicAreas]^.Tag := Copy(TempStr,1,I-1);
            delete(TempStr,1,I-1);
            StripLeadingSpace(TempStr);
            if TempStr<>'' then
            begin
               I := pos(' ',TempStr);
               if I>0 then
                  TempStr := Copy(TempStr,1,I-1);
               TicAreas[NTicAreas]^.SecTag := TempStr;
            end else
               TicAreas[NTicAreas]^.SecTag := '';
            TicAreas[NTicAreas]^.PathFBbs := '';
            TicAreas[NTicAreas]^.Nodes := Nil;
            TicAreas[NTicAreas]^.TicLevel := 0;
            TicAreas[NTicAreas]^.Address := 0;
            TicAreas[NTicAreas]^.Repack := '';
            TicAreas[NTicAreas]^.Mode := TicSend;
            TicAreas[NTicAreas]^.Number := -1;
            TicAreas[NTicAreas]^.AreaDesc := '';
            TicAreas[NTicAreas]^.Group := '';
            TicAreas[NTicAreas]^.BytesMonth := BytesMonthDefault;
            TicAreas[NTicAreas]^.ReadFile_id := False;
            {Ignora le linee Local}
            Found := False;
            TempStr := '';
            While not found and not eof(Cfg) do
            begin
               ReadLn(Cfg,TempStr);
               Inc(Linea);
               StripLeadingSpace(TempStr);
               I := 1;
               While (I<=Length(TempStr)) and (TempStr[I]<>' ') do
               begin
                  TempStr[I] := UpCase(TempStr[I]);
                  Inc(I);
               End;
               Found :=  pos('LOCAL',TempStr)<>1;
               if not Found then
               begin
                  {e' una linea local, se e' per LLIST la processa}
                  {altrimenti la ignora}
                  Delete(TempStr,1,5);
                  StripLeadingSpace(TempStr);
                  if pos('LLIST',TempStr)=1 then
                  begin
                     delete(TempStr,1,5);
                     StripLeadingSpace(TempStr);
                     if TempStr<>'' then
                     begin
                        {prima word in UpCase}
                        I := 1;
                        while (I<=Length(TempStr)) and (TempStr[I]<>' ') do
                        begin
                           TempStr[I] := UpCase(TempStr[I]);
                           inc(I)
                        end;
                        if Pos('LEVEL ',TempStr)=1 then
                        begin
                           delete(TempStr,1,6);
                           stripLeadingSpace(TempStr);
                           Val(TempStr,TempWord,Code);
                           if Code=0 then
                              TicAreas[NTicAreas]^.TicLevel := TempWord;
                        end else
                        if Pos('BYTES ',TempStr)=1 then
                        begin
                           delete(TempStr,1,6);
                           stripLeadingSpace(TempStr);
                           Val(TempStr,TempLong,Code);
                           if (Code=0) and (TempLong>=0) then
                              TicAreas[NTicAreas]^.BytesMonth := TempLong;
                        end else
                        if Pos('ADDRESS ',TempStr)=1 then
                        begin
                           delete(TempStr,1,8);
                           stripLeadingSpace(TempStr);
                           if ParseAddr(TempStr,TempAddr,TempAddr) then
                           begin
                              TicAreas[NTicAreas]^.Address := AddAka(TempAddr);
                           end;
                        end else
                        if Pos('FLAG ',TempStr)=1 then
                        begin
                           delete(TempStr,1,5);
                           if pos('*',TempStr)>0 then
                              TicAreas[NTicAreas]^.Mode := TicAreas[NTicAreas]^.Mode or 2;
                           if pos('&',TempStr)>0 then
                              TicAreas[NTicAreas]^.Mode := TicAreas[NTicAreas]^.Mode and (255 - 1);
                        end else
                        if Pos('REPACK ',TempStr)=1 then
                        begin
                           delete(TempStr,1,7);
                           StripLeadingSpace(TempStr);
                           if length(TempStr)=3 then
                              TicAreas[NTicAreas]^.Repack := Upper(TempStr);
                        end else
                        if Pos('GROUP ',TempStr)=1 then
                        begin
                           delete(TempStr,1,6);
                           StripLeadingSpace(TempStr);
                           TicAreas[NTicAreas]^.Group := Upper(TempStr);
                        end else
                        if tempStr='READFILE_ID' then
                        begin
                           TicAreas[NTicAreas]^.ReadFile_id := True;
                        end else
                        {qui l'"End" non serve!}
                        begin
                           writeln(' * Error in line ',Linea);
                           Writeln(LOgFile,Prelog(LogError),'Error in line ',Linea);
                           Flush(LOgFile);
                        end;
                     end;
                  end;
               end;
            end;
            if found and (TempStr<>'') then
            begin
               Found := False;
               While not found and
                  ((TempStr<>'') or not eof(Cfg)) do
               begin
                  if TempStr='' then
                     ReadLn(cfg,TempStr);
                  StripLeadingSpace(TempStr);
                  TempStr := Upper(TempStr);
                  I := pos(' ',TempStr);
                  if (I>0) and ParseAddr(Copy(TempStr,1,I-1),TempAddr,TempAddr) then
                  begin
                     delete(TempStr,1,I);
                     StripLeadingSpace(TempStr);
                     I := pos(' ',TempStr);
                     if I=0 then
                        I := length(TempStr) +1;
                     if pos('&',TempStr)>I then
                        TicMode := 0
                     else
                        TicMode := TicSend;
                     if pos('*',TempStr)>I then
                        TicMode := TicMode Or TicReceive;
                     TempStr := Copy(TempStr,1,I-1);
                     if AddNode(TicAreas[NTicAreas]^.Nodes,TempAddr,TicMode) then;
                     if (NTicNodes<NMaxTicNodes) and (TempStr<>'UNKNOWN') then
                     begin
                        I := 1;
                        while (I<=NTicNodes) and not AddrEqual(TicNodes[I]^.Node,TempAddr) do
                           inc(I);
                        if (I>NTicNodes) then
                        begin
                           Inc(NTicNodes);
                           New(TicNodes[NTicNodes]);
                           TicNodes[NTicNodes]^.Node := TempAddr;
                           TicNodes[NTicNodes]^.Pw := Upper(TempStr);
                           TicNodes[NTicNodes]^.Flavour := 'F';
                           TicNodes[NTicNodes]^.Notify := False;
                           TicNodes[NTicNodes]^.RequireTicAreas := Nil;
                           TicNodes[NTicNodes]^.RequireTicAreasRef :=
                              Addr(TicNodes[NTicNodes]^.RequireTicAreas);
                           TicNodes[NTicNodes]^.RemoteMaint := False;
                           TicNodes[NTicNodes]^.SendAnnounce := False;
                           TicNodes[NTicNodes]^.Packer := '';
                           TicNodes[NTicNodes]^.TicLevel := 0;
                           TicNodes[NTicNodes]^.SendTic := True;
                           TicNodes[NTicNodes]^.TinySeenBy := False;
                           TicNodes[NTicNodes]^.RequireUplink := False;
                           TicNodes[NTicNodes]^.MaxFileSize := 0;
                           TicAreasModified := True;
                        End;
                     end;
                     TempStr := '';
                  End else
                     Found := True
               End;
            End;
            {Aggiunge l'area}
            if (TicAreas[NTicAreas]^.Download='') or (TicAreas[NTicAreas]^.Tag='') then
            begin
               DeleteNodes(TicAreas[NTicAreas]^.Nodes);
               Dispose(TicAreas[NTicAreas]);
               dec(NTicAreas);
               TicCfgModified := True;
            end;
         End else
            TempStr := '';
      End;
      Close(Cfg);
   end else
   begin
      Writeln(' * ',D0,'Tic.Cfg not found');
      Writeln(LOgFile,Prelog(logError),D0,'Tic.Cfg not found');
      Flush(LOgFile);
   end;

   if OutBound[0]=Nil then
   begin
      MailAttach := True
   end;

   I := 1;
   while I<=NTicAreas do
   begin
      if TicAreas[I]^.Download='' then
      begin
         {e' gia' true, visto che l'area e' stata senz'altro letta dal LLTic.Cfg}
         TicAreasModified := True;
         DeleteNodes(TicAreas[I]^.Nodes);
         Dispose(TicAreas[I]);
         For J := I to NTicAreas-1 do
            TicAreas[J] := TicAreas[J+1];
         dec(NTicAreas);
      end else
         inc(I);
   end;

   GetAreaNumbers;

   For I := 1 to NTicAreas do
   begin
      if TicAreas[I]^.Group='' then
      begin
         {intanto vede se appartiene ad un gruppo gia' esistente}
         J := 1;
         while (j<=NTicGroups) and not ChkGroup(TicAreas[I]^.Tag, TicGroups[J]^.GroupId) do
            inc(J);
         if (J<=NTicGroups) then
         begin
            TicAreas[I]^.Group := TicGroups[J]^.Tag;
            TicCfgModified := True;
            PutInListaAree(TicAreas[I]^.Number,TicAreas[I]^.Number,TicGroups[J]^.Aree)
         end else
         if (NTicGroups<NMaxTicGroups) then
         begin
            {crea un nuovo gruppo}
            J := 1;
            While (J<=length(TicAreas[I]^.Tag)) and (J<=3) and
                (TicAreas[I]^.Tag[J] in ['0'..'9','A'..'Z']) do
               Inc(J);
            dec(J);
            if (J>0) and (TicAreas[I]^.Tag[1]<>'!') then
            begin
               TicAreas[I]^.Group := Copy(TicAreas[I]^.Tag,1,J);
               TicCfgModified := True;
               TicAreasModified := True;
               Inc(NTicGroups);
               New(TicGroups[NTicGroups]);
               TicGroups[NTicGroups]^.Tag := TicAreas[I]^.Group;
               TicGroups[NTicGroups]^.GroupId := Nil;
               L := TicAreas[I]^.Group;
               PosDesc := 1;
               PutDescrizione(TicGroups[NTicGroups]^.GroupId);
               TicGroups[NTicGroups]^.TicLevel := TicAreas[I]^.TicLevel;
               TicGroups[NTicGroups]^.Address := TicAreas[I]^.Address;
               TicGRoups[NTicGRoups]^.Nodes := Nil;
               TicGroups[NTicGroups]^.Aree := Nil;
               TicGroups[NTicGroups]^.UplinkNode := -1;
               PutInListaAree(TicAreas[I]^.Number,TicAreas[I]^.Number,TicGroups[J]^.Aree)
            End;
         end;
      End else
      begin
         J := 1;
         while (J<=NTicGroups) and (TicGroups[J]^.Tag<>TicAreas[I]^.Group) do
            inc(J);
         if (J<=NTicGroups) then
         begin
            PutInListaAree(TicAreas[I]^.Number,TicAreas[I]^.Number,TicGroups[J]^.Aree)
         end else
         if (TicAreas[I]^.Group[1]<>'!') and (NTicGroups<NMaxTicGroups) then
         begin
            TicAreasModified := True;
            Inc(NTicGroups);
            New(TicGroups[NTicGroups]);
            TicGroups[NTicGroups]^.Tag := TicAreas[I]^.Group;
            TicGroups[NTicGroups]^.GroupId := Nil;
            L := TicAreas[I]^.Group;
            PosDesc := 1;
            PutDescrizione(TicGroups[NTicGroups]^.GroupId);
            TicGroups[NTicGroups]^.TicLevel := TicAreas[I]^.TicLevel;
            TicGroups[NTicGroups]^.Address := TicAreas[I]^.Address;
            TicGRoups[NTicGRoups]^.Nodes := Nil;
            TicGroups[NTicGroups]^.Aree := Nil;
            TicGroups[NTicGroups]^.UplinkNode := -1;
            PutInListaAree(TicAreas[I]^.Number,TicAreas[I]^.Number,TicGroups[J]^.Aree)
         end;
      end;
   End;

   {Gruppi vuoti}
   For I := 1 to NTicGroups do
   if TicGroups[I]^.Aree=Nil then
   begin
      PutInListaAree(-1,-1,TicGroups[I]^.Aree)
   end;

   if shOpenTextFile(Cfg,D0+'Raid.Cfg') then
   begin
      SetTextBuf(Cfg,Buf^,SizeBuf);
      Writeln(' * Parsing ',D0,'Raid.Cfg');
      Writeln(LogFile,Prelog(logStart),'Parsing ',D0,'Raid.Cfg');
      Flush(LogFile);
      Linea := 0;
      While not eof(Cfg) do
      begin
         ReadLn(Cfg,TempStr);
         inc(linea);
         I := Pos('%',TempStr);
         if I>0 then
            TempStr := Copy(TempStr,1,I-1);
         if (length(TempStr)>5) and (Upper(Copy(TempStr,1,5))='AREA ') then
         begin
            Delete(TempStr,1,5);
            StripLeadingSpace(TempStr);
            I := Pos(' ',TempStr);
            if I>0 then
            begin
               {Tag}
               TempStr1 := Upper(Copy(TempStr,1,I-1));
               Delete(TempStr,1,I);
               StripLeadingSpace(TempStr);
               {Livello}
               I := pos(' ',TempStr);
               if I>0 then
                  delete(TempStr,1,I)
               else
                  TempStr := '';
               StripLeadingSpace(TempStr);
               {Flags}
               NewTicMode := TicSend;
               I := pos(' ',TempStr);
               J := pos('*',TempStr);
               if (J>0) and (J<I) then
                  NewTicMode := NewTicMode or TicReceive;
               J := pos('&',TempStr);
               if (J>0) and (J<I) then
                  NewTicMode := NewTicMode and (255-TicSend);
               if I>0 then
                  delete(TempStr,1,I)
               else
                  TempStr := '';
               StripLeadingSpace(TempStr);
               if TempStr<>'' then
               begin
                  I := 1;
                  while (I<=NTicAreas) and (TicAreas[I]^.Tag<>TempStr1) do
                     inc(I);
                  if (I<=NTicAreas) then
                  begin
                     if (TicAreas[I]^.AreaDesc='') then
                     begin
                        TicAreas[I]^.AreaDesc := TempStr;
                     end;
                     if NewTicMode<>TicAreas[I]^.Mode then
                     begin
                        TicAreas[I]^.Mode := NewTicMode;
                        TicCfgModified := True
                     end;
                  end else
                  begin
                     {area non esistente, disponibile sull'uplink?}
                     I := 1;
                     while (I<=NTicGroups) and not ChkGroup(TempStr1,TicGroups[I]^.GroupId) do
                        inc(I);
                     if (I<=NTicGroups) and (TicGroups[I]^.UplinkNode<>-1) then
                     begin
                        While length(TempStr1)<21 do
                           TempStr1 := TempStr1 + ' ';
                        L := TempStr1 + Long2Str(TicGroups[I]^.TicLevel,5) +
                          ' ' + TicMode2String(NewTicMode) +
                           ' ---- ' + TempStr;
                        if length(L)>=77 then
                        begin
                           L[0] := #77;
                           while L[length(L)]=' ' do
                              dec(L[0]);
                        end;
                        PutDescrizione(LastArea^);
                        LastArea := Addr(LastArea^^.Next);
                     end;
                  end;
               end;
            end;
         end;
      end;
      Close(Cfg);
   end else
   begin
      Writeln(' * ',D0,'Raid.Cfg not found');
      Writeln(LOgFile,Prelog(logError),D0,'Raid.Cfg not found');
      Flush(LogFile);
   end;

   for I := 1 to NTicAreas do
   if TicAreas[I]^.AreaDesc='' then
   begin
      if (TicAreas[I]^.Group<>'') and (TicAreas[I]^.Group[1]<>'!') then
         TempStr := TicAreas[I]^.Group + ': '
      else
         TempStr := '';
      TempStr := TempStr + TicAreas[I]^.Tag;
      TicAreas[I]^.AreaDesc := TempStr
   End;

   FreeMem(Buf,SizeBuf);
   SaveCfg;

End {ImportTic};

end.
