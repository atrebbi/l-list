Unit MKMsgFid;       {Fido *.Msg Unit}

{$I MKB.Def}

{
     MKMsgFid - Copyright 1993, 1994 by Mark May - MK Software
     You are free to use this code in your programs, however
     it may not be included in Source/TPU function libraries
     without my permission.

     Mythical Kingom Tech BBS (513)237-7737 HST/v32
     FidoNet: 1:110/290
     Rime: ->MYTHKING
     You may also reach me at maym@dmapub.dma.org
}


{
     Now handles message size only limited by disk space and
     the maximum size of a longint, while using only a small
     buffer for low memory usage with reasonable speed
}

Interface

Uses
{$IFDEF VIRTUALPASCAL}
  Os2Base,
{$ENDIF}
  MKGlobT, MKMsgAbs, {MkFFile,} MTask,
{$IFDEF WINDOWS}
  Strings, WinDos;
{$ELSE}
  Dos;
{$ENDIF}

{attributi, bytes 186 e 187}
(* For addressee *ONLY*    * 0000 0000 0000 0001 *)
(* High priority           * 0000 0000 0000 0010 *)
(* Was read by addressee   * 0000 0000 0000 0100 *)
(* Was sent by FidoMail      0000 0000 0000 1000 *)
(* SUBJ=file(s) to send    * 0000 0000 0001 0000 *)
(* Msg from & to elsewhere   0000 0000 0010 0000 *)
(* Msg destination unknown   0000 0000 0100 0000 *)
(* Delete after sending    * 0000 0000 1000 0000 *)
(* Msg is Local, not Net     0000 0001 0000 0000 *)
(* Hold msg for pickup     * 0000 0010 0000 0000 *)
(* ---------------------- X  0000 0100 0000 0000 *)
(* SUBJ=file(s) to get     * 0000 1000 0000 0000 *)
(* Msg Receipt requested  X* 0001 0000 0000 0000 *)
(* Msg is a Msg Receipt   X* 0010 0000 0000 0000 *)
(* Audit Trail requested  X* 0100 0000 0000 0000 *)
(* SUBJ=files(s) to UPD   X* 1000 0000 0000 0000 *)

Const FidoMsgTextSize = 34000;

Type FMsgType = Record
  MsgChar: Array[0.. 189 + FidoMsgTextSize] of Byte;
  MsgFile: File;
  MsgName: String[13];
  MsgOpen: Boolean;
  Error: Word;
  NetMailPath: String[128];
  Dest: AddrType;
  Orig: AddrType;
  MsgStart: LongInt;
  DefaultZone: Word;
  QDate: String[8];
  QTime: String[5];
  CurrMsg: LongInt;
  SeekOver: Boolean;
  SR: SearchRec;
  Name: String[35];
  Handle: String[35];
  MailType: MsgMailType;
  HighMsgNum: Longint;
  {$IFDEF VIRTUALPASCAL}
  MsgSize: Longint;
  {$ELSE}
  MsgSize: Word;
  {$ENDIF}
  End;


Type FidoMsgObj = Object (AbsMsgObj)
  FM: ^FMsgType;
  Constructor Init;                      {Initialize FidoMsgOut}
  Destructor Done; Virtual; {Done FidoMsgOut}
  Procedure PutLong(L: LongInt; Position: LongInt); {Put long into msg}
  Procedure PutWord(W: Word; Position: LongInt);  {Put word into msg}
  Procedure PutByte(B: Byte; Position: LongInt);  {Put byte into msg}
  Function  GetByte(Position: LongInt): Byte; {Get byte from msg}
  Procedure PutNullStr(St: String; Position: LongInt);  {Put string & null into msg}
  Procedure SetMsgPath(St: String); Virtual; {Set netmail path}
  Function  GetHighMsgNum: LongInt; Virtual; {Get highest netmail msg number in area}
  Procedure SetDest(Var Addr: AddrType); Virtual; {Set Zone/Net/Node/Point for Dest}
  Procedure SetOrig(Var Addr: AddrType); Virtual; {Set Zone/Net/Node/Point for Orig}
  Procedure SetFrom(Name: String); Virtual; {Set message from}
  Procedure SetTo(Name: String); Virtual; {Set message to}
  Procedure SetSubj(Str: String); Virtual; {Set message subject}
  Procedure SetCost(SCost: Word); Virtual; {Set message cost}
  Procedure SetRefer(SRefer: LongInt); Virtual; {Set message reference}
  Procedure SetSeeAlso(SAlso: LongInt); Virtual; {Set message see also}
  Procedure SetDate(SDate: String); Virtual; {Set message date}
  Procedure SetTime(STime: String); Virtual; {Set message time}
  Procedure SetLocal(LS: Boolean); Virtual; {Set local status}
  Procedure SetRcvd(RS: Boolean); Virtual; {Set received status}
  Procedure SetPriv(PS: Boolean); Virtual; {Set priveledge vs public status}
  Procedure SetCrash(SS: Boolean); Virtual; {Set crash netmail status}
  Procedure SetHold(SS: Boolean); Virtual;
  Procedure SetEcho(SS: Boolean); Virtual;
  Procedure SetKillSent(SS: Boolean); Virtual; {Set kill/sent netmail status}
  Procedure SetFAttach(SS: Boolean); Virtual; {Set file attach status}
  Procedure SetReqRct(SS: Boolean); Virtual; {Set request receipt status}
  Procedure SetReqAud(SS: Boolean); Virtual; {Set request audit status}
  Procedure SetRetRct(SS: Boolean); Virtual; {Set return receipt status}
  Procedure SetFileReq(SS: Boolean); Virtual; {Set file request status}
  Procedure DoChar(Ch: Char); Virtual; {Add character to message text}
  Function  WriteMsg: Word; Virtual;
  Function  GetChar: Char; Virtual;
  Function  CvtDate: Boolean; Virtual;
  Function  BufferWord(i: Word):Word; Virtual;
  Function  BufferByte(i: Word):Byte; Virtual;
  Function  BufferNullString(i: Word; Max: Word): String; Virtual;
  Procedure MsgStartUp; Virtual; {set up msg for reading}
  Procedure SeekFirst(MsgNum: LongInt); Virtual; {Seek msg number}
  Procedure SeekNext; Virtual; {Find next matching msg}
  Procedure SeekPrior; Virtual; {Seek prior matching msg}
  Function  GetFrom: String; Virtual; {Get from name on current msg}
  Function  GetTo: String; Virtual; {Get to name on current msg}
  Function  GetSubj: String; Virtual; {Get subject on current msg}
  Function  GetCost: Word; Virtual; {Get cost of current msg}
  Function  GetDate: String; Virtual; {Get date of current msg}
  Function  GetTime: String; Virtual; {Get time of current msg}
  Function  GetRefer: LongInt; Virtual; {Get reply to of current msg}
  Function  GetSeeAlso: LongInt; Virtual; {Get see also of current msg}
  Function  GetMsgNum: LongInt; Virtual; {Get message number}
  Procedure GetOrig(Var Addr: AddrType); Virtual; {Get origin address}
  Procedure GetDest(Var Addr: AddrType); Virtual; {Get destination address}
  Function  IsLocal: Boolean; Virtual; {Is current msg local}
  Function  IsCrash: Boolean; Virtual; {Is current msg crash}
  Function  IsKillSent: Boolean; Virtual; {Is current msg kill sent}
  Function  IsFAttach: Boolean; Virtual; {Is current msg file attach}
  Function  IsReqRct: Boolean; Virtual; {Is current msg request receipt}
  Function  IsReqAud: Boolean; Virtual; {Is current msg request audit}
  Function  IsRetRct: Boolean; Virtual; {Is current msg a return receipt}
  Function  IsFileReq: Boolean; Virtual; {Is current msg a file request}
  Function  IsRcvd: Boolean; Virtual; {Is current msg received}
  Function  IsPriv: Boolean; Virtual; {Is current msg priviledged/private}
  Function  IsDeleted: Boolean; Virtual; {Is current msg deleted}
  Function  IsEchoed: Boolean; Virtual; {Msg should be echoed}
  Function  GetMsgLoc: LongInt; Virtual; {Msg location}
  Procedure SetMsgLoc(ML: LongInt); Virtual; {Msg location}
  Procedure YoursFirst(Name: String; Handle: String); Virtual; {Seek your mail}
  Procedure YoursNext; Virtual; {Seek next your mail}
  Function  YoursFound: Boolean; Virtual; {Message found}
  Procedure StartNewMsg; Virtual;
  Function  OpenMsgBase: Word; Virtual;
  Function  CloseMsgBase: Word; Virtual;
  Function  CreateMsgBase(MaxMsg: Word; MaxDays: Word): Word; Virtual;
  Function  SeekFound: Boolean; Virtual;
  Procedure SetMailType(MT: MsgMailType); Virtual; {Set message base type}
  Function  GetSubArea: Word; Virtual; {Get sub area number}
  Procedure ReWriteHdr; Virtual; {Rewrite msg header after changes}
  Procedure DeleteMsg; Virtual; {Delete current message}
  Function  NumberOfMsgs: LongInt; Virtual; {Number of messages}
  Function  GetLastRead(UNum: LongInt): LongInt; Virtual; {Get last read for user num}
  Procedure SetLastRead(UNum: LongInt; LR: LongInt); Virtual; {Set last read}
  Procedure MsgTxtStartUp; Virtual; {Do message text start up tasks}
  Function  MsgBaseExists: Boolean; Virtual;
  Procedure Rescan;
  Function  MsgExists(MsgNum: LongInt): Boolean;
  End;


Type FidoMsgPtr = ^FidoMsgObj;

Function MonthStr(MoNo: Byte): String; {Return 3 char month name for month num}
Function MonthNum(St: String):Word;


Implementation


Uses MKFile, MKString, MKDos;


Constructor FidoMsgObj.Init;
  Begin
  New(FM);
  If FM = Nil Then
    Begin
    Fail;
    Exit;
    End;
  FM^.NetMailPath := '';
  TxtCtr := 190;
  FM^.Dest.Zone := 0;
  FM^.Orig.Zone := 0;
  FM^.SeekOver := False;
  FM^.DefaultZone := 1;
  {FM^.MsgFile.Init(8192);}
  FM^.MsgOpen := False;
  End;


Destructor FidoMsgObj.Done;
  Begin
  If FM^.MsgOpen Then
    Close(FM^.MsgFile);
  {FM^.MsgFile.Done;}
  Dispose(FM);
  End;


Procedure FidoMsgObj.PutLong(L: LongInt; Position: LongInt);
Var Buf: Array[0..3] of byte absolute L;
    I: Integer;
  Begin
    for I := 0 to 3 do
       PutByte(Buf[I], Position + I);
  End;


Procedure FidoMsgObj.PutWord(W: Word; Position: LongInt);
Var Buf: Array[0..1] of byte absolute W;
    I: Integer;
  Begin
    for I := 0 to 1 do
       PutByte(Buf[I], Position + I);
  End;


Procedure FidoMsgObj.PutByte(B: Byte; Position: LongInt);
  Begin
    if Position <= 189 + FidoMsgTextSize then
    begin
       FM^.MsgChar[Position] := B;
       if Position > FM^.MsgSize then
          FM^.MsgSize := Position;
    end;
  End;


Function FidoMsgObj.GetByte(Position: LongInt): Byte;
  Begin
    GetByte := FM^.MsgChar[Position]
  End;


Procedure FidoMsgObj.PutNullStr(St: String; Position: LongInt);
Var
   I : Integer;
  Begin
  for I := 1 to length(ST) do
     PutByte( ord(St[I]), position + I - 1);
  PutByte(0, position + length(St));
  End;


Procedure FidoMsgObj.SetMsgPath(St: String);
  Begin
  FM^.NetMailPath := Copy(St, 1, 110);
  AddBackSlash(FM^.NetMailPath);
  End;


Function FidoMsgObj.GetHighMsgNum: LongInt;
  Begin
     GetHighMsgNum := FM^.HighMsgNum
  End;


Function MonthStr(MoNo: Byte): String;
  Begin
  Case MoNo of
    01: MonthStr := 'Jan';
    02: MonthStr := 'Feb';
    03: MonthStr := 'Mar';
    04: MonthStr := 'Apr';
    05: MonthStr := 'May';
    06: MonthStr := 'Jun';
    07: MonthStr := 'Jul';
    08: MonthStr := 'Aug';
    09: MonthStr := 'Sep';
    10: MonthStr := 'Oct';
    11: MonthStr := 'Nov';
    12: MonthStr := 'Dec';
    Else
      MonthStr := '???';
    End;
  End;


Procedure FidoMsgObj.SetDest(Var Addr: AddrType);
  Var
    TmpChr: Char;
  Begin
  FM^.Dest := Addr;
  PutWord(Addr.Net, 174);
  PutWord(Addr.Node, 166);
  If ((Addr.Point <> 0) and (FM^.MailType = mmtNetmail)) Then
    Begin
    If ((TxtCtr <> 190) And
    (GetByte(TxtCtr - 1) <> 13)) Then
      DoChar(#13);
    {non usare dokludgeln che filtra questo kludge!}
    DoStringLn(#1 + 'TOPT ' + Long2Str(Addr.Point));
    End;
  If ((FM^.Orig.Zone <> 0) and (FM^.MailTYpe = mmtNetMail)) Then
    Begin
    If ((TxtCtr <> 190) And
    (GetByte(TxtCtr - 1) <> 13)) Then
      DoChar(#13);
    {non usare dokludgeln che filtra questo kludge!}
    DoStringLn(#1 + 'INTL ' + PointlessAddrStr(FM^.Dest) + ' ' +
      PointlessAddrStr(FM^.Orig));
    End;
  End;


Procedure FidoMsgObj.SetOrig(Var Addr: AddrType);
  Begin
  FM^.Orig := Addr;
  PutWord(Addr.Net, 172);
  PutWord(Addr.Node, 168);
  If ((Addr.Point <> 0) and (FM^.MailType = mmtNetmail)) Then
    Begin
    If ((TxtCtr <> 190) And
    (GetByte(TxtCtr - 1) <> 13)) Then
      DoChar(#13);
    {non usare dokludgeln che filtra questo kludge!}
    DoStringLn(#1 + 'FMPT ' + Long2Str(Addr.Point));
    End;
  If ((FM^.Dest.Zone <> 0) and (FM^.MailType = mmtNetmail)) Then
    Begin
    If ((TxtCtr <> 190) And
    (GetByte(TxtCtr - 1) <> 13)) Then
      DoChar(#13);
    {non usare dokludgeln che filtra questo kludge!}
    DoStringLn(#1 + 'INTL ' + PointlessAddrStr(FM^.Dest) + ' ' +
      PointlessAddrStr(FM^.Orig));
    End;
  End;


Procedure FidoMsgObj.SetFrom(Name: String);
  Begin
  PutNullStr(Copy(Name, 1, 35),0);
  End;


Procedure FidoMsgObj.SetTo(Name: String);
  Begin
  PutNullStr(Copy(Name, 1, 35), 36);
  End;


Procedure FidoMsgObj.SetSubj(Str: String);
  Begin
  PutNullStr(Copy(Str, 1, 71), 72);
  End;


Procedure FidoMsgObj.SetCost(SCost: Word);
  Begin
  PutWord(SCost, 170);
  End;


Procedure FidoMsgObj.SetRefer(SRefer: LongInt);
  Begin
  PutWord(SRefer, 184);
  End;


Procedure FidoMsgObj.SetSeeAlso(SAlso: LongInt);
  Begin
  PutWord(SAlso, 188);
  End;


Procedure FidoMsgObj.SetDate(SDate: String);
  Var
    TempNum: Word;
    {$IFDEF VIRTUALPASCAL}
    Code: Longint;
    {$ELSE}
    Code: Word;
    {$ENDIF}
    TmpStr: String[20];
  Begin
  FM^.QDate := Copy(SDate,1,8);
  Val(Copy(SDate,1,2),TempNum, Code);
  TmpStr := Copy(SDate,4,2) + ' ' + MonthStr(TempNum) + ' ' +
    Copy(SDate,7,2) + '  ';
  For TempNum := 1 to 11 Do
    PutByte(Ord(TmpStr[TempNum]), TempNum + 143);
  End;


Procedure FidoMsgObj.SetTime(STime: String);
  Begin
  FM^.QTime := Copy(STime,1,5);
  PutNullStr(Copy(STime + ':00', 1, 8), 155);
  End;


Procedure FidoMsgObj.SetLocal(LS: Boolean);
  Begin
  If LS Then
    PutByte(GetByte(187) or 1, 187)
  Else
    PutByte(GetByte(187) and (Not 1), 187);
  End;


Procedure FidoMsgObj.SetRcvd(RS: Boolean);
  Begin
  If RS Then
    PutByte(GetByte(186) or 4, 186)
  Else
    PutByte(GetByte(186) and (not 4), 186);
  End;


Procedure FidoMsgObj.SetPriv(PS: Boolean);
  Begin
  If PS Then
    PutByte(GetByte(186) or 1, 186)
  Else
    PutByte(GetByte(186) and (not 1), 186);
  End;


Procedure FidoMsgObj.SetCrash(SS: Boolean);
  Begin
  If SS Then
    PutByte(GetByte(186) or 2, 186)
  Else
    PutByte(GetByte(186) and (not 2), 186);
  End;

Procedure FidoMsgObj.SetHold(SS: Boolean);
  Begin
  If SS Then
    PutByte(GetByte(187) or 2, 187)
  Else
    PutByte(GetByte(187) and (not 2), 187);
  End;


Procedure FidoMsgObj.SetKillSent(SS: Boolean);
  Begin
  If SS Then
    PutByte(GetByte(186) or 128, 186)
  Else
    PutByte(GetByte(186) and (Not 128), 186);
  End;


Procedure FidoMsgObj.SetEcho(SS: Boolean);
  Begin
  If not SS Then
    PutByte(GetByte(186) or 8, 186)
  Else
    PutByte(GetByte(186) and (Not 8), 186);
  End;


{Procedure FidoMsgObj.SetSent(SS: Boolean);
  Begin
  If SS Then
    PutByte(GetByte(186) or 8, 186)
  Else
    PutByte(GetByte(186) and (not 8), 186);
  End;
}

Procedure FidoMsgObj.SetFAttach(SS: Boolean);
  Begin
  If SS Then
    PutByte(GetByte(186) or 16, 186)
  Else
    PutByte(GetByte(186) and (not 16), 186);
  End;


Procedure FidoMsgObj.SetReqRct(SS: Boolean);
  Begin
  If SS Then
    PutByte(GetByte(187) or 16, 187)
  Else
    PutByte(GetByte(187) and (not 16), 187);
  End;


Procedure FidoMsgObj.SetReqAud(SS: Boolean);
  Begin
  If SS Then
    PutByte(GetByte(187) or 64, 187)
  Else
    PutByte(GetByte(187) and (not 64), 187);
  End;


Procedure FidoMsgObj.SetRetRct(SS: Boolean);
  Begin
  If SS Then
    PutByte(GetByte(187) or 32, 187)
  Else
    PutByte(GetByte(187) and (not 32), 187);
  End;


Procedure FidoMsgObj.SetFileReq(SS: Boolean);
  Begin
  If SS Then
    PutByte(GetByte(187) or 8, 187)
  Else
    PutByte(GetByte(187) and (not 8), 187);
  End;


Procedure FidoMsgObj.DoChar(Ch: Char);
  Begin
  PutByte(Ord(Ch), TxtCtr);
  Inc(TxtCtr);
  End;


Function  FidoMsgObj.WriteMsg: Word;
  {$IFDEF VIRTUALPASCAL}
  Procedure Rename(Var F; NewName: String);
  begin
     Newname := NewName + #0;
     InOutRes := DosMove(@FileRec(F).Name, @Newname[1]);
  end;
  {$ENDIF}
  Var
    NetNum, TmpDate: LongInt;
    TmpDT: DateTime;
    Count, Error: Word;
  Begin
  DoChar(#0);
  PutLong(GetDosDate, 180);
  TmpDT.Year := Str2Long(Copy(FM^.QDate,7,2));
  If TmpDT.Year > 79 Then
    Inc(TmpDT.Year, 1900)
  Else
    Inc(TmpDT.Year, 2000);
  TmpDT.Month := Str2Long(Copy(FM^.QDate,1,2));
  TmpDT.Day := Str2Long(Copy(FM^.QDate,4,2));
  TmpDt.Hour := Str2Long(Copy(FM^.QTime,1,2));
  TmpDt.Min := Str2Long(Copy(FM^.QTime, 4,2));
  TmpDt.Sec := 0;
  PackTime(TmpDT, TmpDate);
  PutLong(TmpDate, 176);
  NetNum := GetHighMsgNum;
  Assign(FM^.MsgFile, GetTempName(FM^.NetmailPath));
  if shMakeFile(FM^.MsgFile, GetTempName(FM^.NetmailPath), 1) then
  begin
     BlockWrite(FM^.MsgFile, FM^.MsgChar, FM^.MsgSize + 1);
     Close(FM^.MsgFile);
     Count := Tries;
     Error := 5;
     While (Count>0) and (Error=5) do
     begin
        inc(netNum);
        {$I-}
        Rename(FM^.MsgFile, FM^.NetMailPath + Long2Str(NetNum) + '.Msg');
        {$I+}
        Error := IOResult;
        if Error=5 then
           Sleep;
        dec(Count);
     end;
     if (Error=0) then
     begin
        WriteMsg := 0;
        FM^.CurrMsg := NetNum;
        FM^.HighMsgNum := NetNum;
     end else
     begin
        WriteMsg := 10;
        FM^.CurrMsg := 0;
     end;
  end else
  begin
     WriteMsg := MkFileError;
     FM^.CurrMsg := 0;
  end;
  End;


Function FidoMsgObj.GetChar: Char;
  Begin
    if TxtCtr <= FM^.MsgSize then
    begin
       GetChar := Chr(GetByte(TxtCtr));
       Inc(TxtCtr);
    end else
    begin
       GetChar := #0;
       EOM := True;
    end;
  End;


Function MonthNum(St: String):Word;
  Begin
  ST := Upper(St);
  MonthNum := 0;
  If St = 'JAN' Then MonthNum := 01;
  If St = 'FEB' Then MonthNum := 02;
  If St = 'MAR' Then MonthNum := 03;
  If St = 'APR' Then MonthNum := 04;
  If St = 'MAY' Then MonthNum := 05;
  If St = 'JUN' Then MonthNum := 06;
  If St = 'JUL' Then MonthNum := 07;
  If St = 'AUG' Then MonthNum := 08;
  If St = 'SEP' Then MonthNum := 09;
  If St = 'OCT' Then MonthNum := 10;
  If St = 'NOV' Then MonthNum := 11;
  If St = 'DEC' Then MonthNum := 12;
  End;


Function FidoMsgObj.CvtDate: Boolean;
  Var
    MoNo: Word;
    TmpStr: String;
    i: Word;
    MsgDt: String[25];
  Begin
  MsgDt := BufferNullString(144, 20);
  MsgDt := PadRight(MsgDt,' ', 20);
  CvtDate := True;
  If MsgDt[3] = ' ' Then
    Begin {Fido or Opus}
    If MsgDt[11] = ' ' Then
      Begin {Fido DD MON YY  HH:MM:SSZ}
      FM^.QTime := Copy (MsgDT,12,5);
      TmpStr := Long2Str(MonthNum(Copy(MsgDt,4,3)));
      If Length(TmpStr) = 1 Then
        TmpStr := '0' + TmpStr;
      FM^.QDate := TmpStr + '-' + Copy(MsgDT,1,2) + '-' + Copy (MsgDt,8,2);
      End
    Else
      Begin {Opus DD MON YY HH:MM:SS}
      FM^.QTime := Copy(MsgDT,11,5);
      TmpStr := Long2Str(MonthNum(Copy(MsgDt,4,3)));
      If Length(TmpStr) = 1 Then
        TmpStr := '0' + TmpStr;
      FM^.QDate := TmpStr + '-' + Copy(MsgDT,1,2) + '-' + Copy (MsgDt,8,2);
      End;
    End
  Else
    Begin
    If MsgDT[4] = ' ' Then
      Begin {SeaDog format DOW DD MON YY HH:MM}
      FM^.QTime := Copy(MsgDT,15,5);
      TmpStr := Long2Str(MonthNum(Copy(MsgDT,8,3)));
      If Length(TmpStr) = 1 Then
        TmpStr := '0' + TmpStr;
      FM^.QDate := TmpStr + '-' + Copy(MsgDT,5,2) + '-' + Copy (MsgDt,12,2);
      End
    Else
      Begin
      If MsgDT[3] = '-' Then
        Begin {Wierd format DD-MM-YYYY HH:MM:SS}
        FM^.QTime := Copy(MsgDt,12,5);
        FM^.QDate := Copy(MsgDt,4,3) + Copy (MsgDt,1,3) + Copy (MsgDt,9,2);
        End
      Else
        Begin  {Bad Date}
        CvtDate := False;
        End;
      End;
    End;
  For i := 1 to 5 Do
    If FM^.QTime[i] = ' ' Then
      FM^.QTime[i] := '0';
  For i := 1 to 8 Do
    If FM^.QDate[i] = ' ' Then
      FM^.QDate[i] := '0';
  If Length(FM^.QDate) <> 8 Then
    CvtDate := False;
  If Length(FM^.QTime) <> 5 Then
    CvtDate := False;
  End;


Function FidoMsgObj.BufferWord(i: Word):Word;
  Begin
  BufferWord := BufferByte(i) + (BufferByte(i + 1) shl 8);
  End;


Function FidoMsgObj.BufferByte(i: Word):Byte;
  Begin
  BufferByte := GetByte(i);
  End;


Function FidoMsgObj.BufferNullString(i: Word; Max: Word): String;
  Var
    Ctr: Word;
    CurrPos: Word;

  Begin
  BufferNullString := '';
  Ctr := i;
  CurrPos := 0;
  While ((CurrPos < Max) and (GetByte(Ctr) <> 0)) Do
    Begin
    Inc(CurrPos);
    BufferNullString[CurrPos] := Chr(GetByte(Ctr));
    Inc(Ctr);
    End;
  BufferNullString[0] := Chr(CurrPos);
  End;


Procedure FidoMsgObj.MsgStartUp;
  Var
    TStr: String;
    TmpChr: Char;
    NumRead: Word;
    LastKludge: Boolean;
    I: Integer;
    {$IFDEF VIRTUALPASCAL}
    Code: Longint;
    {$ELSE}
    Code: Word;
    {$ENDIF}
    TempStr: String;
    oldfm: Word;
    {$IFDEF VIRTUALPASCAL}
    Attr: Longint;
    {$ELSE}
    Attr: Word;
    {$ENDIF}
  Begin
  If FM^.MsgOpen Then
  begin
    Close(FM^.MsgFile);
    FM^.MsgOpen := False;
  end;
  oldfm := FileMode;
  FileMode := fmReadWrite_DA;
  if shOpenFile(FM^.MsgFile, FM^.NetMailPath + Long2Str(FM^.CurrMsg) + '.Msg', 1) then
  begin
     FM^.Error := 0;
     {legge subito tutto in memoria}
     BlockRead(FM^.MsgFile, FM^.MsgChar, 190 + FidoMsgTextSize, FM^.MsgSize);
     {l'array MsgChar e' a base 0}
     dec(FM^.MsgSize);
  end else
     FM^.Error := 10;
  filemode := oldfm;
  If FM^.Error = 0 Then
    FM^.MsgOpen := True;
  FM^.MsgSize := FileSize(FM^.MsgFile);
  FM^.MsgStart := 190;
  FM^.Dest.Zone := FM^.DefaultZone;
  FM^.Dest.Point := 0;
  FM^.Orig.Zone := FM^.DefaultZone;
  FM^.Orig.Point := 0;
  FM^.Orig.Net := BufferWord(172);
  FM^.Orig.Node := BufferWord(168);
  FM^.Dest.Net := BufferWord(174);
  FM^.Dest.Node := BufferWord(166);
  MsgTxtStartUp;
  If FM^.Error = 0 Then
    Begin
       If Not CvtDate Then
         Begin
         FM^.QDate := '09-06-89';
         FM^.QTime := '19:76';
         End;
       if FM^.MailType=mmtNetmail then
       begin
          LastKludge := False;
          while not LastKludge and not EOM do
          begin
             TStr := GetString(128);
             if (TStr='') or (Tstr[1]<>#$01) then
                LastKludge := True
             else
             begin
                {esamina il kludge, se contiene info sugli address}
                I := pos(' ',Tstr);
                if I>0 then
                begin
                   TempStr := Upper(Copy(Tstr,2,I-2));
                   If (TempStr = 'INTL') Then
                   Begin
                      while (Tstr[I]=' ') do
                         inc(I);
                      {comincia l'address di destinazione, la zona fino a ":"}
                      TempStr := Tstr[I];
                      inc(I);
                      while (Tstr[I]<>':') do
                      begin
                          TempStr := TempStr + Tstr[I];
                          inc(I)
                      end;
                      Val(TempStr, FM^.Dest.Zone, Code);
                      While (Tstr[I]<>' ') do
                         inc(I);
                      While (Tstr[I]=' ') do
                         inc(I);
                      TempStr := Tstr[I];
                      inc(I);
                      while (Tstr[I]<>':') do
                      begin
                          TempStr := TempStr + Tstr[I];
                          inc(I)
                      end;
                      Val(TempStr, FM^.Orig.Zone, Code);
                   end else
                   if TempStr='TOPT' then
                   begin
                      while (Tstr[I]=' ') do
                         inc(I);
                      TempStr := Tstr[I];
                      inc(I);
                      while (I<=length(Tstr)) and (Tstr[I]<>' ') do
                      begin
                          TempStr := TempStr + Tstr[I];
                          inc(I)
                      end;
                      Val(TempStr, FM^.Dest.Point, Code);
                   end else
                   if TempStr='FMPT' then
                   begin
                      while (Tstr[I]=' ') do
                         inc(I);
                      TempStr := Tstr[I];
                      inc(I);
                      while (I<=length(Tstr)) and (Tstr[I]<>' ') do
                      begin
                          TempStr := TempStr + Tstr[I];
                          inc(I)
                      end;
                      Val(TempStr, FM^.Orig.Point, Code);
                   end
                end;
             end;
          end;
       end;
    End;
  End;


Procedure FidoMsgObj.MsgTxtStartUp;
  Begin
  FM^.MsgStart := 190;
  TxtCtr := FM^.MsgStart;
  EOM := False;
  WasWrap := False;
  End;


Function FidoMsgObj.GetFrom: String; {Get from name on current msg}
  Begin
  GetFrom := BufferNullString(0, 35);
  End;


Function FidoMsgObj.GetTo: String; {Get to name on current msg}
  Begin
  GetTo := BufferNullString(36,35);
  End;


Function FidoMsgObj.GetSubj: String; {Get subject on current msg}
  Begin
  GetSubj := BufferNullString(72,71);
  End;


Function FidoMsgObj.GetCost: Word; {Get cost of current msg}
  Begin
  GetCost := BufferWord(170);
  End;


Function FidoMsgObj.GetDate: String; {Get date of current msg}
  Begin
  GetDate := FM^.QDate;
  End;


Function FidoMsgObj.GetTime: String; {Get time of current msg}
  Begin
  GetTime := FM^.QTime;
  End;


Function FidoMsgObj.GetRefer: LongInt; {Get reply to of current msg}
  Begin
  GetRefer := BufferWord(184);
  End;


Function FidoMsgObj.GetSeeAlso: LongInt; {Get see also of current msg}
  Begin
  GetSeeAlso := BufferWord(188);
  End;


Function FidoMsgObj.GetMsgNum: LongInt; {Get message number}
  Begin
  GetMsgNum := FM^.CurrMsg;
  End;


Procedure FidoMsgObj.GetOrig(Var Addr: AddrType); {Get origin address}
  Begin
  Addr := FM^.Orig;
  End;


Procedure FidoMsgObj.GetDest(Var Addr: AddrType); {Get destination address}
  Begin
  Addr := FM^.Dest;
  End;


Function FidoMsgObj.IsLocal: Boolean; {Is current msg local}
  Begin
  IsLocal := ((GetByte(187) and 001) <> 0);
  End;


Function FidoMsgObj.IsCrash: Boolean; {Is current msg crash}
  Begin
  IsCrash := ((GetByte(186) and 002) <> 0);
  End;


Function FidoMsgObj.IsKillSent: Boolean; {Is current msg kill sent}
  Begin
  IsKillSent := ((GetByte(186) and 128) <> 0);
  End;


{Function FidoMsgObj.IsSent: Boolean;
  Begin
  IsSent := ((GetByte(186) and 008) <> 0);
  End;
}

Function FidoMsgObj.IsFAttach: Boolean; {Is current msg file attach}
  Begin
  IsFAttach := ((GetByte(186) and 016) <> 0);
  End;


Function FidoMsgObj.IsReqRct: Boolean; {Is current msg request receipt}
  Begin
  IsReqRct := ((GetByte(187) and 016) <> 0);
  End;


Function FidoMsgObj.IsReqAud: Boolean; {Is current msg request audit}
  Begin
  IsReqAud := ((GetByte(187) and 064) <> 0);
  End;


Function FidoMsgObj.IsRetRct: Boolean; {Is current msg a return receipt}
  Begin
  IsRetRct := ((GetByte(187) and 032) <> 0);
  End;


Function FidoMsgObj.IsFileReq: Boolean; {Is current msg a file request}
  Begin
  IsFileReq := ((GetByte(187) and 008) <> 0);
  End;


Function FidoMsgObj.IsRcvd: Boolean; {Is current msg received}
  Begin
  IsRcvd := ((GetByte(186) and 004) <> 0);
  End;


Function FidoMsgObj.IsPriv: Boolean; {Is current msg priviledged/private}
  Begin
  IsPriv := ((GetByte(186) and 001) <> 0);
  End;


Function FidoMsgObj.IsDeleted: Boolean; {Is current msg deleted}
  Begin
  IsDeleted := Not MsgExists(FM^.CurrMsg);
  End;


Function FidoMsgObj.IsEchoed: Boolean; {Is current msg echoed}
  Begin
  IsEchoed := ((GetByte(186) and 008) = 0);
  End;


Procedure FidoMsgObj.SeekFirst(MsgNum: LongInt); {Start msg seek}
  Begin
  FM^.CurrMsg := MsgNum - 1;
  SeekNext;
  End;


Procedure FidoMsgObj.SeekNext; {Find next matching msg}
  Begin
  Inc(FM^.CurrMsg);
  While (FM^.CurrMsg <= FM^.HighMsgNum) and Not MsgExists(FM^.CurrMsg) Do
    Inc(FM^.CurrMsg);
  If FM^.CurrMsg > FM^.HighMsgNum Then
  begin
    if MsgExists(FM^.CurrMsg) then
    begin
       inc(FM^.HighMsgNum)
    end else
       FM^.CurrMsg := 0;
  end;
  End;


Procedure FidoMsgObj.SeekPrior;
  Begin
  Dec(FM^.CurrMsg);
  While ((Not MsgExists(FM^.CurrMsg)) and (FM^.CurrMsg > 0)) Do
    Dec(FM^.CurrMsg);
  End;


Function FidoMsgObj.SeekFound: Boolean;
  Begin
  SeekFound := FM^.CurrMsg <> 0;
  End;


Function FidoMsgObj.GetMsgLoc: LongInt; {Msg location}
  Begin
  GetMsgLoc := GetMsgNum;
  End;


Procedure FidoMsgObj.SetMsgLoc(ML: LongInt); {Msg location}
  Begin
  FM^.CurrMsg := ML;
  End;


Procedure FidoMsgObj.YoursFirst(Name: String; Handle: String);
  Begin
  FM^.Name := Upper(Name);
  FM^.Handle := Upper(Handle);
  FM^.CurrMsg := 0;
  YoursNext;
  End;


Procedure FidoMsgObj.YoursNext;
  Var
    FoundDone: Boolean;
  Begin
  FoundDone := False;
  SeekFirst(FM^.CurrMsg + 1);
  While ((FM^.CurrMsg <> 0) And (Not FoundDone)) Do
    Begin
    MsgStartUp;
    If ((Upper(GetTo) = FM^.Name) Or (Upper(GetTo) = FM^.Handle)) Then
      FoundDone := True;
    If IsRcvd Then FoundDone := False;
    If Not FoundDone Then
      SeekNext;
    If Not SeekFound Then
      FoundDone := True;
    End;
  End;


Function FidoMsgObj.YoursFound: Boolean;
  Begin
  YoursFound := SeekFound;
  End;


Procedure FidoMsgObj.StartNewMsg;
  Begin
  FM^.Error := 0;
  TxtCtr := 190;
  FM^.Dest.Zone := 0;
  FM^.Orig.Zone := 0;
  FM^.Dest.Point := 0;
  FM^.Orig.Point := 0;
  If FM^.MsgOpen Then
    Begin
      Close(FM^.MsgFile);
      FM^.MsgOpen := False;
    End;
  FillChar(FM^.MsgChar, 190, #0);
  End;


Function FidoMsgObj.OpenMsgBase: Word;
  Begin
  Rescan;
  If MsgBaseExists Then
    OpenMsgBase := 0
  Else
    OpenMsgBase := 500;
  End;


Function FidoMsgObj.CloseMsgBase: Word;
  Begin
  CloseMsgBase := 0;
  End;


Function FidoMsgObj.CreateMsgBase(MaxMsg: Word; MaxDays: Word): Word;
  Begin
  If MakePath(FM^.NetMailPath) Then
    CreateMsgBase := 0
  Else
    CreateMsgBase := 1;
  End;


Procedure FidoMsgObj.SetMailType(MT: MsgMailType);
  Begin
  FM^.MailType := Mt;
  End;


Function FidoMsgObj.GetSubArea: Word;
  Begin
  GetSubArea := 0;
  End;


Procedure FidoMsgObj.ReWriteHdr;
  Begin
     Seek(FM^.MsgFile, 0);
     {$I-}
     BlockWrite(FM^.MsgFile, FM^.MsgChar, 190);
     {$I+}
     if ioresult<>0 then;
  End;


Procedure FidoMsgObj.DeleteMsg;
  Begin
  If FM^.MsgOpen Then
  begin
    Close(FM^.MsgFile);
    FM^.MsgOpen := False;
  end;
  if EraseFile(FM^.NetMailPath + Long2Str(FM^.CurrMsg) + '.MSG') then;
  if FM^.CurrMsg=FM^.HighMsgNum then
  begin
     {aggiorna il valore di HighMsgNum}
     dec(FM^.HighMsgNum);
     While (FM^.HighMsgNum>0) and not MsgExists(FM^.HighMsgNum) do
        dec(FM^.HighMsgNum);
  end;
  End;


Function FidoMsgObj.NumberOfMsgs: LongInt;
  Var
    Cnt, Active: LongInt;
  Begin
  Active := 0;
  For Cnt := 1 To FM^.HighMsgNum Do
    Begin
      if MsgExists(Cnt) then
         inc(Active);
    End;
  NumberOfMsgs := Active;
  End;


Function FidoMsgObj.GetLastRead(UNum: LongInt): LongInt;
  Var
    LRec: Word;
  Begin
  If ((UNum + 1) * SizeOf(LRec)) >
  SizeFile(FM^.NetMailPath + 'LastRead') Then
    GetLastRead := 0
  Else
    Begin
    If LoadFilePos(FM^.NetMailPath + 'LastRead', LRec, SizeOf(LRec),
    UNum * SizeOf(LRec)) = 0 Then
      GetLastRead := LRec
    Else
      GetLastRead := 0;
    End;
  End;


Procedure FidoMsgObj.SetLastRead(UNum: LongInt; LR: LongInt);
  Var
    LRec: Word;
    Status: Word;
  Begin
  If ((UNum + 1) * SizeOf(LRec)) >
  SizeFile(FM^.NetMailPath + 'LastRead') Then
    Begin
    Status := ExtendFile(FM^.NetMailPath + 'LastRead',
    (UNum + 1) * SizeOf(LRec));
    End;
  If LoadFilePos(FM^.NetMailPath + 'LastRead', LRec, SizeOf(LRec),
  UNum * SizeOf(LRec)) = 0 Then
    Begin
    LRec := LR;
    Status := SaveFilePos(FM^.NetMailPath + 'LastRead', LRec, SizeOf(LRec),
    UNum * SizeOf(LRec));
    End;
  End;


Function FidoMsgObj.MsgBaseExists: Boolean;
  Var D:DirStr;
  Begin
     GetDir(0,D);
     {$I-}
     ChDir(Copy(FM^.NetMailPath,1,length(FM^.NetMailPath)-1));
     {$I+}
     MsgBaseExists := IOResult=0;
     ChDir(D);
  End;


Procedure FidoMsgObj.Rescan;
  Var
    TmpName: String[13];
    TmpNum: Word;
    {$IFDEF VIRTUALPASCAL}
    Code: Longint;
    {$ELSE}
    Code: Word;
    {$ENDIF}
    SR: SearchRec;
  Begin
  FM^.HighMsgNum := 0;
  FindFirst(FM^.NetMailPath + '*.MSG', ReadOnly + Archive, SR);
  While DosError = 0 Do
    Begin
    TmpName := SR.Name;
    Val(Copy(TmpName, 1,  Pos('.', TmpName) - 1), TmpNum, Code);
    If ((Code = 0) And (TmpNum > 0)) Then
      Begin
         if TmpNum > FM^.HighMsgNum then
            FM^.HighMsgNum := TmpNum
      End;
    FindNext(SR);
    End;
  End;


Function FidoMsgObj.MsgExists(MsgNum: LongInt): Boolean;
  Var
    Code: LongInt;
  Begin
  If (MsgNum > 0) Then
    Begin
       MsgExists := FileExist(FM^.NetMailPath + Long2Str(MsgNum) + '.Msg');
    End
  Else
    MsgExists := False;
  End;


End.
