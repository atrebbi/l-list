Unit MKDos;
{$I MKB.Def}

Interface


Function GetDosDate: LongInt;
Function GetDOW: Word;
Function GetResultCode: Integer;

Implementation


Uses
  {$IFDEF WINDOWS}
  WinDos;
  {$ELSE}
  Dos;
  {$ENDIF}

{$IFDEF OS2}
Function GetResultCode: Integer;
  Begin
     GetResultCode := DosExitCode
  End;
{$ELSE}
Function GetResultCode: Integer;
  Var
    Result: Byte;
  {$IFNDEF BASMINT}
    {$IFDEF WINDOWS}
    Regs: TRegisters;
    {$ELSE}
    Regs: Registers;
    {$ENDIF}
  {$ENDIF}

  Begin
  {$IFDEF BASMINT}
  Asm
    Mov ah, $4d;
    Int $21;
    Cmp ah, $00;
    je @JRes;
    Neg ah;
    Mov Result, ah;
    jmp @JRes2;
    @JRes:
    Mov Result, al;
    @JRes2:
    End;
  {$ELSE}
  Regs.ah := $4d;
  MsDos(Regs);
  If Regs.ah <> 0 Then
    Result := - Regs.ah
  Else
    Result := Regs.al;
  {$ENDIF}
  GetResultCode := Result;
  End;
{$ENDIF}

Function GetDosDate: LongInt;
  Var
    {$IFDEF WINDOWS}
    DT: TDateTime;
    {$ELSE}
    DT: DateTime;
    {$ENDIF}
    DosDate: LongInt;
    {$IFDEF VIRTUALPASCAL}
    DOW: longint;
    {$ELSE}
    DOW: Word;
    {$ENDIF}
  Begin
  GetDate(DT.Year, DT.Month, DT.Day, DOW);
  GetTime(DT.Hour, DT.Min, DT.Sec, DOW);
  PackTime(DT, DosDate);
  GetDosDate := DosDate;
  End;


Function GetDOW: Word;
  Var
    {$IFDEF WINDOWS}
    DT: TDateTime;
    {$ELSE}
    DT: DateTime;
    {$ENDIF}
    {$IFDEF VIRTUALPASCAL}
    DOW: longint;
    {$ELSE}
    DOW: Word;
    {$ENDIF}
  Begin
  GetDate(DT.Year, DT.Month, DT.Day, DOW);
  GetDOW := DOW;
  End;


End.
