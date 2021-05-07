Unit LLEXEC;

{$I LL.Def}

Interface

Var
  IOStatus      : Integer;
  ExecuteResult : Word;

{------------------------------------------------------------------------------}
Function Execute (ComLine:String): Boolean;
{------------------------------------------------------------------------------}

Implementation

Uses DOS,
 {$IFDEF OS2}
 {$ELSE}
    {$IFDEF DPMI}
    {$ELSE}
    ExecSwap,
    {$ENDIF}
 {$ENDIF}

   LLGen,
   MkFile,
   MkString, LLErrMsg;

Var
  Cmd: String;
  D:DirStr; N:NameStr; E:ExtStr;
  I : INteger;
  EnvPath: String;
  ProgName: String;
  TempStr: String;


{$IFDEF OS2}
{$ELSE}
{$IFDEF DPMI}
{$ELSE}
Function DosExitCode:Word;
Var Reg:Registers;
Begin
   Reg.AH := $4D;
   MsDos(Reg);
   DosExitCode := Reg.AL;
End {DosExitCode};
{$ENDIF}
{$ENDIF}


{------------------------------------------------------------------------------}


Function Execute (ComLine: String): Boolean;
Begin

  IOStatus := 0;

  Writeln(' * Execute ',ComLine);
  Writeln(LogFile,Prelog(LogStart),'Execute ',ComLine);
  Flush(LOgFile);

  {Estrae Comando e parametri}
  {$IFDEF VIRTUALPASCAL}
  StripLeadingSpace(ComLine);
  if (ComLine<>'') and (ComLine[1]='*') then
     delete(ComLine, 1, 1);
  if ComLine<>'' then
     ComLine := '/C ' + ComLine;
  ProgName := Cmd;
  {$ELSE}
  StripLeadingSpace(ComLine);
  if (ComLine<>'') then
  begin
     if ComLine[1]='*' then
     begin
        delete(ComLine, 1, 1);
        ProgName := Cmd;
     end else
     begin
        I := pos(' ', ComLine);
        if I>0 then
        begin
           ProgName := Copy(ComLine,1, I-1);
           Delete(ComLine,1,I);
           StripLeadingSpace(ComLine)
        end else
        begin
           ProgName := ComLine;
           ComLine := '';
        end;
        FSplit(ProgName, D, N, E);
        E := Upper(E);
        if D<>'' then
        begin
           if E='' then
           begin
              if FileExist(ProgName+'.COM') then
                 ProgName := Progname + '.COM'
              else
              if FileExist(ProgName+'.EXE') then
                 ProgName := Progname + '.EXE'
              else
              if FileExist(ProgName+'.BAT') then
              begin
                 ComLine := Progname + '.BAT ' + ComLine;
                 Progname := Cmd;
              end else
                 Progname := '';
           end else
           if (E='.BAT') then
           begin
              ComLine := Progname + ' ' + ComLine;
              Progname := Cmd;
           end else
           if (E<>'.COM') and (E<>'.EXE') then
              Progname := '';
        end else
        begin
           if E='' then
           begin
              TempStr := FSearch(progname + '.COM', Envpath);
              if TempStr = '' then
                 TempStr := FSearch(progname + '.EXE', Envpath);
              if TempStr = '' then
              begin
                 TempStr := FSearch(progname + '.BAT', Envpath);
                 if TempStr<>'' then
                 begin
                    TempStr := Cmd;
                    ComLine := Progname + ' ' + ComLine;
                 end;
              end;
              Progname := TempStr;
           end else
           if (E='.BAT') then
           begin
              ComLine := Progname + ' ' + ComLine;
              Progname := Cmd;
           end else
           if (E<>'.COM') and (E<>'.EXE') then
              Progname := '';
        end;
     end;
  end else
     Progname := Cmd;
  {$ENDIF}
  if ProgName <> '' then
  begin
      {$IFDEF OS2}
      SwapVectors;
      Exec(ProgName,ComLine);
      SwapVectors;
      IOStatus := DosError;
      ExecuteResult := DosExitCode;
      {$ELSE}
      {$IFDEF DPMI}
      SwapVectors;
      Exec(ProgName,ComLine);
      SwapVectors;
      IOStatus := DosError;
      ExecuteResult := DosExitCode;
      {$ELSE}

      if InitExecSwap(HeapPtr,D0+'LListSwp'+AppExt) then
      begin
         SwapVectors;
         IoStatus := ExecWithSwap(ProgName,ComLine);
         SwapVectors;
         ExecuteResult := DosExitCode;
         ShutDownExecSwap;
      end else
         IoStatus := 8;
      {$ENDIF}
      {$ENDIF}
  end else
     IoStatus := 2;

  if IOStatus=0 then
  begin
     if ExecuteResult<>0 then
     begin
        writeln(' * Exit code ',ExecuteResult);
        Writeln(LogFile,Prelog(LogError),'Exit code ',ExecuteResult);
        Flush(LogFile);
     end;
     Execute := True
  end else
  begin
     writeln(' * Dos Error ',IoStatus,' ',ErrorMsg(IoStatus));
     Writeln(LogFile,Prelog(LogError),'Dos Error ',IoStatus,' ',ErrorMsg(IoStatus));
     Flush(LOgFile);
     Execute := False
  end;

End;

Begin
   Cmd := GetEnv('COMSPEC');
   Envpath := GetEnv('PATH');
   {$IFDEF OS2}
   {$ELSE}
   UseEmsIfAvailable := True;
   {$ENDIF}
End.


