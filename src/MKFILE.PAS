Unit MKFile;
{$I MKB.Def}

{
     MKFile - Copyright 1993 by Mark May - MK Software
     You are free to use this code in your programs, however
     it may not be included in Source/TPU function libraries
     without my permission.

     Mythical Kingom Tech BBS (513)237-7737 HST/v32
     FidoNet: 1:110/290
     Rime: ->MYTHKING
     You may also reach me at maym@dmapub.dma.org
}


Interface

{$IFDEF OS2}
   {$IFDEF VIRTUALPASCAL}
   Uses
      Os2base, Dos;
   {$ELSE}
   Uses
      Os2Def, DosTypes, DosProcs, Dos;
   {$ENDIF}
{$ELSE}
Uses
   Dos;
{$ENDIF}

{$IFDEF OS2}
     {in os2 sono costanti, in dos variabili il cui valore dipende dal}
     {fatto se share e' caricato o meno}
Const
  fmReadOnly_DA = $10;
  fmWriteOnly_DA= $11;
  fmReadWrite_DA= $12;
  fmReadOnly_DW = $20;
  fmWriteOnly_DW= $21;
  fmReadWrite_DW= $22;
  fmReadOnly_DR = $30;
  fmWriteOnly_DR= $31;
  fmReadWrite_DR= $32;
  fmReadOnly_DN = $40;
  fmWriteOnly_DN= $41;
  fmReadWrite_DN= $42;
  ShareError    = 32;
{$ELSE}
Const
  Shareerror    = 5;
{$ENDIF}

Const
  Tries: Word = 20;

Var
  MKFileError: Word;
  {$IFDEF OS2}
  {$ELSE}
  GotShare: Boolean;
  fmReadOnly_DA, fmWriteOnly_DA, fmReadWrite_DA,
  fmReadOnly_DW, fmWriteOnly_DW, fmReadWrite_DW,
  fmReadOnly_DR, fmWriteOnly_DR, fmReadWrite_DR,
  fmReadOnly_DN, fmWriteOnly_DN, fmReadWrite_DN: Byte;
  {$ENDIF}

Function  FileExist(FName: String): Boolean;
Function  SizeFile(FName: String): LongInt;
Function  DateFile(FName: String): LongInt;
Function  LongLo(InNum: LongInt): Word;
Function  LongHi(InNum: LongInt): Word;
Function  LockFile(Var F; LockStart: LongInt; LockLength: LongInt): Word;
Function  UnLockFile(Var F; LockStart: LongInt; LockLength: LongInt): Word;
Function  shOpenFile(Var F: File; PathName: String; RecSize: Word): Boolean;
Function  shMakeFile(Var F: File; PathName: String; RecSize: Word): Boolean;
Function  LoadFilePos(FN: String; Var Rec; FS: Word; FPos: LongInt): Word;
Function  LoadFile(FN: String; Var Rec; FS: Word): Word;
Function  SaveFilePos(FN: String; Var Rec; FS: Word; FPos: LongInt): Word;
Function  SaveFile(FN: String; Var Rec; FS: Word): Word;
Function  ExtendFile(FN: String; ToSize: LongInt): Word;
Function  GetTempName(FN: String): String;
Function  EraseFile(FN: String): Boolean;
Function  MakePath(FP: String): Boolean;
Procedure FlushFile(Var F);


Implementation

Uses
   MTask;


Function shReset(Var F: File; RecSize: Word): Boolean;
  Var
    Count: Word;
    Code: Word;
  Begin
  if ioresult<>0 then;
  Count := Tries;
  Code := ShareError;
  While ((Count > 0) and (Code = ShareError)) Do
    Begin
    {$I-}
    Reset(F,RecSize);
    {$I+}
    Code := IoResult;
    if code=ShareError then
       Sleep;
    Dec(Count);
    End;
  MKFileError := Code;
  ShReset := (Code = 0);
  End;


Function shRewrite(Var F: File; RecSize: Word): Boolean;
  Var
    Count: Word;
    Code: Word;
  Begin
  if ioresult<>0 then;
  Count := Tries;
  Code := ShareError;
  While ((Count > 0) and (Code = ShareError)) Do
    Begin
    {$I-}
    Rewrite(F,RecSize);
    {$I+}
    Code := IoResult;
    if code=ShareError then
       Sleep;
    Dec(Count);
    End;
  MKFileError := Code;
  ShRewrite := (Code = 0);
  End;


{$IFDEF OS2}
Function LockFile(Var F; LockStart: LongInt; LockLength: LongInt): Word;
Var
    Unlock, Lock: FILELOCK;
Begin
   Lock.lOffset := LockStart;
   Lock.lRange  := LockLength;
   UnLock.lOffset := 0;
   UnLock.lRange  := 0;
   LockFile := DosSetFileLocks(FileRec(F).Handle,UnLock,Lock,55 * Tries,0);
End;
{$ELSE}
Function LockFile(Var F; LockStart: LongInt; LockLength: LongInt): Word;
  Var
    Handle: Word Absolute F;
    Tmp: Word;
    StrtHi: Word;
    StrtLo: Word;
    LgHi: Word;
    LgLo: Word;
    Count: Word;
  Begin
  if GotShare then
  begin
     Tmp := Handle;
     StrtHi := LongHi(LockStart);
     StrtLo := LongLo(LockStart);
     LgHi := LongHi(LockLength);
     LgLo := LongLo(LockLength);
     Count := TRies;
     Tmp := ShareError;
     While (Count>0) and (Tmp=ShareError) do
     begin
        Asm
          Mov ah, $5c;
          Mov al, $00;
          Mov bx, Tmp;
          Mov cx, StrtHi;
          Mov dx, StrtLo;
          Mov si, LgHi;                 {00h = success           }
          Mov di, LgLo;                 {01h = share not loaded  }
          Int $21;                      {06h = invalid handle    }
          Jc @JLock                     {21h = lock violation    }
          Mov ax, $00;                  {24h = share buffer full }
          @JLock:
          Mov Tmp, ax;
        End;
        dec(Count);
        if Tmp<>0 then
           Sleep;
     end;
     LockFile := Tmp;
  end else
     LockFile := 0;
  End;
{$ENDIF}

{$IFDEF OS2}
Function UnLockFile(Var F; LockStart: LongInt; LockLength: LongInt): Word;
Var
    Unlock, Lock: FILELOCK;
Begin
   UnLock.lOffset := LockStart;
   UnLock.lRange  := LockLength;
   Lock.lOffset := 0;
   Lock.lRange  := 0;
   UnLockFile := DosSetFileLocks(FileRec(F).Handle,UnLock,Lock,55 * Tries,0);
End;
{$ELSE}
Function UnLockFile(Var F; LockStart: LongInt; LockLength: LongInt): Word;
  Var
    Handle: Word Absolute F;
    Tmp: Word;
    StrtHi: Word;
    StrtLo: Word;
    LgHi: Word;
    LgLo: Word;
    Count: Word;
  Begin
  if GotShare then
  begin
     Tmp := Handle;
     StrtHi := LongHi(LockStart);
     StrtLo := LongLo(LockStart);
     LgHi := LongHi(LockLength);
     LgLo := LongLo(LockLength);
     Count := Tries;
     Tmp := ShareError;
     While (Count>0) and (Tmp=ShareError) do
     begin
        Asm
          Mov ah, $5c;
          Mov al, $01;
          Mov bx, Tmp;
          Mov cx, StrtHi;
          Mov dx, StrtLo;
          Mov si, LgHi;                 {00h = success           }
          Mov di, LgLo;                 {01h = share not loaded  }
          Int $21;                      {06h = invalid handle    }
          Jc @JLock                     {21h = lock violation    }
          Mov ax, $00;                  {24h = share buffer full }
          @JLock:
          Mov Tmp, ax;
        End;
        if Tmp<>0 then Sleep;
        dec(Count);
     end;
     UnLockFile := Tmp;
  end else
     UnLockFile := 0;
  End;
{$ENDIF}

Function LongLo(InNum: LongInt): Word;
  Begin
  LongLo := InNum and $FFFF;
  End;


Function LongHi(InNum: LongInt): Word;
  Begin
  LongHi := InNum Shr 16;
  End;


Function SizeFile(FName: String): LongInt;
  Var
    SR: SearchRec;
  Begin
  FindFirst(FName, AnyFile, SR);
  If DosError = 0 Then
  begin
    SizeFile := SR.Size;
    {$IFDEF OS2}
    Findclose(SR);
    {$ENDIF}
  end Else
    SizeFile := -1;
  End;


Function  DateFile(FName: String): LongInt;
  Var
    SR: SearchRec;
  Begin
  FindFirst(FName, AnyFile, SR);
  If DosError = 0 Then
  begin
    DateFile := SR.Time;
    {$IFDEF OS2}
    Findclose(SR);
    {$ENDIF}
  end Else
    DateFile := 0;
  End;


Function FileExist(FName: String): Boolean;
  Var
    SR: SearchRec;
  Begin
  FindFirst(FName, ReadOnly + Hidden + Archive, SR);
  if doserror=0 then
  begin
     FileExist := True;
     {$IFDEF OS2}
     Findclose(SR);
     {$ENDIF}
  end else
     FileExist := False;
  End;


Function shOpenFile(Var F: File; PathName: String; RecSize: Word): Boolean;
  Begin
  Assign(f,pathname);
  shOpenFile := shReset(f,RecSize);
  End;


Function shMakeFile(Var F: File; PathName: String; RecSize: Word): Boolean;
  Begin
  Assign(f,pathname);
  shMakeFile := shRewrite(f, RecSize);
  END;


Function LoadFile(FN: String; Var Rec; FS: Word): Word;
  Begin
  LoadFile := LoadFilePos(FN, Rec, FS, 0);
  End;


Function LoadFilePos(FN: String; Var Rec; FS: Word; FPos: LongInt): Word;
  Var
    F: File;
    {$IFDEF VIRTUALPASCAL}
    NumRead: Longint;
    {$ELSE}
    NumRead: Word;
    {$ENDIF}
  Begin
  If shOpenFile(F,FN,1) Then
  begin
    Seek(F,FPos);
    BlockRead(F, Rec, FS, NumRead);
    Close(F);
  end else
  begin
     LoadFilePos := MKFileError;
  end;

  End;


Function SaveFile(FN: String; Var Rec; FS: Word): Word;
   Begin
   SaveFile := SaveFilePos(FN, Rec, FS, 0);
   End;


Function SaveFilePos(FN: String; Var Rec; FS: Word; FPos: LongInt): Word;
  Var
    F: File;
  Begin
  If not shOpenFile(F,FN,1) and (MkFileError=2) Then
  begin
    if not shMakeFile(F,FN,1) then;
  end;
  If MkFileError = 0 Then
  Begin
    Seek(F, FPos);
    If FS > 0 Then
        BlockWrite(F, Rec, FS);
    Close(F);
  end;
  SaveFilePos := MkFileError;
  End;


Function ExtendFile(FN: String; ToSize: LongInt): Word;
{Pads file with nulls to specified size}
  Type
    FillType = Array[1..8000] of Byte;
  Var
    F: File;
    FillRec: ^FillType;
    Size : Longint;
  Begin
  New(FillRec);
  FillChar(FillRec^, SizeOf(FillRec^), 0);
  If not shOpenFile(F,FN,1) and (MkFileError<>5) Then
  begin
    if not shMakeFile(F,FN,1) then;
  end;
  If MkFileError = 0 Then
  Begin
    Size := FileSize(F);
    Seek(F,Size);
    {Bytes da scrivere}
    ToSize := ToSize - Size;
    WHile (ToSize>0) and (MkFileError=0) do
    begin
       Size := ToSize;
       if Size>SizeOf(FillRec^) then
          Size := SizeOf(FillRec^);
       BlockWrite(F, FillRec^, Size);
       dec(ToSize,Size);
    end;
    Close(F);
  end;
  Dispose(FillRec);
  ExtendFile := MkFileError;
  End;


Function  GetTempName(FN: String): String;
   Var TmpStr:String;
       I,J:Integer;
begin
  If ((Length(FN) > 0) and (FN[Length(FN)] <> '\')) Then
    TmpStr := FN + '\'
  Else
    TmpStr := FN;
  RandoMize;
  for I := 1 to 8 do
  begin
    J := Random(15);
    case J of
      0..9:TmpStr := TmpStr + chr(Ord('0')+J);
      10..15:TmpStr := TmpStr + chr(Ord('A')+J-10);
    end;
  end;
  GetTempName := TmpStr;
end;


Function  EraseFile(FN: String): Boolean;
  Var
    F: File;
    Fm: Word;
  Begin
  if ioresult<>0 then;
  Assign(F, FN);
  {$I-}
  Erase(F);
  {$I+}
  EraseFile := IoResult = 0;
  End;


Function  MakePath(FP: String): Boolean;
Var
  i : integer;
  tempdir : String;
  StartDir:DirStr;
  Target: String;
begin
  GetDir(0,StartDir);
  { remove slash at end }
  if FP[Length(FP)]='\' then
    Dec(FP[0]);
  Target := FP;
  { if colon where normally is change to that drive }
  if (length(Target)>=2) and (Target[2] = ':') then
  begin
    {$I-}
    ChDir(Copy(Target, 1, 2));
    {$I+}
    if IOResult=0 then
       Delete(Target,1,2)
    else
       Target := '';
  end;
  if (Target<>'') and (Target[1]='\') then
  begin
    {$I-}
    ChDir('\');
    {$I+}
    if IOResult=0 then
       Delete(Target,1,1)
    else
       Target := '';
  end;
  MakePath := Target<>'';
  While Target<>'' do
  begin
     I := pos('\',Target);
     if I=0 then
     begin
        TempDir := Target;
        Target := '';
     end else
     begin
        TempDir := Copy(Target,1,I-1);
        Delete(Target,1,I);
     end;
     {$I-}
     MkDir(TempDir);
     {$I+}
     if IOResult<>0 then;
     {$I-}
     ChDir(TempDir);
     {$I+}
     if IOREsult<>0 then
     begin
        Target := '';
        MakePath := False
     end;
  end;
  Chdir(StartDir);
  End;


{$IFDEF OS2}
Procedure FlushFile(Var F);
Begin

End;
{$ELSE}
Procedure FlushFile(Var F); {Dupe file handle, close dupe handle}
  Var
    Handle: Word Absolute F;
  {$IFDEF BASMINT}
    Tmp: Word;
  {$ELSE}
    {$IFDEF WINDOWS}
    Regs: TRegisters;
    {$ELSE}
    Regs: Registers;
    {$ENDIF}
  {$ENDIF}

  Begin
  {$IFDEF BASMINT}
  Tmp := Handle;
  Asm
    Mov ah, $45;
    Mov bx, Tmp;
    Int $21;
    Jc  @JFlush;
    Mov bx, ax;
    Mov ah, $3e;
    Int $21;
    @JFlush:
    End;
  {$ELSE}
  Regs.ah := $45;
  Regs.bx := Handle;
  MsDos(Regs);
  If (Regs.Flags and 1) = 0 Then   {carry}
    Begin
    Regs.bx := Regs.ax;
    Regs.Ah := $3e;
    MsDos(Regs);
    End;
  {$ENDIF}
  End;
{$ENDIF}


{$IFDEF OS2}
{$ELSE}
Function ShareInstalled : boolean; assembler;
asm
  mov ax,$1000
  int $2f
end;
{$ENDIF}

begin
   {$IFDEF OS2}
   {$ELSE}
   GotShare := ShareInstalled;
   if GotShare then
   begin
      fmReadOnly_DA := $10;
      fmWriteOnly_DA:= $11;
      fmReadWrite_DA:= $12;
      fmReadOnly_DW := $20;
      fmWriteOnly_DW:= $21;
      fmReadWrite_DW:= $22;
      fmReadOnly_DR := $30;
      fmWriteOnly_DR:= $31;
      fmReadWrite_DR:= $32;
      fmReadOnly_DN := $40;
      fmWriteOnly_DN:= $41;
      fmReadWrite_DN:= $42;
   end else
   begin
      fmReadOnly_DA := $00;
      fmWriteOnly_DA:= $01;
      fmReadWrite_DA:= $02;
      fmReadOnly_DW := $00;
      fmWriteOnly_DW:= $01;
      fmReadWrite_DW:= $02;
      fmReadOnly_DR := $00;
      fmWriteOnly_DR:= $01;
      fmReadWrite_DR:= $02;
      fmReadOnly_DN := $00;
      fmWriteOnly_DN:= $01;
      fmReadWrite_DN:= $02;
   end;
   {$ENDIF}

   {valore iniziale di FileMode, compatibile con il file sharing}
   FileMode := fmReadWrite_DA;

End.
