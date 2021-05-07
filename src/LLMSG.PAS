Unit LLMSG;

{$I LL.Def}

Interface

Procedure PostAnnunciNews(TempAreaId:String);
Procedure GetSearchStr;

Implementation


Uses MTask, Dos, Crt, LLParseS, LLText,
     MKFile, MKString, MKMsgAbs, MKOpen, MKGlobT, MKDos, MKMisc, LLGEN;


Function ParseAreaId(TempStr:String; Var AreaId:PathStr; Var Tipo:Byte): Boolean;
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
      while (AreaId<>'') and (AreaId[length(AreaId)]=' ') do
         dec(AreaId[0]);
      delete(TempStr,1,I);
      if TempStr<>'' then
      begin
         StripLeadingSpace(TempStr);
         val(TempStr,I,Code)
      end else
         Code := 1;
      if (Code=0) and (I>=0) and (I<=2) then
         Tipo := I
      else
         Tipo := 1;
   end;
   ParseAreaId := AreaId <> '';
end {ParseAreaId};


Procedure PostAnnunciNews(TempAreaId:String);
{ 0:Normal,1:EchoMail,2:NetMail }
Var MsgWriteError:Integer;
    TMsg: AbsMsgPtr;
    NewMsgNum:LongInt;
    MsgLen:Longint;
    Part:Integer;
    TempDate:Longint;
    LastLine:String;
    {fm:Byte;}
    TempFileNameRef:DescTypePtr;
    AreaType: Byte;
    AreaId: String;

   Function StripIBM (S:String):String;
   CONST tabella: ARRAY[128..255] OF char =
                        ('C','u','e','a','a','a','a','c','e','e','e','i',
                        'i','i','A','A'
                        ,'E','a','A','o','o','o','u','u','y','O','U','c'
                        ,'L','Y','P','f'
                        ,'a','i','o','u','n','N','a','o','?','+','+','2'
                        ,'4','|','<','>'
                        ,'#','#','#','|','+','+','+','+','+','+','|','+'
                        ,'+','+','+','+'
                        ,'+','+','+','+','-','+','+','+','+','+','+','+'
                        ,'+','=','+','+'
                        ,'+','+','+','+','+','+','+','+','+','+','+','#'
                        ,'#','#','#','#'
                        ,'a','b','c','P','S','s','m','t','F',' ','O','d'
                        ,'8','O','E',' '
                        ,'=','+','>','<','|','|','/','~','o','.','.','/'
                        ,'n','2','.',' ');
   var I:Integer;
   begin
      for I:=1 to length(S) do
      begin
         if S[I]<' ' then
         begin
            S[I] := '.'
         end else
         if not PostIbm and (ord(S[I])>=128) then
         begin
            S[I]:=tabella[ord(S[I])];
         end
      end;
      StripIBM := S;
   end {StripIBM};

begin

  {
  fm := FileMode;
  FileMode := FmReadWrite;
  }
  Part := 0;
  MsgWriteError := 0;
  LastLine := '';

  {controlla se c'e' un AKA}
  I := pos(' ',TempAreaID);
  if I>0 then
  begin
     {segue l'indirizzo da usare nell'area}
     if ParseAddr(Copy(TempAreaId,I+1,length(TempAreaId)-I),
        MsgOrigAddr, MsgOrigAddr) then;
     TempAreaId := Copy(TempAreaId,1,I-1);
  end;

  if ParseAreaId(TempAreaId, AreaId, AreaType) then;

  if OpenOrCreateMsgArea(TMsg, AreaId) then
  Begin
     if TMsg^.LockMsgBase then
     begin
        Case AreaType of
          0: TMsg^.SetMailType(mmtNormal);
          1: TMsg^.SetMailType(mmtEchoMail);
          2: TMsg^.SetMailType(mmtNetMail);
        end;

        if shOpenTextFile(AllFiles, PathAll) then
        begin
           while (MsgWriteError=0) and (LastLine<>'') or not eof(AllFiles) do
           begin
              if LastLine='' then
                 ReadLn(AllFiles,LastLine);

              TMsg^.StartNewMsg;       {initialize for adding msg}

              Inc(Part);

              repeat
                 TempDate := GetDosDate;
                 Sleep;
              until (Lower(HexLong(ToUnixDate(Tempdate)))<>PrevMsgId);

              PrevMsgId := Lower(HexLong(ToUnixDate(Tempdate)));

              TMsg^.SetFrom(MsgFrom);           {Set from name}
              TMsg^.SetTo(MsgTo);               {Set to name}

              if Part=1 then
                 TMsg^.SetSubj(MsgSubject)
              else
                 TMsg^.SetSubj(MsgSubject + ' (' + Long2Str(Part,0)+')');

              TMsg^.SetDate(DateStr(TempDate));   {Set msg date mm-dd-yy}
              TMsg^.SetTime(TimeStr(TempDate));   {Set msg time hh:mm}
              TMsg^.SetEcho(True);                  {Should msg be echoed}
              TMsg^.SetRefer(0);

              Tmsg^.SetLocal(True);

              if AreaType=2 then
              begin
                 Tmsg^.SetPriv(True);
                 TMsg^.SetDest(MsgDestAddr);
                 TMsg^.SetOrig(MsgOrigAddr);
              end;

              TMsg^.DoKludgeLn(#1 + 'MSGID: ' + AddrStr(MsgOrigAddr) + ' ' +
                 PrevMsgId);

              if KludgeReply<>'' then
              begin
                 TMsg^.DoKludgeLn(#1 + 'REPLY: ' + KludgeReply);
              end;

              if KludgeFdn<>'' then
              begin
                 TMsg^.DoKludgeLn(#1 + 'FDN: ' + KludgeFdn);
              end;

              TMsg^.DoKludgeLn(#1 + 'PID: LList ' + versione);

              If PostIbm then
              begin
                 TMsg^.DoKludgeLn( #1 + 'CHRS: IBMPC 2');
              end;

              if (AreaType=2) and (KludgeReplyAddr<>'') then
              begin
                 TMsg^.DoStringLn('To: '+KludgeReplyAddr);
                 Tmsg^.DoStringLn('');
              end;

              if not registrato then
              begin
                 Tmsg^.DoStringLn('');
                 Tmsg^.DoStringLn(' *** Unregistered Evaluation Copy ***');
                 Tmsg^.DoStringLn('');
              end;

              if part=1 then
              begin
                 TempFileNameRef := Prefix;
                 while TempFileNameRef<>Nil do
                 begin
                    if shOpenTextFile(VariText,TEmpFileNameRef^.Descrizione^) then
                    begin
                       SetTextBuf(VariText,VariBuf^,SizeTxtBuf);
                       while not eof(VariText) do
                       begin
                          ReadLn(VariText,TempStr);
                          if length(TempStr)>78 then
                          begin
                             Byte(TempStr[0]) := 78;
                             while (TempStr<>'') and (TempStr[length(TempStr)]=' ') do
                                dec(TempStr[0]);
                          end;
                          TMsg^.DoStringLn(StripIbm(TempStr));
                       end;
                       Close(VariText)
                    end;
                    TempFileNameRef := TempFileNameRef^.Next;
                 end;
              end else
              begin
                 if message[79]=nil then
                    TempStr := '* ... Continues from previous Msg'
                 else
                    TempStr := message[79]^;
                 TMsg^.DoStringLn(TempStr);
                 TMsg^.DoStringLn('');
              end;

              if LastLine<>'' then
              begin
                 TMsg^.DoStringLn(StripIBM(LastLine));
                 MsgLen := length(LastLine)+2;
                 LastLine := '';
              end else
                 MsgLen := 0;

              while not eof(AllFiles) and (MsgLen<6144) do
              begin
                 ReadLn(AllFiles,TempStr);
                 if length(TempStr)>78 then
                 begin
                    Byte(TempStr[0]) := 78;
                    while (TempStr<>'') and (TempStr[length(TempStr)]=' ') do
                       dec(TempStr[0]);
                 end;
                 inc(MsgLen,length(TempStr)+2);
                 TMsg^.DoStringLn(StripIBM(TempStr));
              end;

              if not eof(AllFiles) then
              begin
                 {completa la descrizione del file corrente}
                 I := 25;
                 repeat
                    dec(I);
                    ReadLn(AllFiles,TempStr);
                    if length(TempStr)>78 then
                    begin
                       Byte(TempStr[0]) := 78;
                       while (TempStr<>'') and (TempStr[length(TempStr)]=' ') do
                          dec(TempStr[0]);
                    end;
                    if (TempStr='') or (TempStr[1]<>' ') then
                       LastLine := TempStr
                    else
                       TMsg^.DoStringLn(StripIBM(TempStr));
                 until (I=0) or (TempStr='') or (TempStr[1]<>' ') or eof(AllFiles);
              end;

              if (LastLine='') and eof(AllFiles) then
              begin
                 {
                 FileMode := FmReadOnly + FmDenyWrite;
                 }
                 TempFileNameRef := Suffix;
                 while TempFileNameRef<>Nil do
                 begin
                    if shOpenTextFile(VariText,TEmpFileNameRef^.Descrizione^) then
                    begin
                       SetTextBuf(VariText,VariBuf^,SizeTxtBuf);
                       while not eof(VariText) do
                       begin
                          ReadLn(VariText,TempStr);
                          if length(TempStr)>78 then
                          begin
                             Byte(TempStr[0]) := 78;
                             while (TempStr<>'') and (TempStr[length(TempStr)]=' ') do
                                dec(TempStr[0]);
                          end;
                          TMsg^.DoStringLn(StripIbm(TempStr));
                       end;
                       Close(VariText)
                    end;
                    TempFileNameRef := TempFileNameRef^.Next;
                 end;
              end else
              begin
                 TMsg^.DoStringLn('');
                 if message[80]=nil then
                    TempStr := ' * To be continued ...'
                 else
                    TempStr := message[80]^;
                 TMsg^.DoStringLn(TempStr);
              end;

              Tmsg^.DoStringLn('');
              TMsg^.DoStringLn('---');

              if AreaType=1 then
              begin
                 {Origin solo nella echomail}
                 TMsg^.DoStringLn(StripIBM(' * Origin: '+MsgOrigin+' ('+AddrStr(MsgOrigAddr)+')'));
              end;

              MsgWriteError := TMsg^.WriteMsg;    {Save the message}

              if MsgWriteError=0 then
              begin
                 Writeln(' * Written Msg ',TMsg^.GetMsgDisplayNum,' in ',Copy(AreaId,1,30));
                 Writeln(LogFile,PreLog(LogWork),'Written Msg ',TMsg^.GetMsgDisplayNum,' in ',Copy(AreaId,1,30));
                 Flush(LogFile);
                 {Setta i Flag}
                 if AreaType=1 then
                    EchoWritten := True
                 else
                 if AreaType=2 then
                    NetWritten := True
              end;
           end;
           Close(AllFiles);
        end;
        if Tmsg^.UnlockMsgBase then;
     end else
        MsgWriteError := 10;
     If CloseMsgArea(TMsg) then;
  end else
     MsgWriteError := 10;

  if MsgWriteError<>0 then
  begin
     writeln(' * Can''t write Msg in ',Copy(AreaId,1,30));
     writeln(LogFile,PreLog(LogError),'Can''t write Msg in ',Copy(AreaId,1,30));
     Flush(LOgFile);
     Assign(VariText,D0+'LList.Bad');
     SetTextBuf(VariText,VariBuf^,SizeTxtBuf);
     {
     FileMode := FmReadWrite + FmDenyWrite;
     }
     {$I-}
     Append(VariText);
     {$I+}
     if IOResult<>0 then
     begin
        Rewrite(VariText);
     end;
     Writeln(VariText,'É',RepeatStr('Í',76),'»');
     TempStr := ' From: ' + MsgFrom + ' (' + AddrStr(MsgorigAddr) + ')';
     Writeln(VariText,'º',TempStr,RepeatStr(' ',76-length(TempStr)),'º');
     TempStr := '   To: ' + MsgTo + ' (' + AddrStr(MsgDestAddr) + ')';
     Writeln(VariText,'º',TempStr,RepeatStr(' ',76-length(TempStr)),'º');
     TempStr := ' Subject: ' + MsgSubject;
     Writeln(VariText,'º',TempStr,RepeatStr(' ',76-length(TempStr)),'º');
     TempDate := GetDosdate;
     TempStr := ' Date: ' + DateStr(TempDate);
     Writeln(VariText,'º',TempStr,RepeatStr(' ',76-length(TempStr)),'º');
     TempStr := ' AreaId: ' + AreaId + ',' + Long2Str(AreaType,0);
     Writeln(VariText,'º',TempStr,RepeatStr(' ',76-length(TempStr)),'º');
     Writeln(VariText,'È',RepeatStr('Í',76),'¼');

     if shOpenTextFile(AllFiles, PathAll) then
     begin
        while not eof(AllFiles) do
        begin
           ReadLn(AllFiles,TempStr);
           Writeln(VariText,TempStr);
        end;
        close(AllFiles);
     end;
     Writeln(VariText,RepeatStr('=',78));
     Close(VariText);
  end;

end {PostAnnunciNews};



Procedure GetSearchStr;
(*
Const ValidChr='ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890~!@#$%^&()-_{}';
*)
Var AltriFiles:Boolean;
    TempText:Text;
    KludgeFdn:String;
   Function GetSearchStr1(Var StartingNumber:Longint;
      AreaId:String):Boolean;
   Var
      MsgOut: AbsMsgPtr;
      MsgReadError:Integer;
      Last:Longint;
      TempStr1:String;
      TempAddr:AddrType;
      FoundOrig: Boolean;
      AreaType: Byte;
      TempStr: String;
   begin

      MsgReadError := 0;
      if ParseAreaId(AreaId, AreaId, AreaType) then;

      if Not QuietMode then
         Write(' * Scanning Msg Area ',Copy(AreaID,1,30));
      Writeln(LogFile,PreLog(LogWork),'Scanning Msg Area ',Copy(AreaID,1,30));
      Flush(LOgFile);

      MSgReadError := 0;
      if OpenMsgArea(MsgOut, AreaId) then
      begin
        if Not QuietMode then
        begin
           Last := MsgOut^.GetHighMsgNum;
           I := WhereX;
           write(0:8,' / ',Last);
           GotoXY(I,WhereY);
        end;

        Case AreaType of
            0: MsgOut^.SetMailType(mmtNormal);
            1: MsgOut^.SetMailType(mmtEchoMail);
            2: MsgOut^.SetMailType(mmtNetMail);
        End;

        MsgOut^.SeekFirst(StartingNumber);

        While (NStringSearch=0) and MsgOut^.SeekFound Do
        Begin

           MsgOut^.MsgStartUp;

           if not QuietMode then
              Write(MsgOut^.GetMsgDisplayNum:8,#8#8#8#8#8#8#8#8);

           TempStr := Upper(MsgOut^.GetTo);
           AltriFiles := False;
           PrivateSearch := AreaType = 2;

           I := pos(' ',TempStr);
           if I>0 then
           begin
              {destinatario di due parole, la seconda e' l'indirizzo}
              TempStr1 := Copy(TempStr,1,I-1);
              Delete(TempStr,1,I);
              if ParseAddr(TempStr,TempAddr,TempAddr) then
              begin
                 if AddrEqual(TempAddr,MsgOrigAddr) then
                 begin
                    {il messaggio e' per me}
                    TempStr := TempStr1
                 end else
                 begin
                    {e' per me se trovo un aka valido}
                    I := 1;
                    while (I<=NAka) and not addrequal(TempAddr, aka[i]) do
                       inc(I);
                    if I>NAka then
                    begin
                       TempStr := ''
                    end else
                    begin
                       TempStr := TempStr1;
                    end;
                 end;
              end else
                 TempStr := '';
              if TempStr<>'' then
              begin
                 AltriFiles := True;
                 PrivateSearch := False;
                 SearchDb := False;
              end;
           end;

           if AreaType=2 then
           begin
              {netmail, risponde solo se e' indirizzato al mio nodo}
              MsgOut^.GetDest(TempAddr);
              if AddrEqual(TempAddr,MsgOrigAddr) then
              begin
                 {il messaggio e' per me}
                 {Nothing to do}
              end else
              begin
                 {e' per me se trovo un aka valido}
                 I := 1;
                 while (I<=NAka) and
                      not AddrEqual(TempAddr,Aka[I]) do
                    inc(I);
                 if I>NAka then
                 begin
                    TempStr := '';
                 end else
                 begin
                    {E' per me, nothing to do}
                 end;
              end;
           end;

           if MsgToLlist(TempStr) and
               not (MsgOut^.IsRcvd) then
           begin

              SearchDb := MsgArea[CurrMsgArea]^.SearchDb;
              MsgOut^.SetRcvd(True);
              MsgOut^.RewriteHdr;

                 TempStr := MsgOut^.GetSubj;
                 if pos('Re: ',TempStr)=1 then
                    delete(TempStr,1,4);
                 I := pos('(Part #',TempStr);
                 if I>0 then
                    TempStr := Copy(TempStr,1,I-1);

              MsgTo := MsgOut^.GetFrom;

              MsgOut^.MsgTxtStartUp;
              ViewContents := VcNo;
              KludgeReply := '';
              KludgeReplyTo := '';
              KludgeREplyAddr := '';

              TempStr1 := MsgOut^.GetString(255);
              While (Not MsgOut^.EOM) and
                  (pos('--- ',TempStr1)<>1) and (TempStr1<>'---') and
                 {questo nel caso manchi la tearline prima dell'origin}
                  ((AreaType<>2) or (pos(' * Origin:',TempStr1)<>1))
                 Do
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
                    if pos('REPLYTO ',TempStr1)=1 then
                    begin
                       delete(TempStr1,1,8);
                       StripLeadingSpace(TempStr1);
                       KludgeReplyTo := TempStr1;
                    end;
                    if pos('REPLYADDR ',TempStr1)=1 then
                    begin
                       delete(TempStr1,1,10);
                       StripLeadingSpace(TempStr1);
                       KludgeReplyAddr := TempStr1;
                    end;
                    if pos('REALNAME: ',TempStr1)=1 then
                    begin
                       delete(TempStr1,1,10);
                       StripLeadingSpace(TempStr1);
                       MsgTo := TempStr1;
                    end;
                 end else
                 begin
                    StripLeadingSpace(TempStr1);
                    TempStr1 := Upper(TempStr1);
                    if pos('DIR ',TempStr1)=1 then
                    begin
                       delete(TempStr1,1,4);
                       stripleadingSpace(TempStr1);
                       If TempStr1<>'' then
                          TempStr := TempStr + ' ' + TempStr1;
                    end else
                    if pos('DDIR ',TempStr1)=1 then
                    begin
                       delete(TempStr1,1,5);
                       ViewContents := VcAll;
                       stripleadingSpace(TempStr1);
                       If TempStr1<>'' then
                          TempStr := TempStr + ' ' + TempStr1;
                    end else
                    if pos('KEYWORD ',TempStr1)=1 then
                    begin
                       delete(TempStr1,1,8);
                       stripleadingSpace(TempStr1);
                       If TempStr1<>'' then
                          TempStr := TempStr + ' "' + TempStr1 + '"';
                    end else
                    if pos('DKEYWORD ',TempStr1)=1 then
                    begin
                       delete(TempStr1,1,9);
                       ViewContents := VcAll;
                       stripleadingSpace(TempStr1);
                       If TempStr1<>'' then
                          TempStr := TempStr + ' "' + TempStr1 + '"';
                    end;
                 end;
                 TempStr1 := MsgOut^.GetString(255);
              End;

              Case AreaType of
              0: begin
                    MsgDestAddr := MsgOrigAddr;
                 end;
              1:
                 begin
                    FoundOrig := False;
                    {cerca l'origin del messaggio}
                    while not MsgOut^.EOM and (pos(' * Origin:',TempStr1)<>1) do
                    begin
                       TempStr1 := MsgOut^.GetString(255);
                    end;
                    if pos(' * Origin:',TempStr1)=1 then
                    begin
                       {Ha trovato l'origin del messaggio}
                       I := Length(TempStr1);
                       while (I>0) and (TempStr1[I]<>')') do
                          dec(I);
                       dec(I);
                       if I>0 then
                       begin
                          byte(TempStr1[0]) := I;
                          while (I>0) and (TempStr1[I]<>'(') do
                             dec(I);
                          if I>0 then
                          begin
                             delete(TempStr1,1,I);
                             {esclude l'evantuale domain}
                             I := pos(' ',TempStr1);
                             if I>0 then
                             begin
                                delete(TempStr1,1,I);
                                stripleadingspace(TempStr1)
                             end;
                             {esclude l'eventuale domain}
                             I := pos('@',TempStr1);
                             if I>0 then
                                Byte(TempStr1[0]) := I - 1;
                             FoundOrig :=
                                ParseAddr(TempStr1,MsgDestAddr,MsgDestAddr);
                          end;
                       end;
                    end;
                    if not FoundOrig then
                    begin
                       if (KludgeReply<>'') then
                       begin
                          I := pos(' ',KludgeReply);
                          TempStr1 := Copy(KludgeReply,1,I-1);
                          I := pos('@',TempStr1);
                          if I>0 then
                             Byte(TempStr1[0]) := I - 1;
                          if not ParseAddr(TempStr1,MsgDestAddr,MsgDestAddr) then
                          begin
                             MsgOut^.GetOrig(MsgDestAddr);
                          end
                       end else
                          MsgOut^.GetOrig(MsgDestAddr);
                    end;
                 end;
              2: begin
                    MsgOut^.GetOrig(MsgDestAddr);
                 end;
              end;

              If ViewContents=VcAll then
                 TempStr := TempStr + ' -VC';

              StripLeadingSpace(TempStr);

              if not QuietMode then
                 Writeln;

              Writeln(' * Found request from ',MsgTo,' (',AddrStr(MsgDestAddr),')');
              Writeln(LogFile,PreLog(LogWork),'Found request from ',MsgTo,' (',AddrStr(MsgDestAddr),')');
              Flush(LogFile);

              if ParseSubject(TempStr,AltriFiles,False) then
              begin
                 {cerca un AKA che matcha il numero di zona}
                 I := 0;
                 while (I<=NAka) and (Aka[I].Zone<>MsgDestAddr.Zone) do
                    inc(I);
                 if I>NAka then
                    I := 0;
                 MsgOrigAddr := Aka[I];

                 MsgSubject := TempStr;
                 MsgFrom := 'LList' + ' '+AddrStr(MsgOrigAddr);
                 StartIngNumber := MsgOut^.GetMsgNum + 1;
              end else
              begin
                 if Not QuietMode then
                 begin
                    Write(#13,' * Scanning Msg Area ',Copy(AreaID,1,30));
                    I := WhereX;
                    write(MsgOut^.GetMsgNum:8,' / ',Last);
                    GotoXY(I,WhereY);
                 end;
                 MsgOut^.SeekNext;
              end;
           end else
              MsgOut^.SeekNext;
        end;

        if (NstringSearch=0) then
        begin
           StartingNumber := 1;
           if not quietmode then
           begin
              Writeln('':79-WhereX);
           end;
        end;

        if CloseMsgArea(MsgOut) then;

      end else
      begin
         Writeln;
         MsgReadError := 0;
      end;

      GetSearchStr1 := (NstringSearch>0);

   end {GetSearchStr1};
begin
   Writeln(' * Searching FSEARCH Msg...');
   Writeln(LogFile,PreLog(LogStart),'Searching FSEARCH Msg...');
   Flush(LOgFile);

   NStringSearch := 0;

   RemoveListaNum(Aree);
   Aree := Nil;

   repeat
      inc(CurrMsgArea);
      if CurrMsgArea<=NSearch then
      begin
         MaxBytesUUEncode1 := MsgArea[CurrMsgArea]^.MaxBytesUUEncode;
         Aree := CopyListaAree(MsgArea[CurrMsgArea]^.Aree);
         PostIbm := Not MsgArea[CurrMsgArea]^.NoIbm;
         MsgOrigin := MsgArea[CurrMsgArea]^.MsgOrigin;
         if MsgOrigin='' then
            MsgOrigin := BbsName;
         Prefix := MsgArea[CurrMsgArea]^.Prefix;
         Suffix := MsgArea[CurrMsgArea]^.Suffix;
      end;
   until (CurrMsgArea>NSearch)
      or GetSearchStr1(StartingMsg,MsgArea[CurrMsgArea]^.AreaId1);
   if (CurrMsgArea<=NSearch) then
   begin
      if AltriFiles then
      begin
         AltriFiles := False;
         SearchMaxFiles := SearchMaxFiles1 * 4;
      end else
      begin
         SearchMaxFiles := SearchMaxFiles1;
      end;
   end;
end {GetSearchStr};


end.
