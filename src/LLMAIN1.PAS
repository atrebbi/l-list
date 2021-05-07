Unit LLMAIN1;

{$I LL.DEF}

Interface

Uses Crt, Dos, MkMisc, LLTEND, LLGEN, LLCOLORS, LLMouse;

   Procedure GetBuffer(Start, ScreenLines:Integer;
        Var InizioLista:ListaPtr);
   Procedure ShowBuffer(NLines, ScreenLines, LocalNumero:Integer;
      Var NomeArea:String;
      NFiles, AllSize:Longint);
   Procedure EditLineFBbs(Var StartAt:Integer; Var L:String;
      Var PosStr:Integer; IsDesc,FirstDescLine:Boolean;
      Var FreeDlByte, FreeDlTime:Boolean; Var Download:Integer;
      ScreenLines, SkipDescLines: integer; Var NextLine:String;
      LocalNumero: Integer;
      Var NomeArea:String;
      NFiles, AllSize:Longint;
      Var ModifiedFilesBbs:Boolean; FirstCol: Byte);
   Procedure ShowHelp;
   Procedure TagMissing(Pnt:ListaPtr; Var TaggedList:ListaPtr;
      Var NTaggedFiles, TaggedSize:Longint);
   Procedure TagNew(Var TaggedList, InizioLista:ListaPtr;
      Var NTaggedFiles, TaggedSize:Longint);

implementation

   Procedure GetBuffer(Start, ScreenLines:Integer;
        Var InizioLista:ListaPtr);
      Var I:Integer;
      Procedure GetBuffer1(Pnt:ListaPtr);
      begin
         if Pnt<>Nil then
         begin
            GetBuffer1(Pnt^.Sx);
            if Start<ScreenLines then
            begin
               if (Pnt^.FileInfo<>Nil) and not Pnt^.FileInfo^.Excluded then
               begin
                  inc(Start);
                  if Start>=0 then
                     Lines[Start] := Pnt^.FileInfo;
               end;
               GetBuffer1(Pnt^.Dx)
            end;
         end;
      end {GetBuffer1};
   begin
      Start := -Start;
      GetBuffer1(InizioLista);
      if Start<-1 then
         Start := -1;
      for I := Start+1 to LenPage do
         Lines[I] := Nil;
   end {GetBuffer};

   Procedure ShowBuffer(NLines, ScreenLines, LocalNumero:Integer;
       Var NomeArea:String;
       NFiles, AllSize: Longint);
   Var Posizione1,Posizione2:Longint;
      TempStr:String;
      TempDesc:DescTypePtr;
      Var I,J,N,K:Integer;
      FirstLine:Boolean;
      NewAttr: Byte;
   begin
      HideCursor;
      GotoXY(1,1);
      InvVideo;
      write(' #',LocalNumero:3,' ³ ',NomeArea,'':52-length(NomeArea),
          '':4, NFiles:4,' ',BytesStr(AllSize):11);
      {E' una riga precisa, quindi e' gia' a capo, 1:2}
      NLines := -NLines;
      N := 1;
      K := 0;
      while (NLines<ScreenLines-2) and (Lines[N]<>Nil) do
      begin
         if (Lines[N]^.Tagged) then
            HighVideo
         else
         if (Lines[N]^.Nome<>'') and (Lines[N]^.Size=0) then
            LowVideo
         else
            NormVideo;
         if NLines>=0 then
         begin
            if (Lines[N]^.Nome<>'') then
            begin
               write(Lines[N]^.Nome,'':13-length(Lines[N]^.Nome));
               if SAvePCB then
               begin
                  {Scrive anche size e data nel Files.Bbs}
                  UnpackTime(Lines[N]^.Time,T1);
                  Write(Lines[N]^.Size:8,'  ',NStr[T1.Month],'-',
                     NStr[T1.Day],'-',NStr[T1.Year mod 100],' ');
               end;
               write(' ');
            end else
               Write(' ');
         end;
         FirstLine := True;
         TempDesc:=Lines[N]^.Descrizione;
         if (Lines[N]^.Tagged) then
            HighVideo
         else
         if (Lines[N]^.Nome<>'') and (Lines[N]^.Size=0) then
            LowVideo
         else
            NormVideo;
         Repeat
            Inc(NLines);
            inc(K);
            if NLines>=1 then
            begin
               if (TempDesc<>Nil) and (Nlines<=ScreenLines-2) then
               begin
                  if FirstLine and (Lines[N]^.Nome<>'') then
                  begin
                     if (Lines[N]^.Download>0) or ZeroDC then
                     begin
                        Str(Lines[N]^.Download:DcLen,TempStr);
                        TempStr := DlLimit1[1] + TempStr + dlLimit2[1] + ' '
                     end else
                        TempStr := '';
                     if Lines[N]^.FreeDlTime then
                     begin
                        if Lines[N]^.FreeDlByte then
                           TempStr := TempStr + '/tb '
                        else
                           TempStr := TempStr + '/t ';
                     end else
                     if Lines[N]^.FreeDlByte then
                        TempStr := TempStr + '/b ';
                  end else
                     TempStr := '';
                  TempStr := TempStr + TempDesc^.Descrizione^;

                  FilesOnLine[WhereY] := N;
                  StartDesc[WhereY] := WhereX;
                  DescLine[WhereY] := K;
                     if length(TempStr)>80-WHereX then
                     begin
                        Byte(TempStr[0]) := 80-WhereX;
                        TempStr[80-WhereX] := '¯';
                     end;
                     J := pos(ColorId,TempStr);
                     while J>0 do
                     begin
                        inc(J,2);
                        if ColorId[1]='@' then
                        begin
                           if (J<=length(TempStr)) then
                           begin
                              inc(J);
                              if J<=length(TempStr) then
                                 NewAttr := 16*GetHex(TempStr[J-1]) + GetHex(TempStr[J])
                           end;
                        end else
                        begin
                           if (J<=length(TempStr)) then
                           begin
                              if TempStr[J]=#16 then
                              begin
                                 inc(J);
                                 if (J<=length(TempStr)) then
                                    NewAttr := Byte(TempStr[J]) - 128;
                              end else
                                 NewAttr := Byte(TempStr[J]);
                           end;
                        end;
                        Write(Copy(TempStr,1,J));
                        delete(TempStr,1,J);
                        TextAttr := NewAttr;
                        J := pos(ColorId,TempStr);
                     end;
                     write(TempStr);
                     Writeln('':80-WhereX);
                  if (Lines[N]^.Tagged) then
                     HighVideo
                  else
                  if (Lines[N]^.Nome<>'') and (Lines[N]^.Size=0) then
                     LowVideo
                  else
                     NormVideo;
               end;
            End;
            TempDesc := TempDesc^.Next;
            if (TempDesc<>Nil) and (NLines<ScreenLines-2) and (NLines>=0) then
            begin
               write(' ');
               if Lines[N]^.Nome<>'' then
               begin
                  if SAvePCB then
                  begin
                     Write('':30,LdChar[1],' ');
                  end else
                     write('':ExtDescPos-1,LdChar[1]);
               end;
            end;
            FirstLine := False;
         Until (TempDesc=Nil) or (NLines=ScreenLines-2);
         inc(N);
         K := 0;
      end;
      NormVideo;
      if (WhereY=ScreenLines) and (TempDesc<>Nil) then
         FilesOnLine[ScreenLines] := FilesOnLine[ScreenLines-1]
      else
      for I := WhereY to ScreenLines-1 do
      begin
         Writeln('':79);;
         FilesOnLine[I] := 0;
      end;

      if FilesOnLine[2]=0 then
      begin
         Posizione1 := ScreenLines-4;
      end else
      begin
         if Lines[FilesOnLine[2]]^.NList<=0 then
         begin
            {Primo file}
            Posizione1 := 1;
         end else
         if Lines[FilesOnLine[2]]^.NList=NFiles-1 then
         begin
            {Ultimo file}
            Posizione1 := ScreenLines - 4;
         end else
         begin
            Posizione1 := (Lines[FilesOnLine[2]]^.Nlist + 1) * (ScreenLines -6) div
               (NFiles);
            if Posizione1<=1 then
               Posizione1 := 2;
            if Posizione1 >= ScreenLines-4 then
               Posizione1 := ScreenLines -5;
         end;
      end;

      if FilesOnLine[ScreenLines-1]=0 then
      begin
         Posizione2 := ScreenLines-4;
      end else
      begin
         if Lines[FilesOnLine[ScreenLines-1]]^.NList<=0 then
         begin
            {Primo file}
            Posizione2 := 1;
         end else
         if Lines[FilesOnLine[ScreenLines-1]]^.NList=NFiles-1 then
         begin
            {Ultimo file}
            Posizione2 := ScreenLines - 4;
         end else
         begin
            Posizione2 := (Lines[FilesOnLine[ScreenLines-1]]^.Nlist + 1) * (ScreenLines -6) div
               (NFiles);
            if Posizione2<=1 then
               Posizione2 := 2;
            if Posizione2 >= ScreenLines-4 then
               Posizione2 := ScreenLines -5;
         end;
      end;

      GotoXY(80,2);
      Write(#30);

      For I := 1 to Posizione1 -1 do
      begin
         GotoXY(80,I+2);
         Write('°');
      end;

      for I := POsizione1 to Posizione2 do
      begin
         GotoXY(80,I+2);
         Write('²');
      end;

      for I := POsizione2 + 1 to ScreenLines-4 do
      begin
         GotoXY(80,I+2);
         Write('°');
      end;

      GotoXY(80,ScreenLines-1);
      Write(#31);

      GotoXY(1,2);
      ShowCursor;
   end {ShowBuffer};

   Procedure EditLineFBbs(Var StartAt:Integer; Var L:String;
      Var PosStr:Integer; IsDesc,FirstDescLine:Boolean;
      Var FreeDlByte, FreeDlTime:Boolean; Var Download:Integer;
      ScreenLines, SkipDescLines: integer; Var NextLine:String;
      LocalNumero: Integer;
      Var NomeArea:String;
      NFiles, AllSize:Longint;
      Var ModifiedFilesBbs:Boolean; FirstCol: Byte);
   Var Skip:Byte;
      TempStr,L1:String;
      Ch:Char;
      Temp:integer;
      Done:Boolean;
      I,J,K:Integer;
      Attr: Byte;
      TempDl, PrevDl:Integer;
      TempFreeDlTime, TempFreeDlByte: Boolean;
      NewAttr : Byte;
   begin
      PrevDl := DownLoad;
      dec(PosStr,StartAt);
      inc(PosStr);
      if PosStr<1 then
         PosStr := 1;
      if IsDesc and FirstDescLine then
      begin
         if (Download>0) or ZeroDc then
         begin
            Str(Download:DcLen,TempStr);
            TempStr := DlLimit1[1] + TempStr + dlLimit2[1] + ' '
         end else
            TempStr := '';
         if FreeDlTime then
         begin
            if FreeDlByte then
               TempStr := TempStr + '/tb '
            else
               TempStr := TempStr + '/t ';
         end else
         if FreeDlByte then
            TempStr := TempStr + '/b ';
      end else
         TempStr := '';

      L1 := TempStr + L;

      Skip := 0;
      while PosStr>length(L1)+1 do
         L1 := L1 + ' ';
      Done := False;
      Attr := TextAttr;
      repeat
         HideCursor;
         Temp := WhereY;
         gotoXY(70,ScreenLines);
         InvVideo;
         Write(PosStr+StartAt-1:3);
         GotoXY(1,Temp);
         if (Skip>0) and (PosStr=Skip+1) then
            dec(Skip);
         TempStr := Copy(L1,Skip+1,255);
         if Skip>0 then
            TempStr[1] := '®';
         if length(TempStr)>80-StartAt then
         begin
            if PosStr=80-StartAt+Skip then
            begin
               inc(Skip);
               TempStr := Copy(L1,Skip+1,255);
               TempStr[1] := '®';
               if length(TempStr)>80-StartAt then
               begin
                  TempStr := Copy(TempStr,1,80-StartAt);
                  TempStr[80-StartAt] := '¯';
               end;
            end else
            begin
               TempStr := Copy(TempStr,1,80-StartAt);
               TempStr[80-StartAt] := '¯';
            end;
         end;
         GotoXY(StartAt,WhereY);
         {deve prima determinare il colore di partenza}
         TextAttr := FirstCol;
         I := 1;
         if Skip>0 then
         begin
            Write(Tempstr[1]);
            Delete(TempStr,1,1);
            while (I<=Skip+1) and (I<=Length(L1)) do
            begin
               if L1[I]=ColorId[1] then
               begin
                  {inizio codice colore?}
                  inc(I);
                  if L1[I]=ColorId[2] then
                  begin
                     inc(I);
                     if ColorId[1]='@' then
                     begin
                        if I<=length(L1) then
                        begin
                           inc(I);
                           if I<=length(L1) then
                           begin
                              NewAttr := 16*GetHex(L1[I-1])+GetHex(L1[I]);
                           end;
                        end;
                     end else
                     begin
                        if (I<=length(L1)) then
                        begin
                           if L1[I]=#16 then
                           begin
                              inc(I);
                              if (I<=length(L1)) then
                                 NewAttr := Byte(L1[I]) - 128;
                           end else
                              NewAttr := Byte(L1[I]);
                        end;
                     end;
                     if I>Skip+1 then
                     begin
                        {un pezzo di stringa va scritta subito}
                        Write(Copy(TempStr,1,I-Skip-1));
                        Delete(TempStr,1,I-Skip-1);
                     end;
                     TextAttr := NewAttr
                  end
               end;
               inc(I);
            end;
         end;
         K := pos(ColorId,TempStr);
         while K>0 do
         begin
            inc(K,2);
            if ColorId[1]='@' then
            begin
               if K<=length(TempStr) then
               begin
                  inc(K);
                  if K<=length(TempStr) then
                  begin
                     NewAttr := 16*GetHex(TempStr[K-1])+GetHex(TempStr[K]);
                  end;
               end;
            end else
            begin
               if (K<=length(TempStr)) then
               begin
                  if TempStr[K]=#16 then
                  begin
                     inc(K);
                     if (K<=length(TempStr)) then
                        NewAttr := Byte(TempStr[K]) - 128;
                  end else
                     NewAttr := Byte(TempStr[K]);
               end;
            end;
            Write(Copy(TempStr,1,K));
            delete(TempStr,1,K);
            TextAttr := NewAttr;
            K := pos(ColorId,TempStr);
         end;
         write(TempStr);
         Write('':80-WhereX);
         NormVideo;

         GotoXY(StartAt+PosStr-Skip-1,WhereY);
         ShowCursor;

         waitevent;

         if KeyPressed then
         begin
            Ch := ReadKey;
            if Ch=#0 then
            begin
               Ch := ReadKey;
               case ch of
                  #77:{Right}
                     if PosStr < fbbslen - startat + 1 then
                     begin
                        if PosStr>length(L1) then
                           L1 := L1 + ' ';
                        inc(PosStr);
                        if PosStr-Skip > 80 - StartAt then
                        begin
                           inc(Skip)
                        end;
                     end;
                  #75:{Left}
                      if (PosStr>1) then
                      begin
                         dec(PosStr);
                         if (PosStr=length(L1)) and (L1[PosStr]=' ') then
                            dec(L1[0]);
                         if (PosStr=Skip) then
                            dec(Skip)
                      end else
                      begin
                         dec(PosStr);
                         Done := True;
                      end;
                  #94..#103:{Ctrl-F<n>=Macro in KbdBuffer}
                  begin
                     KbdBuffer := Macro[Ord(Ch)-93];
                  end;
                  #84:{Shift-F1, Color AVT}
                      Begin
                         I := WhereY;
                         TempStr := GetColorStr(2);
                         for J := 1 to length(TempStr) do
                         begin
                            if TempStr[J] >= #32 then
                               KbdBuffer := KbdBuffer + TempStr[J]
                            else
                               KbdBuffer := KbdBuffer + #16 + TempStr[J]
                         end;
                         ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,
                            NFiles,AllSize);
                         GotoXY(1,I);
                      End;
                  #85:{Shift-F2, Ascii code}
                      Begin
                         I := WhereY;
                         KbdBuffer := GetAscii;
                         if KbdBuffer<>'' then
                            KbdBuffer := KbdBuffer + #0 + #85;
                         ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,
                            NFiles,AllSize);
                         GotoXY(1,I);
                      End;
                  #79:{End}
                      Begin
                         PosStr := length(L1) + 1;
                         while PosStr-Skip > 80 - StartAt do
                         begin
                            inc(Skip)
                         end;
                      end;
                  #83:{cancella quello che sta avanti}
                      if PosStr<=length(L1) then
                      begin
                         delete(l1,PosStr,1);
                      end else
                      begin
                         Done := True;
                         if (L1<>'') or not IsDesc then
                            KbdBuffer := #0 + #203;
                      end;
                    else
                    begin
                       Done := True;
                       KbdBuffer := #0 + Ch
                    end;
                end
            end else
            if ch=#25 then
            begin
               KbdBuffer := #25;
               Done := True
            end else
            if ch=#13 then
            begin
               if PosStr>1 then
               begin
                  NextLine := Copy(L1,PosStr,length(L1)-PosStr+1);
                  L1 := Copy(L1,1,PosStr-1);
                  Done := True;
                  KbdBuffer := #0 + #202 + #0 + #80 + #0 + #200;
               end else
               begin
                  NextLine := L1;
                  L1 := '';
                  Done := True;
                  KbdBuffer := #0 + #202 + #0 + #80;
                  PosStr := 1;
               end;
               if not IsDesc then
                  dec(PosStr);
            end else
            if ch=#27 then
            begin
               kbdBuffer := #27;
               Done := True;
            end else
            if ch=#8 then
            begin
               {cancella}
               if PosStr>1 then
               begin
                  delete(L1,PosStr-1,1);
                  dec(PosStr);
                  if (PosStr=Skip) then
                     dec(Skip)
               end else
               if not FirstDescLine then
               begin
                  Done := True;
                  KbdBuffer := #0 + #72 + #0 + #205 + #0 + #79 + #0 + #203;
               end else
               begin
                  Done := True;
                  Dec(PosStr)
               end;
            end else
            if ch=#16 then
            begin
               {Ora chiede un carattere non stampabile}
               Ch := ReadKey;
               if (Ch<=#31) and (Ch<>#10) and (Ch<>#26) then
               begin
                  if PosStr<=length(L1) then
                  begin
                     Insert(Ch,L1,PosStr);
                  end else
                     L1 := L1 + Ch;
                  inc(PosStr);
                  if PosStr-Skip > 80 - StartAt then
                  begin
                     inc(Skip)
                  end;
               end;
               Ch := #0
            end else
            if Ch >= #32 then
            begin
               {carattere stampabile, lo aggiunge}
               if PosStr<=length(L1) then
               begin
                  Insert(Ch,L1,PosStr);
                  if length(L1) > FBbsLen - StartAt + 1 then
                     L1[0] := Chr(FbbsLen - StartAt + 1);
                  if posstr < FbbsLen - startat + 1 then
                     inc(PosStr)
               end else
               if PosStr <= FBbslen - startat + 1 then
               begin
                  L1 := L1 + Ch;
                  if posstr < FbbsLen - startat + 1 then
                     inc(PosStr)
               end;
               if PosStr-Skip > 80 - StartAt then
               begin
                  inc(Skip)
               end;
            end;
         end else
         begin
            ch := #0;
            KbdBuffer := '';
            Done := True;
         end;
      until (Done);

      while (L1<>'') and (L1[length(L1)]=' ') do
         dec(L1[0]);

      if IsDesc and FirstDescLine then
      begin
         StripLeadingSpace(L1);
         TempDl := 0;
         TempFreeDlByte := False;
         TempFreeDlTime := False;
         if L1<>'' then
         begin
            TempStr := L1;
            if Pos(TempStr[1],DlLimit1)>0 then
            begin
               Delete(TempStr,1,1);
               StripLeadingSpace(TempStr);
               while (TempStr<>'') and (TempStr[1] in ['0'..'9']) do
               begin
                  TempDl := TempDl * 10 + ord(TempStr[1]) - Ord('0');
                  Delete(TempStr,1,1)
               end;
               StripLeadingSpace(TempStr);
               if (TempStr<>'') and (Pos(TempStr[1],DlLimit2)>0) then
               begin
                  Delete(TempStr,1,1);
                  StripLeadingSpace(TempStr);
                  L1 := TempStr;
                  {download counter valido}
               end else
               begin
                  TempStr := L1;
                  TempDl := 0
               end;
            end;
            if (TempStr<>'') then
            begin
               if TempStr[1]='/' then
               begin
                  Delete(TempStr,1,1);
                  if (TempStr<>'') and (UpCase(TempStr[1])='T') then
                  begin
                     TempFreeDlTime := true;
                     Delete(TempStr,1,1)
                  end;
                  if (TempStr<>'') and (UpCase(TempStr[1])='B') then
                  begin
                     TempFreeDlByte := true;
                     Delete(TempStr,1,1)
                  end;
                  if TempFreeDlTime or TempFreeDlByte then
                  begin
                     StripLeadingSpace(TempStr);
                     L1 := TempStr
                  end;
               end;
            end;
         end;
         if DownLoad<>TempDl then
         begin
             Download := TempDl;
             ModifiedFilesBbs := True
         end;
         If FreeDlByte <> TempFreeDlByte then
         begin
            FreeDlByte := TempFreeDlByte;
            ModifiedFilesBbs := True
         end;
         If FreeDlTime <> TempFreeDlTime then
         begin
            FreeDlTime := TempFreeDlTime;
            ModifiedFilesBbs := True
         end;
      end;

      if ch=#27 then
         KbdBuffer := ch;

      if (L<>L1) then
      begin
         L := L1;
         ModifiedFilesBbs := True
      end;

      if IsDesc and FirstDescLine then
      begin
         if (Download>0) or ZeroDc then
         begin
            TempStr := DlLimit1[1] + Long2Str(Download,DcLen) + dlLimit2[1] + ' '
         end else
            TempStr := '';
         if FreeDlTime then
         begin
            if FreeDlByte then
               TempStr := TempStr + '/tb '
            else
               TempStr := TempStr + '/t ';
         end else
         if FreeDlByte then
            TempStr := TempStr + '/b ';
      end else
         TempStr := '';
      TempStr := TempStr + L;

      if length(TempStr)>80-StartAt then
      begin
         TempStr := Copy(TempStr,1,80-StartAt);
         TempStr[80-StartAt] := '¯';
      end;

      HideCursor;
      GotoXY(StartAt,WhereY);

      TextAttr := FirstCol;
      K := pos(ColorId,TempStr);

      while K>0 do
      begin
         inc(K,2);
         if ColorId[1]='@' then
         begin
            if K<=length(TempStr) then
            begin
               inc(K);
               if K<=length(TempStr) then
               begin
                  NewAttr := 16*GetHex(TempStr[K-1])+GetHex(TempStr[K]);
               end;
            end;
         end else
         begin
            if (K<=length(TempStr)) then
            begin
               if TempStr[K]=#16 then
               begin
                  inc(K);
                  if (K<=length(TempStr)) then
                     NewAttr := Byte(TempStr[K]) - 128;
               end else
                  NewAttr := Byte(TempStr[K]);
            end;
         end;
         Write(Copy(TempStr,1,K));
         delete(TempStr,1,K);
         TextAttr := NewAttr;
         K := pos(ColorId,TempStr);
      end;
      write(TempStr);
      Write('':80-WhereX);
      ShowCursor;

      PosStr := PosStr + StartAt - 1 - Skip;
   end {EditLineFBbs};




   Procedure TagMissing(Pnt:ListaPtr; Var TaggedList:ListaPtr;
      Var NTaggedFiles, TaggedSize:Longint);
   begin
      if Pnt<>Nil then
      begin
         TagMissing(Pnt^.Sx,TaggedList,NTaggedFiles, TaggedSize);
         if (Pnt^.FileInfo<>Nil) and (Pnt^.FileInfo^.Nome<>'') and (Pnt^.FileInfo^.Size=0) and
            not Pnt^.FileInfo^.Tagged then
         begin
            Pnt^.FileInfo^.Tagged := True;
            PutInListaNo(TaggedList,Pnt^.FileInfo);
            inc(NTaggedFiles);
            inc(TaggedSize,Pnt^.FileInfo^.Size);
         end;
         TagMissing(Pnt^.Dx,TaggedList,NTaggedFiles, TaggedSize);
      end;
   end {TagMissing};


   Procedure TagNew(Var TaggedList, InizioLista:ListaPtr;
      Var NTaggedFiles, TaggedSize:Longint);
   Var ChkDate:LongInt;
       Num:Integer;
       T1:DateTime;
       Days:Word;
      Procedure TagNew1(Pnt:ListaPtr; Var TaggedList:ListaPtr);
      begin
         if Pnt<>Nil then
         begin
            TagNew1(Pnt^.Sx,TaggedList);
            if (Pnt^.FileInfo<>Nil) and (Pnt^.FileInfo^.Nome<>'') and (Pnt^.FileInfo^.Time >= ChkDate) and
               not Pnt^.FileInfo^.Tagged then
            begin
               Pnt^.FileInfo^.Tagged := True;
               PutInListaNo(TaggedList,Pnt^.FileInfo);
               inc(NTaggedFiles);
               inc(TaggedSize,Pnt^.FileInfo^.Size);
            end;
            TagNew1(Pnt^.Dx,TaggedList);
         end;
      end {TagNew1};
   begin
      Num := Newdays;
      ReadBoxInteger('Days number',0,180,Num);
      if Num>0 then
      begin
         UnpackTime(ActDate,T1);
         JulianToGregorian(GregorianToJulian(T1)-Num,Integer(T1.Year),
            Integer(T1.Month),Integer(T1.Day));
         T1.Hour := 0;
         T1.Min := 0;
         T1.Sec := 0;
         PackTime(T1,ChkDate);
         TagNew1(InizioLista,TaggedList)
      end;
   end {TagNew};



   Procedure ShowHelp;
   Var
      MouInfo: MinfoRecType;
      ch: Char;
   Const
      MenuItem: Integer = 1;
   Const
      MaxItems = 34;
      MenuChar  : Array[1..maxitems] of string[2] =
         ( #0#59, #25,
           #0#60, #0#63,
           #0#67, #0#50,
           #0#47, #0#23,
           #0#25, #0#20,
           #0#18, #0#34,
           #0#129, #0#22,
           #0#62, #0#46,
           #0#49, #0#19,
           #0#30, #0#24,
           #0#17, #0#35,
           #0#48, #0#44,
           #0#32, #0#16,
           '', '',
           #0#84, #0#85,
           #0#37, #0#61,
           #27,   #0#31);
      MenuItems : Array[1..maxitems] of string [38] =
         ('F1    = View this help',             'Ctrl-Y = delete current line',
          'F2    = Save Files.Bbs',             'F5    = Look at Files.Bbs',
          'F9    = OS Shell',                   'Alt-M = Hurl tagged files',
          'Alt-V = View content',               'Alt-I = Import File_Id.Diz',
          'Alt-P = Rewrap description',         'Alt-T = Tag/Untag current file',
          'Alt-E = Update current file',        'Alt-G = Tag dupes files',
          'Alt-0 = Tag missing files',          'Alt-U = Tag/Untag all files',
          'F4    = Move tagged lines',          'Alt-C = Copy tagged files',
          'Alt-N = Tag new files',              'Alt-R = Repack (change archiver)',
          'Alt-A = Announce current file',      'Alt-O = Adopt orphan files',
          'Alt-W = Find keyword',               'Alt-H = Hatch',
          'Alt-B = Search dupes in index',      'Alt-Z = Check file',
          'Alt-D = Delete file and description','Alt-Q = Mark to be announced',
          'Alt-F<n> = Execute shell <n>',       'Ctrl-F<n> = Macro <n>',
          'Shift-F1 = Insert color code',       'Shift-F2 = Get ASCII char',
          'Alt-K = Switch 25/50 line mode',     'F3    = Move & Sort tagged lines',
          '<ESC> = exit files.bbs editor',      'Alt-S = Send file');
   begin
      for i := 1 to maxitems do
      if message[149+i]<>nil then
      begin
         menuitems[i]:=message[149+i]^;
         freemem(message[149+i],length(message[149+i]^)+1);
         message[149+i]:=nil;
      end;
      HideCursor;
      NormVideo;
      GotoXY(1,2);
      Write(FrameChars[3], FrameChars[1], Button);
      for J := 6 to 79 do
         Write(FrameChars[1]);
      Write(FrameChars[4]);
      for J := 1 to maxitems div 2 do
      begin
         Write(FrameChars[2],' ',MenuItems[j*2-1],'':38 - length(MenuItems[j*2-1]),
                      MenuItems[j*2],'':38 - length(MenuItems[j*2]),' ', FrameChars[2]);
      end;
      Write(FrameChars[5]);
      for J := 2 to 79 do
         Write(FrameChars[1]);
      Write(FrameChars[6]);
      repeat
         GotoXY(3 + 38 * ((MenuItem-1) mod 2),
            3 + ((MenuItem -1) div 2));
         InvVideo;
         Write(MenuItems[menuitem],'':38 - length(MenuItems[menuitem]));

         waitevent;

         GotoXY(3 + 38 * ((MenuItem-1) mod 2),
            3 + ((MenuItem -1) div 2));
         NormVideo;
         Write(MenuItems[menuitem],'':38 - length(MenuItems[menuitem]));
         if keypressed then
         begin
            Ch := ReadKey;
            if ch=#0 then
            begin
               ch := ReadKey;
               case ch of
                  #75: if MenuItem > 1 then
                          dec(MenuItem);
                  #77: if MenuItem < maxitems then
                          inc(MenuItem);
                  #72: if MenuItem > 2 then
                          dec(MenuItem, 2);
                  #80: if MenuItem < maxitems -1 then
                          inc(MenuItem,2);
               end;
               ch := #0;
            end;
         end else
         begin
            MouGet(MouInfo);
            if (MouInfo.cy>=1) and (mouInfo.cy <= (maxitems div 2) + 1) and
               (mouinfo.buttonstat <> 0)
             and (mouinfo.cx >= 2) and (mouinfo.cx <= 78) then
            begin
               if MouInfo.cy=1 then
               begin
                  if mouinfo.cx=3 then
                     ch := #27
                  else
                     ch := #0;
               end else
               begin
                  MenuItem := (MouInfo.cy - 1) * 2;
                  if mouinfo.cx < 40 then
                     dec(menuItem);
                  if Mouinfo.isDouble then
                     ch := #13
                  else
                     ch := #0;
               end;
            end else
               ch := #0;
         end;
      until (ch=#27) or (ch=#13);
      if ch=#13 then
         KbdBuffer := menuchar[menuitem];
      ShowCursor;
   end;

end.
