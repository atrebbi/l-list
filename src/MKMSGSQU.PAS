Unit MKMsgSqu;

{$I MKB.Def}
{$A-}
Interface

{
     MKMsgSqu - Copyright 1993 by Mark May - MK Software
     You are free to use this code in your programs, however
     it may not be included in Source/TPU function libraries
     without my permission.

     Mythical Kingom Tech BBS (513)237-7737 HST/v32
     FidoNet: 1:110/290
     Rime: ->MYTHKING
     You may also reach me at maym@dmapub.dma.org
}



Uses MKGlobT, MKMsgAbs;

Const
  SqHdrId = $AFAE4453;
  SqLinkNext = 0;
  SqLinkPrev = 1;
  SqNullFrame = 0;
  SqFrameMsg = 0;
  SqFrameFree = 1;
  SqFrameRLE = 2;
  SqFrameLZW = 3;
  SqFromSize = 36;
  SqToSize = 36;
  SqSubjSize = 72;
  SqMaxReply = 10;


Type SqBaseType = Record
  Len: Word; {Length of this record}
  Rsvd1: Word; {Future use}
  NumMsg: LongInt; {Number of messages}
  HighMsg: LongInt; {Highest msg}
  SkipMsg: LongInt; {# of msgs to keep in beginning of area}
  HighWater: LongInt; {High water UMsgId}
  Uid: LongInt; {Next UMsgId}
  Base: String[79]; {Base name of Squish file}
  BeginFrame: LongInt; {Offset of first frame in file}
  LastFrame: LongInt; {Offset of last frame in file}
  FirstFree: LongInt; {Offset of first free frame in file}
  LastFree: LongInt; {Offset of last free frame in file}
  EndFrame: LongInt; {Pointer to end of file}
  MaxMsg: LongInt; {Maximum number of messages}
  KeepDays: Word; {Maximum age of messages}
  SqHdrSize: Word; {Size of frame header}
  Rsvd2: Array[1..124] of Byte; {Future use}
  End;


Type SqFrameHdrType = Record
  Id: LongInt; {Must equal SqHdrId}
  NextFrame: LongInt; {Next msg frame}
  PrevFrame: LongInt; {Prior msg frame}
  FrameLength: LongInt; {Length of this frame not counting header}
  MsgLength: LongInt; {Length of message, tutto compreso ControlLength}
  ControlLength: LongInt; {Length of control information}
  FrameType: Word; {Type of message frame}
  Rsvd: Word; {Future use}
  End;


Type SqMsgHdrType = Record
  Attr: LongInt; {Msg attribute}
  MsgFrom: String[SqFromSize - 1]; {Nul Term from name}
  MsgTo: String[SqToSize - 1]; {Nul term to name}
  Subj: String[SqSubjSize - 1]; {Nul term subject}
  Orig: AddrType; {Origin address}
  Dest: AddrType; {Destination address}
  DateWritten: LongInt; {Date/Time msg written}
  DateArrived: LongInt; {Date/Time msg arrived here}
  UtcOffset: Word; {Minutes offset from UTC}
  ReplyTo: LongInt; {Original msg}
  Replies: Array[1..SqMaxReply] of LongInt; {Replies}
  AzDate: String[19]; {AsciiZ "Fido" style date}
  End;


Type
  SqIdxType = Record
     Ofs: LongInt; {Offset of frame header}
     UMsgId: LongInt; {Unique message id}
     Hash: LongInt; {Hash of MsgTo name}
  End;

Const
  SqIdxArraySize = 5200; {max numero per stare nei 64k}

Type SqIdxArrayType = Array[1..SqIdxArraySize] of SqIdxType;

Type SqIdxPtrType = ^SqIdxArrayType;

Const
  {lunghezza della parte iniziale del .SQD}
  SqBSize: Word = SizeOf(SqBaseType);
  {lunghezza dell'header del frame, NON e' compresa nel campo FrameLength}
  SqFSize: Word = SizeOf(SqFrameHdrType);

Const
  SqTxtBufferSize = 34000;  {34000}

Type SqInfoType = Record
  FN: String[80];
  MsgChars: Array[1..SqTxtBufferSize] of Char;
  Error: Word;
  SqdFile: File;
  SqIFile: File;
  SqBase: SqBaseType;
  SqBaseExtra: Array[1..100] of Char;
  SqdOpened: Boolean;
  SqiOpened: Boolean;
  SqiAlloc: Word;
  Locked: Boolean;
  Frame: SqFrameHdrType;
  MsgHdr: SqMsgHdrType;
  Extra: Array[1..100] of Char;
  CurrIdx: Word;
  StrDate: String[8];
  StrTime: String[8];
  CurrentFramePos: LongInt;
  CurrentUID: LongInt;
  SName: String[35];
  SHandle: String[35];
  HName: LongInt;
  HHandle: LongInt;
  ControlLength: Longint;
  WasDeleted: Boolean; {flag che dice se il msg e' stato cancellato}
                       {serve per seekprior e seeknext}
  MT: MsgMailType;
  {$IFDEF VIRTUALPASCAL}
  TxtSize: Longint;
  {$ELSE}
  TxtSize: Word;
  {$ENDIF}
  End;


Type SqMsgObj = Object(AbsMsgObj)
  SqInfo: ^SqInfoType;
  SqIdx: ^SqIdxArrayType;
  PrevCh: Char;
  Constructor Init; {Initialize}
  Destructor Done; Virtual; {Done cleanup and dispose}
  Function  OpenMsgBase: Word; Virtual; {Open message base}
  Function  CloseMsgBase: Word; Virtual; {Close message base}
  Function  CreateMsgBase(MaxMsg: Word; MaxDays: Word): Word; Virtual;
  Function  MsgBaseExists: Boolean; Virtual;
  Procedure SetMsgPath(FN: String); Virtual; {Set filepath and name - no extension}
  Function  SqdOpen: Word; Virtual; {Open squish data file}
  Function  SqiOpen: Word; Virtual; {Open squish index file}
  Procedure SqdClose; Virtual; {Close squish data file}
  Procedure SqiClose; Virtual; {Close squish index file}
  Function  LockMsgBase: Boolean; Virtual; {Lock msg base}
  Function  UnLockMsgBase: Boolean; Virtual; {Unlock msg base}
  Procedure ReadBase; Virtual; {Read base data record}
  Procedure WriteBase; Virtual; {Write base data record}
  Function  GetHighWater: LongInt; Virtual; {Get high water umsgid}
  Function  GetHighMsgNum: LongInt; Virtual; {Get highest msg number}
  Procedure ReadVarFrame(Var Frame: SqFrameHdrType; FPos: LongInt); Virtual; {Read frame at FPos into Frame}
  Procedure WriteVarFrame(Var Frame: SqFrameHdrType; FPos: LongInt); Virtual;
  Procedure UnlinkFrame(Var Frame: SqFrameHdrType; Var FirstFrame, LastFrame: Longint); Virtual;
     {Unlink frame from linked list}
  Procedure LinkFrame(Var Frame: SqFrameHdrType; FramePos: Longint; Var FirstFrame, LastFrame: Longint);
  Procedure KillMsg(IndexPos: LongInt); {Kill msg msgnum}
  Procedure KillExcess; {Kill msg in excess of limit}
  Procedure FindFrame(Var FL: LongInt; Var FramePos: LongInt); Virtual;
  Function  SqHashName(Name: String): LongInt; Virtual; {Convert name to hash value}
  Procedure StartNewMsg; Virtual; {Initialize msg header}
  Function  GetFrom: String; Virtual; {Get message from}
  Function  GetTo: String; Virtual; {Get message to}
  Function  GetSubj: String; Virtual; {Get message subject}
  Procedure SetFrom(Str: String); Virtual; {Set message from}
  Procedure SetTo(Str: String); Virtual; {Set message to}
  Procedure SetSubj(Str: String); Virtual; {Set message subject}
  Procedure SetDate(Str: String); Virtual; {Set message date}
  Procedure SetTime(Str: String); Virtual; {Set message time}
  Function  GetDate: String; Virtual; {Get message date mm-dd-yy}
  Function  GetTime: String; Virtual; {Get message time hh:mm}
  Function  GetRefer: LongInt; Virtual; {Get reply to of current msg}
  Procedure SetRefer(Num: LongInt); Virtual; {Set reply to of current msg}
  Function  GetSeeAlso: LongInt; Virtual; {Get see also msg}
  Procedure SetSeeAlso(Num: LongInt); Virtual; {Set see also msg}
  Function  GetChar: Char; Virtual;
  Procedure GetOrig(Var Addr: AddrType); Virtual;
  Procedure SetOrig(Var Addr: AddrType); Virtual;
  Procedure GetDest(Var Addr: AddrType); Virtual;
  Procedure SetDest(Var Addr: AddrType); Virtual;
  Procedure DoChar(Ch: Char); Virtual; {Add character to message text}
  Procedure DoKludgeLn(Str: String); Virtual; {Add string and newline to msg text}
  Function  WriteMsg: Word; Virtual; {Write msg to msg base}
  Procedure ReadIdx; Virtual;
  Procedure WriteIdx; Virtual;
  Procedure SeekFirst(MsgNum: LongInt); Virtual; {Seeks to 1st msg >= MsgNum}
  Function  GetMsgNum: LongInt; Virtual;
  Procedure SeekNext; Virtual;
  Procedure SeekPrior; Virtual;
  Function  SeekFound: Boolean; Virtual;
  Function  GetIdxFramePos: LongInt; Virtual;
  Function  GetIdxHash: LongInt; Virtual;
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
  Procedure SetAttr(St: Boolean; Mask: LongInt); Virtual; {Set attribute}
  Procedure SetLocal(St: Boolean); Virtual; {Set local status}
  Procedure SetRcvd(St: Boolean); Virtual; {Set received status}
  Procedure SetPriv(St: Boolean); Virtual; {Set priveledge vs public status}
  Procedure SetCrash(St: Boolean); Virtual; {Set crash netmail status}
  Procedure SetHold(St: Boolean); Virtual; {Set hold netmail status}
  Procedure SetKillSent(St: Boolean); Virtual; {Set kill/sent netmail status}
  Procedure SetFAttach(St: Boolean); Virtual; {Set file attach status}
  Procedure SetReqRct(St: Boolean); Virtual; {Set request receipt status}
  Procedure SetReqAud(St: Boolean); Virtual; {Set request audit status}
  Procedure SetRetRct(St: Boolean); Virtual; {Set return receipt status}
  Procedure SetFileReq(St: Boolean); Virtual; {Set file request status}
  Procedure MsgStartUp; Virtual; {Set up message}
  Procedure MsgTxtStartUp; Virtual; {Set up for msg text}
  Procedure SetMailType(MT: MsgMailType); Virtual; {Set message base type}
  Function  GetSubArea: Word; Virtual; {Get sub area number}
  Procedure ReWriteHdr; Virtual; {Rewrite msg header after changes}
  Procedure DeleteMsg; Virtual; {Delete current message}
  Function  NumberOfMsgs: LongInt; Virtual; {Number of messages}
  Procedure SetEcho(ES: Boolean); Virtual; {Set echo status}
  Function  IsEchoed: Boolean; Virtual; {Is current msg unmoved echomail msg}
  Function  GetLastRead(UNum: LongInt): LongInt; Virtual; {Get last read for user num}
  Procedure SetLastRead(UNum: LongInt; LR: LongInt); Virtual; {Set last read}
  Function  GetMsgLoc: LongInt; Virtual; {To allow reseeking to message}
  Procedure SetMsgLoc(ML: LongInt); Virtual; {Reseek to message}
  Function  IdxHighest: LongInt; Virtual; { *** }
  Procedure YoursFirst(Name: String; Handle: String); Virtual; {Seek your mail}
  Procedure YoursNext; Virtual; {Seek next your mail}
  Function  YoursFound: Boolean; Virtual; {Message found}
  Function  GetMsgDisplayNum: LongInt; Virtual; {Get msg number to display}
  End;

Type SqMsgPtr = ^SqMsgObj;

Implementation

Uses MKFile, MKString, MKDos
{$IFDEF WINDOWS}
,WinDos;
{$ELSE}
,Dos;
{$ENDIF}


Const
  SqMsgPriv =   $00001;
  SqMsgCrash =  $00002;
  SqMsgRcvd =   $00004;
  SqMsgSent =   $00008;
  SqMsgFile =   $00010;
  SqMsgFwd =    $00020;
  SqMsgOrphan = $00040;
  SqMsgKill =   $00080;
  SqMsgLocal =  $00100;
  SqMsgHold =   $00200;
  SqMsgXX2 =    $00400;
  SqMsgFreq =   $00800;
  SqMsgRrq =    $01000;
  SqMsgCpt =    $02000;
  SqMsgArq =    $04000;
  SqMsgUrg =    $08000;
  SqMsgScanned= $10000;


Constructor SqMsgObj.Init;
  Begin
  New(SqInfo);
  If (SqInfo = nil) Then
  Begin
    Fail;
    Exit;
  End;
  SqInfo^.SqdOpened := False;
  SqInfo^.SqiOpened := False;
  SqInfo^.FN := '';
  SqInfo^.Error := 0;
  SqInfo^.Locked := False;
  SqInfo^.WasDeleted := False;
  SqInfo^.SqiAlloc := SIzeOf(SqIdxArrayType);
  GetMem(SqIdx, SqInfo^.SqiAlloc);
  End;


Destructor SqMsgObj.Done;
  Begin
  If SqInfo^.SqdOpened Then
    SqdClose;
  If SqInfo^.SqiOpened Then
    SqiClose;
  FreeMem(SqIdx, SqInfo^.SqiAlloc);
  Dispose(SqInfo);
  End;


Procedure SqMsgObj.SetMsgPath(FN: String);
Var D: DirStr; N: NameStr; E: ExtStr;
  Begin
     FSplit(FExpand(FN),D,N,E);
     Sqinfo^.FN := D + N;
  End;


Function SqMsgObj.OpenMsgBase: Word;
  Begin
  If SqiOpen = 0 Then
  Begin
    ReadIdx;
    OpenMsgBase := SqdOpen;
  End Else
    OpenMsgBase := 100;
  End;


Function SqMsgObj.SqdOpen: Word;
  Var
    Fm: Word;
  Begin
  If Not SqInfo^.SqdOpened Then
  Begin
    Fm := FileMode;
    FileMode := fmReadWrite_DN;
    If Not shOpenFile(SqInfo^.SqdFile, SqInfo^.FN + '.SQD', 1) Then
      SqdOpen := MKFileError
    Else
      Begin
      SqInfo^.SqdOpened := True;
      SqdOpen := 0;
      BlockRead(SqInfo^.SqdFile, SqInfo^.SqBase, 2);
      If SqInfo^.SqBase.Len = 0 Then
        SqInfo^.SqBase.Len := SizeOf(SqBaseType);
      If SqInfo^.SqBase.Len > (SizeOf(SqBaseType) + 100) Then
        SqdOpen := 1001
      Else
        Begin
        SqBSize := SqInfo^.SqBase.Len;
        ReadBase;
        End;
      End;
      FileMode := Fm
    End
  Else
    SqdOpen := 0;
  End;


Function SqMsgObj.SqiOpen: Word;
Var
   Fm:Word;
  Begin
  If Not SqInfo^.SqiOpened Then
    Begin
    Fm := FileMode;
    FileMode := fmReadWrite_DN;
    If Not shOpenFile(SqInfo^.SqiFile, SqInfo^.FN + '.SQI', 1) then
      SqiOpen := MKFileError
    Else
      Begin
      SqInfo^.SqiOpened := True;
      SqiOpen := 0;
      End;
    FileMode := Fm
    End
  Else
    SqiOpen := 0;
  End;


Function SqMsgObj.CloseMsgBase: Word;
  Begin
  SqdClose;
  SqiClose;
  CloseMsgBase := 0;
  End;


Function SqMsgObj.CreateMsgBase(MaxMsg: Word; MaxDays: Word): Word;
  Var
    i: Word;
    D: DirStr; N:NameStr; E:ExtStr;
  Begin
  If Not SqInfo^.SqdOpened Then
    Begin
    FSplit(sqinfo^.Fn, D, N, E);
    if (D<>'') and (D[length(D)]='\') then
       dec(D[0]);
    If D<>'' Then
      Begin
      If MakePath(D) Then;
      End;
    FillChar(SqInfo^.SqBase, SizeOf(SqInfo^.SqBase), 0);
    SqInfo^.SqBase.Len := 256;
    SqInfo^.SqBase.SqHdrSize := SqFSize;
    SqInfo^.SqBase.UID := 1;
    SqInfo^.SqBase.NumMsg := 0;
    SqInfo^.SqBase.Base := SqInfo^.FN;
    Str2Az(SqInfo^.FN, 78, SqInfo^.SqBase.Base);
    SqInfo^.SqBase.MaxMsg := MaxMsg;
    SqInfo^.SqBase.KeepDays := MaxDays;
    SqInfo^.SqBase.EndFrame := SqInfo^.SqBase.Len;
    CreateMsgBase := SaveFile(SqInfo^.FN + '.SQD', SqInfo^.SqBase, SqInfo^.SqBase.Len);
    If SaveFile(SqInfo^.FN + '.SQI', SqInfo^.SqBase, 0) = 0 Then;
    If SaveFile(SqInfo^.FN + '.SQL', SqInfo^.SqBase, 0) = 0 Then;
    End
  Else
    CreateMsgBase := 176;
  End;


Function SqMsgObj.MsgBaseExists: Boolean;
  Begin
  MsgBaseExists :=  FileExist(SqInfo^.FN + '.SQD');
  End;


Procedure SqMsgObj.SqdClose;
  Begin
  If SqInfo^.SqdOpened Then
    Close(SqInfo^.SqdFile);
  SqInfo^.SqdOpened := False;
  End;


Function SqMsgObj.LockMsgBase: Boolean; {Lock msg base}
  Begin
  If Not SqInfo^.Locked Then
    Begin
    SqInfo^.Locked := LockFile(SqInfo^.SqdFile, 0, 1) = 0;
    LockMsgBase := SqInfo^.Locked;
    ReadBase;
    ReadIdx;
    End;
  End;


Function SqMsgObj.UnLockMsgBase: Boolean; {Unlock msg base}
  Begin
  If SqInfo^.Locked Then
    Begin
    WriteBase;
    WriteIdx;
    SqInfo^.Locked := UnLockFile(SqInfo^.SqdFile, 0, 1) <> 0;
    UnLockMsgBase := Not SqInfo^.Locked;
    End;
  End;


Procedure SqMsgObj.SqiClose;
  Begin
  If SqInfo^.SqiOpened Then
    Close(SqInfo^.SqiFile);
  SqInfo^.SqiOpened := False;
  End;


Procedure SqMsgObj.ReadBase;
  Begin
  Seek(SqInfo^.SqdFile, 0);
  BlockRead(SqInfo^.SqdFile, SqInfo^.SqBase, SqBSize);
  If SqInfo^.SqBase.SqHdrSize = 0 Then
    SQInfo^.SqBase.SqHdrSize := SqFSize;
  SqFSize := SqInfo^.SqBase.SqHdrSize;
  End;


Procedure SqMsgObj.WriteBase;
  Begin
  Seek(SqInfo^.SqdFile, 0);
  BlockWrite(SqInfo^.SqdFile, SqInfo^.SqBase, SQBSize);
  End;


Procedure SqMsgObj.StartNewMsg; {Initialize msg header}
  Begin
  FillChar(SqInfo^.MsgHdr, SizeOf(SqInfo^.MsgHdr), 0);
  FillChar(SqInfo^.Frame, SizeOf(SqInfo^.Frame), 0);
  TxtCtr := 0;
  DoChar(#0);
  SqInfo^.ControlLength := TxtCtr;
  SqInfo^.StrDate := '';
  SqInfo^.StrTime := '';
  End;


Function SqMsgObj.GetFrom: String; {Get message from}
  Begin
  GetFrom := Az2Str(SqInfo^.MsgHdr.MsgFrom, 35);
  End;


Function SqMsgObj.GetTo: String; {Get message to}
  Begin
  GetTo := Az2Str(SqInfo^.MsgHdr.MsgTo, 35);
  End;


Function SqMsgObj.GetSubj: String; {Get message subject}
  Begin
  GetSubj := Az2Str(SqInfo^.MsgHdr.Subj, 72);
  End;


Procedure SqMsgObj.SetFrom(Str: String); {Set message from}
  Begin
  Str2Az(Str, 35, SqInfo^.MsgHdr.MsgFrom);
  End;


Procedure SqMsgObj.SetTo(Str: String); {Set message to}
  Begin
  Str2Az(Str,35, SqInfo^.MsgHdr.MsgTo);
  End;


Procedure SqMsgObj.SetSubj(Str: String); {Set message subject}
  Begin
  Str2Az(Str,72, SqInfo^.MSgHdr.Subj);
  End;


Function SqMsgObj.GetDate: String; {Get message date mm-dd-yy}
  Var
    TmpDate: LongInt;
  Begin
  TmpDate := (SqInfo^.MsgHdr.DateWritten shr 16) +
   ((SqInfo^.MsgHdr.DateWritten and $ffff) shl 16);
  GetDate := DateStr(TmpDate);
  End;


Function SqMsgObj.GetTime: String; {Get message time hh:mm}
  Var
    TmpDate: LongInt;
  Begin
  TmpDate := (SqInfo^.MsgHdr.DateWritten shr 16) +
   ((SqInfo^.MsgHdr.DateWritten and $ffff) shl 16);
  GetTime := TimeStr(TmpDate);
  End;


Procedure SqMsgObj.SetDate(Str: String);
  Begin
  SqInfo^.StrDate := Copy(Str,1,8);
  End;


Procedure SqMsgObj.SetTime(Str: String);
  Begin
  SqInfo^.StrTime := Copy(Str,1,8);
  End;


Procedure SqMsgObj.GetOrig(Var Addr: AddrType);
  Begin
  Addr := SqInfo^.MsgHdr.Orig;
  End;


Procedure SqMsgObj.SetOrig(Var Addr: AddrType);
  Begin
  SqInfo^.MsgHdr.Orig := Addr;
  End;


Procedure SqMsgObj.GetDest(Var Addr: AddrType);
  Begin
  Addr := SqInfo^.MsgHdr.Dest;
  End;


Procedure SqMsgObj.SetDest(Var Addr: AddrType);
  Begin
  SqInfo^.MsgHdr.Dest := Addr;
  End;


Function SqMsgObj.SqHashName(Name: String): LongInt;
  Var
    Hash: LongInt;
    Tmp: LongInt;
    Counter: Word;
  Begin
  Hash := 0;
  Counter := 1;
  While Counter <= Length(Name) Do
    Begin
    Hash := (Hash shl 4) + Ord(LoCase(Name[Counter]));
    Tmp := Hash and $F0000000;
    If (Tmp <> 0) Then
      Hash := (Hash or (Tmp shr 24)) or Tmp;
    Inc(Counter);
    End;
  SqHashName := Hash and $7fffffff;
  End;


Procedure SqMsgObj.ReadVarFrame(Var Frame: SqFrameHdrType; FPos: LongInt);
  Begin
  Seek(SqInfo^.SqdFile, FPos);
  BlockRead(SqInfo^.SqdFile, Frame, SizeOf(SqFrameHdrType));
  End;


Procedure SqMsgObj.WriteVarFrame(Var Frame: SqFrameHdrType; FPos: LongInt); {Write frame at FPos}
  Begin
  Seek(SqInfo^.SqdFile, FPos);
  BlockWrite(SqInfo^.SqdFile, Frame, SizeOf(SqFrameHdrType));
  End;


Procedure SqMsgObj.UnlinkFrame(Var Frame: SqFrameHdrType; Var FirstFrame, LastFrame: Longint);
  Var
    TmpFrame: SqFrameHdrType;
  Begin
  If Frame.PrevFrame <> 0 Then
  Begin
    ReadVarFrame(TmpFrame, Frame.PrevFrame);
    TmpFrame.NextFrame := Frame.NextFrame;
    WriteVarFrame(TmpFrame, Frame.PrevFrame);
  End else
    FirstFrame := Frame.NextFrame;
  If Frame.NextFrame <> 0 Then
  Begin
    ReadVarFrame(TmpFrame, Frame.NextFrame);
    TmpFrame.PrevFrame := Frame.PrevFrame;
    WriteVarFrame(TmpFrame, Frame.NextFrame);
  End else
    LastFrame := Frame.NextFrame;
  End;


Procedure SqMsgObj.LinkFrame(Var Frame: SqFrameHdrType;
    FramePos: Longint; Var FirstFrame, LastFrame: Longint);
  Var
    TmpFrame: SqFrameHdrType;
  Begin
    If (FirstFrame = 0) Then
    Begin
      FirstFrame := FramePos;
      LastFrame := FramePos;
      Frame.PrevFrame := 0;
    End Else
    Begin
      Frame.PrevFrame := LastFrame;
      ReadVarFrame(TmpFrame, LastFrame);
      TmpFrame.NextFrame := FramePos;
      WriteVarFrame(TmpFrame, LastFrame);
      LastFrame := FramePos;
    End;
    Frame.NextFrame := 0;
    WriteVarFrame(Frame, FramePos);
  End;


Procedure SqMsgObj.FindFrame(Var FL: LongInt; Var FramePos: LongInt);
  Var
    TmpFrame: SqFrameHdrType;
    BestFoundSize: LongInt;
    TmpPos: Longint;
  Begin
  FramePos := 0;
  BestFoundSize := 0;
  TmpPos := SqInfo^.SqBase.FirstFree;
  While (TmpPos<>0) and (BestFoundSize<>FL) do
  begin
    ReadVarFrame(TmpFrame, TmpPos);
    if TmpFrame.FrameLength >= FL then
    begin
       if (BestFoundSize = 0) or (TmpFrame.FrameLength < BestFoundSize) then
       begin
          BestFoundSize := TmpFrame.FrameLength;
          FramePos := TmpPos;
       end;
    end;
    TmpPos := TmpFrame.NextFrame;
  end;
  If FramePos = 0 Then
  Begin
    FramePos := SqInfo^.SqBase.EndFrame;
  End Else
  Begin
    ReadVarFrame(TmpFrame, FramePos);
    UnLinkFrame(TmpFrame, SqInfo^.SqBase.FirstFree, SqInfo^.SqBase.LastFree);
    FL := TmpFrame.FrameLength;
  End;
End;


Procedure SqMsgObj.KillMsg(IndexPos: LongInt);
  Var
    KillPos: LongInt;
    KillFrame: SqFrameHdrType;
    TmpFrame: SqFrameHdrType;
    AlreadyLocked: Boolean;
    FreeCtr: Word;
  Begin
  AlreadyLocked := SqInfo^.Locked;
  If Not AlreadyLocked Then
    If LockMsgBase Then;
  If ( IndexPos <= sqInfo^.sqbase.NumMsg) Then
  Begin
    KillPos := SqIdx^[IndexPos].Ofs;
    ReadVarFrame(KillFrame, KillPos);
    UnLinkFrame(KillFrame, SqInfo^.sqBase.BeginFrame, SqInfo^.SqBase.LastFrame);
    KillFrame.FrameType := sqFrameFree;
    LinkFrame(KillFrame, KillPos, SqInfo^.SqBase.FirstFree, SqInfo^.SqBase.LastFree);
    Dec(SqInfo^.SqBase.NumMsg);
    Dec(SqInfo^.SqBase.HighMsg);
    While IndexPos <= SqInfo^.SqBase.NumMsg Do
    Begin
      SqIdx^[IndexPos] := SqIdx^[IndexPos + 1];
      Inc(IndexPos);
    End;
  End;
  If Not AlreadyLocked Then
    If UnlockMsgBase Then;
  End;


Procedure SqMsgObj.DoChar(Ch: Char); {Add character to message text}
  Begin
  If TxtCtr < SqTxtBufferSize Then
  Begin
    Inc(TxtCtr);
    SqInfo^.MsgChars[TxtCtr] := ch;
  End;
  End;


Procedure SqMsgObj.DoKludgeLn(Str: String); {Add string and newline to msg text}
begin
  if (pos('INTL',Str)<>2) and (pos('FMPT', Str)<>2) and (pos('TOPT', Str) <> 2) then
  begin
     {rimuove il precedente #0}
     if TxtCtr=SqInfo^.ControlLength then
     begin
        dec(TxtCtr);
        DoString(Str);
        DoChar(#0);
        Sqinfo^.ControlLength := TxtCtr;
     end else
     begin
        DoStringLn(Str);
     end;
  end;
  End;


Procedure SqMsgObj.KillExcess;
  Var
    AlreadyLocked: Boolean;
  Begin
  AlreadyLocked := SqInfo^.Locked;
  If Not AlreadyLocked Then
    If LockMsgBase Then;
  If (SqInfo^.SqBase.MaxMsg > 0) then
  Begin
    While (SqInfo^.SqBase.NumMsg > SqInfo^.SqBase.MaxMsg) Do
      KillMsg(SqInfo^.SqBase.SkipMsg + 1);
  End;
  If Not AlreadyLocked Then
    If UnlockMsgBase Then;
  End;


Function SqMsgObj.WriteMsg: Word; {Write msg to msg base}
  Var
    FramePos: LongInt;
    TmpFrame: SqFrameHdrType;
    TmpDate: LongInt;
    {$IFDEF WINDOWS}
    TmpDT: TDateTime;
    {$ELSE}
    TmpDT: DateTime;
    {$ENDIF}
    TmpStr: String;
    AlreadyLocked: Boolean;
    var i: word;
  Begin
  DoChar(#0);
  TmpDT.Year := Str2Long(Copy(SqInfo^.StrDate,7,2));
  If TmpDT.Year > 79 Then
    Inc(TmpDT.Year, 1900)
  Else
    Inc(TmpDT.Year, 2000);
  TmpDT.Month := Str2Long(Copy(SqInfo^.StrDate,1,2));
  TmpDT.Day := Str2Long(Copy(SqInfo^.StrDate,4,2));
  TmpDt.Hour := Str2Long(Copy(SqInfo^.StrTime,1,2));
  TmpDt.Min := Str2Long(Copy(SqInfo^.StrTime, 4,2));
  TmpDt.Sec := 0;
  TmpStr := FormattedDate(TmpDT, 'DD NNN YY  ') + Copy(SqInfo^.StrTime,1,5) + ':00';
  PackTime(TmpDT, TmpDate);
  SqInfo^.MsgHdr.DateWritten :=  (TmpDate shr 16) + ((TmpDate and $ffff) shl 16);
  TmpDate := GetDosDate;
  SqInfo^.MsgHdr.DateArrived := (TmpDate shr 16) + ((TmpDate and $ffff) shl 16);
  Str2AZ(TmpStr, 20, SqInfo^.MsgHdr.AZDate);
  AlreadyLocked := SqInfo^.Locked;
  If Not AlreadyLocked Then
    If LockMsgBase Then;
  If SqInfo^.Locked Then
  Begin
    ReadIdx;
    If (SqIdx=Nil) or (SqInfo^.SqBase.NumMsg >= SqInfo^.SqiAlloc) Then
    Begin
      SqInfo^.Error := 999;
      WriteMsg := 999;
    End Else
    Begin
      TmpFrame.msglength := SizeOf(SqMsgHdrType) + TxtCtr;
      Tmpframe.FrameLength := tmpframe.msglength;
      FindFrame(TmpFrame.Framelength, FramePos);
      TmpFrame.Id := SqHdrId;
      TmpFrame.FrameType := SqFrameMsg;
      TmpFrame.Rsvd := 0;
      TmpFrame.ControlLength := sqInfo^.ControlLength;
      TmpFrame.PrevFrame := SqInfo^.SqBase.LastFrame;
      WriteVarFrame(TmpFrame, FramePos);
      BlockWrite(SqInfo^.SqdFile, SqInfo^.MsgHdr, SizeOf(SqMsgHdrType));
      BlockWrite(SqInfo^.SqdFile, SqInfo^.MsgChars, TxtCtr);
      LinkFrame(TmpFrame, FramePos, SqInfo^.SqBase.BeginFrame, SqInfo^.SqBase.LastFrame);
      Inc(SqInfo^.SqBase.NumMsg);
      SqIdx^[SqInfo^.SqBase.NumMsg].Ofs := FramePos;
      SqIdx^[SqInfo^.SqBase.NumMsg].UMsgId := SqInfo^.SqBase.UID;
      SqIdx^[SqInfo^.SqBase.NumMsg].Hash := SqHashName(Az2Str(SqInfo^.MsgHdr.MsgTo, 35));
      Inc(SqInfo^.SqBase.UId);
      SqInfo^.SqBase.HighMsg := SqInfo^.SqBase.NumMsg;
      SqInfo^.SqBase.EndFrame := FileSize(SqInfo^.SqdFile);
      SqInfo^.SqBase.LastFrame := FramePos;
      KillExcess;
      SqInfo^.CurrIdx := SqInfo^.SqBase.NumMsg;
      WriteMsg := 0;
    End;
    If Not AlreadyLocked Then
      If UnLockMsgBase Then;
    End
  Else
    WriteMsg := 5;
  End;


Function SqMsgObj.GetChar: Char;
Var
   Ch: Char;
  Begin
  if (TxtCtr <= SqInfo^.ControlLength) then
  begin
    {campo di controllo, non ci sono CR tra una riga e la successiva}
    {si cerca quindi il ^A}
    {l'ultima termina con un #0}
    if PrevCh <> #0 then
    begin
       GetChar := PrevCh;
       PrevCh := #0;
       Inc(TxtCtr);
    end else
    begin
       Ch := SqInfo^.MsgChars[TxtCtr];
       if Ch=#0 then
       begin
          {fine del campo di controllo}
          if TxtCtr>1 then
          begin
             {termina la riga precedente}
             GetChar := #13;
             TxtCtr := SqInfo^.ControlLength + 1;
          end else
          begin
             TxtCtr := SqInfo^.ControlLength + 1;
             If (TxtCtr <= SqInfo^.TxtSize) then
             Begin
               GetChar := SqInfo^.MsgChars[TxtCtr];
               Inc(TxtCtr);
             End Else
             Begin
               GetChar := #0;
               EOM := True;
             End;
          end;
       end else
       if (ch=#1) and (TxtCtr>1) then
       begin
          {termina la riga precedente}
          GetChar := #13;
          {il ^A lo restituisce alla successiva chiamata}
          PrevCh := #1;
       end else
       begin
          GetChar := Ch;
          inc(TxtCtr)
       end;
    end;
  end else
  If (TxtCtr <= SqInfo^.TxtSize) then
  Begin
    GetChar := SqInfo^.MsgChars[TxtCtr];
    Inc(TxtCtr);
  End Else
  Begin
    GetChar := #0;
    EOM := True;
  End;
  End;


Function SqMsgObj.GetHighWater: LongInt; {Get high water umsgid}
  Begin
  GetHighWater := LongInt(SqInfo^.SqBase.HighWater);
  End;


Function SqMsgObj.GetHighMsgNum: LongInt; {Get highest msg number}
  Begin
  GetHighMsgNum := LongInt(SqInfo^.SqBase.Uid) - 1;
  End;


Procedure Sqmsgobj.ReadIdx;
   Var
      NumRead: Word;
     Begin
     NumRead := FileSize(SqInfo^.SqiFile);
     if NumRead > SqInfo^.SqiAlloc then
     begin
        SqInfo^.Error := 999
     end else
     begin
        Seek(SqInfo^.SqiFile, 0);
        BlockRead(SqInfo^.SqiFile, SqIdx^, NumRead);
     end;
   End;


Procedure SqMsgObj.WriteIdx;
  Begin
     Seek(SqInfo^.SqiFile, 0);
     BlockWrite(SqInfo^.SqiFile, SqIdx^, SqInfo^.SqBase.NumMsg * SizeOf(SqIdxType));
     Truncate(SqInfo^.SqiFile);
  End;


Procedure SqMsgObj.SeekFirst(MsgNum: LongInt);
  Begin
  SqInfo^.WasDeleted := False;
  SqInfo^.CurrIdx := 1;
  ReadIdx;
  While ((SqInfo^.CurrIdx <= SqInfo^.SqBase.NumMsg) and
  (MsgNum > LongInt(SqIdx^[SqInfo^.CurrIdx].UMsgId))) Do
    SeekNext;
  End;


Function SqMsgObj.IdxHighest: LongInt;
  Var
    i: Word;
    Tmp: LongInt;
  Begin
  Tmp := 0;
  i := 1;
  While i <= SqInfo^.SqBase.NumMsg Do
    Begin
    If  SqIdx^[i].UMsgId > Tmp Then
      Tmp := SqIdx^[i].UMsgId;
    Inc(i);
    End;
  IdxHighest := Tmp;
  End;


Function SqMsgObj.GetMsgNum: LongInt;
  Begin
  If ((SqInfo^.CurrIdx <= SqInfo^.SqBase.NumMsg) and
  (SqInfo^.CurrIdx > 0)) Then
    GetMsgNum := LongInt(SqIdx^[SqInfo^.CurrIdx].UMsgId)
  Else
    GetMsgNum := -1;
  End;


Procedure SqMsgObj.SeekNext;
  Begin
     if not SqInfo^.WasDEleted then
        Inc(SqInfo^.CurrIdx)
     else
        SqInfo^.WasDEleted := False;
  End;


Procedure SqMsgObj.SeekPrior;
  Begin
    If SqInfo^.CurrIdx > 1 Then
       Dec(SqInfo^.CurrIdx)
    Else
       SqInfo^.CurrIdx := 0;
    SqInfo^.WasDeleted := False;
  End;


Function SqMsgObj.SeekFound: Boolean;
  Begin
  SeekFound := GetMsgNum >= 0;
  End;


Function SqMsgObj.GetIdxFramePos: LongInt;
  Begin
  If SqInfo^.CurrIdx <= SqInfo^.SqBase.NumMsg Then
    GetIdxFramePos := SqIdx^[SqInfo^.CurrIdx].Ofs
  Else
    GetIdxFramePos := -1;
  End;


Function SqMsgObj.GetIdxHash: LongInt;
  Begin
  If SqInfo^.CurrIdx <= SqInfo^.SqBase.NumMsg Then
    GetIdxHash := SqIdx^[SqInfo^.CurrIdx].Hash
  Else
    GetIdxHash := 0;
  End;


Function SqMsgObj.IsLocal: Boolean; {Is current msg local}
  Begin
  IsLocal := ((SqInfo^.MsgHdr.Attr and SqMsgLocal) <> 0);
  End;


Function SqMsgObj.IsCrash: Boolean; {Is current msg crash}
  Begin
  IsCrash := ((SqInfo^.MsgHdr.Attr and SqMsgCrash) <> 0);
  End;


Function SqMsgObj.IsKillSent: Boolean; {Is current msg kill sent}
  Begin
  IsKillSent := ((SqInfo^.MsgHdr.Attr and SqMsgKill) <> 0);
  End;


Function SqMsgObj.IsFAttach: Boolean; {Is current msg file attach}
  Begin
  IsFAttach := ((SqInfo^.MsgHdr.Attr and SqMsgFile) <> 0);
  End;


Function SqMsgObj.IsReqRct: Boolean; {Is current msg request receipt}
  Begin
  IsReqRct := ((SqInfo^.MsgHdr.Attr and SqMsgRRQ) <> 0);
  End;


Function SqMsgObj.IsReqAud: Boolean; {Is current msg request audit}
  Begin
  IsReqAud := ((SqInfo^.MsgHdr.Attr and SqMsgArq) <> 0);
  End;


Function SqMsgObj.IsRetRct: Boolean; {Is current msg a return receipt}
  Begin
  IsRetRct := ((SqInfo^.MsgHdr.Attr and SqMsgCpt) <> 0);
  End;


Function SqMsgObj.IsFileReq: Boolean; {Is current msg a file request}
  Begin
  IsFileReq := ((SqInfo^.MsgHdr.Attr and SqMsgFreq) <> 0);
  End;


Function SqMsgObj.IsRcvd: Boolean; {Is current msg received}
  Begin
  IsRcvd := ((SqInfo^.MsgHdr.Attr and SqMsgRcvd) <> 0);
  End;


Function SqMsgObj.IsPriv: Boolean; {Is current msg priviledged/private}
  Begin
  IsPriv := ((SqInfo^.MsgHdr.Attr and SqMsgPriv) <> 0);
  End;


Function SqMsgObj.IsEchoed: Boolean;
  Begin
  IsEchoed := ((SqInfo^.MsgHdr.Attr and SqMsgScanned) = 0) and
     ((Sqinfo^.MsgHdr.Attr and SqMsgSent) = 0);
  End;


Function SqMsgObj.IsDeleted: Boolean; {Is current msg deleted}
  Begin
  IsDeleted := False;
  End;


Function SqMsgObj.GetRefer: LongInt; {Get reply to of current msg}
  Begin
  GetRefer := LongInt(SqInfo^.MsgHdr.ReplyTo);
  End;


Procedure SqMsgObj.SetRefer(Num: LongInt); {Set reply to of current msg}
  Begin
  SqInfo^.MsgHdr.ReplyTo := LongInt(Num);
  End;


Function SqMsgObj.GetSeeAlso: LongInt; {Get see also msg}
  Begin
  GetSeeAlso := LongInt(SqInfo^.MsgHdr.Replies[1]);
  End;


Procedure SqMsgObj.SetSeeAlso(Num: LongInt); {Set see also msg}
  Begin
  SqInfo^.MsgHdr.Replies[1] := LongInt(Num);
  End;


Procedure SqMsgObj.SetAttr(St: Boolean; Mask: LongInt); {Set attribute}
  Begin
  If St Then
    SqInfo^.MsgHdr.Attr := SqInfo^.MsgHdr.Attr or Mask
  Else
    SqInfo^.MsgHdr.Attr := SqInfo^.MsgHdr.Attr and (Not Mask);
  End;


Procedure SqMsgObj.SetLocal(St: Boolean); {Set local status}
  Begin
  SetAttr(St, SqMsgLocal);
  End;


Procedure SqMsgObj.SetRcvd(St: Boolean); {Set received status}
  Begin
  SetAttr(St, SqMsgRcvd);
  End;


Procedure SqMsgObj.SetPriv(St: Boolean); {Set priveledge vs public status}
  Begin
  SetAttr(St, SqMsgPriv);
  End;


Procedure SqMsgObj.SetEcho(ES: Boolean);
  Begin
  case SqInfo^.MT of
     mmtEchoMail: SetAttr(Not ES, SqMsgScanned);
     mmtNetMail: SetAttr(not ES, SqMsgSent)
  end;
  End;


Procedure SqMsgObj.SetCrash(St: Boolean); {Set crash netmail status}
  Begin
  SetAttr(St, SqMsgCrash);
  End;


Procedure SqMsgObj.SetHold(St: Boolean); {Set crash netmail status}
  Begin
  SetAttr(St, SqMsgHold);
  End;


Procedure SqMsgObj.SetKillSent(St: Boolean); {Set kill/sent netmail status}
  Begin
  SetAttr(St, SqMsgKill);
  End;


Procedure SqMsgObj.SetFAttach(St: Boolean); {Set file attach status}
  Begin
  SetAttr(St, SqMsgFile);
  End;


Procedure SqMsgObj.SetReqRct(St: Boolean); {Set request receipt status}
  Begin
  SetAttr(St, SqMsgRrq);
  End;


Procedure SqMsgObj.SetReqAud(St: Boolean); {Set request audit status}
  Begin
  SetAttr(St, SqMsgarq);
  End;


Procedure SqMsgObj.SetRetRct(St: Boolean); {Set return receipt status}
  Begin
  SetAttr(St, SqMsgCpt);
  End;


Procedure SqMsgObj.SetFileReq(St: Boolean); {Set file request status}
  Begin
  SetAttr(St, SqMsgFreq);
  End;


Procedure SqMsgObj.MsgStartUp;
  Begin
  SqInfo^.CurrentFramePos := GetIdxFramePos;
  SqInfo^.CurrentUID := SqIdx^[SqInfo^.CurrIdx].UMsgId;
  ReadVarFrame(SqInfo^.Frame, SqInfo^.CurrentFramePos);
  BlockRead(SqInfo^.SqdFile, SqInfo^.MsgHdr, SizeOf(SqMsgHdrType));
  SqInfo^.ControlLength := SqInfo^.Frame.ControlLength;
  PrevCh := #0;
  End;


Procedure SqMsgObj.MsgTxtStartUp;
Begin
   Seek(SqInfo^.SqdFile, SqInfo^.CurrentFramePos + SizeOf(SqFrameHdrType)
      + SizeOf(SqMsgHdrType));
   SqInfo^.TxtSize := SqInfo^.frame.MsgLength - SizeOf(SqMsgHdrType);
   if SqInfo^.TxtSize > sqTxtbufferSize then
      SqInfo^.TxtSize := SqTxtBufferSize;
   BlockRead(SqInfo^.SqdFile, SqInfo^.MsgChars, SqInfo^.TxtSize);
   TxtCtr := 1;
   EOM := False;
   WasWrap := False;
End;


Procedure SqMsgObj.SetMailType(MT: MsgMailType);
  Begin
  SqInfo^.MT := MT;
  End;


Function SqMsgObj.GetSubArea: Word;
  Begin
  GetSubArea := 0;
  End;


Procedure SqMsgObj.ReWriteHdr;
  Var
    AlreadyLocked: Boolean;
    i: LongInt;
  Begin
  AlreadyLocked := SqInfo^.Locked;
  If Not AlreadyLocked Then
    If LockMsgBase Then;
  WriteVarFrame(SqInfo^.Frame, SqInfo^.CurrentFramePos);
  {il file e' gia' alla posizione giusta, scrive l'header}
  BlockWrite(SqInfo^.SqdFile, SqInfo^.MsgHdr, SizeOf(SqMsgHdrType));
  i := 1;
  While ((i <= SqInfo^.SqBase.NumMsg) and (SqInfo^.CurrentFramePos <> SqIdx^[i].Ofs)) Do
    Inc(i);
  If SqIdx^[i].Ofs = SqInfo^.CurrentFramePos Then
    Begin
    If IsRcvd Then
      SqIdx^[i].Hash := 0
    Else
      SqIdx^[i].Hash := SqHashName(SqInfo^.MsgHdr.MsgTo);
    End;
  If Not AlreadyLocked Then
    If UnLockMsgBase Then;
  End;


Procedure SqMsgObj.DeleteMsg;
  Begin
     KillMsg(SqInfo^.CurrIdx);
     SqInfo^.WasDeleted := True; {per la prossima SeekNext}
  End;


Function SqMsgObj.NumberOfMsgs: LongInt;
  Var
    TmpBase: SqBaseType;
  Begin
  If LoadFile(SqInfo^.FN + '.Sqd', TmpBase, SizeOf(TmpBase)) = 0 Then
    NumberOfMsgs := TmpBase.NumMsg
  Else
    NumberOfMsgs := 0;
  End;


Function SqMsgObj.GetLastRead(UNum: LongInt): LongInt;
  Var
    LRec: LongInt;
  Begin
  If ((UNum + 1) * SizeOf(LRec)) >
  SizeFile(SqInfo^.FN + '.Sql') Then
    GetLastRead := 0
  Else
    Begin
    If LoadFilePos(SqInfo^.FN + '.Sql', LRec, SizeOf(LRec),
    UNum * SizeOf(LRec)) = 0 Then
      GetLastRead := LRec
    Else
      GetLastRead := 0;
    End;
  End;


Procedure SqMsgObj.SetLastRead(UNum: LongInt; LR: LongInt);
  Var
    LRec: LongInt;
    Status: Word;
  Begin
  Status := 0;
  If ((UNum + 1) * SizeOf(LRec)) >
  SizeFile(SqInfo^.FN + '.Sql') Then
    Begin
    Status := ExtendFile(SqInfo^.FN + '.Sql', (UNum + 1) * SizeOf(LRec));
    End;
  LRec := LR;
  If Status = 0 Then
    Status := SaveFilePos(SqInfo^.FN + '.Sql', LRec, SizeOf(LRec),
      UNum * SizeOf(LRec));
  End;


Function SqMsgObj.GetMsgLoc: LongInt;
  Begin
  GetMsgLoc := GetMsgNum;
  End;


Procedure SqMsgObj.SetMsgLoc(ML: LongInt);
  Begin
  SeekFirst(ML);
  End;


Procedure SqMsgObj.YoursFirst(Name: String; Handle: String);
  Begin
  SqInfo^.WasDeleted := False;
  SqInfo^.CurrIdx := 0;
  ReadIdx;
  SqInfo^.SName := Upper(Name);
  SqInfo^.SHandle := Upper(Handle);
  SqInfo^.HName := SqHashName(Name);
  SqInfo^.HHandle := SqHashName(Handle);
  YoursNext;
  End;


Procedure SqMsgObj.YoursNext;
  Var
    WasFound: Boolean;
  Begin
  WasFound := False;
  if SqInfo^.WasDEleted then
     SqInfo^.WasDeleted := False
  else
     Inc(SqInfo^.CurrIdx);
  While ((SqInfo^.CurrIdx <= SqInfo^.SqBase.NumMsg) and (Not WasFound)) Do
    Begin
    While ((SqIdx^[SqInfo^.CurrIdx].Hash <> SqInfo^.HName) And
    (SqIdx^[SqInfo^.CurrIdx].Hash <> SqInfo^.HHandle) And
    (SqInfo^.CurrIdx <= SqInfo^.SqBase.NumMsg)) Do
      Inc(SqInfo^.CurrIdx);
    If SqInfo^.CurrIdx <= SqInfo^.SqBase.NumMsg Then
      Begin
      MsgStartUp;
      If ((Not IsRcvd) and
      ((Upper(GetTo) = SqInfo^.SName) or (Upper(GetTo) = SqInfo^.SHandle))) Then
        WasFound := True
      Else
        Inc(SqInfo^.CurrIdx);
      End;
    End;
  End;


Function SqMsgObj.YoursFound: Boolean;
  Begin
  YoursFound := SqInfo^.CurrIdx <= SqInfo^.SqBase.NumMsg;
  End;


Function SqMsgObj.GetMsgDisplayNum: LongInt;
  Begin
  GetMsgDisplayNum := SqInfo^.CurrIdx;
  End;


End.
