Program LList;

{
Lista dei File Per LORA 2.34 ... 2.40
}

{$I LL.Def}

{$IFDEF OS2}
   {$IFDEF VIRTUALPASCAL}
      {$M 32768, 200000, 655360}
   {$ENDIF}
{$ELSE}
   {$M 32768, 200000, 655360}
{$ENDIF}

Uses

     {$IFDEF OS2}
     {$ELSE}
        {$IFDEF DPMI}
        {$ELSE}
            {$IFOPT G+}
            _286,
            {$ENDIF}
        {$ENDIF}
     {$ENDIF}

     Crt, Dos,

     {$IFDEF OVR}
         OverLay, LLOvr,
     {$ENDIF}

     {librerie gestione base messaggi}
     MKString, MKGlobT, MkDos, MkFile,
     MkMisc, MkOpen, LLGEN, LLSETVAR,
     LLMSG,

     LLMAIN, LLMGIDX,
     LLMAGIC, LLHDR, LLBDL, LLSEARCH,

     LLSHELL, LLTIC, LLTIC1, LLGETTIC, LLCOLORS;

{$IFDEF OVR}
   {$O MkMsgAbs}
    {$O MkMsgSqu}
    {$O MkMsgHud}
    {$O MkMsgFid}
    {$O MkMsgjam}
   {$O MkOpen}
   {$O LLSETVAR}
   {$O LLMSG}
   {$O LLMAIN}
   {$O LLMGIDX}
   {$O LLMAGIC}
   {$O LLHDR}
   {$O LLBDL}
   {$O LLSEARCH}
   {$O LLPARSES}
   {$O LLCOMP}
   {$O LLCOPY}
   {$O LLERRMSG}
   {$O LLEXEC}
   {$O LLSHELL}
   {$O LLUUE}
   {$O LLTic}
   {$O LLColors}
   {$O LLTend}
   {$O LLGetDB}
   {$O LLTIC1}
   {$O LLFILEID}
   {$O LLMAIN1}
   {$O LLVIEW}
   {$O LLGETTIC}
{$ENDIF}

Var
    CurrTicNode:Integer;
    Interactive : Boolean;
    LastError:Word;
    TempB:Boolean;
    D: Dirstr;
    N: NameStr;
    E: ExtStr;
    I : Integer;
    NeedsIndexUpdate : Boolean;
    {$IFDEF VIRTUALPASCAL}
    TempWord: Longint;
    {$ENDIF}
    OldAree: ListaNumRef;

begin

   SetColor(0);
   PrevSort := FixFBbsSort;

   {parametri di default per la MkOpen}
   SetDefaultZone(Aka[0].Zone);
   SetDefaultPathAreasBbs(PathAreasBbs);
   SetPathHudson(PathHudson);

   if Bbs<>Unknown then
   begin
      TempWord := FileMode;
      FileMode := FmReadOnly_DN;
      if DirFiles=Nil then
      begin
         assign(f,BbsConfigName[Bbs]);
         {$I-}
         Reset(F,1);
         {$I+}
         LastError := IOResult;
      end else
      begin
         DirFilesPtr := DirFiles;
         Repeat
            assign(f,DirFiles^.Descrizione^);
            {$I-}
            Reset(F,1);
            {$I+}
            LastError := IOResult;
            if LastError<>0 then
               DirFilesPtr := DirFilesPtr^.Next
         until (LastError=0) or (DirFilesPtr=Nil);
      end;
      FileMode := TempWord;
      FindFirst(PathIdx,Archive+ReadOnly,S);
      if DosError=0 then
      begin
         GetFTime(F,TempLong);
         NeedsIndexUpdate := S.Time < TempLong;
         {$IFDEF OS2}
         FindClose(S);
         {$ENDIF}
      end else
         NeedsIndexUpdate := True;
   end else
   begin
      LastError := 0;
      NeedsIndexUpdate := False;
   end;

   if (LastError=0) then
   begin
      ResetAreaFile;
      case Bbs of
         Lora:begin
                 SizeAreaFile := SizeOf(AreaFileLoraType);
              end;
         Ra250:begin
                 SizeAreaFile := SizeOf(AreaFileRa250Type);
              end;
         SBBS:begin
                 SizeAreaFile := SizeOf(AreaFileSBBSType);
              end;
         Max:begin
                 seek(f,4);
                 blockread(f,SizeAreaFile,2,TempWord);
                 seek(f,0);
              end;
         Max300:begin
                 {salta l'header}
                 seek(f,4);
                 SizeAreaFile := 16384;
              end;
         QBbs:begin
                 SizeAreaFile := SizeOf(AreaFileQBbsType);
              end;
         PcBoard:begin
                 SizeAreaFile := SizeOf(AreaFilePcBoardType);
              end;
      end;

      if (Bbs<>Unknown) then
      begin
         FileAreaToRead := 16384 div SizeAreaFile;
         GetMem(AreaFile,SizeAreaFile*FileAreaToRead);
      end;

      Lock(D0+'Tic');
      GetTicInfo;
      Unlock(D0+'Tic');

      {Prepara la lista dei magic names}
      For I := 1 to NMagic do
      begin
         if Magic[I]=Nil then
         begin
            TempStr := ''
         end else
         begin
            TempStr := ExpandMagic(Magic[I]);
            Freemem(Magic[I],length(Magic[I]^)+1);
         end;
         GetMem(Magic[I],length(TempStr)+1);
         Magic[I]^ := TempStr
      end;

      {Liste files}
      CurrFileList := 0;

      if LlistStatus=Unselected then
      begin
         {controlla se c'e' qualche opzione in coda}
         LlistStatus := Unselected;
         while (LlistStatus<>LlistEnd) and not (llistStatus in OtherOptions) do
            inc(LlistStatus);
         if llistStatus=LlistEnd then
           lliststatus := EditFilesBbs
      end;

      Interactive := LlistStatus=EditFilesBbs;
      if (LListStatus=EditFilesBbs) and not NeedsIndexUpdate then
      begin
         RemoveListaNum(Aree);
         Aree := Nil;
         GetLListStatus;
         ClrScr;
         GotoXY(1,10);
      End;

      if NeedsIndexUpdate then
      begin
         Writeln(' * File Idx out of date');
         Writeln(LogFile,Prelog(LogError),'File Idx out of date');
         flush(logFile);
         if LlistStatus<>llistend then
            OtherOptions := OtherOptions + [LlistStatus];
         LlistStatus := FileIdx;
         OldAree := Aree;
         Aree := Nil;
      end;

      {Ciclo principale}
      while (LListStatus<>LListEnd) do
      begin

         ResetAreaFile;
         FixFBbsSort := PrevSort;

         SetColor(0);
         HdrStyle := 1;

         if LlistStatus=HatchFile then
         begin
            OtherOptions := OtherOptions - [HatchFile];
            FSplit(HatchName,D,N,E);
            if D<>'' then
            begin
               if D[length(D)]<>'\' then
                  D := D + '\';
            end;
            I := 1;
            while (I<=NTicAreas) and (TicAreas[I]^.Tag<>HatchArea) do
               inc(I);
            if I<=NTicAreas then
            begin
               Lock(D0+'Tic');
               if TicAreas[I]^.Number<>-1 then
                  Lock(D0+'Area'+Long2Str(TicAreas[I]^.Number,0));
               if D='' then
                  D := TicAreas[I]^.Download;
               FindFirst(D+N+E,Archive+ReadOnly,S);
               if DosError<>0 then
               begin
                  Writeln(' * ',D,N,E,' not found');
                  Writeln(LogFile,Prelog(LogError),D,N,E,' not found');
                  flush(logFile);
               end else
               While DosError=0 do
               begin
                  TempDescTypePtr := Nil;
                  L := HatchDesc;
                  if L='' then
                     L := OrfanoStr(N+E);
                  PosDesc := 1;
                  putdescrizione(TempDescTypePtr);
                  Hatch(D,S.Name,'','',TempDescTypePtr,
                     TicAreas[I]^.Nodes, TicAreas[I]^.Tag, '',
                     Aka[TicAreas[I]^.Address],
                     S.Size, S.Time, TicAreas[i]^.AreaDesc);
                  cancelladescrizione(TempDescTypePtr);
                  FindNext(S);
               end;
               if TicAreas[I]^.Number<>-1 then
                  UnLock(D0+'Area'+Long2Str(TicAreas[I]^.Number,0));
               Unlock(D0+'Tic');
            end else
            begin
               Writeln(' * Invalid area ',HatchArea);
               Writeln(LogFile,Prelog(LogError),'Invalid area ',HatchArea);
               flush(logFile);
            end;
            if Interactive then
            begin
               GetLListStatus;
               ClrScr;
               GotoXY(1,10);
            End else
               LListStatus := LListEnd;
         end else
         {Edit Files.Bbs}
         if LListStatus=EditFilesBbs then
         begin
            OtherOptions := OtherOptions - [EditFilesBbs];
            ViewContents := VcNo;
            QuietMode1 := QuietMode;
            QuietMode := True;
            FirstArea := True;
            RepackPerc := -1;
            FixFBbsSort := No;
            NoFirstLine := False;
            Sort := No;
            OffLIne := True;
            OtherFiles := True;
            Orfani := False;
            {queste serviranno per gli eventuali annunci}
            HdrStyle := MsgHdrStyle;
            Prefix := Nil;
            Suffix := Nil;
            MsgFrom := SysopName;
            MsgOrigin := BbsName;
            MsgTo := 'All';
            KludgeReply := '';
            KludgeFdn := '';

            {si' alle descrizioni multiple!}
            DelDupFBBS := False;
            Writeln(LogFile,PreLog(LogStart),'Editing Files.Bbs');
            Flush(LogFile);
            TotSize := 0;
            NTotFiles := 0;
            PrevNTotFiles := 0;
            TotNewSize := 0;
            NTotNewFiles := 0;
            PrevNTotNewFiles := 0;
            NAree := 0;

            if message[108]=nil then
                TempStr := 'Select area to edit'
            else
                TempStr := message[108]^;
            while GetArea(TempStr,True) do
            begin
               MakeList(PathFbbs,PathDown,Numero,Nome,Livello,Attr,False,IsCdRom);
               if message[108]=nil then
                   TempStr := 'Select area to edit'
               else
                   TempStr := message[108]^;
            end;
            QuietMode := QuietMode1;
            TextAttr := StartAttr;
            writeln(LogFile,PreLog(LogDone),'Total of ',NTotFiles,' files.');
            Flush(LOgFile);
            FirstArea := True;
            DosMode := False;

            if (UpDateFileIdx<>Nil) then
            begin
               Aree := UpdateFileIdx;
               UpDateFileIdx := Nil;
               LListStatus := FileIdx;
               ClrScr;
               GotoXY(1,10);
            end else
            begin
               GetLListStatus;
               ClrScr;
               GotoXY(1,10);
            End;
         end else
         if llistStatus=RaidProcess then
         begin
            OtherOptions := OtherOptions - [RaidProcess];
            Lock(D0+'Tic');
            KludgeReply := '';
            Raid;
            Flush(LogFile);
            Unlock(D0+'Tic');
            LListStatus := LListEnd;
         end else
         if LListStatus=TicProcess then
         begin
            OtherOptions := OtherOptions - [TicProcess];
            Lock(D0+'Tic');
            NTotFiles := 0;
            FirstShell := False;
            TempB := CheckTic;
            writeln(' * Total of ',NTotFiles,' files.');
            writeln(LogFile,PreLog(LogDone),'Total of ',NTotFiles,' files.');
            Flush(LogFile);
            Unlock(D0+'Tic');
            if TempB and not NoAnnounceAfterTic then
            begin
               LListStatus := Announce;
            end else
            if Interactive then
            begin
               GetLListStatus;
               ClrScr;
               GotoXY(1,10);
            End else
               LListStatus := LListEnd;
         end else
         begin
            case LListStatus of
               Announce:
               begin
                  OtherOptions := OtherOptions - [Announce];
                  {aggiorna la data corrente}
                  KludgeReply := '';
                  NoFirstLine := True;
                  CurrTicNode := 1;
                  CurrAnnounce := 0;
                  if NAnnounce=0 then
                     CurrAnnounce := 1;
                  lock(D0+'FileIdx');
                  lock(D0+'Announce');
                  TempWord := FileMode;
                  FileMode := FmReadWrite_DA;
                  assign(FilesIdxTot,PathIdx);
                  {$I-}
                  Reset(FilesIdxTot,SizeOf(IdxType));
                  {$I+}
                  if IOResult<>0 then
                  begin
                     rewrite(FilesIdxTot,SizeOf(IdxType));
                  end;
                  assign(AnnounceIdx,D0+'Announce.Idx');
                  {$I-}
                  Reset(AnnounceIdx, SizeOf(IdxType));
                  {$I+}
                  if IOResult<>0 then
                  begin
                     rewrite(AnnounceIdx,SizeOf(IdxType));
                  end;
                  FileMode := TempWord;
                  Right1 := FileSize(FilesIdxTot);
                  RightAnnounceIdx := FileSize(AnnounceIdx);
                  GetMem(BufAll,SizeTxtBuf);
                  {seleziona vari parametri per annuncio novita'}
                  Sort := Alfa;
                  Offline := False;
                  OtherFiles := True;
                  Orfani := False;
                  ModDc := StripDC;
                  {no alle descrizioni multiple!}
                  DelDupFBBS := True;
                  {valori di default}
                  UpDateFileIdx := Nil;
                  HdrStyle := MsgHdrStyle;
                  dec(Colonne);
               end;
               MakeSearch:
               begin
                  OtherOptions := OtherOptions - [MakeSearch];
                  KludgeReply := '';
                  GetMem(BufAll,SizeTxtBuf);
                  Orfani := false;
                  OtherFiles := True;
                  OffLine := True;
                  Sort := Alfa;
                  DelDupFBBS := False;
                  ModDc := StripDc;
                  PathAvail := '';
                  KludgeFdn := '';
                  CurrMsgArea := -1;
                  NStringSearch :=0;
                  StartingMsg := 1;
                  SearchPurge;
                  GetSearchStr;
                  HdrStyle := MsgHdrStyle;
                  dec(Colonne);

               end;
               FileIdx:
               begin
                  OtherOptions := OtherOptions - [FileIdx];
                  Lock(D0+'FileIdx');
                  {seleziona tutte le aree}
                  {lo mantiene se ADDFILEIDX, e se non esiste lo crea con size 0}
                  TempWord := FileMode;
                  FileMode := FmReadWrite_DA;
                  assign(FilesIdxTot,PathIdx);
                  {$I-}
                  Reset(FilesIdxTot,1);
                  {$I+}
                  if IOResult<>0 then
                  begin
                     rewrite(FilesIdxTot,1);
                  end;
                  FileMode := TempWord;
                  {Cancella files da rimpiazzare}
                  FirstMerge := True;
                  {Imposta parametri per FileIdx}
                  OffLine := False;
                  Orfani := False;
                  OtherFiles := TRue;
                  DelDupFBBS := TRue;
                  Sort := Alfa;
                  {lista comma}
                  LenRead1 := 2000;
                  GetMem(Buf4,LenRead1 * SizeOf(IdxType));
               end;
               FixFbbs:
               begin
                  OtherOptions := OtherOptions - [FixFBbs];
                  ViewContents := VcNo;
                  Orfani := True;
                  OtherFiles := True;
                  OffLIne := False;
                  ModDc := NoMod;
                  DelDupFBbs := True;
                  Sort := FixFBbsSort;
               end;
               MakeListSum, CDMakeListSum:
               begin
                  {Compilazione liste file, nessuna funzione estesa richiesta}
                  OtherOptions := OtherOptions - [LListStatus];
                  Lock(D0+'FileList');
                  repeat
                     inc(CurrFileList);
                  until (llistStatus=MakeListSum) XOR (FileList[CurrFileList]^.Cd);
                  PathAll := FileList[CurrFileList]^.PathAll;
                  FSplit(PathAll, D, N, PackAll);
                  if (PackAll='') then
                  begin
                     PathAll := PathAll + '.Txt';
                  end else
                  begin
                     Delete(PackAll,1,1);
                     PackAll := Upper(PackAll);
                     {quella estratta e' proprio l'estensione}
                     J := 1;
                     while (J<=NPacker) and (Packer[J]^.Ext<>PackAll) do
                        inc(J);
                     if J<=NPacker then
                     begin
                        PathAll := D + N + '.Txt';
                     end else
                     begin
                        PackAll := '';
                     end;
                  end;

                  PathNew := FileList[CurrFileList]^.PathNew;
                  if PathNew<>'' then
                  begin
                     FSplit(PathNew, D, N, PackNew);
                     if (PathNew='') then
                     begin
                        PathNew := PathNew + '.Txt';
                     end else
                     begin
                        Delete(packNew,1,1);
                        PackNew := Upper(packNew);
                        {quella estratta e' proprio l'estensione}
                        J := 1;
                        while (J<=NPacker) and (Packer[J]^.Ext<>PackNew) do
                           inc(J);
                        if J<=NPacker then
                        begin
                           PathNew := D + N + '.Txt';
                        end else
                        begin
                           PackNew := '';
                        end;
                     end;
                  end;

                  PathAvail := FileList[CurrFileList]^.PathAvail;
                  PathBdl := FileList[CurrFileList]^.PathBdl;

                  Aree := CopyListaAree(FileList[CurrFileList]^.Aree);
                  KludgeFdn := FileList[CurrFileList]^.KludgeFdn;
                  Maxbest1 := FileList[CurrFileList]^.Maxbest1;

                  if KludgeFdn<>'' then
                  begin
                     RemoveListaNum(Aree);
                     Aree := Nil;
                     J := 1;
                     while (J<=NTicGroups) and (TicGroups[J]^.Tag<>KludgeFdn) do
                        inc(J);
                     if (J<=NTicGroups) then
                     begin
                        Aree := CopyListaAree(TicGroups[J]^.Aree);
                     end else
                     begin
                        Writeln(' * Invalid FDN ',KludgeFdn);
                        Writeln(LogFile,Prelog(LogError),'Invalid FDN ',KludgeFdn);
                        Flush(LogFile);
                        Aree := Nil;
                        PutInListaAree(-1,-1,Aree);
                     end;
                  end;

                  AllFilesSize := 0;
                  Sort := No;
                  DelDupFBbs := False;
                  Orfani := False;
                  OffLIne := True;
                  OtherFiles := True;
                  ViewContents := VcNo;

                  ModDc := NoMod;

                  UnpackTime(ActDate,T1);
                  {Genera la data da cui considerare nuovi i file}
                  if (newdays>0) and (PathNew<>'') then
                  begin
                     JulianToGregorian(GregorianToJulian(T1)-NewDays,Integer(T1.Year),
                        Integer(T1.Month),Integer(T1.Day));
                     T1.Hour := 0;
                     T1.Min := 0;
                     T1.Sec := 0;
                  end;
                  PackTime(T1,ChkDate);

                  Assign(AllFiles,PathAll);
                  GetMem(BufAll,SizeTxtBuf);
                  SetTextBuf(AllFiles,BufAll^,SizeTxtBuf);
                  Rewrite(AllFiles);

                  if (Newdays>0) and (PathNew<>'') then
                  begin
                     Assign(NewFiles,PathNew);
                     GetMem(BufNew,SizeTxtBuf);
                     SetTextBuf(NewFiles,BufNew^,SizeTxtBuf);
                     Rewrite(NewFiles);
                  end;

                  WriteHeader;

                  if filelist[currfilelist]^.PathHdr <> Nil then
                     importfile(filelist[currfilelist]^.PathHdr)
                  else
                     ImportFile(PathHdr);

                  if PathAvail<>'' then
                  begin
                     GetMem(BufAvail,SizeTxtBuf);
                     assign(OkFile,PathAvail);
                     SetTextBuf(OkFile,BufAvail^,SizeTxtBuf);
                     {$I-}
                     Rewrite(OkFile);
                     {$I+}
                     if IoResult<>0 then
                        PathAvail := '';
                  end;

                  if (not FileList[CurrFileList]^.Cd) and
                     ((NMagic>2) or (Magic[1]<>Nil) or (Magic[2]<>Nil)) then
                  begin
                     Writeln(AllFiles,HdrStr);
                     if Message[1]<>nil then
                        TempStr := Message[1]^
                     else
                        TempStr := 'MAGIC FILE NAMES';
                     while length(TempStr)<33 do
                        TempStr := ' ' + tempstr + ' ';
                     if length(TempStr)>33 then
                        TempStr := Copy(TempStr,1,33);
                     TempStr := 'º' + FrameHdr1 + TempStr + FrameHdr2 + 'º';
                     Writeln(AllFiles,TempStr);
                     Writeln(AllFiles,Ok2Str);
                     inc(AllFilesSize,81*3);
                     if (NewDays>0) and (PathNew<>'') then
                     begin
                        Writeln(NewFiles,HdrStr);
                        Writeln(NewFiles,TempStr);
                        Writeln(NewFiles,Ok2Str);
                     end;
                     for I:=1 to Nmagic do
                     if Magic[I]<>Nil then
                     begin
                        TempStr := Magic[I]^;
                        if TempStr<>'' then
                        begin
                           if (I>2) and (PathAvail<>'') then
                              writeln(OkFile,'@',MagicOk(TempStr));
                           TempStr := MagicAll(TempStr);
                           if TempStr<>'' then
                           begin
                              TempStr := Copy(TempStr,1,76);
                              WriteLn(AllFiles,'º ',TempStr,'º':77-length(TempStr));
                              if (Newdays>0) and (PathNew<>'') then
                                 WriteLn(NewFiles,'º ',TempStr,'º':77-length(TempStr));
                              inc(AllFilesSize,81);
                           end;
                        end;
                     end;
                     Writeln(AllFiles,Ok3Str);
                     inc(AllFilesSize,81);
                     if (NewDays>0) and (PathNew<>'') then
                        Writeln(NewFiles,Ok3Str);
                     TempDescTypePtr := OkLines;
                     while TempDescTypePtr<>Nil do
                     begin
                        if PathAvail<>'' then
                           Writeln(OkFile,TempDescTypePtr^.Descrizione^);
                        TempDescTypePtr := TempDescTypePtr^.Next
                     end;
                  end;

                  if (PathAvail<>'') and NoDlPath then
                  begin
                     Close(OkFile);
                     FreeMem(BufAvail,SizeTxtBuf);
                  end;

                  {Most downloaded files}
                  if (MaxBest1>0) then
                  begin
                     {Se deve creare il file BDL, ora prepara le variabili}
                     GetMem(Best,MaxBest1*SizeOf(BestType));
                     for I:=1 to MaxBest1 do
                     begin
                        Best^[I].Nome := '';
                        Best^[I].DownLoad := -1;
                        Best^[I].Descrizione := '';
                     end;

                     PosListBdl := AllFilesSize;
                     Writeln(AllFiles,HdrStr);

                     if Message[3]<>nil then
                        TempStr := Message[3]^
                     else
                        TempStr := 'Most downLoaded files';
                     while length(TempStr)<33 do
                        TempStr := ' ' + tempstr + ' ';
                     if length(TempStr)>33 then
                        TempStr := Copy(TempStr,1,33);
                     TempStr := 'º' + FrameHdr1 + TempStr + FrameHdr2 + 'º';

                     Writeln(AllFiles,TempStr);
                     Writeln(AllFiles,FtrStr);
                     inc(AllFilesSize,81*3);
                     for I := 1 to MaxBest1+4 do
                     begin
                        Writeln(AllFiles,'':79);
                        inc(AllFilesSize,81);
                     end;
                     if (NewDays>0) and (PathNew<>'') then
                     begin
                        Writeln(NewFiles,HdrStr);
                        Writeln(NewFiles,TempStr);
                        Writeln(NewFiles,FtrStr);
                        for I := 1 to MaxBest1+4 do
                           Writeln(NewFiles,'':79);
                     end;
                     Inc(PosListBdl,81*3);
                  end;
                  WriteCopyright;
               end;
            end;

            if ((LListStatus<>MakeSearch) or (NstringSearch>0)) and
               ((LListStatus<>Announce) or
                 (CurrAnnounce<=NAnnounce) or (CurrTicNode<=NTicNodes)) and
               ((LListStatus<>EditFilesBbs) or (Aree<>Nil))
                then
            repeat
               if (LListStatus=Announce) then
               begin
                  {Prende i parametri dalla definizione dell'annuncio}
                  if (CurrAnnounce>NAnnounce) then
                  begin
                     {annunci per i tic-nodes}
                     PreFix := Nil;
                     Suffix := Nil;
                     RemoveListaNum(Aree);
                     Aree := Nil;
                     KludgeFdn := '';
                     MsgFrom := SysopName;
                     if message[53]=Nil then
                        MsgSubject := 'New files in linked TIC areas'
                     else
                        MsgSubject := Message[53]^;
                     MsgOrigin := BbsName;
                     MsgTo := 'Sysop';
                     GetAree(TicNodes[CurrTicNode]^.Node,Aree);
                     MsgDestAddr := TicNodes[CurrTicNode]^.Node;
                     I := 0;
                     while (I<=NAka) and (Aka[I].Zone<>TicNodes[CurrTicNode]^.Node.Zone) do
                        inc(I);
                     if I>NAka then
                        I := 0;
                     MsgOrigAddr := Aka[I];
                     Filter := Nil;
                  end else
                  begin
                     inc(CurrAnnounce);
                     {
                     questi di default sono uguali al valore precedente
                     }
                     MsgFrom := Annunci[CurrAnnounce]^.MsgFrom;
                     if MsgFrom='' then
                        MsgFRom := SysopName;
                     MsgTo := Annunci[CurrAnnounce]^.MsgTo;
                     if MsgTo ='' then
                        MsgTo := 'All';
                     MsgSubject := Annunci[CurrAnnounce]^.MsgSubject;
                     if MsgSubject='' then
                     begin
                        if message[78]=Nil then
                           TempStr := 'New files on %1'
                        else
                           TempStr := Message[78]^;
                        SubstPar(TempStr,Bbsname,'1');
                        MsgSubject := TempStr;
                     end;
                     MsgOrigin := Annunci[CurrAnnounce]^.MsgOrigin;
                     if MsgOrigin='' then
                        MsgOrigin := BbsName;
                     Prefix := Annunci[CurrAnnounce]^.Prefix;
                     Suffix := Annunci[CurrAnnounce]^.Suffix;

                     RemoveListaNum(Aree);
                     Aree := Nil;

                     if Annunci[CurrAnnounce]^.KludgeFdn<>'' then
                     begin
                        KludgeFdn := Annunci[CurrAnnounce]^.KludgeFdn;
                        J := 1;
                        while (J<=NTicGroups) and (TicGroups[J]^.Tag<>KludgeFdn) do
                           inc(J);
                        if (J<=NTicGroups) then
                        begin
                           Aree := CopyListaAree(TicGroups[J]^.Aree);
                        end else
                        begin
                           Writeln(' * Invalid FDN ',KludgeFdn);
                           Writeln(LogFile,Prelog(LogError),'Invalid FDN ',KludgeFdn);
                           Flush(LogFile);
                           Aree := Nil;
                           PutInListaAree(-1,-1,Aree);
                        end;
                     end else
                     begin
                        KludgeFdn := '';
                        Aree := CopyListaAree(Annunci[CurrAnnounce]^.Aree);
                     end;

                     PostIBM := not Annunci[CurrAnnounce]^.NoIbm;
                     if Annunci[CurrAnnounce]^.Vc then
                        ViewContents := VcAll
                     else
                        ViewContents := VcNo;

                     MsgOrigAddr := Aka[0];
                     MsgDestAddr := MsgOrigAddr;

                     Filter := Annunci[CurrAnnounce]^.Filter;

                  end;
               end;

               case LListStatus of
                  FileIdx:
                  begin
                     Write(' * Making File Idx');
                     Write(LogFile,PreLog(LogStart),'Making File Idx')
                  end;
                  FixFbbs:
                  begin
                     Write(' * Writing new Files.Bbs');
                     Write(LogFile,PreLog(LogStart),'Writing new Files.Bbs');
                  end;
                  Announce, MakeSearch:
                  begin
                     if (LListStatus=Announce) then
                     begin
                        Write(' * Announcing new files');
                        Write(LogFile,PreLog(LogStart),'Announcing new files');
                     end else
                     begin
                        Write(' * Searching in File Base');
                        Write(LogFile,PreLog(LogStart),'Searching in File Base');
                        Numero := 0;
                        while (numero<prevnumero) and GetNextArea do;
                     end;
                     repeat
                        PathAll := D0 + HexLong(ToUnixDate(GetDosDate)) + AppExt;
                        Assign(AllFiles,PathAll);
                        SetTextBuf(AllFiles,BufAll^,SizeTxtBuf);
                        {$I-}
                        Rewrite(AllFiles);
                        {$I+}
                     until IOResult=0;
                  end;
                  MakeListCmp:
                  begin
                     Write(' * Making File List');
                     Write(LogFile,PreLog(LogStart),'Making File List');
                  end;
                  MakeListSum, CDMakeListSum:
                  begin
                     Write(' * Making File List summary');
                     Write(LogFile,PreLog(LogStart),'Making File List summary');
                  end;
               end;

               ShowListaNum(Aree);
               Writeln;
               Writeln(LogFile);
               Flush(LogFile);

               if (LListStatus=MakeListSum) or (llistStatus=CdMakeListSum) then
               begin
                  PosListSum := AllFilesSize;
                  Assign(FileArea, D0 + 'FAree' + Long2Str(CurrFilelist,0) +
                     '.Txt');
                  Rewrite(FileArea);
                  Writeln(FileArea,HdrStr);
                  if Message[4]<>nil then
                     TempStr := Message[4]^
                  else
                     TempStr := 'Index of file areas';
                  while length(TempStr)<33 do
                     TempStr := ' ' + tempstr + ' ';
                  if length(TempStr)>33 then
                     TempStr := Copy(TempStr,1,33);
                  TempStr := 'º' + FrameHdr1 + TempStr + FrameHdr2 + 'º';
                  Writeln(FileArea,TempStr);
                  if LongSummary then
                     Writeln(FileArea,AfaL2Str)
                  else
                     Writeln(FileArea,Afa2Str);
                  Writeln(AllFiles,'':79);
                  Writeln(AllFiles,'':79);
                  Writeln(AllFiles,'':79);
                  if (NewDays>0) and (PathNew<>'') then
                  begin
                     Writeln(NewFiles,'':79);
                     Writeln(NewFiles,'':79);
                     Writeln(NewFiles,'':79);
                  end;
               end;

               TotSize := 0;
               NTotFiles := 0;
               PrevNTotFiles := 0;
               TotNewSize := 0;
               NTotNewFiles := 0;
               PrevNTotNewFiles := 0;
               NAree := 0;

               while
                 ((LListStatus<>MakeSearch) or (NtotFiles<SearchMaxFiles)) and
                    GetNextArea do
               begin

                  if ((Aree=Nil) or IsInLista(Numero,Aree))
                        and
                     (Livello <= MaxLev)
                        and
                     ((LlistStatus<>Announce) or not IsCdRom)
                        then
                  begin
                    inc(NAree);
                    if (LListStatus=MakeListSum) or (llistStatus=CdMakeListSum) then
                    begin
                       if LongSummary then
                       begin
                          Writeln(AllFiles,'':79);
                          if (NewDays>0) and (PathNew<>'') then
                             Writeln(NewFiles,'':79);
                       end else
                       begin
                          if not Odd(NAree) then
                             Writeln(AllFiles,'':79);
                          if (NewDays>0) and (PathNew<>'') then
                          begin
                             if not Odd(NAree) then
                                Writeln(NewFiles,'':79);
                          end;
                       end;
                    end else
                    begin
                       MakeList(PathFbbs,PathDown,Numero,Nome,Livello,Attr,
                          (NewDays > 0) and (PathNew<>''),
                          IsCdRom);
                       if (LListStatus=MakeLIstCmp) then
                       begin
                          if LongSummary then
                          begin
                             Writeln(FileArea,'º',Numero:4,' ³ ',Nome,'':52-length(nome),' ',
                                NTotFiles - PrevNTotFiles:8,
                                NTotNewFiles - PrevNTotNewFiles:8,' º');
                          end else
                          begin
                             if NTotFiles-PrevNTotFiles>0 then
                             begin
                                TempStr := Long2Str(NTotFiles-PrevNTotFiles,0);
                             end else
                                TempStr := '';
                             Nome := Copy(Nome,1,30 - length(TempStr));
                             if length(Nome)<30 - length(TempStr) then
                             begin
                                Nome := Nome + RepeatStr(' ',30 - length(TempStr) -
                                   length(Nome));
                             end;
                             Nome := Nome + ' ' + TempStr;
                             TempStr := 'º'+Long2Str(Numero,4)+
                                ' ³ '+Nome+
                                RepeatStr(' ',31-length(Nome));
                             Write(FileArea,TempStr);
                             if not Odd(NAree) then
                                Writeln(FileArea,'º');
                          end;
                          PrevNTotFiles := NTotFiles;
                          PrevNTotNewFiles := NTotNewFiles;
                       end;
                    end;
                  end;
               end;
               if (LListStatus=MakeListSum) or (LListStatus=CdMakeListSum) then
               begin
                  if not LongSummary and Odd(NAree) then
                  begin
                     Writeln(AllFiles,'':79);
                     if (NewDays>0) and (PathNew<>'') then
                       Writeln(NewFiles,'':79);
                  end;
                  Writeln(AllFiles,'':79);
                  if (NewDays>0) and (PathNew<>'') then
                     WriteLn(NewFiles,'':79);
                  writeln(' * Total of ',NAree,' areas.');
                  writeln(LogFile,PreLog(LogDone),'Total of ',NAree,' areas.');
                  Flush(LOgFile);
                  QuietMode := QuietMode1;
               end else
               begin
                  if not QuietMode and not FirstArea then
                     Writeln;
                  QuietMode := QuietMode1;
                  writeln(' * Total of ',NTotFiles,' files.');
                  writeln(LogFile,PreLog(LogDone),'Total of ',NTotFiles,' files.');
                  Flush(LogFile);
                  FirstArea := True;

                  Case LListStatus of
                     MakeSearch:
                     begin

                        PrevNumero := Numero;

                        if SearchDb and (LlistDb<>Nil) then
                        begin
                           Writeln(' * Searching in LListDb');
                           Writeln(LogFile,Prelog(LogStart),'Searching in LListDb');
                           Flush(LOgFile);
                           TempDescTypePtr := LlistDb;
                           while (TempDescTypePtr<>Nil) do
                           begin
                              PathFBBs := TempDescTypePtr^.Descrizione^;
                              Attr := 64;
                              Numero := 0;
                              Nome := TempDescTypePtr^.Descrizione^;
                              PathDown := '\\'; {non valido!}
                              IsCdRom := False;
                              Livello := 0;
                              MakeList(PathFbbs,PathDown,Numero,Nome,Livello,Attr,NewDays > 0, IsCdRom);
                              TempDescTypePtr := TempDescTypePtr^.Next;
                           end;
                           if not QuietMode and not FirstArea then
                              Writeln;
                           QuietMode := QuietMode1;
                           writeln(' * Total of ',NTotFiles,' files.');
                           writeln(LogFile,PreLog(LogDone),'Total of ',NTotFiles,' files.');
                           Flush(LOgFile);
                           FirstArea := True;
                        end;

                        NStringSearch := 0;

                        AddSearch(PrevNumero);

                        if (NTotFiles >= SearchMaxFiles) and GetNextArea then
                        begin
                           {Ricerca non completa}
                           Writeln(AllFiles);
                           if Message[52]=Nil then
                              TempStr := 'Reply to this msg to get info on next %1 files'
                           else
                              TempStr := message[52]^;
                           SubstPar(TempStr,long2Str(SearchMaxFiles1 * 4,0),'1');
                           writeln(AllFiles, TempStr);
                           Writeln(AllFiles);
                        end;

                        if (NTotFiles=0) and privateSearch then
                        begin
                           {Messaggio privato, risponde comunque}
                           Writeln(AllFiles);
                           if message[51]=nil then
                              TempStr := 'Sorry, no file found'
                           else
                              TempStr := Message[51]^;
                           writeln(AllFiles,TempStr);
                           Writeln(AllFiles);
                           NTotFiles := 1;
                        end;

                        Close(AllFiles);
                        if (NTotFiles>0) then
                        begin
                           if MsgArea[CurrMsgArea]^.AreaId2<>'' then
                           begin
                              PostAnnunciNews(MsgArea[CurrMsgArea]^.AreaId2);
                           end else
                           begin
                              PostAnnunciNews(NetAreaId)
                           end;
                        end;
                        if EraseFile(PathAll) then;
                        dec(CurrMsgArea);
                        GetSearchStr;
                        if (NStringSearch>0) then
                        begin
                           TotSize := 0;
                           NTotFiles := 0;
                           TotNewSize := 0;
                           NTotNewFiles := 0;
                           ResetAreaFile
                        end;
                     end;
                     Announce:
                     begin
                        Close(AllFiles);
                        if NTotFiles>0 then
                        begin
                           if CurrAnnounce <= NAnnounce then
                           begin
                              TempDescTypePtr := Annunci[CurrAnnounce]^.XC;
                              while (TempDescTypePtr<>Nil) do
                              begin
                                 PostAnnunciNews(TempDescTypePtr^.Descrizione^);
                                 TempDescTypePtr := TempDescTypePtr^.Next;
                              end;
                              {manda i carbon copy in NetMail}
                              TempDescTypePtr := Annunci[CurrAnnounce]^.CC;
                              while (TempDescTypePtr<>Nil) do
                              begin
                                 TempStr := TempDescTypePtr^.Descrizione^;
                                 I := pos(',',TempStr);
                                 if I=0 then
                                 begin
                                    MsgTo := TempStr;
                                 end else
                                 begin
                                    MsgTo := Copy(TempStr,1,I-1);
                                    while (MsgTo<>'') and (msgTo[length(MsgTo)]=' ') do
                                       dec(MsgTo[0]);
                                    Delete(TempStr,1,I);
                                    StripLeadingSpace(TempStr);
                                    if ParseAddr(TempStr, MsgDestAddr, MsgDestAddr) then;
                                 end;
                                 PostAnnunciNews(NetAreaId);
                                 TempDescTypePtr := TempDescTypePtr^.Next;
                              end;
                           end else
                              PostAnnunciNews(NetAreaId);
                        end;
                        if EraseFile(PathAll) then;
                        if (CurrAnnounce<NAnnounce) then
                        begin
                           TotSize := 0;
                           NTotFiles := 0;
                           TotNewSize := 0;
                           NTotNewFiles := 0;
                           ResetAreaFile;
                        end else
                        if CurrAnnounce=NAnnounce then
                        begin
                           {era l'ultimo annuncio, inizia gli annunci per i tic-nodes}
                           Inc(CurrAnnounce);
                           CurrTicNode := 1;
                           While (CurrTicNode<=NTicNodes) and not
                               TicNodes[CurrTicNode]^.SendAnnounce do
                             inc(CurrTicNode);
                           if (CurrTicNode <= NTicNodes) then
                           begin
                              TotSize := 0;
                              NTotFiles := 0;
                              TotNewSize := 0;
                              NTotNewFiles := 0;
                              ResetAreaFile
                           end;
                        end else
                        begin
                           inc(CurrTicNode);
                           While (CurrTicNode<=NTicNodes) and not
                              TicNodes[CurrTicNode]^.SendAnnounce do
                             inc(CurrTicNode);
                           if (CurrTicNode <= NTicNodes) then
                           begin
                              TotSize := 0;
                              NTotFiles := 0;
                              TotNewSize := 0;
                              NTotNewFiles := 0;
                              ResetAreaFile
                           end;
                        end
                     end;
                     FileIdx:
                     begin
                        MergeIdx;
                        Close(FilesIdxTot);
                     end;
                     MakeListCmp:
                     begin
                        Writeln(AllFiles);
                        if (Newdays>0) and (PathNew<>'') then
                           WriteLn(NewFiles);

                        if filelist[currfilelist]^.PathFtr <> Nil then
                           importfile(filelist[currfilelist]^.PathFtr)
                        else
                           ImportFile(PathFtr);

                        WriteFooter;
                        Close(AllFiles);
                        if (NewDays>0) and (PathNew<>'') then
                           Close(NewFiles);

                        {Scrive il resoconto anche in cima alla lista}
                        {non c'e' piu' bisogno di salvare la posizione del file}
                        {visto che alla fine ho terminato}

                        if PosListSum > 0 then
                        begin
                           if Not LongSummary and odd(NAree) then
                           begin
                               Writeln(FileArea,'º','³':6,'º':33);
                           end;
                           if LongSummary then
                              Writeln(FileArea,AfaL3Str)
                           else
                              Writeln(FileArea,Afa3Str);
                           Close(FileArea);
                           ImportBin(D0 + 'FAree' + Long2Str(CurrFilelist,0) +
                              '.Txt',POsListSum);
                        end;

                        if MaxBest1>0 then
                        begin
                           if PathBdl='' then
                           begin
                              PathBdl := d0 + 'Bdl' + Long2Str(CurrFileList,0) +
                                 '.Txt';
                              CreateBdlBBS(0);
                              ImportBin(PathBdl,PosListBdl);
                           end else
                           begin
                              CreateBdlBBS(0);
                              ImportBin(PathBdl,PosListBdl);
                              CreateBdlBBS(1);
                              CreateBdlBBS(2);
                              SetColor(0);
                           end;
                           FreeMem(Best,MaxBest1*SizeOf(BestType));
                        end;

                        if not NoDlPath and (PathAvail<>'') then
                        begin
                           close(OkFile);
                           FreeMem(BufAvail,SizeTxtBuf);
                        end;

                        CompPacker := 0;
                        I := 1;
                        TempStr := '';
                        while (CompPacker=0) and (I<=NPacker) do
                        begin
                            if Packer[I]^.Ext = PackAll then
                            begin
                               CompPacker := I
                            end else
                               inc(I);
                        end;

                        FreeMem(BufAll,SizeTxtBuf);
                        if CompPacker<>0 then
                        begin
                           TempStr1 := PathAll;
                           while (TempStr1<>'') and (TempStr1[length(TempStr1)]<>'.') do
                              dec(TempStr1[0]);
                           if TempStr1<>'' then
                              dec(TempStr1[0]);
                           TempStr1 := TempStr1 + '.' + PackAll;
                           FirstShell := False;
                           if Compress(TempStr1,PathAll,CompPacker) then;
                        end;

                        if (NewDays>0) and (PathNew<>'') then
                        begin
                           FreeMem(bufNew,SizeTxtBuf);

                           CompPacker := 0;
                           I := 1;
                           TempStr := '';
                           while (CompPacker=0) and (I<=NPacker) do
                           begin
                               if Packer[I]^.Ext = PackNew then
                               begin
                                  CompPacker := I
                               end else
                                  inc(I);
                           end;

                           if CompPacker<>0 then
                           begin
                              TempStr1 := PathNew;
                              while (TempStr1<>'') and (TempStr1[length(TempStr1)]<>'.') do
                                 dec(TempStr1[0]);
                              if TempStr1<>'' then
                                 dec(TempStr1[0]);
                              TempStr1 := TempStr1 + '.' + PackNew;
                              FirstShell := False;
                              if Compress(TempStr1,PathNew,CompPacker) then;
                           end;
                        end;
                     end;
                  end;
               end;
            until ((LListStatus<>MakeSearch) or (NStringSearch=0)) and
               ((LListStatus<>Announce) or
                ((CurrAnnounce>NAnnounce) and (CurrTicNode>NTicNodes)));

            if (LlistStatus<>MakeListSum) and (LListStatus<>CDMakeListSum) then
            begin
               RemoveListaNum(Aree);
               Aree := Nil;
            end;

            if (LListStatus=Announce) then
            begin
               FreeMem(BufAll,SizeTxtBuf);
               {Truncate(LastDateFile);
               Close(LastdateFile);}
               Inc(Colonne);
               Close(AnnounceIdx);
               if EraseFile(D0 + 'Announce.Idx') then;
               Close(FilesIdxTot);
               UnLock(D0+'Announce');
               Unlock(D0+'FileIdx');
               ModDc := NoMod;
               if (UpDateFileIdx<>Nil) then
               begin
                  Aree := UpdateFileIdx;
                  UpDateFileIdx := Nil;
                  MaxLev := Ml;
                  LListStatus := FileIdx;
               end else
               if Interactive then
               begin
                  GetLListStatus;
                  ClrScr;
                  GotoXY(1,10);
               End else
                  LListStatus := LListEnd;
            end else
            if (LLIstStatus=MakeListSum) then
            begin
               LListStatus := MakeListCmp;
            end else
            if (LLIstStatus=CDMakeListSum) then
            begin
               LListStatus := MakeListCmp;
            end else
            if LListStatus=FixFBbs then
            begin
               if (UpDateFileIdx<>Nil) then
               begin
                  Aree := UpdateFileIdx;
                  UpDateFileIdx := Nil;
                  MaxLev := Ml;
                  LListStatus := FileIdx;
               end else
               if Interactive then
               begin
                  GetLListStatus;
                  ClrScr;
                  GotoXY(1,10);
               End else
                  LListStatus := LListEnd;
            end else
            if LListStatus=MakeSearch then
            begin
               FreeMem(BufAll,SizeTxtBuf);
               Inc(Colonne);
               if Interactive then
               begin
                  GetLListStatus;
                  ClrScr;
                  GotoXY(1,10);
               End else
                  LListStatus := LListEnd;
            end else
            if LListStatus=FileIdx then
            begin
               FreeMem(Buf4,LenRead1 * SizeOf(IdxType));
               UnLock(D0+'FileIdx');
               if NeedsIndexUpdate then
               begin
                  NeedsIndexupdate := False;
                  Aree := OldAree;
               end;
               if Interactive then
               begin
                  GetLListStatus;
                  ClrScr;
                  GotoXY(1,10);
               End else
                  LListStatus := LListEnd;
            end else
            if LLIstStatus=MakeListCmp then
            begin
               Unlock(D0+'FileList');
               if FileList[CurrFileList]^.CD then
                  llistStatus := CDMakeListSum
               else
                  llistStatus := MakeListSum;
               while (CurrFileList < NFileList) and
                   (FileList[CurrFileList+1]^.CD XOR (LListStatus=CDMakeListSum)) do
                  inc(CurrFileList);
               if CurrFileList<NFileList then
               begin
                  LListStatus := MakeListSum;
               end else
               begin
                  CurrFileList := 0;
                  if Interactive then
                  begin
                     GetLListStatus;
                     ClrScr;
                     GotoXY(1,10);
                  End else
                     LListStatus := LListEnd;
               end;
            end else
            begin
               if Interactive then
               begin
                  GetLListStatus;
                  ClrScr;
                  GotoXY(1,10);
               End else
                  LListStatus := LListEnd;
            end;
         end;

         if LlistStatus=LlistEnd then
         begin
            {controlla se c'e' qualche opzione in coda}
            LlistStatus := Unselected;
            while (LlistStatus<>LlistEnd) and not (llistStatus in OtherOptions) do
               inc(LlistStatus);
         end;

      end;

      if Bbs<>Unknown then
      begin
         if (DirFiles=Nil) or (DirFilesPtr<>Nil) then
            Close(F)
      end;

   end;

end.
