Unit LLSHell;

{Unit per comandi esterni ai compattatori}

{$I LL.Def}

Interface

Uses LLGen, Dos,
   MkFile,
    MkString, LLExec, LLTend;

Const MakeTempDir: Boolean=True;

Procedure SubstPar(Var S:String; Par:String; Ch:Char);
Function UnCompress(Nome, ExtractPath: String; Var Comp:Byte): Boolean;
Function VirusDetected(Nome:String; Var Comp:Byte): Boolean;
Procedure ExecuteExternalShell(N:Byte; FileName:String);
Function ChangeToRepack(PathDown:String;
   Var Nome:String; Var Comp:Byte; Var Size:Longint;
   Time:Longint): Boolean;
Procedure DosShell;
Function Compress(Nome,Nome1:String; Comp:Byte):Boolean;
Function DelCompressed(Nome,Nome1:String; Comp:Byte):Boolean;

Implementation

Var OldExitProc:Pointer;

Procedure SubstPar(Var S:String; Par:String; Ch:Char);
Var I:Integer;
begin
   I := pos('%'+Ch,S);
   if I=0 then
   begin
      if Par<>'' then
         S := S + ' ' + Par
   end else
   while I>0 do
   begin
      delete(S,I,2);
      Insert(Par,S,I);
      I := pos('%'+Ch,S);
   end;
end {SubstPar};

Procedure CleanTempDir;
Type FileInfoRef=^FileInfo;
     FileInfo=Record
        S:SearchRec;
        Next:FileInfoRef
     end;
Var
   ListaFile,Temp:FileInfoRef;
   PosLista:^FileInfoRef;
   S:SearchRec;
   F:File;
Begin
   ListaFile := Nil;
   PosLista := Addr(ListaFile);
   FindFirst('*.*',Archive + Directory + ReadOnly + Hidden,S);
   while DosError=0 do
   begin
      new(PosLista^);
      PosLista^^.Next := Nil;
      PosLista^^.S := S;
      PosLista := Addr(PosLista^^.Next);
      FindNext(S);
   end;
   {processa la directory}
   Temp := ListaFile;
   while (Temp<>Nil) do
   begin
      if ((Temp^.S.Attr and Directory) <> 0) then
      begin
         if (Temp^.S.Name<>'.') and (Temp^.S.Name<>'..') then
         begin
            chdir(Temp^.S.Name);
            CleanTempDir;
            ChDir('..');
            RmDir(Temp^.S.Name);
         end;
      end else
      begin
         {Archivio da cancellare}
         assign(F,Temp^.S.Name);
         if (Temp^.S.Attr and ReadOnly) <> 0 then
         begin
            {strippa l'attributo read-only}
            {$I-}
            SetFAttr(F, Temp^.S.Attr - ReadOnly);
            {$I+}
            if ioresult <> 0 then;
         end;
         {$I-}
         erase(F);
         {$I+}
         If IOResult=0 then;
      end;
      Temp := Temp^.Next
   end;
   {Rimuove lista}
   while ListaFile<>Nil do
   begin
      Temp := ListaFile;
      ListaFile := ListaFile^.Next;
      Dispose(Temp)
   end;
end {CleanTempDir};

Function UnCompress(Nome:String; ExtractPath:String; Var Comp:Byte): Boolean;
Var ComLine:String;
    D:DirStr;
begin
  if Comp=0 then
  begin
     Comp := GetComp(Nome);
  end;
  if (Comp>0) and (Comp<128) then
     ComLine := Packer[Comp]^.UnPack
  else
     ComLine := '';
  if ComLine<>'' then
  begin
     if FirstShell then
     begin
        writeln;
        FirstShell := False;
        FirstArea := True;
     end;
     SubstPar(Comline, Nome, '1');
     SubstPar(ComLine, ExtractPath, '2');
     GetDir(0,D);
     if MakeTempDir then
     begin
        TempDir := GetEnv('TEMP');
        if TempDir='' then
        begin
           TempDir := D0;
        end else
        begin
           if TempDir[length(TempDir)]<>'\' then
              TempDir := TempDir + '\';
        end;
        TempDir := Upper(TempDir + 'LLTEMP' + AppExt + '\');
        if MakePath(Copy(TempDir,1,length(TempDir)-1)) then;
        MakeTempDir := False;
     end;
     ChDir(Copy(TempDir,1,length(TempDir)-1));
     CleanTempDir;
     if Execute(ComLine) then
     begin
        UnCompress := ExecuteResult=0
     end else
        UnCompress := False;
     ChDir(D);
  end else
     UnCompress := False;
end {UnCompress};


Function Compress(Nome,Nome1:String; Comp:Byte):Boolean;
Var ComLine:String;
   D:DirStr;
   D1:DirStr; N:NameStr; E:ExtStr;
Begin
  if (Comp>0) and (Comp<128) then
     ComLine := Packer[Comp]^.Pack
  else
     ComLine := '';
  if ComLine<>'' then
  begin
     if FirstShell then
     begin
        writeln;
        FirstShell := False;
        FirstArea := True;
     end;
     GetDir(0,D);
     if pos(TempDir, Nome1)=1 then
     begin
        ChDir(Copy(TempDir,1,length(TempDir)-1));
        Delete(Nome1,1,length(TempDir));
     end else
     begin
        FSplit(Nome1,D1,N,E);
        if D1<>'' then
        begin
           if D1[length(D1)]='\' then
              dec(D1[0]);
           ChDir(D1);
        End;
        Nome1 := N+E;
     end;
     SubstPar(Comline, Nome, '1');
     SubstPar(ComLine, Nome1, '2');
     if Execute(ComLine) then
     begin
        Compress := ExecuteResult=0
     end else
        Compress := False;
     if D1<>'' then
        ChDir(D);
  end else
     Compress := False;
End {Compress};


Function DelCompressed(Nome,Nome1:String; Comp:Byte):Boolean;
Var ComLine:String;
Begin
  if (Comp>0) and (Comp<128) then
     ComLine := Packer[Comp]^.Delete
  else
     ComLine := '';
  if ComLine<>'' then
  begin
     if FirstShell then
     begin
        writeln;
        FirstShell := False;
        FirstArea := True;
     end;
     SubstPar(Comline, Nome, '1');
     SubstPar(ComLine, Nome1, '2');
     if Execute(ComLine) then
     begin
        DelCompressed := ExecuteResult=0
     end else
        DelCompressed := False;
  end else
     DelCompressed := False;
End {DelCompressed};


Function VirusDetected(Nome:String; Var Comp:Byte): Boolean;
Var Err:Boolean;
    D:DirStr;
    ComLine:String;
begin
   Err := False;
   if Comp=0 then
   begin
       Comp := GetComp(PathDown+ Nome);
       if Comp >= 128 then
          Comp := 0
       else if Comp<>0 then
       Err := not Uncompress(Nome,'*.*',Comp)
   end;
   if not err and (Comp<>0) and (VirusCheck<>'') then
   begin
      GetDir(0,D);
      ChDir(Copy(TempDir,1,Length(TempDir)-1));
      ComLine := VirusCheck;
      SubstPar(ComLine,'*.*','1');
      if Execute(ComLine) then
      begin
         if ExecuteResult = 1 then
         begin
            Writeln(' * Virus detected');
            Writeln(LogFile,Prelog(LogError),'Virus detected');
            Flush(LogFile);
            VirusDetected := True;
         end else
            VirusDetected := False;
      end else
         VirusDetected := False;
      ChDir(D);
   end else
      VirusDetected := False;
end {VirusDetected};

Procedure ExecuteExternalShell(N:Byte; FileName:String);
Var ComLine:String;
   D:DirStr;
begin
   ComLine := ExternalShell[N];
   if ComLine<>'' then
   begin
      GetDir(0,d);
      SubstPar(ComLine,FileName,'1');
      if Execute(ComLine) then;
      ChDir(D)
   end;
end {End};

Function ChangeToRepack(PathDown:String;
   Var Nome:String; Var Comp:Byte; Var Size:Longint;
   Time:Longint): Boolean;
Var TempNome:String;
   I, J:Byte;
   TempF:File;
   NewSize:Longint;
   Err : Boolean;
   NewComp:Byte;
   S:SearchRec;
Begin
   if Size<>0 then
   begin
      NewComp := 1;
      while (NewComp<=NPacker) and (Packer[NewComp]^.Ext <> Repack) do
         inc(NewComp);
      if NewComp<=NPacker then
      begin
         Err := False;
         if Comp=0 then
         begin
             Comp := GetComp(PathDown+ Nome);
             if Comp >= 128 then
                Comp := 0
             else
             if Comp<>0 then
             begin
                Err := (Packer[Comp]^.Ext=Repack) or
                   not UnCompress(PathDown+Nome,'*.*',Comp);
                if Err then
                   Comp := 0;
             end;
         end else
            Err := Packer[Comp]^.Ext=Repack;
         if not err then
         begin
            I := pos('.',Nome);
            TempNome := Copy(Copy(Nome,1,I) + Repack,1,length(Nome));
            if (Comp>0) and (Upper(Copy(Nome,I+1,length(nome)-I))<>'EXE')
               then
            for J := I+1 to length(Nome) do
            begin
               if Nome[J]<>Packer[Comp]^.Ext[J-I] then
                  TempNome[J] := Nome[J];
            end;

            while FileExist(PathDown+TempNome) do
            begin
               if TempNome[length(TempNome)] in ['1'..'9','A'..'E'] then
                  inc(TempNome[length(TempNome)])
               else
               if TempNome[length(TempNome)-1] = 'F' then
               begin
                  if TempNome[length(TempNome)-1] in ['1'..'9','A'..'F'] then
                     inc(TempNome[length(TempNome)-1])
                  else
                     TempNome[length(TempNome)-1] := '1';
               end else
                  TempNome[length(TempNome)] := '1';
            end;

            if ((Comp=0) and Compress(PathDown+TempNome,PathDown+Nome, NewComp))
               or ((Comp>0) and Compress(PathDown+TempNome, TempDir+'*.*', NewComp)) then
            begin
               FindFirst(PathDown+TempNome,Archive+ReadOnly,S);
               if (DosError=0) then
               begin
                  {$IFDEF OS2}
                  Findclose(S);
                  {$ENDIF}
                  Assign(TempF,PathDown+TempNome);
                  {$I-}
                  Reset(TempF,1);
                  {$I+}
                  if IOResult=0 then
                  begin
                     SetFTime(TempF,Time);
                     NewSize := FileSize(TempF);
                     Close(TempF);
                  end;
                  Writeln(' * Size old / new : ',Size,' / ',NewSize);
                  Writeln(LogFile,Prelog(LogWork),'Size old / new : ',Size,' / ',NewSize);
                  Flush(LOgFile);
                  if (
                    (LListStatus=EditFilesBbs) and Conferma('Accept new file')
                     ) or
                     (
                    (LListStatus<>EditFilesBbs) and
                      (
                    (RepackPerc=-1) or
                    (NewSize<Size) and ((Size-NewSize) * 100 div Size>=RepackPerc)
                      )
                     )
                     then
                  begin
                     Assign(TempF,PathDown+Nome);
                     Erase(TempF);
                     Size := NewSize;
                     ChangeToRepack := True;
                     Nome := TempNome;
                     Comp := NewComp
                  end else
                  begin
                     Assign(TempF,PathDown+TempNome);
                     Erase(TempF);
                     ChangeToRepack := False;
                  end;
               end else
               begin
                  ChangeToRepack := False;
               end;
            End else
            begin
               ChangeToRepack := False;
            end;
         End else
            ChangeToRepack := False;
      End else
         ChangeToRepack := False
   end else
      ChangeToRepack := False;
End;

PROCEDURE DosShell;
VAR
   D: DirStr;
BEGIN
  GetDir(0,D);
  ChDir(Copy(PathDown,1,length(PathDown)-1));
  if Execute('') then;
  ChDir(D);
END;{DosShell}

Procedure NewExit; Far;  { MUST be far! }
Var D:DirStr;
begin
  ExitProc := OldExitProc;
  if not MakeTempDir then
  begin
     GetDir(0,D);
     ChDir(Copy(TempDir,1,length(TempDir)-1));
     CleanTempDir;
     ChDir('..');
     RmDir(Copy(TempDir,1,length(TempDir)-1));
     ChDir(D);
  end
end {NewExit};

begin
   OldExitProc := ExitProc;
   ExitProc := @newExit;

end.

