Program MsgUtil;

{$IFDEF WINDOWS}
{$M 16384, 8196}
{$ELSE}
{$M 16384, 0, 655360}
{$ENDIF}

{$I MKB.Def}

{$X+}

Uses
   MKMsgAbs, MKOpen, MKDos, MKString, MKFile, MKGlobT, MkMisc, Dos, crc32,
   MkDupes;


{$I MSGUTVER.DEF}


Var
  Pid: String;
  PathHudson, PathAreasBbs, NetAreaId: String;
  AreasBbs, OldAreasBbs, Cfg: Text;
  Tag, AreaId, OldAreaId: String;
  L : String;
  UpdateAreasBbs, LastChanged: Boolean;
  ConvertedAreas, NAreas: Integer;
  D: DirStr;
  I : Integer;

  Msg: AbsMsgPtr;                      {Pointer to msg object}
  MsgAreaId: String[128];              {Message Area Id to post msg in}
  MsgFrom: String[50];                 {Author of the message}
  MsgTo: String[50];                   {Who the message is to}
  MsgSubj: String[100];                {Subject of the message}
  OrigAddr: AddrType;                  {Fido-style originating address}
  DestAddr: AddrType;                  {Fido-style destination address}
  MsgFileName: String;                 {File name with message text}
  MsgType: MsgMailType;                {Type of msg to be written}
  Priv: Boolean;                       {Is message private}
  Del: Boolean;                        {Erase msg text file afterwards}

  D0: DirStr;
  N: NameStr;
  E: ExtStr;

  Msgorigin: String;

  MakeConversion: Boolean;

  Personalareaid: String;

  scanPersonal: Boolean;

  Sysop, UpSysop, InvUpSysop: String;

  MsgFound: Longint;

  DupesPtr: checkDupeptr;

Const
  StLen = 78;                          {wrap strings at 78 characters}



Procedure ConvertArea(InAreaId, OutAreaId: String);
Var LastRead, InNum, OutNum: Longint;
    MsgIn, MsgOut: AbsMsgPtr;
    TmpStr: String;
    TmpAddr: AddrType;                   {temporary address storage}
    PriorWrap: Boolean;                  {prior text line was wrapped}
begin
   WriteLn(' * ',Copy(InAreaId, 1, 28),' *--=> ',Copy(OutAreaId, 1, 28));
   If Not OpenMsgArea(MsgIn, InAreaId) Then
   Begin
     WriteLn(' * Unable to open input message base');
   End else
   If Not OpenOrCreateMsgArea(MsgOut, OutAreaId) Then
   Begin
     WriteLn(' * Unable to open/create output message base');
     {l'altra comunque deve chiuderla}
     If CloseMsgArea(MsgIn) Then;
   End else
   begin
      If MsgOut^.LockMsgBase Then
      begin
         if MsgIn^.LockMsgBase then
         begin
            {tutto a posto, le aree sono state aperte e lockate}
            {procede con la conversione}
            LastRead := MsgIn^.GetLastRead(0);
            MsgOut^.SetMailType(mmtEchoMail);
            MsgIn^.SetMailType(mmtEchoMail);
            MsgIn^.SeekFirst(1);                   {Start at begining of msg base}
            Write(' * Total: ',MsgIn^.GetHighMsgNum:5,' Current: ');
            While MsgIn^.SeekFound Do
            Begin
              MsgIn^.MsgStartUp;                   {Initialize input msg}
              InNum := MsgIn^.GetMsgNum;
              MsgOut^.StartNewMsg;                 {Initialize output msg}
              MsgIn^.MsgTxtStartUp;                {Initialize input msg text}
              MsgIn^.GetDest(TmpAddr);             {Set header fields}
              MsgOut^.SetDest(TmpAddr);
              MsgIn^.GetOrig(TmpAddr);
              MsgOut^.SetOrig(TmpAddr);
              MsgOut^.SetFrom(MsgIn^.GetFrom);
              MsgOut^.SetTo(MsgIn^.GetTo);
              MsgOut^.SetSubj(MsgIn^.GetSubj);
              {il successivo e' solo per la netmail, lo esclude}
              {MsgOut^.SetCost(MsgIn^.GetCost);}
              {il link dei messaggi non va bene perche' i numeri possono cambiare}
              {mette a 0 nel nuovo messaggio}
              MsgOut^.SetRefer(0);
              MsgOut^.SetSeeAlso(0);
              MsgOut^.SetDate(MsgIn^.GetDate);
              MsgOut^.SetTime(MsgIn^.GetTime);
              MsgOut^.SetLocal(MsgIn^.IsLocal);
              MsgOut^.SetRcvd(MsgIn^.IsRcvd);
              MsgOut^.SetPriv(MsgIn^.IsPriv);
              {esclude i successivi che sono solo per la netmail}
              {MsgOut^.SetCrash(MsgIn^.IsCrash);
              MsgOut^.SetKillSent(MsgIn^.IsKillSent);
              MsgOut^.SetSent(MsgIn^.IsSent);
              MsgOut^.SetFAttach(MsgIn^.IsFAttach);
              MsgOut^.SetReqRct(MsgIn^.IsReqRct);
              MsgOut^.SetRetRct(MsgIn^.IsRetRct);
              MsgOut^.SetFileReq(MsgIn^.IsFileReq);}
              MsgOut^.SetEcho(MsgIn^.IsEchoed);
              PriorWrap := MsgIn^.WasWrap;
              TmpStr := MsgIn^.GetString(StLen);   {Get line of message text}
              While (Not MsgIn^.EOM) or (Length(TmpStr) > 0) Do
                Begin
                If (
                    ((TmpStr<>'') and (TmpStr[1] = #1)) or
                    (pos('AREA:',TmpStr)=1) or (pos('SEEN-BY:', TmpStr)=1)
                   )
                  and Not PriorWrap Then
                begin
                  MsgOut^.DoKludgeLn(TmpStr)       {Save as ^A Kludge line}
                end Else
                  Begin
                  If MsgIn^.WasWrap Then
                    MsgOut^.DoString(TmpStr)       {Save as normal text}
                  Else
                    MsgOut^.DoStringLn(TmpStr);    {Save as normal text with CR}
                  End;
                TmpStr := MsgIn^.GetString(StLen); {Get next line of message text}
                End;
              If MsgOut^.WriteMsg = 0 Then
              begin
                 OutNum := MsgOut^.GetMsgNum;
                 if InNum=LastRead then
                 begin
                    MsgOut^.SetLastRead(0,OutNum);
                 end;
                 MsgIn^.DeleteMsg;
              end else
                 OutNum := 0;
              Write(InNum:5,' > ',OutNum:5,#8#8#8#8#8#8#8#8#8#8#8#8#8);
              MsgIn^.SeekNext;                     {Seek next message}
            End;
            Write(#13,'':79,#13);
            {seconda passata per cancellare i messaggi dalla InArea}
            {Write(' * Delete old msg ...');
            MsgIn^.SeekFirst(1);
            While MsgIn^.SeekFound do
            begin
               MsgIn^.MsgStartUp;
               MsgIn^.DeleteMsg;
               MsgIn^.SeekNext;
            end;
            Write(#13,'':79,#13);}
            If MsgIn^.UnLockMsgBase Then;
         end else
            WriteLn(' * Can''t lock input message base');
         if MsgOut^.UnlockMsgBase then;
      end else
         WriteLn(' * Can''t lock output message base');
      If CloseMsgArea(MsgIn) Then;
      If CloseMsgArea(MsgOut) Then;
   end;
end {ConvertArea};


Procedure PersonalMsg(InAreaId, tag: String);
Var LastRead, InNum, OutNum: Longint;
    MsgIn, MsgOut: AbsMsgPtr;
    TmpStr: String;
    PriorWrap: Boolean;                  {prior text line was wrapped}
    MsgIdKludge: String;
    MsgFrom, MsgTo: String;
    Dup: DupesType;
    TmpAddr: AddrType;
begin
   If Not OpenMsgArea(MsgIn, InAreaId) Then
   Begin
     WriteLn(' * Unable to open input message base');
   End else
   begin
      if MsgIn^.LockMsgBase then
      begin
         {tutto a posto, le aree sono state aperte e lockate}
         {procede con la conversione}
         if (Tag='') then
            MsgIn^.SetMailType(mmtNetMail)
         else
            MsgIn^.SetMailType(mmtEchoMail);
         LastRead := MsgIn^.GetLastRead(0);
         MsgIn^.SeekFirst(1);                   {Start at begining of msg base}
         While MsgIn^.SeekFound Do
         Begin
           MsgIn^.MsgStartUp;
           MsgFrom := Upper(MsgIn^.GetFrom);
           MsgTo := Upper(MsgIn^.GetTo);
           if (((MsgFrom=UpSysop) or (MsgFrom=InvUpSysop)) and (msgin^.isSent)) or
               (MsgTo=UpSysop) or (MsgTo=InvUpSysop) or
               (MsgTo='SYSOP')
              then
           begin
              MsgIdKludge:='';
              {copia il messaggio nell'area PERSONAL}
              if OpenOrCreateMsgArea(MsgOut, PersonalareaId) then
              begin
                 if msgOut^.LockMsgBase then
                 begin
                    MsgOut^.SetMailType(mmtEchoMail);
                    InNum := MsgIn^.GetMsgNum;
                    MsgIn^.MsgTxtStartUp;                {Initialize input msg text}
                    MsgOut^.StartNewMsg;                 {Initialize output msg}
                    MsgIn^.GetDest(TmpAddr);             {Set header fields}
                    MsgOut^.SetDest(TmpAddr);
                    MsgIn^.GetOrig(TmpAddr);
                    MsgOut^.SetOrig(TmpAddr);
                    MsgOut^.SetFrom(MsgIn^.GetFrom);
                    MsgOut^.SetTo(MsgIn^.GetTo);
                    MsgOut^.SetSubj(MsgIn^.GetSubj);
                    {il successivo e' solo per la netmail, lo esclude}
                    {MsgOut^.SetCost(MsgIn^.GetCost);}
                    {il link dei messaggi non va bene perche' i numeri possono cambiare}
                    {mette a 0 nel nuovo messaggio}
                    MsgOut^.SetRefer(0);
                    MsgOut^.SetSeeAlso(0);
                    MsgOut^.SetDate(MsgIn^.GetDate);
                    MsgOut^.SetTime(MsgIn^.GetTime);
                    MsgOut^.SetLocal(MsgIn^.IsLocal);
                    MsgOut^.SetRcvd(MsgIn^.IsRcvd);
                    MsgOut^.SetPriv(MsgIn^.IsPriv);
                    {esclude i successivi che sono solo per la netmail}
                    {MsgOut^.SetCrash(MsgIn^.IsCrash);
                    MsgOut^.SetKillSent(MsgIn^.IsKillSent);
                    MsgOut^.SetSent(MsgIn^.IsSent);
                    MsgOut^.SetFAttach(MsgIn^.IsFAttach);
                    MsgOut^.SetReqRct(MsgIn^.IsReqRct);
                    MsgOut^.SetRetRct(MsgIn^.IsRetRct);
                    MsgOut^.SetFileReq(MsgIn^.IsFileReq);}
                    MsgOut^.SetEcho(MsgIn^.IsEchoed);
                    {informazione sull'area}
                    if tag<>'' then
                       MsgOut^.DoKludgeLn(#1+'AREA:' + Tag);

                    PriorWrap := MsgIn^.WasWrap;
                    TmpStr := MsgIn^.GetString(StLen);   {Get line of message text}
                    While (Not MsgIn^.EOM) or (Length(TmpStr) > 0) Do
                      Begin
                      If (
                          ((TmpStr<>'') and (TmpStr[1] = #1)) or
                          (pos('AREA:',TmpStr)=1) or (pos('SEEN-BY:', TmpStr)=1)
                         )
                        and Not PriorWrap Then
                      begin
                        if pos(#1+'MSGID:',TmpStr)=1 then
                           MsgidKludge := TmpStr;
                        MsgOut^.DoKludgeLn(TmpStr)       {Save as ^A Kludge line}
                      end Else
                        Begin
                        If MsgIn^.WasWrap Then
                          MsgOut^.DoString(TmpStr)       {Save as normal text}
                        Else
                          MsgOut^.DoStringLn(TmpStr);    {Save as normal text with CR}
                        End;
                      TmpStr := MsgIn^.GetString(StLen); {Get next line of message text}
                      End;
                    if MsgidKludge='' then
                    begin
                       TmpStr := MsgIn^.GetTime + MsgIn^.GetDate;
                       Dup.msgId := CrcSeed;
                       Dup.MsgId := UpdC32Block(tmpStr[1],length(TmpStr),Dup.MsgId);
                       Dup.msgid := Dup.msgid xor CRCSeed;
                       MsgIn^.Getorig(Dup.Addr);
                    end else
                    begin
                       DupesPtr^.Msgid2Dupes(Dup, MsgIdKludge);
                    end;
                    if not DupesPtr^.isDupes(Dup) then
                    begin
                       If MsgOut^.WriteMsg = 0 Then;
                       if not lastchanged then
                       begin
                          lastchanged := true;
                          writeln;
                       end;
                       inc(MsgFound);
                       writeln(' * Found MSG ',msgfound:3,' "',msgIn^.GetSubj,'"');
                       writeln('   From: ',MsgIn^.GetFrom);
                       Writeln('     To: ',MsgIn^.GetTo);
                    end;
                    if msgout^.UnlockMsgBase then;
                 end;
                 if closeMsgArea(MsgOut) then;
              end;
           end;
           MsgIn^.SeekNext;                     {Seek next message}
         End;
         {seconda passata per cancellare i messaggi dalla InArea}
         {Write(' * Delete old msg ...');
         MsgIn^.SeekFirst(1);
         While MsgIn^.SeekFound do
         begin
            MsgIn^.MsgStartUp;
            MsgIn^.DeleteMsg;
            MsgIn^.SeekNext;
         end;
         Write(#13,'':79,#13);}
         If MsgIn^.UnLockMsgBase Then;
      end else
         WriteLn(' * Can''t lock input message base');
      If CloseMsgArea(MsgIn) Then;
   end;
end {PersonalMsg};




Procedure processCfgFile;
var TF:Text;
    TmpStr, keyword:String;
    I : word;
begin
   assign(TF, D0 + 'MsgUtil.Cfg');
   {$I-}
   reset(TF);
   {$I+}
   if IOResult=0 then
   begin
      while not eof(TF) do
      begin
         readln(TF, TmpStr);
         {prima keyword in maiuscolo}
         I := 1;
         while (I<=length(TmpStr)) and (TmpStr[i]<>' ') do
         begin
            TmpStr[i] := upcase(TmpStr[i]);
            inc(i);
         end;
         keyword := Copy(TmpStr,1,I-1);
         delete(TmpStr,1,I);
         while (TmpStr<>'') and (TmpStr[1]=' ') do
            delete(TmpStr,1,1);
         if (Keyword='ADDRESS') then
         begin
            If ParseAddr(TmpStr, OrigAddr, OrigAddr) Then;
            If ParseAddr(TmpStr, DestAddr, DestAddr) Then;
         end else
         if (Keyword='SYSOP') then
         begin
            Sysop := TmpStr;
         end else
         if (Keyword='AREASBBS') then
         begin
            PathAreasbbs := TmpStr;
         end else
         if (Keyword='HUDSON') then
         begin
            PathHudson := TmpStr;
         end else
         if (Keyword='NETMAIL') then
         begin
            NetAreaId := TmpStr;
         end else
         if (Keyword='SYSTEM') then
         begin
            Msgorigin := TmpStr;
         end else
         if (Keyword='PERSONALAREAID') then
         begin
            PersonalAreaid := TmpStr;
         end else
         begin
            Writeln(' * Unknown keyword ',keyword);
         end;
      end;
      close(TF);
   end;
end;


Procedure ProcessCmdLine;              {Process command line params}
  Var
    i: Word;
    TmpStr: String;

  Begin
  For i := 1 to ParamCount Do
    Begin
    TmpStr := ParamStr(i);
    Case TmpStr[1] of
      '-','/':                         {command line param}
        Begin
        Case UpCase(TmpStr[2]) of
          'F': MsgFrom := Copy(TmpStr, 3, 50);
          'S': MsgSubj := Copy(TmpStr, 3, 100);
          'T': MsgTo := Copy(TmpStr, 3, 50);
          'A': MsgAreaId := 'T' + Copy(TmpStr, 3, 128);
          'H': PathHudson := Copy(TmpStr, 1, 128);
          {
          'P': Priv := True;
          }
          'E': Del := True;
          'M': Scanpersonal := True;
          {
          'G': DoEcho := True;
          }
          {
          'Z': Case UpCase(TmpStr[3]) of
                 'E': MsgType := mmtEchomail;
                 'N': MsgType := mmtNetmail;
                 'L': MsgType := mmtNormal;
                 Else
                   WriteLn(' Valid mail types are E=Echo N=Netmail L=Local');
                   halt(1);
                 End;
          }
          'O': If ParseAddr(Copy(TmpStr, 3, 128), DestAddr, OrigAddr) Then;
          'D': If ParseAddr(Copy(TmpStr, 3, 128), OrigAddr, DestAddr) Then;
          'C': MakeConversion := True;
          Else
            WriteLn('Invalid cmd line param: ', TmpStr);
            halt(1);
          End;
        End;
      Else
        Begin                          {Msg Text Filename}
        msgFileName:= TmpStr;
        End;
      End;
    End;
  End;


Procedure ProcessMsgFile;              {Process text from message file}
  Var
    TF: Text;                         {Use TFile object for ease of use}
    TmpStr: String;

  Begin

  Assign(TF, MsgFileName);
  {$I-}
  Reset(TF);
  {$I+}
  if (IOResult=0) then
    Begin
    If OpenOrCreateMsgArea(Msg, MsgAreaId) Then
      Begin
      if Msg^.LockMsgBase then
      begin
         Msg^.StartNewMsg;
         {
         FixSpaces(MsgFrom);
         }
         Msg^.SetFrom(Proper(MsgFrom));
         {
         FixSpaces(MsgTo);
         }
         Msg^.SetTo(Proper(MsgTo));
         {
         FixSpaces(MsgSubj);
         }
         Msg^.SetSubj(MsgSubj);
         Msg^.SetPriv(msgType=mmtnetmail);
         Msg^.SetDate(DateStr(GetDosDate));
         Msg^.SetTime(TimeStr(GetDosDate));
         Msg^.SetLocal(True);
         Msg^.SetOrig(OrigAddr);
         Msg^.SetDest(DestAddr);

         {msgid kuldge}
         Msg^.DoKludgeLn(#1 + 'MSGID: ' + AddrStr(OrigAddr) + ' ' +
            Lower(HexLong(ToUnixDate(getDosdate))));
         Msg^.Dokludgeln(#1 + 'PID: ' + Pid);

         While not eof(TF) Do
           Begin
           readln(TF,TmpStr);
           Msg^.DoStringLn(TmpStr);
           End;

         {Aggiunge tear-line e origin in echo}
         Msg^.DoStringLn('---');
         if msgtype=mmtEchomail then
         begin
            Msg^.DoStringLn(' * Origin: '+Msgorigin+' ('+AddrStr(OrigAddr)+')');
         end;

         If Msg^.WriteMsg <> 0 Then
           WriteLn(' * Error saving message')
         Else
           Writeln(' * Written Msg ',Msg^.GetMsgDisplayNum,' in ',Copy(MsgAreaId,1,30));
         Msg^.UnlockMsgBase;

      end;
      If CloseMsgArea(Msg) Then;
      End
    Else
      WriteLn(' * Unable to open msg base: ', MsgAreaId);
    close(TF);
    End
  Else
    WriteLn(' * Unable to open msg text file: ', MsgFileName);
  If Del Then
    Begin
    If EraseFile(MsgFileName) Then
      WriteLn(MsgFileName, ' erased');
    End;
  End;


Begin

   Writeln;

   Pid := 'MSGUTIL v' + versione + '-';
   {$IFDEF OS2}
   Pid := Pid + 'OS2';
   {$ELSE}
   Pid := Pid + 'DOS';
   {$ENDIF}

   Writeln(Pid,'; Msg-Base utility');

   Writeln('        Copyright (C) 1996 by Alessandro Trebbi, All Rights Reserved');
   Writeln;

   if ParamCount=0 then
   begin
      Writeln(' * Usage: ',ParamStr(0),' [TextFile] [/C] [Optional paramaters]');
      WriteLn('    /FFrom_Name        /TTo_Name            /SSubject_Line');
      WriteLn('    /OOrigAddr         /DDestAddr           /AAreaTAG');
      WriteLn('    /E = Erase File    /HHudsonPath         /C = Convert Msg Base');
      Writeln('    /M = Scan Personal');
      Halt(1);
   end;

   fsplit(fexpand(Paramstr(0)),D0,N,E);
   if (D0[length(d0)]<>'\') then
      D0 := d0 + '\';

   MakeConversion := False;
   Msgfilename := '';
   PathHudson := '';
   PathAreasbbs := '';
   NetAreaid := '';
   MsgAreaid := '';
   MsgTo := 'All';
   Sysop := 'Sysop';
   MsgSubj := '';
   Msgorigin := '';
   PersonalAreaid := '';
   Scanpersonal := false;

   ProcessCfgFile;
   UpSysop := Upper(Sysop);
   i := pos(' ',UpSysop);
   if (I>0) then
   begin
      InvUpSysop := Copy (upSysop,i+1,length(upSysop)-i) + ' ' +
         Copy(UpSysop,1,i-1);
   end else
      InvUpSysop := UpSysop;

   MsgFrom := Sysop;

   ProcessCmdLine;

   if MsgAreaid = '' then
   begin
      MsgAreaId := NetAreaId;
      msgtype := mmtnetmail;
   end else
      msgtype := mmtechomail;

   if MsgSubj='' then
      Msgsubj := msgFilename;

   setpathhudson(PathHudson);
   SetDefaultPathareasBbs(PathAreasBbs);

   if MakeConversion then
   begin
      UpDateAreasBbs := False;
      LastChanged := True;
      ConvertedAreas := 0;
      NAreas := 0;

      Assign(Cfg,D0 + 'MsgCvt.Cfg');
      {$I-}
      Reset(Cfg);
      {$I+}
      if IOResult=0 then
      begin
         while not eof(Cfg) do
         begin
            ReadLn(Cfg,L);
            L := Upper(StripBoth(L, ' '));
            if pos('CVT ',L)=1 then
            begin
               Delete(L,1,4);
               L := StripLead(L, ' ');
               I := Pos(' ',L);
               OldAreaId := Copy(L,1,I-1);
               delete(L,1,I);
               Areaid := StripLead(L, ' ');
               ConvertArea(OldAreaId, AreaId);
            end;
         end;
         close(Cfg);
      end;

      Assign(AreasBbs,PathAreasbbs);
      {$I-}
      Reset(AreasBbs);
      {$I+}
      If IOResult=0 then
      begin
         Writeln(' * Convert MSG areas');
         while not eof(AreasBbs) do
         begin
            ReadLn(AreasBbs,L);
            ParseAreasBbsLine(L, Tag, AreaId);
            if Tag<>'' then
            begin
               inc(NAreas);
               if not LastChanged then
                  Writeln(#13,'   ц');
               Write('   юд',NAreas:4,' - ',Tag);
               LastChanged := False;
               {TempStr=TAG, TempStr1=AREAID}
               OldAreaId := Tag2AreaId(Tag,D0+'OldAreas.Bbs');
               if OldAreaId='' then
               begin
                  {nuova area}
                  UpDateAreasBbs := true;
               end else
               if (Upper(OldAreaId)<>Upper(AreaId)) then
               begin
                  UpDateAreasBbs := True;
                  LastChanged := True;
                  Writeln;
                  {il formato e' cambiato, fa la conversione}
                  ConvertArea(OldAreaId, AreaId);
                  inc(ConvertedAreas);
               end;
            end;
         end;
         Close(AreasBbs);
         if not LastChanged then
            Writeln;
         Writeln(' * Total of ',ConvertedAreas,' converted MSG areas');
         if UpDateAreasBbs then
         begin
            {ora aggiorna il file}
            Assign(AreasBbs,PathAreasBbs);
            {$I-}
            Reset(AreasBbs);
            {$I+}
            if IOResult=0 then
            begin
               Assign(OldAreasBbs,D0+'OldAreas.Bbs');
               {$I-}
               Rewrite(OldAreasBbs);
               {$I+}
               if IOResult=0 then
               begin
                  Writeln(' * Update OldAreas.Bbs');
                  While not eof(AreasBbs) do
                  begin
                     ReadLn(AreasBbs,L);
                     Writeln(OldAreasBbs, L);
                  end;
                  Close(OldAreasBbs);
               end;
               Close(AreasBbs);
            end;
         end;
      end else
      begin
         Writeln(' * Areas.Bbs not found');
      end;
   end;

   {modo IMPORT}
   if msgFilename<>'' then
      ProcessMsgFile;

   if ScanPersonal and (personalAreaId<>'') then
   begin
      Writeln(' * Search personal MSG');

      DupesPtr := new(checkDupePtr, init(D0 + 'MsgDupes.dat', 2048));

      MsgFound := 0;
      {controllo netmail}
      NAreas:=0;
      lastchanged := False;

      Write('   юд   0 - Netmail');
      PersonalMsg(NetareaId, '');

      {EchoMail}
      Assign(AreasBbs,PathAreasbbs);
      {$I-}
      Reset(AreasBbs);
      {$I+}
      If IOResult=0 then
      begin
         while not eof(AreasBbs) do
         begin
            ReadLn(AreasBbs,L);
            ParseAreasBbsLine(L, Tag, AreaId);
            if Tag<>'' then
            begin
               inc(NAreas);
               if not lastchanged then
                  Writeln(#13,'   ц');
               Write('   юд',NAreas:4,' - ',Tag);
               lastchanged := False;
               PersonalMsg(AreaId, tag);
            end;
         end;
         Close(AreasBbs);
         if not lastchanged then
            writeln;
         Writeln(' * Total of ',MsgFound,' personal MSG found');
      end else
      begin
         Writeln(' * Areas.Bbs not found');
      end;

      dispose(dupesptr, done);

   end;

End.
