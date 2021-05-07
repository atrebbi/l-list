Unit MKMsgHud;        {Hudson/QuickBbs-style Message Base}

{$I MKB.Def}



{
     MKMsgHud - Copyright 1993 by Mark May - MK Software
     You are free to use this code in your programs, however
     it may not be included in Source/TPU function libraries
     without my permission.

     Mythical Kingom Tech BBS (513)237-7737 HST/v32
     FidoNet: 1:110/290
     Rime: ->MYTHKING
     You may also reach me at maym@dmapub.dma.org
}


{$X+}


Interface


Uses MKMsgAbs, MKGlobT;

{$I Struct.Hud}


Const TxtSize = 64;
Const SeekSize = 250;
Const YourSize = 100;

Const HudsonFlushing: Boolean = True;
Const HudsonLast: String = '';
Const HudsonEcho: String = '';

Type TxtRecsType = Array[1..TxtSize] of MsgTxtType;
Type SeekArrayType = Array[1..SeekSize] of MsgIdxType;

Type YourSearchType = Record
  {$IFDEF VIRTUALPASCAL}
  NumRead: Longint;
  {$ELSE}
  NumRead: Word;
  {$ENDIF}
  SeekStart: Integer;
  CurrPos: Integer;
  MsgFound: Boolean;
  Name: String[35];
  Handle: String[35];
  SearchArray: Array[1..YourSize] of String[35];
  End;


Type HudsonMsgType = Record
  MsgPath: String[50];                 {Message base directory}
  MsgInfoFile: File;
  MsgTxtFile: File;
  MsgHdrFile: File;
  MsgToIdxFile: File;
  MsgIdxFile: File;
  Opened: Boolean;
  Locked: Boolean;
  Error: Word; {0=no error}
  MsgHdr: MsgHdrType;                  {Current message header}
  MsgInfo: MsgInfoType;                {MsgInfo record}
  MsgPos: Word;                        {MsgHdr seek position of current rec}
  {$IFDEF VIRTUALPASCAL}
  SeekNumRead: Longint;
  {$ELSE}
  SeekNumRead: Word;                   {Number of records in the array}
  {$ENDIF}
  SeekPos: Integer;                    {Current position in array}
  SeekStart: Word;                     {File Pos of 1st record in Idx Array}
  SeekOver: Boolean;                   {More idx records?}
  CurrMsgNum: Word;                    {Current Seek Msg number}
  OrigPoint: Word;                     {Point Addr orig}
  DestPoint: Word;                     {Point Addr destination}
  Echo: Boolean;                       {Should message be exported}
  Area: Word;
  MT: MsgMailType;
  End;


Type HudsonMsgObj = Object(AbsMsgObj)  {Message Export Object}
  MsgRec: ^HudsonMsgType;
  MsgChars: ^TxtRecsType;
  SeekArray: ^SeekArrayType;
  YourInfo: ^YourSearchType;
  Constructor Init; {Initialize}
  Destructor Done; Virtual; {Done}
  Procedure MsgStartUp; Virtual; {Setup message/read header}
  Procedure MsgTxtStartUp; Virtual; {Setup message text}
  Function  GetChar: Char; Virtual; {Get msg text character}
  Procedure SeekFirst(MsgNum: LongInt); Virtual; {Seek msg number}
  Procedure SeekNext; Virtual; {Find next matching msg}
  Procedure SeekPrior; Virtual; {Find prior matching msg}
  Procedure SeekRead(NumToRead: Word); {Refill seek array}
  Function  GetFrom: String; Virtual; {Get from name on current msg}
  Function  GetTo: String;Virtual; {Get to name on current msg}
  Function  GetSubj: String; Virtual; {Get subject on current msg}
  Function  GetCost: Word; Virtual; {Get cost of current msg}
  Function  GetDate: String; Virtual; {Get date of current msg}
  Function  GetTime: String; Virtual; {Get time of current msg}
  Function  GetRefer: LongInt; Virtual; {Get reply to of current msg}
  Function  GetSeeAlso: LongInt; Virtual; {Get see also of current msg}
  Function  GetMsgNum: LongInt; Virtual; {Get message number}
  {Function  GetMsgDisplayNum: LongInt; Virtual;}
  Procedure GetOrig(Var Addr: AddrType); Virtual; {Get origin address}
  Procedure GetDest(Var Addr: AddrType); Virtual; {Get destination address}
  Function  IsLocal: Boolean; Virtual; {Is current msg local}
  Function  IsCrash: Boolean; Virtual; {Is current msg crash}
  Function  IsKillSent: Boolean; Virtual; {Is current msg kill sent}
  {Function  IsSent: Boolean; Virtual;} {Is current msg sent}
  Function  IsFAttach: Boolean; Virtual; {Is current msg file attach}
  Function  IsReqRct: Boolean; Virtual; {Is current msg request receipt}
  Function  IsReqAud: Boolean; Virtual; {Is current msg request audit}
  Function  IsRetRct: Boolean; Virtual; {Is current msg a return receipt}
  Function  IsFileReq: Boolean; Virtual; {Is current msg a file request}
  Function  IsRcvd: Boolean; Virtual; {Is current msg received}
  Function  IsPriv: Boolean; Virtual; {Is current msg priviledged/private}
  Function  IsDeleted: Boolean; Virtual; {Is current msg deleted}
  Function  IsEchoed: Boolean; Virtual; {Is current msg unmoved echomail msg}
  Procedure YoursFirst(Name: String; Handle: String); Virtual; {Search for mail to caller}
  Procedure YoursNext; Virtual; {Search for next message}
  Function  YoursFound: Boolean; Virtual; {Found a message}
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
  Procedure SetEcho(ES: Boolean); Virtual; {Set echo status}
  Procedure SetMsgAttr(Setting: Boolean; Mask: Word);
  Procedure SetNetAttr(Setting: Boolean; Mask: Word);
  Procedure SetLocal(LS: Boolean); Virtual; {Set local status}
  Procedure SetRcvd(RS: Boolean); Virtual; {Set received status}
  Procedure SetPriv(PS: Boolean); Virtual; {Set priveledge vs public status}
  Procedure SetCrash(SS: Boolean); Virtual; {Set crash netmail status}
  Procedure SetKillSent(SS: Boolean); Virtual; {Set kill/sent netmail status}
  {Procedure SetSent(SS: Boolean); Virtual;} {Set sent netmail status}
  Procedure SetFAttach(SS: Boolean); Virtual; {Set file attach status}
  Procedure SetReqRct(SS: Boolean); Virtual; {Set request receipt status}
  Procedure SetReqAud(SS: Boolean); Virtual; {Set request audit status}
  Procedure SetRetRct(SS: Boolean); Virtual; {Set return receipt status}
  Procedure SetFileReq(SS: Boolean); Virtual; {Set file request status}
  Procedure DoChar(Ch: Char); Virtual; {Add character to message text}
  Function  WriteMsg: Word; Virtual; {Write msg to message base}
  Function  OpenMsgBase: Word; Virtual; {Individual msg open}
  Function  CloseMsgBase: Word; Virtual; {Individual msg close}
  Function  SeekEnd: Word; Virtual; {Seek to eof for msg base files}
  Function  SeekMsgBasePos(Position: Word): Word; Virtual; {Seek to pos of Msg Base File}
  Function  Check: Word; Virtual; {Check if msg base is ok}
  Function  CreateMsgBase(MaxMsg: Word; MaxDays: Word): Word; Virtual;{Create initial msg base files}
  Function  LockMsgBase: Boolean; Virtual; {Lock msg base for updating}
  Function  UnlockMsgBase: Boolean; Virtual; {Unlock msg base after updating}
  Function  WriteMailIdx(FN: String; MsgPos: Word): Word; Virtual;
    {Write Netmail or EchoMail.Bbs}
  Function  MsgBaseSize: Word; Virtual; {Number of msg base index records}
  Function  GetNumActive: Word; Virtual; {Get number of active messages}
  Function  GetHighMsgNum: LongInt; Virtual; {Get highest msg number}
  Function  GetLowMsgNum: LongInt; Virtual; {Get lowest msg number}
  Procedure StartNewMsg; Virtual; {Initialize message}
  Procedure SetMsgPath(MP: String); Virtual;
  Function  SeekFound:Boolean; Virtual; {Seek msg found}
  Procedure SetMailType(MT: MsgMailType); Virtual; {Set message base type}
  Function  GetSubArea: Word; Virtual; {Get sub area number}
  Procedure ReWriteHdr; Virtual; {Rewrite msg header after changes}
  Procedure DeleteMsg; Virtual; {Delete current message}
  Function  GetMsgLoc: LongInt; Virtual; {To allow reseeking to message}
  Procedure SetMsgLoc(ML: LongInt); Virtual; {Reseek to message}
  Function  NumberOfMsgs: LongInt; Virtual; {Number of messages}
  Function  GetLastRead(UNum: LongInt): LongInt; Virtual; {Get last read for user num}
  Procedure SetLastRead(UNum: LongInt; LR: LongInt); Virtual; {Set last read}
  Procedure GetAllLastRead(UNum: LongInt; Var LR: LastReadType); Virtual; {all areas}
  Procedure GetHighest(Var LR: LastReadType); Virtual; {Get highest all areas}
  Function  MsgBaseExists: Boolean; Virtual;
  End;


Type HudsonMsgPtr = ^HudsonMsgObj;

Implementation

Uses
  MKFile, MKString;


Constructor HudsonMsgObj.Init;
  Begin
  New(MsgRec);
  New(MsgChars);
  New(SeekArray);
  New(YourInfo);
  If ((MsgRec = Nil) Or (MsgChars = Nil) or (SeekArray = Nil) or (YourInfo = Nil)) Then
    Begin
    If MsgRec <> Nil Then
      Dispose(MsgRec);
    If MsgChars <> Nil Then
      Dispose(MsgChars);
    If SeekArray <> Nil Then
      Dispose(SeekArray);
    If YourInfo <> Nil Then
      Dispose(YourInfo);
    Fail;
    Exit;
    End;
  MsgRec^.MsgPath := '';
  MsgRec^.Opened := False;
  MsgRec^.Locked := False;
  MsgRec^.Error := 0;
  End;


Procedure HudsonMsgObj.YoursFirst(Name: String; Handle: String);
  Begin
  YourInfo^.NumRead := 0;
  YourInfo^.SeekStart := 0;
  YourInfo^.CurrPos := 1;
  YourInfo^.MsgFound := False;
  YourInfo^.Name := Copy(StripBoth(Upper(Name), ' '),1, 35);
  YourInfo^.Handle := Copy(StripBoth(Upper(Handle), ' '),1,35);
  YoursNext;
  End;


Procedure HudsonMsgObj.YoursNext;
  Var
    SearchOver: Boolean;
  Begin
  Inc(YourInfo^.CurrPos);
  SearchOver := False;
  YourInfo^.MsgFound := False;
  While Not SearchOver Do
    Begin
    If YourInfo^.CurrPos > YourInfo^.NumRead Then
      Begin
      Inc(YourInfo^.SeekStart, YourInfo^.NumRead);
      YourInfo^.CurrPos := 1;
      Seek(MsgRec^.MsgToIdxFile, YourInfo^.SeekStart);
      BlockRead(MsgRec^.MsgToIdxFile, YourInfo^.SearchArray,
         YourSize, YourInfo^.NumRead);
      End;
    If YourInfo^.NumRead = 0 Then
      SearchOver := True
    Else
      Begin
      If (((Upper(YourInfo^.SearchArray[YourInfo^.CurrPos]) = YourInfo^.Name) Or
      (Upper(YourInfo^.SearchArray[YourInfo^.CurrPos]) = YourInfo^.Handle)) And
      ((YourInfo^.CurrPos > 0) And (YourInfo^.CurrPos <= YourInfo^.NumRead)))Then
        Begin
        MsgRec^.MsgPos := YourInfo^.SeekStart + YourInfo^.CurrPos - 1;
        MsgStartUp;
        If Not (IsRcvd)  Then
          Begin
          YourInfo^.MsgFound := True;
          SearchOver := True;
          End;
        End;
      End;
    If Not YourInfo^.MsgFound Then
      Inc(YourInfo^.CurrPos);
    End;
  End;


Function  HudsonMsgObj.YoursFound: Boolean;
  Begin
  YoursFound := YourInfo^.MsgFound;
  End;


Destructor HudsonMsgObj.Done;
  Begin
  Dispose(MsgRec);
  Dispose(MsgChars);
  Dispose(SeekArray);
  Dispose(YourInfo);
  End;


Procedure HudsonMsgObj.MsgStartUp;
  Begin
  MsgRec^.Error := SeekMsgBasePos(MsgRec^.MsgPos);
  MsgRec^.OrigPoint := 0;
  MsgRec^.DestPoint := 0;
  If MsgRec^.Error = 0 Then
    Begin
      BlockRead(MsgRec^.MsgHdrFile, MsgRec^.MsgHdr, SizeOf(MsgHdrType));
    End;
  {inizializza ECHO}
  {case MsgRec^.MT of
     mmtEchoMail: MsgRec^.Echo := (MsgRec^.MsgHdr.MsgAttr and maUnmovedEcho <> 0);
     mmtNetMail:MsgRec^.Echo := (MsgRec^.MsgHdr.MsgAttr and maUnmovedNet <> 0);
     mmtNormal: MsgRec^.Echo := False
  end;}
  {in realta' leggono il Sent della NetMail...}
  MsgRec^.Echo := (MsgRec^.MsgHdr.NetAttr and naSent = 0);
  End;


Procedure HudsonMsgObj.SetMsgAttr(Setting: Boolean; Mask: Word);
  Begin
  If Setting Then
    MsgRec^.MsgHdr.MsgAttr := MsgRec^.MsgHdr.MsgAttr or Mask
  Else
    MsgRec^.MsgHdr.MsgAttr := MsgRec^.MsgHdr.MsgAttr and (Not Mask);
  End;


Procedure HudsonMsgObj.SetRcvd(RS: Boolean);
  Begin
  SetMsgAttr(RS, maRcvd);
  End;


Procedure HudsonMsgObj.SetPriv(PS: Boolean);
  Begin
  SetMsgAttr(PS, maPriv);
  End;


Procedure HudsonMsgObj.SetNetAttr(Setting: Boolean; Mask: Word);
  Begin
  If Setting Then
    MsgRec^.MsgHdr.NetAttr := MsgRec^.MsgHdr.NetAttr Or Mask
  Else
    MsgRec^.MsgHdr.NetAttr := MsgRec^.MsgHdr.NetAttr And (Not Mask);
  End;


Procedure HudsonMsgObj.SetSeeAlso(SAlso: LongInt);
  Begin
  MsgRec^.MsgHdr.SeeAlso := SAlso;
  End;


Procedure HudsonMsgObj.SetFrom(Name: String); {Set msg from}
  Begin
  MsgRec^.MsgHdr.MsgFrom := Name;
  End;


Procedure HudsonMsgObj.SetTo(Name: String); {Set msg to}
  Begin
  MsgRec^.MsgHdr.MsgTo := Name;
  End;


Procedure HudsonMsgObj.SetSubj(Str: String); {Set msg subject}
  Begin
  MsgRec^.MsgHdr.Subj := Str;
  End;


Function HudsonMsgObj.GetFrom: String;
  Begin
  GetFrom := MsgRec^.MsgHdr.MsgFrom;
  End;


Function HudsonMsgObj.GetTo: String;
  Begin
  GetTo := MsgRec^.MsgHdr.MsgTo;
  End;


Function HudsonMsgObj.GetSubj: String;
  Begin
  GetSubj := MsgRec^.MsgHdr.Subj;
  End;


Function HudsonMsgObj.GetCost: Word;
  Begin
  GetCost := MsgRec^.MsgHdr.Cost;
  End;


Function HudsonMsgObj.GetDate: String;            {Get date of current msg}
  Begin
  GetDate := MsgRec^.MsgHdr.Date;
  End;


Function HudsonMsgObj.GetTime: String;            {Get time of current msg}
  Begin
  GetTime := MsgRec^.MsgHdr.Time;
  End;


Function HudsonMsgObj.GetRefer: LongInt;
  Begin
  GetRefer := MsgRec^.MsgHdr.ReplyTo;
  End;


Function HudsonMsgObj.GetSeeAlso: LongInt;
  Begin
  GetSeeAlso := MsgRec^.MsgHdr.SeeAlso;
  End;


Function HudsonMsgObj.GetMsgNum: LongInt;
  Begin
  GetMsgNum := MsgRec^.MsgHdr.MsgNum;
  End;


Procedure HudsonMsgObj.GetOrig(Var Addr: AddrType);
  Begin
  Addr.Zone := MsgRec^.MsgHdr.OrigZone;
  Addr.Net := MsgRec^.MsgHdr.OrigNet;
  Addr.Node := MsgRec^.MsgHdr.OrigNode;
  Addr.Point := MsgRec^.OrigPoint;
  End;


Procedure HudsonMsgObj.GetDest(Var Addr: AddrType);
  Begin
  Addr.Zone := MsgRec^.MsgHdr.DestZone;
  Addr.Net := MsgRec^.MsgHdr.DestNet;
  Addr.Node := MsgRec^.MsgHdr.DestNode;
  Addr.Point := MsgRec^.DestPoint;
  End;


Function HudsonMsgObj.IsLocal: Boolean;
  Begin
  IsLocal := ((MsgRec^.MsgHdr.MsgAttr and maLocal) <> 0);
  End;


Function HudsonMsgObj.IsCrash: Boolean;
  Begin
  IsCrash := ((MsgRec^.MsgHdr.NetAttr and naCrash) <> 0);
  End;


Function HudsonMsgObj.IsKillSent: Boolean;
  Begin
  IsKillSent := ((MsgRec^.MsgHdr.NetAttr and naKillSent) <> 0);
  End;


Function HudsonMsgObj.IsFAttach: Boolean;
  Begin
  IsFAttach := ((MsgRec^.MsgHdr.NetAttr and naFAttach) <> 0);
  End;


Function HudsonMsgObj.IsReqRct: Boolean;
  Begin
  IsReqRct := ((MsgRec^.MsgHdr.NetAttr and naReqRcpt) <> 0);
  End;


Function HudsonMsgObj.IsReqAud: Boolean;
  Begin
  IsReqAud := ((MsgRec^.MsgHdr.NetAttr and naReqAudit) <> 0);
  End;


Function HudsonMsgObj.IsRetRct: Boolean;
  Begin
  IsRetRct := ((MsgRec^.MsgHdr.NetAttr and naRetRcpt) <> 0);
  End;


Function HudsonMsgObj.IsFileReq: Boolean;
  Begin
  IsFileReq := ((MsgRec^.MsgHdr.NetAttr and naFileReq) <> 0);
  End;


Function HudsonMsgObj.IsRcvd: Boolean;
  Begin
  IsRcvd := ((MsgRec^.MsgHdr.MsgAttr and maRcvd) <> 0);
  End;


Function HudsonMsgObj.IsPriv: Boolean;
  Begin
  IsPriv := ((MsgRec^.MsgHdr.MsgAttr and maPriv) <> 0);
  End;


Function HudsonMsgObj.IsDeleted: Boolean;
  Begin
  IsDeleted := ((MsgRec^.MsgHdr.MsgAttr and maDeleted) <> 0);
  End;


Function HudsonMsgObj.IsEchoed: Boolean;
  Begin
   IsEchoed := MsgRec^.Echo;
{  IsEchoed := ((MsgRec^.MsgHdr.MsgAttr and maUnmovedEcho) <> 0); }
{  IsUnmovedNet := ((MsgRec^.MsgHdr.MsgAttr and maUnmovedNet) <> 0);}
  End;


Procedure HudsonMsgObj.MsgTxtStartUp;
  var
     MaxTxt: Word;
  Begin
  WasWrap := False;
  If MsgRec^.MsgHdr.NumRecs > TxtSize Then
    MaxTxt := TxtSize
  Else
    MaxTxt := MsgRec^.MsgHdr.NumRecs;
  Seek(MsgRec^.MsgTxtFile, MsgRec^.MsgHdr.StartRec * SizeOf(MsgTxtType));
  BlockRead(MsgRec^.MsgTxtFile, MsgChars^, MaxTxt * SizeOf(MsgTxtType));
  TxtCtr := 0;
  EOM := False;
  End;


Function HudsonMsgObj.GetChar: Char;
  Var
    CurrTxtRec, CurrTxtPos: Word;
  Begin
    CurrTxtRec := TxtCtr div 255 + 1;
    CurrTxtpos := TxtCtr mod 255 + 1;
    If (CurrTxtRec <= TxtSize) and
       (CurrTxtPos <= length(MsgChars^[CurrTxtRec])) then
    begin
       GetChar := MsgChars^[CurrTxtRec, CurrTxtPos];
       inc(TxtCtr);
    end else
    begin
       GetChar := #0;
       EOM := True;
    end;
  End;


Procedure HudsonMsgObj.StartNewMsg;  {Initialize message}
  Const
    Blank = '* Blank *';
  Begin
  TxtCtr := 0;
  FillChar(MsgRec^.MsgHdr, SizeOf(MsgRec^.MsgHdr), #0);
  MsgRec^.Echo := True;
  MsgRec^.MsgHdr.Time := '00:00';
  MsgRec^.MsgHdr.Date := '00-00-00';
  MsgRec^.MsgHdr.MsgTo := Blank;
  MsgRec^.MsgHdr.MsgFrom := Blank;
  MsgRec^.MsgHdr.Subj := Blank;
  if MsgRec^.MT = mmtNetmail then
     SetMsgAttr(True, maNetMail);
  End;


Procedure HudsonMsgObj.SetEcho(ES: Boolean); {Set echo status}
  Begin
  MsgRec^.Echo := ES;
  {poi la WriteMsg lo andra' a scrivere nel campo attributo}
  {appropriato al tipo di area}
  End;


Procedure HudsonMsgObj.SetLocal(LS: Boolean); {Set local status}
  Begin
    SetMsgAttr(LS, maLocal);
  End;


Procedure HudsonMsgObj.SetCrash(SS: Boolean); {Set crash netmail status}
  Begin
  SetNetAttr(SS, naCrash);
  End;


Procedure HudsonMsgObj.SetKillSent(SS: Boolean); {Set kill/sent netmail status}
  Begin
  SetNetAttr(SS, naKillSent);
  End;


{Procedure HudsonMsgObj.SetSent(SS: Boolean);
  Begin
  SetNetAttr(SS, naSent);
  End;
}

Procedure HudsonMsgObj.SetFAttach(SS: Boolean); {Set file attach status}
  Begin
  SetNetAttr(SS, naFAttach);
  End;


Procedure HudsonMsgObj.SetReqRct(SS: Boolean); {Set request receipt status}
  Begin
  SetNetAttr(SS, naReqRcpt);
  End;


Procedure HudsonMsgObj.SetReqAud(SS: Boolean); {Set request audit status}
  Begin
  SetNetAttr(SS, naReqAudit);
  End;


Procedure HudsonMsgObj.SetRetRct(SS: Boolean); {Set return receipt status}
  Begin
  SetNetAttr(SS, naRetRcpt);
  End;


Procedure HudsonMsgObj.SetFileReq(SS: Boolean); {Set file request status}
  Begin
  SetNetAttr(SS, naFileReq);
  End;


Procedure HudsonMsgObj.SetCost(SCost: Word);      {Set message cost}
  Begin
  MsgRec^.MsgHdr.Cost := SCost;
  End;


Procedure HudsonMsgObj.SetRefer(SRefer: LongInt);    {Set message reference}
  Begin
  MsgRec^.MsgHdr.ReplyTo := SRefer;
  End;


Procedure HudsonMsgObj.SetDate(SDate: String);    {Set message date}
  Begin
  MsgRec^.MsgHdr.Date := Copy(PadLeft(SDate,'0',8),1,8);
  MsgRec^.MsgHdr.Date[3] := '-';
  MsgRec^.MsgHdr.Date[6] := '-';
  End;


Procedure HudsonMsgObj.SetTime(STime: String);    {Set message time}
  Begin
  MsgRec^.MsgHdr.Time := Copy(PadLeft(STime,'0',5),1,5);
  MsgRec^.MsgHdr.Time[3] := ':';
  End;


Procedure HudsonMsgObj.DoChar(Ch: Char);          {Add character to message text}
Var
   CurrTxtRec, CurrTxtPos: Word;
  Begin
   CurrTxtRec := TxtCtr div 255 + 1;
   CurrTxtpos := TxtCtr mod 255 + 1;
  If (CurrTxtRec < TxtSize) or (CurrTxtPos < 255) Then
    Begin
      MsgChars^[CurrTxtRec, 0] := Chr(CurrTxtpos);
      MsgChars^[CurrTxtRec, CurrTxtPos] := Ch;
      Inc(TxtCtr);
    End;
  End;


Function HudsonMsgObj.WriteMsg: Word;
  Var
    WriteError: Word;
    MsgPos: Word;
    MsgIdx: MsgIdxType;
    FN: String[13];
    AlreadyLocked: Boolean;
    I : Integer;
  Begin
  If FileSize(MsgRec^.MsgTxtFile) div SizeOf(MsgTxtType) > $ff00 Then
    WriteError := 99
  Else
    WriteError := 0;
  Dec(TxtCtr);
  if GetChar<>#13 then
     DoChar(#13);
  MsgRec^.MsgHdr.NumRecs := TxtCtr div 255 + 1;
  {i successivi fino alla fine del blocco = #0}
  For I := TxtCtr mod 255 + 2 to 255 do
     MsgChars^[MsgRec^.MsgHdr.NumRecs, i] := #0;
  {ci sono da settare un po' di attributi, che dipendono dal tipo di area}
  {maNetmail io lo setto subito nello StartNewMsg, e maUnmoved* sono sempre}
  {=0, quindi non c'e' bisogno di resettarli}
  Case MsgRec^.MT of
    {mmtNormal:  Begin
             MsgRec^.MsgHdr.MsgAttr := MsgRec^.MsgHdr.MsgAttr and
               Not(maNetMail + maUnmovedNet + maUnmovedEcho);
             End;}
    mmtEchoMail: Begin
             {MsgRec^.MsgHdr.MsgAttr := MsgRec^.MsgHdr.MsgAttr and
               Not(maNetMail + maUnmovedNet);}
             SetMsgAttr(MsgRec^.Echo, maUnmovedEcho);
             End;
    mmtNetMail: Begin
             {MsgRec^.MsgHdr.MsgAttr := MsgRec^.MsgHdr.MsgAttr and Not(maUnmovedEcho);
             MsgRec^.MsgHdr.MsgAttr := MsgRec^.MsgHdr.MsgAttr or maNetMail;}
             SetMsgAttr(MsgRec^.Echo, maUnmovedNet);
             End;
    End;
  {il Sent lo configura comunque... forse dipende dal software utilizzato}
  {ma ho l'impressione che i maUnmoved* non servano a nulla...}
  SetNetAttr(not MsgRec^.Echo, naSent);
  MsgRec^.MsgHdr.Area := MsgRec^.Area;
  AlreadyLocked := MsgRec^.Locked;
  If Not AlreadyLocked Then
    If Not LockMsgBase Then
      WriteError := 5;
  If WriteError = 0 Then
    WriteError := SeekEnd;
  If WriteError = 0 Then               {Write MsgHdr}
  Begin
    MsgRec^.MsgHdr.StartRec :=
       FileSize(MsgRec^.MsgTxtFile) div SizeOf(MsgTxtType);
    MsgPos := FileSize(MsgRec^.MsgHdrFile) div SizeOf(MsgHdrType);
    Inc(MsgRec^.MsgInfo.HighMsg);
    MsgRec^.MsgHdr.MsgNum := MsgRec^.MsgInfo.HighMsg;
    Inc(MsgRec^.MsgInfo.Active);
    Inc(MsgRec^.MsgInfo.AreaActive[MsgRec^.MsgHdr.Area]);
    BlockWrite(MsgRec^.MsgHdrFile, MsgRec^.MsgHdr, SizeOf(MsgHdrType));
    BlockWrite(MsgRec^.MsgToIdxFile, MsgRec^.MsgHdr.MsgTo, SizeOf(MsgToIdxType));
    MsgIdx.MsgNum := MsgRec^.MsgHdr.MsgNum;
    MsgIdx.Area := MsgRec^.MsgHdr.Area;
    BlockWrite(MsgRec^.MsgIdxFile, MsgIdx, SizeOf(MsgIdxType));
    BlockWrite(MsgRec^.MsgTxtFile, MsgChars^,
       MsgRec^.MsgHdr.NumRecs * SizeOf(MsgTxtType));
    Case MsgRec^.MT of
      mmtEchoMail: FN := 'ECHOMAIL.BBS';
      mmtNetMail: FN := 'NETMAIL.BBS';
      Else
        FN := '';
      End; {Case MsgType}
    If ((Length(FN) > 0) and MsgRec^.Echo) Then
      WriteError := WriteMailIdx(FN, MsgPos);
  End;
  {ci sarebbe da aggiornare anche il MsgInfo.Bbs, con i dati aggiornati}
  {questo viene comunque fatto dalla UnLock}
  If WriteError = 0 Then
    If Not AlreadyLocked Then
      If Not UnlockMsgBase Then
        WriteError := 5;
  If ((WriteError = 0) and (HudsonFlushing)) Then
    Begin
    FlushFile(MsgRec^.MsgTxtFile);
    FlushFile(MsgRec^.MsgHdrFile);
    FlushFile(MsgRec^.MsgInfoFile);
    FlushFile(MsgRec^.MsgToIdxFile);
    FlushFile(MsgRec^.MsgIdxFile);
    End;
  MsgRec^.MsgPos := MsgPos;;
  WriteMsg := WriteError;
  End;


Procedure HudsonMsgObj.SetDest(Var Addr: AddrType);   {Set Zone/Net/Node/Point for Dest}
  Begin
  MsgRec^.MsgHdr.DestZone := Lo(Addr.Zone);
  MsgRec^.MsgHdr.DestNet := Addr.Net;
  MsgRec^.MsgHdr.DestNode := Addr.Node;
  MsgRec^.DestPoint := Addr.Point;
  If ((MsgRec^.DestPoint <> 0) and (MsgRec^.Mt = mmtNetMail)) Then
    DoStringLn(#1 + 'TOPT ' + Long2Str(MsgRec^.DestPoint));
  End;


Procedure HudsonMsgObj.SetOrig(Var Addr: AddrType);   {Set Zone/Net/Node/Point for Orig}
  Begin
  MsgRec^.MsgHdr.OrigZone := Lo(Addr.Zone);
  MsgRec^.MsgHdr.OrigNet := Addr.Net;
  MsgRec^.MsgHdr.OrigNode := Addr.Node;
  MsgRec^.OrigPoint := Addr.Point;
  If ((MsgRec^.OrigPoint <> 0) and (MsgRec^.Mt = mmtNetmail)) Then
    DoStringLn(#1 + 'FMPT ' + Long2Str(MsgRec^.OrigPoint));
  End;



Procedure HudsonMsgObj.SetMsgPath(MP: String);
  Begin
  MsgRec^.Area := Str2Long(Copy(MP,1,3));
  MsgRec^.MsgPath := Copy(MP,4,60);
  AddBackSlash(MsgRec^.MsgPath);
  {Assign(MsgRec^.MsgIdxFile, MsgRec^.MsgPath + 'MSGIDX.BBS');
  Assign(MsgRec^.MsgToIdxFile, MsgRec^.MsgPath + 'MSGTOIDX.BBS');
  Assign(MsgRec^.MsgHdrFile, MsgRec^.MsgPath + 'MSGHDR.BBS');
  Assign(MsgRec^.MsgTxtFile, MsgRec^.MsgPath + 'MSGTXT.BBS');
  Assign(MsgRec^.MsgInfoFile, MsgRec^.MsgPath + 'MSGINFO.BBS');}
  End;


Function HudsonMsgObj.LockMsgBase: Boolean; {Lock msg base prior to adding message}
  Var
    LockError: Word;
  Begin
  LockError := 0;
  If Not MsgRec^.Locked Then
    Begin
    LockError := LockFile(MsgRec^.MsgInfoFile,406,1);
    If LockError = 0 Then
      Begin
      Seek(MsgRec^.MsgInfoFile,0);
      BlockRead(MsgRec^.MsgInfoFile, MsgRec^.MsgInfo, SizeOf(MsgInfoType));
      End;
    End;
  MsgRec^.Locked := (LockError = 0);
  LockMsgBase := LockError = 0;
  End;


Function HudsonMsgObj.UnlockMsgBase: Boolean; {Unlock msg base after adding message}
  Var
    LockError: Word;
  Begin
  LockError := 0;
  If MsgRec^.Locked Then
    Begin
    Seek(MsgRec^.MsgInfoFile,0);
    BlockWrite(MsgRec^.MsgInfoFile, MsgRec^.MsgInfo, SizeOf(MsgInfoType));
    LockError := UnLockFile(MsgRec^.MsgInfoFile,406,1);
    End;
  MsgRec^.Locked := False;
  UnlockMsgBase := LockError = 0;
  End;


Function HudsonMsgObj.GetNumActive: Word;
  Begin
  GetNumActive := MsgRec^.MsgInfo.Active;
  End;


Function HudsonMsgObj.GetHighMsgNum: LongInt;
  Begin
  GetHighMsgNum := MsgRec^.MsgInfo.HighMsg;
  End;


Function HudsonMsgObj.GetLowMsgNum: LongInt;
  Begin
  GetLowMsgNum := MsgRec^.MsgInfo.LowMsg;
  End;


Function HudsonMsgObj.CreateMsgBase(MaxMsg: Word; MaxDays: Word): Word;
  Var
    CreateError: Word;
    i: Word;
Begin
  CreateError := 0;
  If Not MakePath(MsgRec^.MsgPath) Then
  begin
     CreateError := 1;
  end else
  begin
     if not shMakeFile(MsgRec^.MsgIdxFile, MsgRec^.MsgPath+ 'MSGIDX.BBS', 1) then
     begin
        CreateError := MkFileError;
     end else
     begin
        if not shMakeFile(MsgRec^.MsgToIdxFile, MsgRec^.MsgPath+ 'MSGTOIDX.BBS', 1) then
        begin
           CreateError := MkFileError;
        end else
        begin
           if not shMakeFile(MsgRec^.MsgHdrFile, MsgRec^.MsgPath+ 'MSGHDR.BBS', 1) then
           begin
              CreateError := MkFileError;
           end else
           begin
              if not shMakeFile(MsgRec^.MsgTxtFile, MsgRec^.MsgPath+ 'MSGTXT.BBS', 1) then
              begin
                 CreateError := MkFileError;
              end else
              begin
                 if not shMakeFile(MsgRec^.MsgInfoFile, MsgRec^.MsgPath+ 'MSGINFO.BBS', 1) then
                 begin
                    CreateError := MkFileError;
                 end else
                 begin
                    MsgRec^.MsgInfo.LowMsg := 1;
                    MsgRec^.MsgInfo.HighMsg := 0;
                    MsgRec^.MsgInfo.Active := 0;
                    For i := 1 to 200 Do
                      MsgRec^.MsgInfo.AreaActive[i] := 0;
                    {ora lo salva}
                    BlockWrite(MsgRec^.MsgInfoFile, MsgRec^.MsgInfo, SizeOf(MsgInfoType));
                    Close(MsgRec^.MsgInfoFile);
                 end;
                 Close(MsgRec^.MsgTxtFile);
              end;
              Close(MsgRec^.MsgHdrFile);
           end;
           Close(MsgRec^.MsgToIdxFile);
        end;
        Close(MsgRec^.MsgIdxFile);
     end;
  end;
  CreateMsgBase := CreateError;
End;


Function  HudsonMsgObj.MsgBaseExists: Boolean;
  Begin
  MsgBaseExists := (Check <> 1);
  End;


Function HudsonMsgObj.Check: Word;          {Check if msg base is Ok}
  { 0 = ok, 1 = not there (create), 2 = corrupted}
  Var
    BaseSize: LongInt;
    Status: Word;
  Begin
  Status := 0;
  If (Not FileExist(MsgRec^.MsgPath + 'MSGINFO.BBS'))  Then
    Status := 1;
  If (Not FileExist(MsgRec^.MsgPath + 'MSGHDR.BBS'))  Then
    Begin
    If Status = 0 Then
      Status := 2;
    End
  Else
    Begin
    If Status = 1 Then
      Status := 2;
    End;
  If (Not FileExist(MsgRec^.MsgPath + 'MSGTXT.BBS'))  Then
    Begin
    If Status = 0 Then
      Status := 2;
    End
  Else
    Begin
    If Status = 1 Then
      Status := 2;
    End;
  If (Not FileExist(MsgRec^.MsgPath + 'MSGIDX.BBS')) Then
    Begin
    If Status = 0 Then
      Status := 2;
    End
  Else
    Begin
    If Status = 1 Then
      Status := 2;
    End;
  If (Not FileExist(MsgRec^.MsgPath + 'MSGTOIDX.BBS'))  Then
    Begin
    If Status = 0 Then
      Status := 2;
    End
  Else
    Begin
    If Status = 1 Then
      Status := 2;
    End;
  If Status = 0 Then
    Begin
    If SizeFile(MsgRec^.MsgPath + 'MSGINFO.BBS') <> SizeOf(MsgInfoType) Then
      Status := 2;
    End;
  If Status = 0 Then
    Begin
    BaseSize := SizeFile(MsgRec^.MsgPath + 'MSGHDR.BBS') Div SizeOf(MsgHdrType);
    If BaseSize <> (SizeFile(MsgRec^.MsgPath + 'MSGIDX.BBS') Div SizeOf(MsgIdxType)) Then
      Status := 2;
    If BaseSize <> (SizeFile(MsgRec^.MsgPath + 'MSGTOIDX.BBS') Div SizeOf(MsgToIdxType)) Then
      Status := 2;
    End;
  Check := Status;
  End;


Function HudsonMsgObj.MsgBaseSize:Word;
  Begin
  If Length(MsgRec^.MsgPath) > 0 Then
    Begin
    MsgBaseSize := FileSize(MsgRec^.MsgIdxFile);
    End
  Else
    MsgBaseSize := 0;
  End;


Function HudsonMsgObj.SeekEnd: Word;        {Seek to end of Msg Base Files}
  Begin
  Seek(MsgRec^.MsgIdxFile, FileSize(MsgRec^.MsgIdxFile));
  Seek(MsgRec^.MsgToIdxFile, FileSize(MsgRec^.MsgToIdxFile));
  Seek(MsgRec^.MsgTxtFile, FileSize(MsgRec^.MsgTxtFile));
  Seek(MsgRec^.MsgHdrFile, FileSize(MsgRec^.MsgHdrFile));
  SeekEnd := 0;
  End;


Function HudsonMsgObj.SeekMsgBasePos(Position: Word): Word; {Seek to pos of Msg Base File}
  Var
    SeekError: Word;
  Begin
  SeekError := 0;
  Seek(MsgRec^.MsgIdxFile, Position * SizeOf(MsgIdxType));
  Seek(MsgRec^.MsgToIdxFile, Position * SizeOf(MsgToIdxType));
  Seek(MsgRec^.MsgHdrFile, Position * SizeOf(MsgHdrType));
  SeekMsgBasePos := SeekError;
  End;


Function HudsonMsgObj.WriteMailIdx(FN: String; MsgPos: Word): Word; {Write Netmail or EchoMail.Bbs}
  Var
    IdxFile: File;
    WriteError: Word;
    IdxName: String;
    Fm: Word;
  Begin
  WriteError := 0;
  If Length(HudsonEcho) > 0 Then
    IdxName := WithBackSlash(HudsonEcho) + FN
  Else
    IdxName := MsgRec^.MsgPath + FN;
  Fm := FileMode;
  FileMode := fmReadWrite_DN;
  If not shOpenFile(IdxFile, IdxName, 1) Then
    Begin
       if not shMakeFile(IdxFile, IdxName, 1) then
          WriteError := MkFileError;
    End;
  If WriteError = 0 Then
    Begin
       Seek(IdxFile, FileSize(IdxFile));
       BlockWrite(IdxFile, MsgPos, SizeOf(Word));
       Close(IdxFile);
    End;
  FileMode := Fm;
  WriteMailIdx := WriteError;
  End;


Function HudsonMsgObj.OpenMsgBase: Word; {Set path and initialize}
  Var
    OpenError: Word;
    CheckMode: Word;
    Fm : Word;
  Begin
  OpenError := 0;
  If Not MsgRec^.Opened Then
    Begin
    CheckMode := Check;
    If CheckMode = 1 Then
      Begin
      OpenError := CreateMsgBase(100,100);
      If OpenError = 0 Then
        CheckMode := 0;
      End;
    If CheckMode = 2 Then
      OpenError := 5000;
    If CheckMode = 0 Then
      Begin
      Fm := FileMode;
      FileMode := fmReadWrite_DN;
      If (OpenError=0) and
          Not ShOpenFile(MsgRec^.MsgIdxFile, MsgRec^.MsgPath + 'MSGIDX.BBS', 1)
         Then
        OpenError := MKFileError;
      If (OpenError=0) and
          Not shOpenFile(MsgRec^.MsgToIdxFile, MsgRec^.MsgPath + 'MSGTOIDX.BBS', 1)
         Then
        OpenError := MKFileError;
      If (OpenError=0) and
          Not shOpenFile(MsgRec^.MsgHdrFile, MsgRec^.MsgPath + 'MSGHDR.BBS', 1)
         Then
        OpenError := MKFileError;
      If (OpenError=0) and
          Not shOpenFile(MsgRec^.MsgTxtFile, MsgRec^.MsgPath + 'MSGTXT.BBS', 1)
         Then
        OpenError := MKFileError;
      If (OpenError=0) and
          Not shOpenFile(MsgRec^.MsgInfoFile, MsgRec^.MsgPath + 'MSGINFO.BBS', 1)
         Then
        OpenError := MKFileError;
      {apre il file LastRead.Bbs, se non esiste lo crea}
      End;
      FileMode := Fm;
    End;
  If OpenError = 0 Then
    Begin
    BlockRead(MsgRec^.MsgInfoFile, MsgRec^.MsgInfo, SizeOf(MsgRec^.MsgInfo));
    End;
  MsgRec^.Opened := (OpenError = 0);
  OpenMsgBase := OpenError;
  End;


Function HudsonMsgObj.CloseMsgBase: Word;         {Close Msg Base Files}
  Var
    CloseError: Word;
  Begin
  CloseError := 0;
  If MsgRec^.Opened Then
    Begin
    Close(MsgRec^.MsgIdxFile);
    Close(MsgRec^.MsgToIdxFile);
    Close(MsgRec^.MsgTxtFile);
    Close(MsgRec^.MsgHdrFile);
    Close(MsgRec^.MsgInfoFile);
    End;
  CloseMsgBase := CloseError;
  End;


Procedure HudsonMsgObj.SeekRead(NumToRead: Word);
  Begin
  If NumToRead > SeekSize Then
    NumToRead := SeekSize;
  Seek(MsgRec^.MsgIdxFile, MsgRec^.SeekStart * SizeOf(MsgIdxType));
  BlockRead(MsgRec^.MsgIdxFile, SeekArray^,
    NumToRead * SizeOf(MsgIdxType), MsgRec^.SeekNumRead);
  MsgRec^.SeekNumRead :=
    MsgRec^.SeekNumread div SizeOf(MsgIdxType);
  End;


Procedure HudsonMsgObj.SeekNext;
  Var
    SDone: Boolean;
  Begin
  SDone := False;
  While Not SDone Do
    Begin
    Inc(MsgRec^.SeekPos);
    If (MsgRec^.SeekPos > MsgRec^.SeekNumRead) Then
      Begin
      Inc(MsgRec^.SeekStart, MsgRec^.SeekNumRead);
      SeekRead(SeekSize);
      MsgRec^.SeekPos := 1;
      End;
    If MsgRec^.SeekNumRead = 0 Then
      Begin
      MsgRec^.SeekOver := True;
      SDone := True;
      End
    Else
      Begin
      If ((SeekArray^[MsgRec^.SeekPos].MsgNum > MsgRec^.CurrMsgNum) And
      (SeekArray^[MsgRec^.SeekPos].MsgNum <> $ffff) And
      (SeekArray^[MsgRec^.SeekPos].Area = MsgRec^.Area) And
      (MsgRec^.SeekPos > 0) And (MsgRec^.SeekPos <= MsgRec^.SeekNumRead)) Then
        Begin
        SDone := True;
        MsgRec^.CurrMsgNum := SeekArray^[MsgRec^.SeekPos].MsgNum;
        End;
      End;
    End;
  MsgRec^.MsgPos := MsgRec^.SeekStart + MsgRec^.SeekPos - 1;
  End;


Procedure HudsonMsgObj.SeekPrior;
  Var
    SDone: Boolean;
    SeekDec: Word;
  Begin
  MsgRec^.SeekOver := False;
  SDone := False;
  While Not SDone Do
    Begin
    Dec(MsgRec^.SeekPos);
    If (MsgRec^.SeekPos < 1) Then
      Begin
      If MsgRec^.SeekStart = 0 Then
        Begin
        MsgRec^.SeekOver := True;
        SDone := True;
        End;
      If (MsgRec^.SeekStart < SeekSize) Then
        SeekDec := MsgRec^.SeekStart
      Else
        SeekDec := SeekSize;
      Dec(MsgRec^.SeekStart, SeekDec);
      If MsgRec^.SeekStart < 0 Then
        MsgRec^.SeekStart := 0;
      SeekRead(SeekDec);
      MsgRec^.SeekPos := MsgRec^.SeekNumRead;
      End;
    If Not MsgRec^.SeekOver Then
      Begin
      If ((SeekArray^[MsgRec^.SeekPos].MsgNum < MsgRec^.CurrMsgNum) And
      (SeekArray^[MsgRec^.SeekPos].MsgNum <> $ffff) And
      (SeekArray^[MsgRec^.SeekPos].Area = MsgRec^.Area) And
      (MsgRec^.SeekPos > 0) And (MsgRec^.SeekPos <= MsgRec^.SeekNumRead)) Then
        Begin
        SDone := True;
        MsgRec^.CurrMsgNum := SeekArray^[MsgRec^.SeekPos].MsgNum;
        End;
      End;
    End;
  MsgRec^.MsgPos := MsgRec^.SeekStart + MsgRec^.SeekPos - 1;
  End;


Function HudsonMsgObj.SeekFound:Boolean;   {Seek has been completed}
  Begin
  SeekFound := Not MsgRec^.SeekOver;
  End;


Procedure HudsonMsgObj.SeekFirst(MsgNum: LongInt);
  Begin
  MsgRec^.SeekStart := 0;
  MsgRec^.SeekNumRead := 0;
  MsgRec^.SeekPos := 0;
  MsgRec^.SeekOver := False;
  SeekRead(SeekSize);
  MsgRec^.CurrMsgNum := MsgNum - 1;
  SeekNext;
  End;


Procedure HudsonMsgObj.SetMailType(MT: MsgMailType);
  Begin
  MsgRec^.MT := MT;
  End;


Function HudsonMsgObj.GetSubArea: Word;
  Begin
  GetSubArea := MsgRec^.MsgHdr.Area;
  End;


Procedure HudsonMsgObj.ReWriteHdr;
  Var
    NumRead: Word;
    RcvdName: String[35];
    MsgError: Word;
    MsgIdx: MsgIdxType;
  Begin
  MsgError := SeekMsgBasePos(MsgRec^.MsgPos);
  If IsRcvd Then
    RcvdName := '* Received *'
  Else
    RcvdName := MsgRec^.MsgHdr.MsgTo;
  If IsDeleted Then
    Begin
    RcvdName := '* Deleted *';
    MsgIdx.MsgNum := $ffff;
    End
  Else
    MsgIdx.MsgNum := MsgRec^.MsgHdr.MsgNum;
  If MsgError = 0 Then
    Begin
    BlockWrite(MsgRec^.MsgHdrFile, MsgRec^.MsgHdr, SizeOf(MsgHdrType));
    End;
  If MsgError = 0 Then
    Begin
    BlockWrite(MsgRec^.MsgToIdxFile, RcvdName, SizeOf(MsgToIdxType));
    End;
  MsgIdx.Area := MsgRec^.MsgHdr.Area;
  If MsgError = 0 Then
    Begin
    BlockWrite(MsgRec^.MsgIdxFile, MsgIdx, SizeOf(MsgIdxType));
    End;
  End;


Procedure HudsonMsgObj.DeleteMsg;
  Var
    RcvdName: String[35];
    MsgIdx: MsgIdxType;
    MsgError: Word;
  Begin
  MsgIdx.Area := MsgRec^.MsgHdr.Area;
  If LockMsgBase Then
    MsgError := 0
  Else
    MsgError := 5;
  If MsgError = 0 Then
    MsgError := SeekMsgBasePos(MsgRec^.MsgPos);
  If MsgError = 0 Then
    Begin
    BlockRead(MsgRec^.MsgHdrFile, MsgRec^.MsgHdr, SizeOf(MsgHdrType));
    End;
  If ((MsgRec^.MsgHdr.MsgAttr and maDeleted) = 0) Then
    Begin
    Dec(MsgRec^.MsgInfo.Active);
    Dec(MsgRec^.MsgInfo.AreaActive[MsgRec^.MsgHdr.Area]);
    End;
  MsgRec^.MsgHdr.MsgAttr := MsgRec^.MsgHdr.MsgAttr Or maDeleted;
  RcvdName := '* Deleted *';
  MsgIdx.MsgNum := $ffff;
  If MsgError = 0 Then
    MsgError := SeekMsgBasePos(MsgRec^.MsgPos);
  If MsgError = 0 Then
    Begin
    BlockWrite(MsgRec^.MsgHdrFile, MsgRec^.MsgHdr, SizeOf(MsgHdrType));
    BlockWrite(MsgRec^.MsgToIdxFile, RcvdName, SizeOf(MsgToIdxType));
    BlockWrite(MsgRec^.MsgIdxFile, MsgIdx, SizeOf(MsgIdxType));
  end;
  If MsgError = 0 Then
    If Not UnLockMsgBase Then
      MsgError := 5;
  End;


Function HudsonMsgObj.GetMsgLoc: LongInt;
  Begin
  GetMsgLoc := MsgRec^.MsgPos;
  End;


Procedure HudsonMsgObj.SetMsgLoc(ML: LongInt);
  Begin
  MsgRec^.MsgPos := ML;
  End;


Function HudsonMsgObj.NumberOfMsgs: LongInt;
  Begin
    NumberOfMsgs := MsgRec^.MsgInfo.AreaActive[MsgRec^.Area]
  End;


Procedure HudsonMsgObj.GetAllLastRead(UNum: LongInt; Var LR: LastReadType);
  Var
    LastName: String;
  Begin
  If Length(HudsonLast) > 0 Then
    LastName := WithBackSlash(HudsonLast) + 'LastRead.Bbs'
  Else
    LastName := MsgRec^.MsgPath + 'LastRead.Bbs';
  FillChar(LR, SizeOf(LR), 0);
  If ((UNum + 1) * SizeOf(LastReadType)) <=
  SizeFile(LastName) Then
    Begin
    If LoadFilePos(LastName, LR, SizeOf(LR),
    UNum * SizeOf(LastReadType)) = 0 Then;
    End;
  End;


Function HudsonMsgObj.GetLastRead(UNum: LongInt): LongInt;
  Var
    LastReadFile: File;
    LastRead: LastReadType;
    fm: Word;
  Begin
  Fm := FileMode;
  FileMode := fmReadOnly_DW;
  if not shOpenFile(lastReadFile, MsgRec^.MsgPath + 'MSGINFO.BBS', 1) then
     GetLastRead := 0
  else
  begin
     if FileSize(LastReadFile) > UNum * SizeOf(LastReadType) then
     begin
        seek(LastReadFile, UNum * SizeOf(LastReadType));
        blockread(LastReadFile, LastRead, SizeOf(LastReadType));
        getLastRead := LastRead[MsgRec^.Area];
     end else
        GetLastRead := 0;
     close(LastReadFile);
  end;
  filemode := fm;
  End;


Procedure HudsonMsgObj.SetLastRead(UNum: LongInt; LR: LongInt);
Var
    LastReadFile: File;
    LastRead: LastReadType;
    fm: Word;
  Begin
  fm := FileMode;
  FileMode := fmReadWrite_DA;
  if not shOpenFile(LastReadFile, MsgRec^.Msgpath + 'LASTREAD.BBS', 1) then
     if not shMakeFile(LastReadFile, MsgRec^.Msgpath + 'LASTREAD.BBS', 1) then;
  While (UNum>0) and not eof(LastReadFile) do
  begin
     BlockRead(LastReadFile, LastRead, SizeOf(LastReadType));
     dec(UNum);
  end;
  fillChar(LastRead, SizeOf(LastRead), 0);
  While UNum>0 do
  begin
     {bisogna completare il file}
     BlockWrite(LastReadFile, LastRead, SizeOf(LastReadType));
     dec(UNum);
  end;
  if not eof(LastReadFile) then
  begin
     BlockRead(LastReadFile, LastRead, SizeOf(LastReadType));
     Seek(LastReadFile, FilePos(LastReadFile) - SizeOf(LastReadType));
  end;
  LastRead[MsgRec^.Area] := LR;
  BlockWrite(LastReadFile, LastRead, SizeOf(LastReadType));
  Close(LastReadFile);
  filemode := fm;
  End;


Procedure HudsonMsgObj.GetHighest(Var LR: LastReadType);
  Var
    i: Word;
    IdxFile: File;
    MIdx: ^SeekArrayType;
    Fm : Word;
    {$IFDEF VIRTUALPASCAL}
    NumRead: Longint;
    {$ELSE}
    NumRead: Word;
    {$ENDIF}
  Begin
  New(MIdx);
  For i := 1 to 200 Do
    LR[i] := 0;
  Fm := FileMode;
  FileMode := fmReadOnly_DN;
  If shOpenFile(IdxFile, MsgRec^.MsgPath + 'MSGIDX.BBS', SizeOf(MsgIdxType)) Then
  begin
     While Not(Eof(IdxFile)) Do
       Begin
       BlockRead(IdxFile, MIdx^, SeekSize, NumRead);
       i := 1;
       While i <= NumRead Do
         Begin
         If MIdx^[i].MsgNum <> $ffff Then
           Begin
           If MIdx^[i].MsgNum > LR[MIdx^[i].Area] Then
             LR[MIdx^[i].Area] := MIdx^[i].MsgNum;
           End;
         Inc(i);
         End;
       End;
     Close(IdxFile);
  end;
  Dispose(MIdx);
  FileMode := Fm;
  End;


End.
