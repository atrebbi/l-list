Unit LLFileId;

{$I LL.DEF}

Interface

Uses dos, LLGen, LLShell;

Procedure PackDesc(Var Pnt:DescTypePtr; IgnoreFirst: Boolean);
Function ReadExtractedDesc(Var Pnt:DescTypePtr;
   DescFileName:String): Boolean;
Function ImportDesc(N:String; Comp:Byte; Var Pnt:DescTypePtr):Boolean;

implementation

Procedure PackDesc(Var Pnt:DescTypePtr; IgnoreFirst: Boolean);
Var TempDescPtr, NewDescPtr:DescTypePtr;
   L1:String;
   I : Byte;
   File_IdLines:Integer;
   Uploader:String;
Begin
   if not nopackfile_id then
   begin
      NewDescPtr := Nil;
      TempDescPtr := Pnt;
      PosDesc := 1;
      File_IdLines := 0;
      Uploader := '';
      {La prima linea non la "Impacca"}
      if IgnoreFirst and (TempDescPtr<>Nil) then
      begin
         L := TempDescPtr^.Descrizione^;
         PutDescrizione(NewDescPtr);
         TempDescPtr := TempDescPtr^.Next;
         Inc(File_IdLines);
      end;
      L := '';
      If TempDescPtr<>Nil then
      begin
         L1 := TempDescPtr^.Descrizione^;
         if pos(UploaderStr,L1)=1 then
         begin
            Uploader := L1;
            L1 := '';
         end;
      end else
         L1 := '';
      while (TempDescPtr<>Nil) and (L1='') do
      begin
         TempDescPtr := TempDescPtr^.Next;
         if TempDescPtr<>Nil then
            L1 := TempDescPtr^.Descrizione^;
         if pos(UploaderStr,L1)=1 then
         begin
            Uploader := L1;
            L1 := '';
         end;
      end;
      While (File_IdLines<MaxFile_IdLines) and (L1<>'') do
      begin
         {Toglie spazi e cornici all'inizio}
         I := 1;
         while (I<=Length(L1)) and ((L1[I]=' ') or
             ((L1[I] >= #176) and (L1[I] <= #223))) do
            inc(I);
         if I>1 then
            delete(L1,1,I-1);
         {Toglie spazi e cornici alla fine}
         I := length(L1);
         while (I>0) and ((L1[I]=' ') or
             ((L1[I] >= #176) and (L1[I] <= #223))) do
            dec(I);
         L1[0] := chr(I);
         {Rewrap della stringa, riducendo a 1 le sequenze di blank}
         I := 1;
         while I<length(L1) do
         begin
            if (L1[I]=' ') and (L1[I+1]=' ') then
               delete(L1,I,1)
            else
               inc(I)
         end;
         I := Pos(' ',L1);
         if (I=0) and (L1<>'') then
            I := length(L1) + 1;
         while (I>0) and (I+length(L)<MaxLenDesc) do
         begin
            if L<>'' then
               L := L + ' ';
            L := L + copy(L1,1,I-1);
            delete(L1,1,I-1);
            StripLeadingSpace(L1);
            I := Pos(' ',L1);
            if (I=0) and (L1<>'') then
               I := length(L1) + 1;
         end;
         if L='' then
         begin
            {da notare che va bene se anche la prima riga supera MaxLenDesc}
            if (length(L1)<=MaxLenDesc) or (L1[MaxLenDesc+1]=' ') then
            begin
               L := L1;
               if length(L)>MaxLenDesc then
                  L := Copy(L,1,MaxLenDesc);
            end else
            begin
               L := Copy(L1,1,MaxLenDesc);
               while (L<>'') and (L[length(L)]<>' ') do
                  dec(L[0]);
               if L<>'' then
                  dec(L[0]);
               if L='' then
               begin
                  L := Copy(L1,1,MaxLenDesc);
               end;
            end;
            delete(L1,1,length(L));
            StripLeadingSpace(L1);
         end else
         begin
            I := Pos(' ',L1);
            if (I=0) and (L1<>'') then
               I := length(L1)+1;
            while (I>0) and (I+length(L)<MaxLenDesc) do
            begin
               if L<>'' then
                  L := L + ' ';
               L := L + copy(L1,1,I-1);
               delete(L1,1,I-1);
               StripLeadingSpace(L1);
               I := Pos(' ',L1);
               if (i=0) and (L1<>'') then
                  I := length(L1) + 1;
            end;
         end;
         if L1<>'' then
         begin
            PutDescrizione(NewDescPtr);
            inc(File_IdLines);
            if (length(L1)<=MaxLenDesc) or (L1[MaxLenDesc+1]=' ') then
            begin
               L := L1;
               if length(L)>MaxLenDesc then
                  L := Copy(L,1,MaxLenDesc);
            end else
            begin
               L := Copy(L1,1,MaxLenDesc);
               while (L<>'') and (L[length(L)]<>' ') do
                  dec(L[0]);
               if L='' then
               begin
                  L := Copy(L1,1,MaxLenDesc);
               end;
            end;
            delete(L1,1,length(L));
            StripLeadingSpace(L1);
         end;
         while (L1='') and (TempDescPtr<>Nil) do
         begin
            TempDescPtr := TempDescPtr^.Next;
            if TempDescPtr<>Nil then
               L1 := TempDescPtr^.Descrizione^;
            if pos(UploaderStr,L1)=1 then
            begin
               Uploader := L1;
               L1 := '';
            end;
         end;
      end;
      if (L<>'') and (File_IdLInes<MaxFile_IdLines) then
         PutDescrizione(NewDescPtr);
      if Uploader<>'' then
      begin
         L := Uploader;
         PutDescrizione(NewDescPtr);
      end;
      CancellaDescrizione(Pnt);
      Pnt := NewDescPtr;
   end;
end {PackDesc};

Function ReadExtractedDesc(Var Pnt:DescTypePtr;
   DescFileName:String): Boolean;
Var File_Id:Text;
    I : Integer;
    File_IdLines:Integer;
    Uploader, FirstLine:String;
    TempDescPtr:DescTypePtr;
    L1:String;
Begin
   Assign(File_Id,TempDir+DescFileName);
   {$I-}
   Reset(File_Id);
   {$I+}
   if IOResult=0 then
   begin
      writeln(' * Read ',DescFileName);
      Writeln(LogFile,Prelog(LogError),'Read ',DescFileName);
      Flush(LogFile);
      {Cerca l'uploader nella vecchia descrizione}
      Uploader := '';
      TempDescPtr := Pnt;
      if TempDescPtr<>Nil then
      begin
         if NoFirstLine then
            FirstLine := ''
         else
            FirstLine := TempDescPtr^.Descrizione^;
         TempDescPtr := TempDescPtr^.Next;
         while (Uploader='') and (TempDescPtr<>Nil) do
         begin
            if Pos(UploaderStr,TempDescPtr^.Descrizione^)=1 then
            begin
               Uploader := TempDescPtr^.Descrizione^
            end;
            TempDescPtr := TempDescPtr^.Next
         End;
      end else
         FirstLIne := '';
      PosDesc := 1;
      CancellaDescrizione(Pnt);
      File_IdLines := 0;
      Pnt := Nil;
      if FirstLine<>'' then
      begin
         L := FirstLine;
         PutDescrizione(Pnt);
         Inc(File_IdLines);
      end;
      while not eof(File_Id) and
         (File_IdLines<MaxFile_IdLines) do
      begin
         readln(File_Id,L1);
         L1 := ExpandTabs(L1);

         {controlla #10}
         {come terminatore di linea}

         While (L1<>'') do
         begin
            I := pos(#10,L1);
            if I=0 then
            begin
               L := L1;
               L1 := '';
            end else
            begin
               L := Copy(L1,1,I-1);
               Delete(L1,1,I);
            end;
            {elimina i caratteri non ammessi}
            I := pos(#12, L);
            while (I>0) do
            begin
               delete(L,i,1);
               I := pos(#12, L);
            end;
            While (L<>'') and (L[length(L)]=' ') do
               dec(L[0]);
            if L<>'' then
            begin
               inc(File_IdLines);
               PutDescrizione(Pnt);
            end;
         end;
      end;
      close(File_Id);
      if Uploader<>'' then
      begin
         L := Uploader;
         PutDescrizione(Pnt);
      end;
      ReadExtractedDesc := True
   end else
   begin
      ReadEXtractedDesc := False
   end;
End {ReadExtractedDesc};


Function ImportDesc(N:String; Comp:Byte; Var Pnt:DescTypePtr):Boolean;
Var TempB:Boolean;
    TempDescPtr, OldDesc:DescTypePtr;
    SubDir: String;
    FoundSub: Boolean;
    S: SearchRec;
    TmpStr: String;
begin
   if (Comp<>0) or Uncompress(N,DescFiles,Comp) then;
   if (Comp>=128) then
   begin
      {mette il formato nella descrizione}
      if (Pnt=Nil) and (GraficFileInfo<>'') then
      begin
         {solo se non c'era una precedente descrizione}
         L := GraficFileInfo;
         PosDesc := 1;
         PutDescrizione(Pnt);
         ImportDesc := True;
      end else
         ImportDesc := False;
   end else
   begin
      SubDir := '';
      repeat
         FoundSub := False;
         findfirst(TempDir+SubDir+'*.*',directory,S);
         while (dosError=0) and not foundsub do
         begin
            if ((S.Attr and Directory)<>0) and
              (S.name<>'.') and (S.name<>'..') then
            begin
               {trovata una subdir}
               foundsub := true;
               SubDir := SubDir + S.name + '\';
               {$IFDEF VIRTUALPASCAL}
               findclose(S);
               {$ENDIF}
            end else
               findnext(S);
         end;
      until not foundsub;
      if (Comp<>0) then
      begin
         TempB := False;
         TmpStr := DescFiles + ' ';
         I := pos(' ',TmpStr);
         while not tempB and (I>0) do
         begin
            tempB := ReadExtractedDesc(Pnt,SubDir+Copy(TmpStr,1,I-1));
            delete(TmpStr,1,I);
            I := pos(' ',TmpStr);
         end;
         ImportDesc := TempB;
      end else
         ImportDesc := False;
   end;
end {ImportDesc};

end.
