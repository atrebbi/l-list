Unit LLCOPY;

{$I LL.Def}

Interface

Uses Dos, Crt, LLTend,
   MkFile,
   LLGen, LLErrMsg, Ra250fb;

Function CopyFile(Name:String; Size,FTime:LongInt; Descrizione:DescTypePtr;
   Var Move:Boolean; Replaces:DescTypePtr; AreaNum: Word): String;
Function GetDestPath(Int:String): Boolean;
Function GetDesc(Name, PathFBbs:String):DescTypePtr;
Function AddFBbsLine(PathCopyFBbs, DestName:String; Descrizione:DescTypePtr;
   Sort:SortType; Replaces:DescTypePtr):Boolean;

Implementation




Function GetDesc(Name, PathFBbs:String):DescTypePtr;
Var FBbs:Text;
   TempDescTypePtr:DescTypePtr;
   Found:Boolean;
   TempPCB: Boolean;
Begin
   Assign(Fbbs,PathFBbs);
   {$I-}
   Reset(FBbs);
   {$I+}
   if IOResult=0 then
   begin
      Found := False;
      TempPCB := False;
      TempDescTypePtr := Nil;
      while not eof(FBbs) do
      begin
         Readln(FBbs,TempStr);
         if (TempStr<>'') and (TempStr[1]<>' ') then
         begin
            {e' il nome di un file}
            I := 1;
            while (I<=length(TempStr)) and (TempStr[I]<>' ') do
            begin
               TempStr[I] := UpCase(TempStr[I]);
               inc(I);
            end;
            if I<=length(TempStr) then
            begin
               Found := Pos(Name+' ',TempStr)=1;
            end else
            begin
               Found := Name=TempSTr;
            end;
            if found then
            begin
               CancellaDescrizione(TempDescTypePtr);
               delete(TempStr,1,I);
               StripLeadingSpace(TempStr);

               I := 1;
               While (I<=length(TempStr)) and (TempStr[I] in ['0'..'9']) do
                  inc(I);
               if (I<=length(TempStr)) and (tempStr[I]=' ') then
               begin
                  While (I<=length(TempStr)) and (TempStr[I]=' ') do
                     inc(I);
                  if (I<=length(TempStr)) and (tempStr[I] in ['0'..'9']) then
                  begin
                     While (I<=length(TempStr)) and (TempStr[I] in ['0'..'9','-']) do
                       inc(I);
                     if (I<=length(TempStr)) and (tempStr[I]=' ') then
                     begin
                        While (I<=length(TempStr)) and (TempStr[I]=' ') do
                           inc(I);
                        Delete(TempStr,1,I-1);
                        TempPCB := True
                     end else
                        TempPCB := False;
                  end else
                     TempPCB := False;
               end else
                  TempPCB := False;

               PosDesc := 1;
               L := TempStr;
               if L<>'' then
               begin
                  if pos(TempStr[1],DlLimit1)>0 then
                  begin
                     Delete(TempStr,1,1);
                     StripLeadingSpace(TempStr);
                     while (TempStr<>'') and (TempStr[1] in ['0'..'9']) do
                     begin
                        Delete(TempStr,1,1)
                     end;
                     StripLeadingSpace(TempStr);
                     if (TempStr<>'') and (Pos(TempStr[1],DlLimit2)>0) then
                     begin
                        Delete(TempStr,1,1);
                        StripLeadingSpace(TempStr);
                        L := TempStr;
                        {download counter valido}
                     end else
                     begin
                        TempStr := L;
                     end;
                  end;
                  if (TempStr<>'') then
                  begin
                     if TempStr[1]='/' then
                     begin
                        Delete(TempStr,1,1);
                        if (TempStr<>'') then
                        begin
                           Delete(TempStr,1,1);
                           if (TempStr<>'') then
                           begin
                              if UpCase(TempStr[1])='T' then
                              begin
                                 Delete(TempStr,1,1);
                                 if (TempStr<>'') and (UpCase(TempStr[1])='B') then
                                    Delete(TempStr,1,1);
                                 StripLeadingSpace(TempStr);
                                 L := TempStr
                              end else
                              if UpCase(TempStr[1])='B' then
                              begin
                                 delete(TempStr,1,1);
                                 StripLeadingSpace(TempStr);
                                 L := TempStr
                              end;
                           end;
                        end;
                        if (TempStr<>'') and (UpCase(TempStr[1])='B') then
                        begin
                           Delete(TempStr,1,1)
                        end;
                        StripLeadingSpace(TempStr);
                        L := TempStr
                     end;
                  end;
               end;
               PutDescrizione(TempDescTypePtr);
            end;
         end else
         begin
            if found then
            begin
               {lo scrive solo se non e' la continuazione del file}
               {precedente che era stato cancellato}
               I := 1;
               While (I<=length(TempStr)) and (TempStr[I]=' ') do
                  inc(I);
               if I>length(TempStr) then
               begin
                  {commento vuoto}
                  Found := False;
               end else
               begin
                  if pos(TempStr[I],LdChar)=0 then
                  begin
                     {commento, non e' una descrizione estesa}
                     found := False;
                  end else
                  begin
                     inc(I);
                     if TempPCB and (I<=length(TempStr)) and (TempStr[I]=' ') then
                        inc(I);
                     PosDesc := I;
                     L := TempStr;
                     PutDescrizione(TempDescTypePtr);
                  end;
               end;
            end;
         end;
      end;
      Close(FBbs);
      GetDesc := TempDescTypePtr;
   end else
      GetDesc := Nil;
End {GetDEsc};


Function AddFBbsLine(PathCopyFBbs, DestName:String; Descrizione:DescTypePtr;
   Sort:SortType; Replaces:DescTypePtr):Boolean;
Var FBBs, NewFBbs:Text;
    Found:Boolean;
    TempFBbs:String;
    TempDescTypePtr:DescTypePtr;
    TempStr, TempStr1, TempStr2: String;
    Inserted:Boolean;
    XPos: Byte;

    Procedure WriteLine(TempStr1: String);
    Var TempStr2: String;
    begin
       While (TempStr1<>'') do
       begin
          TempStr2 := TempStr1;
          if (Length(TempStr1) > FBbsLen - XPos +1) then
          begin
             {la linea e' troppo lunga, va spezzata in linee}
             {piu' brevi}
             TempStr2 := Copy(TempStr1,1,FBbsLen - XPos +1);
             if (TempStr2[length(TempStr2)] = ' ') then
             begin
                While (TempStr2<>'') and (TempStr2[length(TempStr2)]=' ') do
                   dec(TempStr2[0]);
                if TempStr2='' then
                begin
                   {questa condizione non si puo' mai verificare}
                   TempStr2 := Copy(TempStr1,1,FBbsLen - XPos +1);
                end;
             end else
             if (TempStr1[FBbsLen - XPos + 2]<>' ') then
             begin
                {cerca la prima posizione con lo spazio}
                While (TempStr2<>'') and (TempStr2[length(TempStr2)]<>' ') do
                   dec(TempStr2[0]);
                {ed ora rimuove gli spazi}
                While (TempStr2<>'') and (TempStr2[length(TempStr2)]=' ') do
                   dec(TempStr2[0]);
                if TempStr2='' then
                begin
                   TempStr2 := Copy(TempStr1,1,FBbsLen - XPos +1);
                end;
             end;
          end else
             TempStr2 := TempStr1;
          Writeln(NewFBbs,TempStr2);
          Delete(TempStr1,1,length(TempStr2));
          StripLeadingSpace(TempStr1);
          if (TempStr1<>'') then
          begin
             if SAvePCB then
             begin
                Write(NewFBbs,'':31,LdChar[1],' ');
                XPos := 34;
             end else
             begin
                write(NewFBbs,'':ExtDescPos,LdChar[1]);
                XPos := ExtDescPos + 2;
             end;
          end;
       end;
    end {writeline};

Begin
   TempFBbs := PathCopyFBbs;
   while (TempFBbs<>'') and
       (TempFBbs[length(TempFBbs)]<>'\') do
      dec(TempFBbs[0]);
   TempFBbs := TempFBbs + 'TempFBbs' + AppExt;
   Assign(NewFBbs,TempFBbs);
   {$I-}
   Rewrite(NewFBbs);
   {$I+}
   if IOResult=0 then
   begin
      Inserted := False;
      assign(FBbs,PathCopyFBbs);
      {$I-}
      Reset(FBbs);
      {$I+}
      if IOResult=0 then
      begin
         Found := False;
         while not eof(FBbs) do
         begin
            Readln(FBbs,TempStr);
            if (TempStr<>'') and (TempStr[1]<>' ') then
            begin
               {e' il nome di un file}
               I := 1;
               while (I<=length(TempStr)) and (TempStr[I]<>' ') do
               begin
                  TempStr[I] := UpCase(TempStr[I]);
                  inc(I);
               end;
               if not inserted and
                  ((Sort=Date) or ((sort=alfa) and (DestName<TempStr))) then
               begin
                   Write(NewFBbs,DestName);
                   if Descrizione=Nil then
                   begin
                      Writeln(NewFBbs)
                   end else
                   begin
                      if SavePCB then
                      begin
                         Write(NewFBbs,'':13-length(DestName));
                         XPos := 14;
                      end else
                      begin
                         Write(NewFBbs,'':15-length(DestName));
                         XPos := 16;
                      end;
                      while Descrizione<>Nil do
                      begin
                         TempStr1 := Descrizione^.Descrizione^;
                         WriteLine(TempStr1);
                         Descrizione := Descrizione^.Next;
                         if Descrizione<>Nil then
                         begin
                            if SAvePCB then
                            begin
                               Write(NewFBbs,'':31,LdChar[1],' ');
                               XPos := 34;
                            end else
                            begin
                               write(NewFBbs,'':ExtDescPos,LdChar[1]);
                               XPos := ExtDescPos + 2;
                            end;
                         end;
                      end;
                   end;
                   inserted := True;
               end;
               if I<=length(TempStr) then
               begin
                  Found := Pos(DestName+' ',TempStr)=1;
               end else
               begin
                  Found := DestName=TempSTr;
               end;
               if Not found then
               begin
                  {puo' darsi che sia comunque tra i replaces}
                  TempDescTypePtr := Replaces;
                  TempStr1 := TempStr;
                  ExpandWildCards(TempStr1);
                  While not found and (TempDescTypePtr<>Nil) do
                  begin
                     TempStr2 := TempDescTypePtr^.Descrizione^;
                     ExpandWildcards(TempStr2);
                     Found := MatchFileSpec(TempStr1,TempStr2);
                     TempDescTypePtr := TempDescTypePtr^.Next;
                  end;
               end;
               if not found then
                  Writeln(NewFBbs,TempStr);
            end else
            begin
               if not found then
               begin
                  Writeln(NewFBbs,TempStr);
               end else
               begin
                  {lo scrive solo se non e' la continuazione del file}
                  {precedente che era stato cancellato}
                  I := 1;
                  While (I<=length(TempStr)) and (TempStr[I]=' ') do
                     inc(I);
                  if I>length(TempStr) then
                  begin
                     {commento vuoto}
                     Writeln(NewFBbs,TempStr);
                     found := False;
                  end else
                  begin
                     if pos(TempStr[I],LdChar)=0 then
                     begin
                        {commento, non e' una descrizione estesa}
                        Writeln(NewFBbs,TempStr);
                        found := False
                     end
                  end;
               end;
            end;
         end;
         Close(FBbs);
         {$I-}
         Erase(FBbs);
         {$I+}
         if IOResult=0 then;
      end;
      if not inserted then
      begin
          Write(NewFBbs,DestName);
          if Descrizione=Nil then
          begin
             Writeln(NewFBbs)
          end else
          begin
             if SavePCB then
             begin
                Write(NewFBbs,'':13-length(DestName));
                XPos := 14;
             end else
             begin
                Write(NewFBbs,'':15-length(DestName));
                XPos := 16;
             end;
             while Descrizione<>Nil do
             begin
                TempStr1 := Descrizione^.Descrizione^;
                WriteLine(TempStr1);
                Descrizione := Descrizione^.Next;
                if Descrizione<>Nil then
                begin
                   if SAvePCB then
                   begin
                      Write(NewFBbs,'':31,LdChar[1],' ');
                      XPos := 34;
                   end else
                   begin
                      write(NewFBbs,'':ExtDescPos,LdChar[1]);
                      XPos := ExtDescPos + 2;
                   end;
                end;

             end;
          end;
          inserted := True
      end;
      close(NewFBbs);
      {$I-}
      Rename(NewFbbs,PathCopyFBbs);
      {$I+}
      AddFBbsLine := IOResult=0;
   end else
   begin
      AddFBbsLine := False;
   end;
End {AddFBbsLine};

Function ClearScreen:Boolean;
Begin
   TextAttr := StartAttr;
   ClrScr;
   GotoXY(1,10);
   ClearScreen := True;
End {ClearScreen};

Procedure AddRecfb(AreaNum: Word; Name: String; FTime, FSize: Longint;
   Descrizione: DescTypePtr);
Var
   fb: FbManagePtr;
begin
   fb := New (fbManagePtr, Init(AreaNum));
   fb^.Append;
   if fb^.FbIOResult=0 then
   begin
      fb^.WriteRec(Name, FTime, FSize, 0, Descrizione);
   end;
   dispose(fb , done);
end;

Function CopyFile(Name:String; Size,FTime:LongInt; Descrizione:DescTypePtr;
   Var Move:Boolean; Replaces:DescTypePtr; AreaNum: Word): String;
Var fm:Word;
    Source,Dest:File;
    Buf:Pointer;
    {$IFDEF VIRTUALPASCAL}
    Result, TempWord: Longint;
    {$ELSE}
    result:word;
    {$ENDIF}
    Ch:Char;
    Blocks:Longint;
    Drive:Byte;
    DestName, TempFBbs:String;
    FirstRen, NoRen:Boolean;
    PercCopied:LongInt;
    LastError:Word;
    TempCopyFile:String;
    SizeBuf:Longint;
    Done:Boolean;
    FreeSpace: Longint;

begin
   {Controlla se esite il file di destinazione}
   DestName := Name;
   FirstRen := True;
   NoRen := False;

   While not NoRen and FileExist(PathCopy+DestName) do
   begin
      if FirstRen then
      begin
         if DestName[length(DestName)]<>'1' then
            DestName[length(DestName)] := '1'
         else
            DestName[length(DestName)] := '2';
         FirstRen := False;
      end else
      if DestName[length(DestName)] in ['1'..'8'] then
         inc(DestName[length(DestName)])
      else
      if DestName[length(DestName)] ='9' then
         DestName[length(DestName)] := 'A'
      else
      if DestName[length(DestName)] in ['A'..'E'] then
         inc(DestName[length(DestName)])
      else
      begin
         NoRen := True
      end;
   end;

   if Not NoRen then
   begin

      if ZeroDc then
      begin
         TempStr := Descrizione^.Descrizione^;
         FreeMem(Descrizione^.Descrizione,length(Descrizione^.Descrizione^)+1);
         TempStr := DlLimit1[1] + Long2Str(0,DcLen) + DlLimit2[1] + ' ' +
            TempStr;
         GetMem(Descrizione^.Descrizione,length(TempStr)+1);
         Descrizione^.Descrizione^ := TempStr;
      end;

      if SAvePCB then
      begin
         {modifica la prima riga di descrizione, mette SIZE e DATA}
         UnpackTime(FTime,T1);
         TempStr := Long2Str(Size,8) + '  ' + NStr[T1.Month] +
            '-' + NStr[T1.Day] + '-' + NStr[T1.Year mod 100] + '  ' +
            Descrizione^.Descrizione^;
         FreeMem(Descrizione^.Descrizione,length(Descrizione^.Descrizione^)+1);
         GetMem(Descrizione^.Descrizione,length(TempStr)+1);
         Descrizione^.Descrizione^ := TempStr;
      end;

      Repeat
         Writeln(' * Append description to ',PathCopyFBbs);
         Writeln(LogFile,Prelog(LogStart),'Append description to ',PathCopyFBbs);
         Flush(LOgFile);
         if (bbs=Ra250) and (AreaNum<>0) then
            AddRecfb(AreaNum, DestName, FTime, Size, Descrizione)
         else
         if AddFBbsLine(PathCopyFBbs,DestName,Descrizione,FixFBbsSort,Replaces)
            then;
         assign(Source,PathDown+Name);
         if Move then
         begin
            {$I-}
            Rename(Source,PathCopy+DestName);
            {$I+}
            LastError := IOResult;
            if LastError=0 then
            begin
               Writeln(' * Move to ',PathCopy,DestName);
               Writeln(LogFile,Prelog(LogStart),'Move to ',PathCopy,DestName);
               Flush(LOgFile);
               Assign(Source,PathCopy+DestName);
               fm := FileMode;
               FileMode := FmReadWrite_DA;
               {$I-}
               Reset(Source,1);
               {$I+}
               if IOResult=0 then
               begin
                  {$I-}
                  SetFTime(Source,FTime);
                  {$I+}
                  if ioresult<>0 then;
                  Close(Source);
               end;
               FileMode := Fm;
               Done := True;
            end else
               Done := False;
         end;

         if Not Move or Not Done then
         begin
            fm := FileMode;
            FileMode := fmReadOnly_DW;
            {$I-}
            Reset(Source,1);
            {$I+}
            LastError := IOResult;
            FileMode := Fm;
            if LastError=0 then
            begin
               assign(dest,PathCopy+DestName);
               fm := FileMode;
               FileMode := FmReadWrite_DA;
               {$I-}
               Rewrite(Dest,1);
               {$I+}
               LastError := IOREsult;
               FileMode := fm;

               FreeSpace := DiskFree(Ord(UpCase(PathCopy[1]))-ord('A')+1);

               Write(' * Copy to ',PathCopy,DestName,' (',Size,' / ',FreeSpace,') ... ');
               Writeln(LogFile,Prelog(LogStart),'Copy to ',PathCopy,DestName,' (',Size,' / ',FreeSpace,')');
               Flush(LogFile);

               if lasterror=0 then
               begin
                  {Controlla lo spazio disponibile sul drive di destinazione}

                  if FreeSpace >= Size then
                  begin
                     Blocks := 0;
                     SizeBuf := MaxAvail;
                     if SizeBuf>32768 then
                        SizeBuf := 32768;
                     getmem(buf,SizeBuf);
                     while not eof(Source) and (LastError=0) do
                     begin
                        Inc(Blocks);
                        blockread(Source,Buf^,SizeBuf,Result);
                        {$I-}
                        blockwrite(Dest,Buf^,Result,TempWord);
                        {$I+}
                        LastError := IOResult;
                        PercCopied := Blocks * SizeBuf * 100 div Size;
                        If PercCopied>100 then
                           PercCopied := 100;
                        write(PercCopied:3,'%',#8#8#8#8);
                     end;
                     freemem(buf,SizeBuf);
                  end else
                  begin
                     {spazio rimasto non sufficiente}
                     LastError := $1D
                  end;

                  Close(Dest);
                  Write(#8#8#8#8,'':8);

                  if LastError<>0 then
                  begin
                     {cancella il file, che non e' stato copiato bene}
                     {$I-}
                     Erase(Dest);
                     {$I+}
                     if ioresult<>0 then;
                  end else
                  begin
                     fm := FileMode;
                     FileMode := FmReadWrite_DA;
                     {$I-}
                     Reset(Dest,1);
                     {$I+}
                     if IOResult=0 then
                     begin
                        {$I-}
                        SetFTime(Dest,FTime);
                        {$I+}
                        if ioresult<>0 then;
                        close(Dest);
                     end;
                     FileMode := Fm;
                  end;
               end;

               close(Source);
               writeln;

               if (LastError=0) then
               begin
                  if move then
                  begin
                     {$I-}
                     Erase(Source);
                     {$I+}
                     LastError := IOResult;
                     Move := LastError=0;
                     if Move then
                     begin
                        Writeln(' * Deleted ',PathDown+Name);
                        Writeln(LogFile,Prelog(LogStart),'Deleted ',PathDown+Name);
                        Flush(LOgFile);
                     end else
                     begin
                        {$I-}
                        Erase(Dest);
                        {$I+}
                        if ioresult<>0 then;
                     end;
                  end;
               end;
            end;
         end;
         if LastError<>0 then
         begin
            Writeln(' * ',ErrorMsg(LastError));
            Writeln(LogFile,Prelog(LogError),ErrorMsg(LastError));
            Flush(LOgFile);
            TempCopyFile := '';
         end else
         begin
            TempCopyFile := DestName;
         end;

      Until (LListStatus<>EditFilesBbs) or (TempCopyFile<>'') or
         (Size=0) or
         not (Conferma('Retry') and ClearScreen);

      if SavePCB then
      begin
         {ripristina la descrizione originale}
         TempStr :=  Descrizione^.Descrizione^;
         FreeMem(Descrizione^.Descrizione,length(TempStr)+1);
         Delete(TempStr,1,20);
         GetMem(Descrizione^.Descrizione,length(TempStr)+1);
         Descrizione^.Descrizione^ := TempStr;
      end;

      if ZeroDc then
      begin
         TempStr :=  Descrizione^.Descrizione^;
         FreeMem(Descrizione^.Descrizione,length(TempStr)+1);
         Delete(TempStr,1,2 + DcLen + 1);
         GetMem(Descrizione^.Descrizione,length(TempStr)+1);
         Descrizione^.Descrizione^ := TempStr;
      end;

      CopyFile := TempCopyFile;
   end else
   begin
      CopyFile := '';
      Writeln(' * ',PathCopy+DestName,' already exists');
      Writeln(LogFile,Prelog(LogError),PathCopy+DestName,' already exists');
      Flush(LogFile);
   end;
end {CopyFile};

Function GetDestPath(Int:String): Boolean;
Var PrevNumero:Integer;
   PrevPathFBbs, PrevPathDown, PrevNome:String;
Begin
   PrevNumero := Numero;
   PrevPathDown := PathDown;
   PrevPathFBbs := PathFBbs;
   PrevNome := Nome;
   GetDestPath := GetArea(Int,False) and
      (PathDown<>PrevPathDown) and (PrevPathFbbs<>PathFBbs);
   PathCopy := PathDown;
   PathCopyFBbs := PathFBbs;
   NumberCopy := Numero;
   Numero := PrevNumero;
   PathDown := PrevPathDown;
   PathFbbs := PrevPathFBbs;
   Nome := PrevNome;
End {GetDestPath};

end.
