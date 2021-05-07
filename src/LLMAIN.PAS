
Unit LLMain;

{$I LL.Def}

Interface

Uses Dos, Crt, MkString, MkMisc, MkFile, MkDos, MkGlobT, LLGEN, LLTend,
   LLMGIDX, LLCOPY,
   LLSHELL, LLCOMP, LLUUE, LLPARSES, LLTIC, LLGETDB, LLMSG,
   LLFILEID, LLMAIN1, LLCOLORS, LLTEXT, RA250FB, LLMOUSE;


Procedure MakeList(LocalPathFBbs,LocalPathDown:PathStr; LocalNumero:integer; NomeArea:String;
          LevDown:LongInt;
          Attr:Byte; MakeNew,IsCdRom:Boolean);


Implementation


Procedure SaveRec(Rec:IdxType);
Var I,L,R:Longint;
begin
   {Punta all'ultimo record}
   if NIdx1=0 then
   begin
      I := 0;
   end else
   begin
      L := 1;
      R := Nidx1;
      I := (L + R) div 2;
      while L<=R do
      begin
         if (Buf4^[I-1].Nome>Rec.Nome) or
            ((Buf4^[I-1].Nome=Rec.Nome) and (Buf4^[I-1].Area>Rec.Area)) then
         begin
            {I e' piu' grande, va senz'altro prima}
            R := I - 1;
         end else
         begin
            L := I + 1;
         end;
         I := (L + R) div 2;
      end;
      if I<Nidx1 then
         Move(Buf4^[I],Buf4^[I+1],(Nidx1 - I) * SizeOf(IdxType));
   end;

   Buf4^[I] := Rec;
   inc(NIdx1);
   if Nidx1 = LenRead1 then
   begin
      {Buffer pieno, fa il Merge con il vecchio file}
      MergeIdx;
   end;

end {SaveRec};


Function IsInIndex(NomeFile:String; NArea:Integer;
   Var FilesIdxTot: File; Right1: Longint):Boolean;
Var L,R,M:Longint;
    CNome:CharNome;
    Found:Boolean;
    Rec:IdxType;
    {$IFDEF VIRTUALPASCAL}
    Result: Longint;
    {$ELSE}
    Result:Word;
    {$ENDIF}
Begin
   if Right1 >= 1 then
   begin
      R := Right1;
      Fillchar(CNome,12,0);
      Move(NomeFile[1],CNome,length(NomeFile));
      L := 1;
      Found := False;
      while (L<=R) do
      begin
         M := (L + R) div 2;
         Seek(FilesIdxTot,M-1);
         BlockRead(FilesIdxTot,Rec,1,Result);
         if Rec.Nome<CNome then
         begin
            L := M + 1;
         end else
         if Rec.Nome>CNome then
         begin
            R := M - 1
         end else
         begin
            {il nome corrisponde, controlla il numero di area}
            if Rec.Area<NArea then
            begin
               L := M + 1
            end else
            if Rec.Area>NArea then
            begin
               R := M -1
            end else
            begin
               {Trovato !!!}
               {Forza l'uscita dal ciclo}
               R := L - 1;
               Found := True;
            end;
         end;
      end;
      IsInIndex := Found;
   end else
      IsInIndex := False;
End {IsInIndex};

Function WasAnnounce(Nome: String; Area: Integer): Boolean;
Var
   TempWord: Word;
begin
    {controlla se era da annunciare...}
    lock(D0+'FileIdx');
    lock(D0+'Announce');
    TempWord := FileMode;
    FileMode := FmReadWrite_DA;
    assign(FilesIdxTot,PathIdx);
    {$I-}
    Reset(FilesIdxTot,SizeOf(IdxType));
    {$I+}
    if IOResult<>0 then
    begin
       rewrite(FilesIdxTot,SizeOf(IdxType));
    end;
    assign(AnnounceIdx,D0+'Announce.Idx');
    {$I-}
    Reset(AnnounceIdx, SizeOf(IdxType));
    {$I+}
    if IOResult<>0 then
    begin
       rewrite(AnnounceIdx,SizeOf(IdxType));
    end;
    FileMode := TempWord;
    Right1 := FileSize(FilesIdxTot);
    RightAnnounceIdx := FileSize(AnnounceIdx);
    WasAnnounce :=
       not IsInIndex(Nome,Area,FilesIdxTot,Right1)
         or
       IsInIndex(Nome,Area,AnnounceIdx,RightAnnounceIdx);
    Close(FilesIdxTot);
    Close(AnnounceIdx);
    Unlock(D0+'FileIdx');
    Unlock(D0+'Announce');
end;


Procedure MakeList(LocalPathFBbs,LocalPathDown:PathStr; LocalNumero:integer; NomeArea:String;
          LevDown:LongInt;
          Attr:Byte; MakeNew,IsCdRom:Boolean);

Var

    First:FileInfoPtr;
    InizioLista, ListaNewFiles:ListaPtr;
    PosLista:ListaPtrRef;
    S:SearchRec;
    J,TempDownLoad:Integer;
    TempStr,TempStr1:String;
    AllSize,NewSize,NFiles,NNewFiles,Temp,TempSize,TempTime,
       TaggedSize,NTaggedFiles,DupesExcluded,OffLineExcluded:LongInt;
    T:DateTime;
    N,FixFbbs1:Boolean;
    Rec:IdxType;
    Len:Byte;
    MinDl:Integer;
    H,H1:Boolean;
    Know,Unknow,Protected:Boolean;
    TempNome:String;
    Status:(MakeNewFiles,MakeAllFiles);
    Ch:Char;
    Result:Word;
    LenDate:ShortInt;
    TempFreeDlByte, TempFreeDlTime: Boolean;
    ModifiedFilesBbs:Boolean;
    DelCopied:Boolean;
    NOrfani:Longint;
    TotDownload: Longint;
    TempPCB: Boolean;
    SkipDescLines, ScreenLines, NCurrLine: Integer;
    TaggedList, TempLista: ListaPtr;
    {Questo per RA 2.50}
    Fb: FbManagePtr;

   Function OpenFBbs: Boolean;
   begin
      if Bbs=Ra250 then
      begin
         fb^.FbReset;
         OpenFbbs := Fb^.FbIOResult=0;
      end else
      if shOpenTextFile(VariText,LOcalPathFBbs) then
      begin
         SetTextBuf(VariText,VariBuf^,SizeTxtBuf);
         OpenFbbs := true
      end else
         OpenFbbs := false;
   end;

   Function RewriteFBbs: Boolean;
      Procedure NewName(Var Path:PathStr);
      Var D:DirStr; N:NameStr; E:ExtStr;
          F:File;
      begin
         if Bbs<>Ra250 then
         begin
            FSplit(Path,D,N,E);
            {lascia l'estensione immutata, crea file di backup}
            if erasefile (D+N+'.BAK') then;
            assign(F,Path);
            {$I-}
            Rename(F,D+N+'.BAK');
            {$I+}
            if IOREsult=0 then;
         end;
      end {NewName};
   begin
      NewName(LocalPathFBbs);
      if Bbs=Ra250 then
      begin
         if Registrato then
         begin
            fb^.FbRewrite;
            RewriteFbbs := Fb^.FbIOResult=0;
         end else
            RewriteFbbs := False;
      end else
      if shMakeTextFile(VariText,LOcalPathFBbs) then
      begin
         SetTextBuf(VariText,VariBuf^,SizeTxtBuf);
         RewriteFbbs := true
      end else
         RewriteFbbs := false;
   end;

   Procedure CloseFbbs;
   begin
      if Bbs=Ra250 then
         Fb^.FbClose
      else
         Close(VariText);
   end;

   Function GetDescLine(Var L:String):Boolean;
   begin
      if Bbs=Ra250 then
      begin
         if not fb^.EOFB then
         begin
            L := fb^.GetFbbsLine;
            GetDescLine := True;
         end else
            GetDescLine := False;
      end else
      begin
         if not eof(VariText) then
         begin
            ReadLn(VariText,L);
            While (L<>'') and (L[length(L)]=' ') do
               dec(L[0]);
            GetDescLine := True
         end else
            GetDescLine := False
      end;
   end {GetDescLine};

   Procedure WriteFbbsLine(Pnt: FileInfoPtr; var VariText: Text);
   Var TempDesc: DescTypePtr;
   begin
         if Bbs<>Ra250 then
         begin
            Write(VariText,Pnt^.Nome,'':13-length(Pnt^.Nome));
            if SAvePCB then
            begin
               {Scrive anche size e data nel Files.Bbs}
               UnpackTime(Pnt^.Time,T1);
               Write(VariText,Pnt^.Size:8,'  ',NStr[T1.Month],'-',
                  NStr[T1.Day],'-',NStr[T1.Year mod 100],'  ');
            end;
            if Pnt^.Descrizione<>Nil then
            begin
               if (Pnt^.Download>0) or ZeroDc then
                  TempStr := + DlLImit1[1] + Long2Str(Pnt^.Download,DcLen) +
                     DlLimit2[1] + ' '
               else
                  TempStr := '';
               if Pnt^.FreeDlTime then
               begin
                  if Pnt^.FreeDlByte then
                     TempStr := TempStr + '/tb '
                  else
                     TempStr := TempStr + '/t '
               end else
               if Pnt^.FreeDlByte then
                  TempStr := TempStr + '/b ';
               Writeln(VariText,TempStr,Pnt^.Descrizione^.Descrizione^);
               TempDesc := Pnt^.Descrizione^.Next;
               while TempDesc<>Nil do
               begin
                  if SavePCB then
                  begin
                     Writeln(VariText,'':31,LdChar[1],' ',TempDesc^.Descrizione^);
                  end else
                  begin
                     Writeln(VariText,'':ExtDescPos,LdChar[1],TempDesc^.Descrizione^);
                  end;
                  TempDesc := TempDesc^.Next
               end;
            end else
            begin
               Writeln(VariText,'  ',OrfanoStr(Pnt^.Nome));
            end;
         end else
         begin
            {scrive nella filebase di Ra 2.50}
            fb^.WriteRec(Pnt^.Nome, Pnt^.Time, Pnt^.Size, Pnt^.Download,
               Pnt^.Descrizione);
         end;
   end;


   Procedure Report;
   Var
      PrevY : Byte;
   begin
      if not quietmode then
      begin
         if NFiles>0 then
         begin
            write(Nfiles:4);
            if NNewFiles>0 then
               write(NNewFiles:4);
         end;
         PrevY := WhereY;
         GotoXY(1,1);
         InvVideo;
         Write(TotSize:12:0,' bytes in ',NTotFiles:12,' files','':40);
         TextAttr := StartAttr;
         GotoXY(1,PrevY);
      end;
   end {Report};

   Procedure ll(Var t : FileInfoPtr);
   Var
     p : FileInfoPtr;
   begin
     p := t^.sx;
     t^.sx  := p^.dx;
     p^.dx := t;
     t := p;
   end {ll};

   Procedure rr(Var t : FileInfoPtr);
   Var
      p : FileInfoPtr;
   begin
     p := t^.dx;
     t^.dx := p^.sx;
     p^.sx  := t;
     t := p;
   end {rr};

   Procedure lr(Var t : FileInfoPtr);
   begin
     rr(t^.sx);
     ll(t);
   end {lr};

   Procedure rl(Var t : FileInfoPtr);
   begin
     ll(t^.dx);
     rr(t);
   end {rl};

  Procedure balanceleft(Var t : FileInfoPtr);
  begin
    Case t^.bal of
      +1 :
        begin
          t^.bal := 0;
          h := False;
        end;
       0 : t^.bal := -1;
      -1 :
        begin { rebalance }
          if t^.sx^.bal = -1 then
          begin { single ll rotation }
            ll(t);
            t^.dx^.bal := 0;
          end
          else { t^.sx^.bal  = +1 }
          begin  { double lr rotation }
            lr(t);
            if t^.bal = -1 then
              t^.dx^.bal := +1
            else
              t^.dx^.bal := 0;
            if t^.bal = +1 then
              t^.sx^.bal := -1
            else
              t^.sx^.bal := 0;
          end;
          t^.bal := 0;
          h := False;
        end;
    end;
  end;

  Procedure balanceright(Var t : FileInfoPtr);
  begin
    Case t^.bal of
      -1 :
        begin
          t^.bal := 0;
          h := False;
        end;
       0 : t^.bal := +1;
      +1 :
        begin { rebalance }
          if t^.dx^.bal = +1 then
          begin { single rr rotation }
            rr(t);
            t^.sx^.bal := 0
          end
          else { t^.dx^.bal  = -1 }
          begin  { double rl rotation }
            rl(t);
            if t^.bal = -1 then
              t^.dx^.bal := +1
            else
              t^.dx^.bal := 0;
            if t^.bal = +1 then
              t^.sx^.bal := -1
            else
              t^.sx^.bal := 0;
          end;
          t^.bal := 0;
          h := False;
        end;
    end;
  end;

   Procedure PutInAlbero(Var Pnt:FileInfoPtr);
   Begin
      if Pnt=Nil then
      begin
         New(Pnt);
         Pnt^.Dx := Nil;
         Pnt^.Sx := Nil;
         Pnt^.Nome := TempNome;
         Pnt^.Dupes := False;
         Pnt^.Size := TempSize;
         Pnt^.Time := TempTime;
         Pnt^.DownLoad := 0;
         Pnt^.FreeDlTime := False;
         Pnt^.FreeDlByte := False;
         Pnt^.Tagged := False;
         if (Pnt^.Time >= ChkDate) and MakeNew then
         begin
            Pnt^.New := True;
         end else
            Pnt^.New := False;
         Pnt^.Excluded := False;
         Pnt^.Descrizione := Nil;
         Pnt^.Bal := 0;
         H := True;
      end else
      if Pnt^.Nome < TempNome then
      begin
         PutInAlbero(Pnt^.Sx);
         if H then
            BalanceLeft(Pnt);
      end else
      begin
         PutInAlbero(Pnt^.Dx);
         if H then
            BalanceRight(Pnt);
      end;
   End {PutInAlbero};


   Procedure Descrivi(Var Pnt:FileInfoPtr);
   Begin
      if Pnt=Nil then
      begin
         {se TempSize=-1, OffLine file, va aggiunto}
         if ((OffLine and (TempSize=0) and (TempTime=0)) or (OtherFiles and ((TempSize>0) or (TempTime>0)))) then
         begin
            Inc(Nfiles);
            inc(AllSize,TempSize);
            New(Pnt);
            Pnt^.NList := NFiles-1+DupesExcluded+OffLineExcluded;
            Pnt^.Dx := Nil;
            Pnt^.Sx := Nil;
            Pnt^.Nome := TempNome;
            Pnt^.Dupes := False;
            Pnt^.Descrizione := Nil;
            Pnt^.FreeDlTime := TempFreeDlTime;
            Pnt^.FreeDlByte := TempFreeDlByte;
            PutDescrizione(Pnt^.Descrizione);
            Pnt^.Size := TempSize;
            Pnt^.Time := TempTime;
            Pnt^.Tagged := False;
            Pnt^.Download := TempDownload;
            inc(TotDownload, Pnt^.Download);
            if (Pnt^.Time >= ChkDate) and MakeNew then
            begin
               inc(NNewFiles);
               Pnt^.New := True;
               if TempSize>0 then
                  Inc(NewSize,TempSize);
            end else
               Pnt^.New := False;
            Pnt^.Excluded := False;
            case Sort of
               No:PutInListaNo(PosLista^,Pnt);
               Date:PutInListaDate(PosLista^,Pnt);
               Alfa:PutInListaAlfa(PosLista^,Pnt);
            end;
            if Pnt^.New then
               PutInListaDate(ListaNewFiles,Pnt);
            H := True;
            Pnt^.Bal := 0;
         end else
         begin
            H := False;
            LastDesc := Nil;
            inc(OffLineExcluded);
         end;
      end else
      if Pnt^.Nome < TempNome then
      Begin
         Descrivi(Pnt^.Sx);
         if H then
            BalanceLeft(Pnt);
      end else
      if Pnt^.Nome > TempNome then
      Begin
         Descrivi(Pnt^.Dx);
         if H then
            BalanceRight(Pnt);
      end else
      begin
         if (Pnt^.Descrizione=Nil) then
         begin
            if not Pnt^.Excluded then
            begin
               {File non ancora descritto}
               if OtherFiles then
               begin
                  inc(NFiles);
                  inc(AllSize,Pnt^.Size);
                  if Pnt^.New then
                  begin
                     inc(NNewFiles);
                     inc(NewSize,Pnt^.Size);
                  end;
                  Pnt^.Download := TempDownLoad;
                  inc(TotDownLoad, TempDownload);
                  Pnt^.FreeDlTime := TempFreeDlTime;
                  Pnt^.FreeDlByte := TempFreeDlByte;
                  PutDescrizione(Pnt^.Descrizione);
                  Pnt^.NList := NFiles-1+DupesExcluded+OffLineExcluded;
                  case sort of
                     No:PutInListaNo(PosLista^,Pnt);
                     Date:PutInListadate(PosLista^,Pnt);
                     Alfa:PutInListaAlfa(PosLista^,Pnt);
                  end;
                  if Pnt^.New then
                     PutInListaDate(ListaNewFiles,Pnt);
               end else
               begin
                  {da escludere}
                  Pnt^.Excluded := True;
                  LastDesc := Nil
               end;
            end;
            H := false;
         end else
         begin
            {Stesso Nome, era un duplicato; ricava i vari dati
            (size e data) e poi lo aggiunge}
            if not Pnt^.Dupes then
            begin
               Pnt^.Dupes := True;
               TempSize := Pnt^.Size;
               TempTime := Pnt^.Time;
               if DelDupFBBS then
               begin
                  inc(DupesExcluded);
                  dec(AllSize,Pnt^.Size);
                  dec(NFiles);
                  dec(TotDownload, Pnt^.DownLoad);
                  if Pnt^.New then
                  begin
                     dec(NewSize,Pnt^.Size);
                     dec(NNewFiles);
                  end;
                  Pnt^.Excluded := True;
               end;
            end;
            Descrivi(Pnt^.Dx);
            if H then
               BalanceRight(Pnt);
         end;
      end;
   End {Descrivi};

   Procedure ExcludeOrfani(Var Pnt:FileInfoPtr);
   Var I : Byte;
       Flag: Boolean;
   Begin
      if Pnt<>Nil then
      begin
         ExcludeOrfani(Pnt^.Sx);
         ExcludeOrfani(Pnt^.Dx);
         if not Pnt^.Excluded then
         begin
            if Pnt^.Descrizione=Nil then
            begin
               if not orfani then
               begin
                  Pnt^.Excluded := True;
               end else
               begin
                  Flag := False;
                  I := 1;
                  TempStr := Pnt^.Nome;
                  ExpandWildCards(TempStr);
                  while not Flag and (I<=NExclude) do
                  begin
                     Flag := MatchFileSpec(TempStr,PathExclude[I]);
                     inc(I)
                  end;
                  if Flag then
                  begin
                     Pnt^.Excluded := True;
                  end else
                  begin
                     {mette nelle liste}
                     inc(NFiles);
                     inc(AllSize,Pnt^.Size);
                     if Pnt^.New then
                     begin
                        inc(NNewFiles);
                        inc(NewSize,Pnt^.Size);
                     end;
                     Pnt^.NList := NFiles-1+DupesExcluded+OffLineExcluded;
                     case sort of
                        No:PutInListaNo(PosLista^,Pnt);
                        Date:PutInListadate(PosLista^,Pnt);
                        Alfa:PutInListaAlfa(PosLista^,Pnt);
                     end;
                     if Pnt^.New then
                     begin
                        PutInListaDate(ListaNewFiles,Pnt);
                     end;
                     inc(NOrfani);
                  end;
               end;
            end;
         end;
      end
   end {ExcludeOrfani};

   Procedure ExcludeAnnounce(Var Pnt:FileInfoPtr);
   Var I : Byte;
       Flag: Boolean;
   Begin
      if Pnt<>Nil then
      begin
         ExcludeAnnounce(Pnt^.Sx);
         if not Pnt^.Excluded then
         begin
            Flag := False;
            I := 1;
            TempStr := Nome;
            ExpandWildCards(TempStr);
            while not Flag and (I<=NExcludeAnnounce) do
            begin
               Flag := MatchFileSpec(TempStr,PathExcludeAnnounce[I]);
               inc(I)
            end;
            if Flag then
            begin
               Pnt^.Excluded := True;
               Dec(NFiles);
               Dec(AllSize,Pnt^.Size);
            end;
         end;
         ExcludeAnnounce(Pnt^.Dx);
      end
   end {ExcludeAnnounce};

   Function IsSearched: Boolean;
   var I:Byte;
      Function Booyer(Pnt:SearchTypeRef):Boolean;
      {$V-}
         Function Booyer1(Pnt:SearchStringTypeRef; Var SearchIn:String; P:Integer; Fixed, Continues:Boolean):Boolean;
         var J,K,L,LMax:Byte;
             {ch:Char;}
             Temp:Boolean;
         begin
            Temp := False;
            J := Pnt^.LenCurrent;
            LMax := length(SearchIn) - Pnt^.PostQM - Pnt^.LenOther;
            {Ch := Pnt^.Keyword[J];}
            inc(P,J);
            if Fixed and not continues and (Pnt^.Next=Nil) and (P<LMax) then
               P := LMax + 1;
            while not Temp and (P<=LMax) do
            begin
               if (J=0) or (SearchIn[P] in Pnt^.Keyword[J]) then
               begin
                  {potrebbe essere, verifica gli altri caratteri}
                  Temp := True;
                  K := P - J;
                  L := 1;
                  while Temp and (L<J) do
                  begin
                     if not (SearchIn[K+L] in Pnt^.Keyword[L]) then
                        Temp := False
                     else
                        inc(L)
                  end;
                  if Temp then
                  begin
                     {La stringa e' trovata}
                     Fixed := False;
                     if Pnt^.Next<>Nil then
                     begin
                        Temp := False;
                        Inc(P,Pnt^.PostQM); {non puo' comunque andare in overflow}
                        Pnt := Pnt^.Next;
                        J := Pnt^.lencurrent;
                        LMax := length(SearchIn) - Pnt^.PostQM - Pnt^.LenOther;
                        {Ch := Pnt^.Keyword[J];}
                        inc(P,J);
                        if not continues and (Pnt^.Next=Nil) then
                           P := LMax;
                     end;
                  end else
                     inc(P,Pnt^.Booyer[Byte(SearchIn[P])]);
               end else
                  inc(P,Pnt^.Booyer[Byte(SearchIn[P])]);
               if Fixed then
               begin
                  P := LMax + 1
               end;
            end;
            Booyer1 := Temp and (Continues or (P=LMax));
         end {Booyer1};
      Begin
         While (Pnt<>Nil) and
           (
             (Pnt^.IsPath and (Booyer1(Pnt^.SearchString,TempNome,Pnt^.SearchString^.PreQM,
                Pnt^.Fixed,Pnt^.Continues) xor Pnt^.Negative))
             or
             (Not Pnt^.IsPath and (Booyer1(Pnt^.SearchString,L,PosDesc-1+Pnt^.SearchString^.PreQM,
                Pnt^.Fixed,Pnt^.Continues) xor Pnt^.Negative))
           )
          do
         begin
            Pnt := Pnt^.AndSearch
         end;
         Booyer := Pnt=Nil;
      end {Booyer};
   begin
      I := 1;
      while (I<=NStringSearch)
          and not Booyer(Search[I]) do
         inc(I);
      IsSearched := I <= NStringSearch;
      {$V+}
   end {IsSearched};


   Procedure HeadArea(Var AllFiles:Text; Numero:integer; NomeArea:String;
                      NFiles,Size:Longint);
   Var
       I, K: Integer;
       TempDescTypePtr: DescTypePtr;
       TempStr, TempStr1: String;
       FillChar: Char;
   begin
      If HdrStyle>0 then
      Begin
         {una linea vuota all'inizio}
         if lliststatus=fixfbbs then
         begin
            if Bbs=Ra250 then
               fb^.WriteComment('')
            else
               Writeln(AllFiles);
         end else
            Writeln(AllFiles);
         if HdrStyle=1 then
            TempDescTypePtr := AreaHeaderLines
         else
            TempDescTypePtr := MsgAreaHeaderLines;
         While (TempDescTypePtr<>Nil) do
         begin
            TempStr1 := '';
            FillChar := ' ';
            K := 1;
            TempStr := TempDescTypePtr^.Descrizione^;
            While (k<=length(TempStr)) do
            begin
               if TempStr[K]='^' then
               begin
                  inc(k);
                  if (k<=length(TempStr)) then
                  begin
                     case upcase(TempStr[k]) of
                        'B':TempStr1 := TempStr1 + BytesStr(Size);
                        'F':TempStr1 := TempStr1 + Long2Str(NFiles,4);
                        'A':begin
                              TempStr1 := TempStr1 + NomeArea;
                              if length(nomeArea)<52 then
                              begin
                                 TempStr1 := TempStr1 + ' ';
                                 for I := length(NomeArea)+2 to 52 do
                                    TempStr1 := TempStr1 + FillChar;
                              end;
                              FillChar := ' ';
                            end;
                        'S':begin
                              TempStr1 := TempStr1 + SysopName;
                              if length(SysopName)<36 then
                              begin
                                 TempStr1 := TempStr1 + ' ';
                                 for I := length(SysopName)+2 to 36 do
                                    TempStr1 := TempStr1 + FillChar;
                              end;
                              FillChar := ' ';
                            end;
                        'C':begin
                              TempStr1 := TempStr1 + Bbsname;
                              if length(BbsName)<36 then
                              begin
                                 TempStr1 := TempStr1 + ' ';
                                 for I := length(Bbsname)+2 to 36 do
                                    TempStr1 := TempStr1 + FillChar;
                              end;
                              FillChar := ' ';
                            end;
                        'N':TempStr1 := TempStr1 + Long2Str(Numero,4);
                        'L':TempStr1 := TempStr1 + Lev2Str(LevDown);
                        'D':if TotDownLoad < 10000 then
                               TempStr1 := TempStr1 + Long2Str(TotDownload,4)
                            else
                               TempStr1 := TempStr1 + Long2Str(TotDownLoad div 1000, 3) + 'k';
                        '^':TempStr1 := TempStr1 + '^';
                        '_':TempStr1 := TempStr1 + ' ';
                        '*':begin
                               inc(k);
                               if k<=length(TempStr) then
                                  FillChar := TempStr[k]
                               else
                                  FillChar := ' ';
                            end;
                       else
                        TempStr1 := TempStr1 + '^' + TempStr[k];
                     end;
                  end else
                     TempStr1 := TempStr1 + TempStr[k];
               end else
               if (TempStr[k]=ColorId[1]) then
               begin
                  {inizio sequenza colore, da skippare}
                  inc(k);
                  if (k<=length(TempStr)) and (TempStr[k]=ColorId[2]) then
                  begin
                     if LlistStatus=FixFBbs then
                        TempStr1 := TempStr1 + ColorId;
                     if ColorId[1]='@' then
                     begin
                        inc(k);
                        if k<=length(TEmpStr) then
                        begin
                           if LlistStatus=FixFBbs then
                              TempStr1 := TempStr1 + TempStr[K];
                           inc(k);
                           if k<=length(TEmpStr) then
                              if LlistStatus=FixFBbs then
                                 TempStr1 := TempStr1 + TempStr[K];
                        end;
                     end else
                     begin
                        if (k+1<=length(TempStr)) then
                        begin
                           if TempStr[K+1]=#16 then
                           begin
                              if LListStatus=FixFBbs then
                                 TempStr1 := TempStr1 + TempStr[K+1];
                              inc(k)
                           end;
                           if (K+1<=Length(TempStr)) then
                           begin
                              if LListStatus=FixFBbs then
                                 TempStr1 := TempStr1 + TempStr[K+1];
                              inc(k)
                           end;
                        end;
                     end;
                  end else
                     TempStr1 := TempStr1 + ColorId[1] + TempStr[k];
               end else
                  TempStr1 := TempStr1 + TempStr[k];
               inc(k);
            end;
            while (TempStr1<>'') and (TempStr1[length(TempStr1)]=' ') do
               dec(TempStr1[0]);
            if lliststatus=fixfbbs then
            begin
               if Bbs=Ra250 then
                  fb^.WriteComment(TempStr1)
               else
               begin
                  if TempStr1<>'' then
                     TempStr1 := ' ' + TempStr1;
                  Writeln(AllFiles,TempStr1);
               end;
            end else
               Writeln(allFiles, TempStr1);
            TempDescTypePtr := TempDescTypePtr^.Next
         end;
         if AreaHeaderReqInfo then
         begin
            {aggiunge una linea con le info su a chi e' consentito il f/r}
            if Unknow or Know or Protected then
            begin
               if message[5]=Nil then
                  TempStr := 'Ч File Request allowed to %1 nodes Ч'
               else
                  TempStr := Message[5]^;
               TempStr1 := '';
               if Unknow then
                  TempStr1 := TempStr1 + ' Unknown';
               if know then
                  TempStr1 := TempStr1 + ' Known';
               if Protected then
                  TempStr1 := TempStr1 + ' Protected';
               delete(TempStr1,1,1);
               substpar(tempStr, TempStr1,'1')
            end else
            begin
               if message[6]=Nil then
                  TempStr := 'Ч No File Request allowed Ч'
               else
                  TempStr := Message[6]^;
            end;
            {centra la linea}
            for I := 1 to 40 - length(tempStr) div 2 do
                TempStr := ' ' + TempStr;
            if llistStatus=FixFbbs then
            begin
               if Bbs=Ra250 then
                  fb^.WriteComment(TempStr)
               else
                  Writeln(AllFiles, TempStr);
            end else
               Writeln(AllFiles, TempStr);
         end;
         {una linea vuota alla fine}
         if llistStatus=FixFbbs then
         begin
            if Bbs=Ra250 then
               fb^.WriteComment('')
            else
               Writeln(AllFiles);
         end else
            Writeln(AllFiles);
      end;
   end {HeadArea};

   Procedure DisplayInfo(Pnt:FileInfoPtr; Var AllFiles:Text; LenDate:ShortInt);
   Const NewChar:Array[0..1] of Char=' *';
   Var Temp:DescTypePtr;
       I,P,L2,L1,Skip,Skip1:Integer;
       FirstRiga:Boolean;
       TempStr, TempStr1: String;

       Procedure GetL1L2;
       begin
          if Length(TempStr)-P<Colonne-LenDate+Skip1 then
          begin
             L2 := length(TempStr) - P + 1;
             L1 := L2;
          end else
          begin
             L2 := Colonne - LenDate + Skip1;
             if (TempStr[P+L2]=' ') then
             begin
                L1 := L2;
                inc(L2);
                while (TempStr[P+L1-1]=' ') do
                   dec(L1);
             end else
             if (TempStr[P+L2]=ColorId[1]) and (TempStr[P+L2+1]=ColorId[2]) then
             begin
                {il carattere che segue nella descrizione e' uno spazio}
                L2 := length(TempStr) - P + 1;
                L1 := L2;
             end else
             begin
                {potrebbe essere a meta' di una parola}
                {Se e' un codica Colore lo termina}
                if ((TempStr[P+L2-1]=ColorId[1]) and
                   (TempStr[P+L2]=ColorId[2])) or
                   ((TempStr[P+L2-2]=ColorId[1]) and
                   (TempStr[P+L2-1]=ColorId[2])) or
                   ((TempStr[P+L2-3]=ColorId[1]) and
                   (TempStr[P+L2-2]=ColorId[2])) then
                begin
                   L2 := length(TempStr) - P + 1;
                   L1 := L2;
                end else
                begin
                   while (L2>Skip) and (TempStr[P+L2-1]<>' ') and
                       not ((TempStr[P+L2-1]=ColorId[1]) and (TempStr[P+L2]=ColorId[2])) do
                      dec(L2);
                   if (L2=0) then
                   begin
                      L2 := Colonne - LenDate + Skip1;
                      L1 := L2;
                   end else
                   if (TempStr[P+L2-1]=ColorId[1]) then
                   begin
                      L2 := length(TempStr) - P + 1;
                      L1 := L2;
                   end else
                   begin
                      L1 := L2;
                      while (TempStr[P+L1-1]=' ') do
                         dec(L1);
                   end;
                end;
             end;
          end;
          TempStr1 := Copy(TempStr,P+Skip,L1-Skip);
       end {GetL1L2};
   begin
      FirstRiga := Pnt^.Nome<>'';
      if not FirstRiga then
         TextAttr := StartAttr;
      Temp := Pnt^.Descrizione;
      TempStr := '';
      while FirstRiga or (Temp<>Nil) or (TempStr<>'') do
      begin
         if Temp<>Nil then
            TempStr := TempStr + Temp^.Descrizione^;
         P := 1;
         repeat
            if FirstRiga then
            begin
               TextAttr := NumCol[ColName];
               Write(AllFiles,Pnt^.Nome);
               TextAttr := NumCol[ColDef];
               Write(AllFiles,'':13-length(Pnt^.Nome));
               if Pnt^.Size=0 then
               begin
                  TextAttr := NumCol[ColSizeU];
                  if ShortSize then
                     Write(AllFiles,copy(OffLineStr,1,8+Lendate),
                         '':7+LenDate-length(OffLineStr))
                  else
                     Write(AllFiles,copy(OffLineStr,1,8+Lendate),
                         '':9+LenDate-length(OffLineStr));
                  TextAttr := NumCol[ColDef];
               end else
               begin
                  TextAttr := NumCol[ColSizeU];
                  if ShortSize then
                  begin
                     Write(AllFiles,Pnt^.Size Shr 10:4,'k');
                  end else
                  begin
                     Write(AllFiles,Pnt^.Size:7);
                  end;
                  TextAttr := NumCol[ColDef];
                  if LenDate>0 then
                  begin
                     UnPackTime(Pnt^.Time,T);
                     MyDateStr(T);
                     Write(AllFiles,' ');
                     TextAttr := NumCol[ColSizeC];
                     Write(AllFiles,PrevDataStr);
                     TextAttr := NumCol[ColDef];
                     Write(AllFiles,
                        NewChar[Byte((Pnt^.New) and (Status=MakeAllFiles))],
                        ' ');
                  end else
                  begin
                     Write(AllFiles,'  ');
                  end;
               end;
               FirstRiga := False;
               if Pnt^.Descrizione = Nil then
               begin
                  if IndentDc and (ModDc<>StripDc) then
                  begin
                     Write(AllFiles,'':DcLen+3);
                     LenDate := LenDate + DcLen + 3;
                  end;
                  TempStr := OrfanoStr(Pnt^.Nome);
               end else
               if IndentDc and (ModDC<>StripDc) then
               begin
                  if Pnt^.DownLoad>0 then
                  begin
                     str(Pnt^.Download:DcLen,TempStr1);
                     Write(AllFiles,DlLimit1[1],TempStr1,DlLimit2[1],' ');
                     LenDate := LenDate + length(TempStr1) + 3;
                  end else
                  begin
                     Write(AllFiles,'':DcLen+3);
                     LenDate := LenDate + DcLen + 3;
                  end;
               end else
               {Download Counter in TempStr}
               if Pnt^.DownLoad>0 then
               begin
                  str(Pnt^.Download:DcLen,TempStr1);
                  TempStr := DlLimit1[1] + TempStr1 + DlLimit2[1] + ' ' +
                     TempStr;
               end;
            end else
            begin
               Write(AllFiles,'':22+LenDate);
            end;
            {ora scrive la descrizione vera e propria, potrebbe contenere}
            {codici AVATAR}
            Skip := 0;
            Skip1 := 0;
            GetL1L2;
            I := Pos(ColorID,TempStr1);
            while (I>0) and (I<length(TempStr1)) do
            begin
               Write(AllFiles,Copy(TempStr1,1,I-1));
               if (ColorId[1]='@') then
               begin
                  if (llistStatus=EditFilesBbs) and (I<=length(TempStr1)+1) then
                     TextAttr := 16*GetHex(TempStr1[I+2]) + GetHex(TempStr1[I+3]);
                  inc(Skip1,4);
                  inc(Skip,I+3);
               end else
               begin
                  if TempStr1[I+2]=#16 then
                  begin
                     TextAttr := Byte(TempStr1[I+3]) - 128;
                     {recupera i caratteri che sono andati persi}
                     inc(Skip,I+3);
                     inc(Skip1,4);
                  end else
                  begin
                     TextAttr := Byte(TempStr1[I+2]);
                     {recupera i caratteri che sono andati persi}
                     inc(Skip,I+2);
                     inc(Skip1,3);
                  end;
               end;
               GetL1L2;
               I := Pos(ColorID,TempStr1);
            end;
            Writeln(AllFiles,TempStr1);
            inc(P,L2);
            while (P<=length(TempStr)) and (TempStr[P]=' ') do
               inc(P);
         until (P>length(TempStr));
         if Temp<>Nil then
            Temp := Temp^.Next;
         TempStr := '';
         TextAttr := StartAttr;
      end;
      if Pnt^.Nome<>'' then
      begin
         if ((ViewContents=VcAll) or ((ViewContents=VcNew) and (Pnt^.New))) and
           (Pnt^.Size>0) then
         begin
            ViewCompressed(LocalPathDown+Pnt^.Nome,AllFiles);
         end;
         if UUEncodeFound and (Pnt^.Size>0) and (Pnt^.Size<=MaxBytesUUEncode) then
         begin
            UUEncode(AllFiles, Pnt^.Nome, 0);
            Dec(MaxBytesUUEncode,Pnt^.Size);
         end;
         if XXEncodeFound and (Pnt^.Size>0) and (Pnt^.Size<=MaxBytesUUEncode) then
         begin
            UUEncode(AllFiles, Pnt^.Nome, 1);
            Dec(MaxBytesUUEncode,Pnt^.Size);
         end;
      end;
   end {DisplayInfo};


   Procedure MostraLista1(Pnt:FileInfoPtr; Var AllFiles:Text);
   Var TempDesc:DescTypePtr;
       Comp:Byte;
       MoveFiles:Boolean;
   begin
      if (Pnt<>Nil) and not (Pnt^.Excluded) then
      begin
         if Pnt^.Nome<>'' then
         begin
            if (LListStatus=FileIdx) then
            begin
               FillChar(Rec,SizeOf(Rec),0);
               Move(Pnt^.Nome[1],Rec.Nome[1],Byte(Pnt^.Nome[0]));
               Rec.Area := LocalNumero;
               SaveRec(Rec);
            end else
            if LListStatus=FixFBbs then
            begin
               if FixFBbs1 then
               begin
                  {gli orfani li inserisce nell'"Announce.Idx"}
                  if Pnt^.Descrizione=Nil then
                  begin
                     FillChar(Rec,SizeOf(Rec),0);
                     Move(Pnt^.Nome[1],Rec.Nome[1],Byte(Pnt^.Nome[0]));
                     Rec.Area := LocalNumero;
                     AddAnnounceIdx(Rec);
                  end;
                  Comp := 0;
                  if CheckFiles then
                  begin
                     if Uncompress(LocalPathDown+Pnt^.Nome,'*.*',Comp) then
                     begin
                        if VirusDetected(LocalPathDown+Pnt^.Nome,Comp) then
                        begin
                           if not IsCdRom and (DirInfectedFiles<>'') then
                           begin
                              {File Bad, rimuovere}
                              MoveFiles := True;
                              PathCopy := DirInfectedFiles;
                              PathCopyFBbs := DirInfectedFiles + 'Files.Bbs';
                              if CopyFile(Pnt^.Nome,
                                 Pnt^.Size,
                                 Pnt^.Time,
                                 Pnt^.Descrizione,MoveFiles,Nil,0)<>'' then
                              begin
                                 if MoveFiles then
                                 begin
                                    Pnt^.Size := 0;
                                    Pnt^.Time := 0;
                                 end;
                              end;
                           end;
                        end else
                        if MakeRepack then
                        begin
                           if not IsCdRom then
                           begin
                              TempStr1 := Pnt^.Nome;
                              if ChangeToRepack(localPathDown,TempStr1,Comp,Pnt^.Size,Pnt^.Time) then
                              begin
                                 Pnt^.Nome := TempStr1;
                              end;
                           end;
                        end;
                     end else
                     begin
                        if (Comp<>0) then
                        begin
                           if not IsCdRom and (DirBadFiles<>'') then
                           begin
                              {File Bad, rimuovere}
                              MoveFiles := True;
                              PathCopy := DirBadFiles;
                              PathCopyFBbs := DirBadFiles + 'Files.Bbs';
                              if CopyFile(Pnt^.Nome,
                                 Pnt^.Size,
                                 Pnt^.Time,
                                 Pnt^.Descrizione,MoveFiles,Nil,0)<>'' then
                              begin
                                 if MoveFiles then
                                 begin
                                    Pnt^.Size := 0;
                                    Pnt^.Time := 0;
                                 end;
                              end;
                           end;
                        end else
                        if MakeRepack then
                        begin
                           if not IsCdRom then
                           begin
                              TempStr1 := Pnt^.Nome;
                              if ChangeToRepack(localPathDown,TempStr1,Comp,Pnt^.Size,Pnt^.Time) then
                              begin
                                 Pnt^.Nome := TempStr1;
                              end;
                           end;
                        end;
                     end;
                  end else
                  if MakeRepack then
                  begin
                     if not IsCdRom then
                     begin
                        TempStr1 := Pnt^.Nome;
                        if ChangeToRepack(localPathDown,TempStr1,Comp,Pnt^.Size,Pnt^.Time) then
                        begin
                           Pnt^.Nome := TempStr1;
                        end;
                     end
                  end;
                  if (Pnt^.Descrizione=Nil) then
                  begin
                     if ImportDesc(LocalPathDown+Pnt^.Nome,Comp,Pnt^.Descrizione) then
                        PackDesc(Pnt^.Descrizione, False);
                     if Pnt^.Descrizione= Nil then
                     begin
                        L := OrfanoStr(Pnt^.Nome);
                        PosDesc := 1;
                        PutDescrizione(Pnt^.Descrizione);
                     end;
                     if UploaderStr<>'' then
                     begin
                        L := UploaderStr + SysopName;
                        PosDesc := 1;
                        PutDescrizione(Pnt^.Descrizione);
                     end;
                  end else
                  if ReadFile_Id then
                  begin
                     if ImportDesc(LocalPathDown+Pnt^.Nome,Comp,Pnt^.Descrizione) then;
                  end;
                  WriteFbbsLine(Pnt, VariText);
               end
            end else
            begin
                if (LListStatus=Announce) and (Pnt^.Size>0) and
                   Not NoAnnounceReadFile_Id then
                begin
                   {mette il File_Id.Diz nell'annuncio}
                   Comp := 0;
                   if ImportDesc(LocalPathDown+Pnt^.Nome,Comp,Pnt^.Descrizione) then;
                   {Controlla se c'e' un Magic Name per questo file}
                   I := 1;
                   While (I<=NMagic) and
                      ((Magic[I]=Nil) or (Pos(LocalPathDown+Pnt^.Nome,Magic[I]^)=0)) do
                       inc(I);
                   if (I<=NMagic) then
                   begin
                      L := Magic[I]^;
                      I := Pos(' ',L);
                      L := 'FREQ: '+Copy(L,1,I-1);
                      PosDesc := 1;
                      PutDescrizione(Pnt^.Descrizione)
                   end;
                end;
                DisplayInfo(Pnt,AllFiles,LenDate)
            end
         end else
         begin
            {Linee di commento, solo in AllFiles}
            if not FixFbbsHeader or (Pnt^.NList<>-1) or (LlistStatus=EditFilesBbs) then
            begin
               if (LListStatus=FixFBbs) then
               begin
                  if FixFBbs1 then
                  begin
                     if Bbs<>Ra250 then
                     begin
                        TempDesc := Pnt^.Descrizione;
                        while TempDesc<>Nil do
                        begin
                           if TempDesc^.Descrizione^='' then
                           begin
                              Writeln(VariText)
                           end else
                           begin
                              Writeln(VariText,' ',TempDesc^.Descrizione^);
                           end;
                           TempDesc := TempDesc^.Next
                        end;
                     end else
                        Fb^.WriteRec('',0,0,0,Pnt^.Descrizione)
                  end;
               end else
               begin
                  DisplayInfo(Pnt,AllFiles,-22)
               end;
            end;
         end;
      end;
   end {MostraLista1};

   Procedure MostraLista2(Pnt:FileInfoPtr);
   begin
      if Status=MakeAllFiles then
         MostraLista1(Pnt,AllFiles)
      else
         MostraLista1(Pnt,NewFiles);
   end {MostraLista2};

   Procedure MostraLista(Pnt:ListaPtr);
   begin
      if Pnt<>Nil then
      begin
         MostraLista(Pnt^.Sx);
         MostraLista2(Pnt^.FileInfo);
         MostraLista(Pnt^.Dx);
      end
   end {MostraLista};

   Procedure CancellaAlbero(Var Pnt:FileInfoPtr);
   Begin
      if Pnt<>Nil then
      begin
         CancellaAlbero(Pnt^.Sx);
         CancellaAlbero(Pnt^.Dx);
         CancellaDescrizione(Pnt^.Descrizione);
         Dispose(Pnt);
      end;
   end {CancellaAlbero};

   Procedure CancellaLista(Var Pnt:ListaPtr);
   begin
      if Pnt<>Nil then
      begin
         CancellaLista(Pnt^.Sx);
         CancellaLista(Pnt^.Dx);
         Dispose(Pnt);
      end;
   end {CancellaLista};

   Procedure Commento;
   var Temp:FileInfoPtr;
       Temp1:ListaPtr;
   begin
      if
         ((LListStatus=MakeListCmp) or (LListStatus=FixFBbs) or
           (LListStatus=EditFilesBbs)) then
      begin
         if LastComm<>Nil then
         begin
            PosDesc := 2;
            PutDescrizione(LastComm)
         end else
         begin
            {FileInfo}
            new(Temp);
            Temp^.Nome := '';
            Temp^.Excluded := False;
            Temp^.Descrizione := Nil;
            Temp^.Tagged := False;
            Temp^.NList := NFiles -1;
            PosDesc := 2;
            PutDescrizione(Temp^.Descrizione);
            {Lista}
            New(Temp1);
            Temp1^.FileInfo := Temp;
            Temp1^.Sx := InizioLista;
            Temp1^.Dx := Nil;
            Temp1^.Bal := 0;
            PosLista := Addr(Temp1^.Dx);
            InizioLista := Temp1;
         end;
         LastComm := LastDesc;
         LastDesc := Nil;
      end else
      begin
         LastDesc := Nil;
         {Non c'e' bisogno di settare LastComm, che
         in questo caso non verra' mai usato}
      end;
   end {Commento};

   Procedure PutInBest;
   Var I, J: Integer;
   begin
      I := 1;
      {Cerca la posizione in cui inserire il record}
      while (I<=MaxBest1) and (TempDownLoad>Best^[I].DownLoad) do
         inc(I);
      {Ora in ordine alfabaetico all'interno del suo gruppo}
      while (I<=MaxBest1) and (TempDownLoad=Best^[I].DownLoad) and
          (Best^[I].Nome>TempNome) do
         inc(I);
      dec(i);
      {ora sposta di 1 posizione tutti quelli precedenti}
      for J := 1 to I - 1 do
         Best^[j] := best^[j+1];
      {Ora scrive il nuovo record}
      Best^[I].Nome := TempNome;
      Best^[I].DownLoad := TempDownLoad;
      Best^[I].Descrizione := Copy(L,PosDesc,Length(L)-PosDesc+1);
      StripAvt(Best^[i].descrizione);
      MinDl := Best^[1].DownLoad;
   end {PutInBest};

   Procedure ImportOrphans(Var Pnt1:ListaPtr);
   Var ImportedOne:Boolean;
      Procedure ImportOrphans1(Pnt:FileInfoPtr);
      Var I:Integer;
         Flag:Boolean;
         TempDescPtr:DescTypePtr;
         Comp : Byte;
      begin
         if Pnt<>Nil then
         begin
            ImportOrphans1(Pnt^.Sx);
            if (Pnt^.Descrizione=Nil) then
            begin
               TempStr := Pnt^.Nome;
               ExpandWildCards(TempStr);
               I := 1;
               Flag := False;
               while not flag and (I<=NExclude) do
               begin
                  Flag := MatchFileSpec(TempStr,PathExclude[I]);
                  inc(I);
               end;
               if not flag then
               begin
                  {Da importare come orfano}
                  if not ImportedOne then
                  begin
                     {$IFDEF NO4350}
                     {$ELSE}
                     if ModeFont8x8 then
                        TextMode(CO80);
                     {$ENDIF}
                     TextAttr := StartAttr;
                     ClrScr;
                     GotoXY(1,10);
                     ImportedOne := True;
                  end;
                  Inc(NFiles);
                  Inc(AllSize,Pnt^.Size);
                  Pnt^.NList := NFiles -1;
                  {if OrphanUpdate then
                  begin
                     if Update(LocalPathDown+Nome) then
                        Pnt^.Time := ActDate
                  end;}
                  Comp := 0;
                  if not dosmode and ImportDesc(LocalPathDown+Pnt^.Nome,Comp,Pnt^.Descrizione) then
                  begin
                     PackDesc(Pnt^.Descrizione, False);
                  end else
                  begin
                     L := OrfanoStr(Pnt^.Nome);
                     PosDesc := 1;
                     PutDescrizione(Pnt^.Descrizione);
                  end;
                  if UploaderStr<>'' then
                  begin
                     L := UploaderStr + SysopName;
                     PosDesc := 1;
                     PutDescrizione(Pnt^.Descrizione);
                  end;
                  Pnt^.FreeDlTime := False;
                  Pnt^.FreeDlByte := False;
                  Pnt^.Tagged := False;
                  PutInListaNo(Pnt1,Pnt);
                  Pnt^.Excluded := False;
                  ModifiedFilesBbs := True;
                  if (localNumero>=0) then
                  begin
                     FillChar(Rec,SizeOf(Rec),0);
                     Move(Pnt^.Nome[1],Rec.Nome[1],Byte(Pnt^.Nome[0]));
                     Rec.Area := LocalNumero;
                     AddAnnounceIdx(Rec);
                  end;
               end;
            end;
            ImportOrphans1(Pnt^.Dx);
         end;
      end {ImportOrphans1};
   Begin
      ImportedOne := False;
      ImportOrphans1(First);
      {$IFDEF NO4350}
      {$ELSE}
      if ImportedOne then
         if ModeFont8x8 then
            TextMode(Font8x8+Co80);
      {$ENDIF}
   End {ImportOrphans};

   Function GetDesc(N:Integer; Pnt:DescTypePtr):String;
   begin
      while (N>1) and (Pnt<>Nil) do
      begin
         dec(N);
         Pnt := Pnt^.Next;
      end;
      if Pnt<>Nil then
         GetDesc := Pnt^.Descrizione^
      else
         GetDesc := ''
   end {GetDesc};

   Procedure SetDesc(N:Integer; Pnt:DescTypePtr; Var NewDesc:String);
   begin
      while (N>1) and (Pnt<>Nil) do
      begin
         dec(N);
         Pnt := Pnt^.Next
      end;
      if Pnt<>Nil then
      begin
         FreeMem(Pnt^.Descrizione,length(Pnt^.Descrizione^)+1);
         GetMem(Pnt^.Descrizione,length(NewDesc)+1);
         Pnt^.Descrizione^ := NewDesc
      end;
   end {SetDesc};

   Function RimDesc(N:Integer; Pnt:DescTypePtr):Boolean;
   Var Temp:DescTypePtr;
       Prev:DescTypePtr;
   begin
      Prev := Nil;
      while (N>1) and (Pnt<>Nil) do
      begin
         dec(N);
         Prev := Pnt;
         Pnt := Pnt^.Next
      end;
      if Pnt<>Nil then
      begin
         FreeMem(Pnt^.Descrizione,length(Pnt^.Descrizione^)+1);
         if Pnt^.Next<>Nil then
         begin
            Temp := Pnt^.Next;
            Pnt^ := Pnt^.Next^;
            Dispose(Temp);
            RimDesc := True
         end else
         if (Prev=Nil) then
         begin
            {Non puo' cancellarla completamente, lascia una linea vuota}
            GetMem(Pnt^.Descrizione,1);
            Pnt^.Descrizione^ := '';
            RimDesc := False
         end else
         begin
            Dispose(Pnt);
            Prev^.Next := Nil;
            RimDesc := True
         end;
      end else
         RimDesc := False;
   end {RimDesc};

   Procedure AddEmptyLine(N:Integer; Pnt:DescTypePtr);
   Var Temp:DescTypePtr;
   begin
      while (N>1) and (Pnt<>Nil) do
      begin
         Dec(N);
         Pnt := Pnt^.Next
      end;
      if Pnt<>Nil then
      begin
         {Inserisce una linea Prima della posizione corrente}
         New(Temp);
         Temp^ := Pnt^;
         Pnt^.Next := Temp;
         GetMem(Pnt^.Descrizione,1);
         Pnt^.Descrizione^:= '';
      end;
   end {AddEmptyLine};

   Function NDescLines(Pnt:DescTypePtr):Integer;
   Var Temp:INteger;
   Begin
      Temp := 0;
      while Pnt<>Nil do
      begin
         inc(Temp);
         Pnt := Pnt^.Next
      end;
      NDescLines := Temp
   End {NDescLines};

   Procedure MergeDesc(N:Integer; Pnt:DescTypePtr);
   Var TempStr:String;
      TempDescPtr:DescTypePtr;
   begin
      while (N>1) and (Pnt<>Nil) do
      begin
         dec(N);
         Pnt := Pnt^.Next
      end;
      if (Pnt<>Nil) and (Pnt^.Next<>Nil) then
      begin
         TempStr := Pnt^.Descrizione^ + Pnt^.Next^.Descrizione^;
         TempDescPtr := Pnt^.Next;
         Pnt^.Next := Pnt^.Next^.Next;
         {Rimuove TempDescPtr}
         FreeMem(TempDescPtr^.Descrizione,length(TempDescPtr^.Descrizione^)+1);
         Dispose(TempDescPtr);
         {Cambia la descrizione di Pnt}
         FreeMem(Pnt^.Descrizione,length(Pnt^.Descrizione^)+1);
         GetMem(Pnt^.Descrizione,length(TempStr)+1);
         Pnt^.Descrizione^ := TempStr;
      end;
   end {MergeDesc};

   Function IsListed(N:String; Exclude:FileInfoPtr):Boolean;
   Var TempB:Boolean;
     Procedure IsListed1(Pnt:ListaPtr);
     begin
        if Pnt<>Nil then
        begin
           TempB := (Pnt^.FileInfo<>Nil) and
              (Pnt^.FileInfo<>Exclude) and (Pnt^.FileInfo^.Nome=N);
           if not TempB then
              IsListed1(Pnt^.Sx);
           if not TempB then
              IsListed1(Pnt^.Dx);
        end;
     end {IsListed1};
   begin
       TempB := False;
       IsListed1(InizioLista);
       IsListed := TempB
   end {IsListed};

   Procedure AddNewComment1(Pnt:ListaPtr; SearchFor:FileInfoPtr);
   Var Temp:FileInfoPtr;
   begin
      if Pnt<>Nil then
      begin
         AddNewComment1(Pnt^.Sx,SearchFor);
         if Pnt^.FileInfo=SearchFor then
         begin
            {Trovato, il commento deve essere inserito prima di Pnt};
            if LastComm<>Nil then
            begin
               PosDesc := 1;
               L := '';
               PutDescrizione(LastComm);
            end else
            begin
               New(Temp);
               Temp^.Nome := '';
               Temp^.Descrizione := Nil;
               Temp^.Excluded := false;
               Temp^.Tagged := False;
               Temp^.NList := SearchFor^.Nlist -1;
               New(Temp^.Descrizione);
               Temp^.Descrizione^.Next := Nil;
               GetMem(Temp^.Descrizione^.Descrizione,1);
               Temp^.Descrizione^.Descrizione^ := '';
               PutInListaNo(Pnt^.Sx,Temp);
            end;
         end else
         begin
            if (Pnt^.FileInfo<>Nil) and not Pnt^.FileInfo^.Excluded then
            begin
               if Pnt^.FileInfo^.Nome<>'' then
                  LastComm := Nil
               else
                  LastComm := Pnt^.FileInfo^.Descrizione;
            end;
            AddNewComment1(Pnt^.Dx,SearchFor);
         end;
      end;
   end {AddNewComment};

   Function IsDupes(Pnt:FileInfoPtr; Nome:String):Boolean;
   Var TempDupes:Boolean;
      Procedure IsDupes1(Pnt1:ListaPtr);
      Begin
         if Pnt1<>Nil then
         begin
            IsDupes1(Pnt1^.Sx);
            If (Pnt1^.FileInfo<>Nil) and not (Pnt1^.FileInfo^.Excluded) and
               (Pnt1^.FileInfo^.Nome=Nome) and (Pnt1^.FileInfo<>Pnt) then
            begin
               TempDupes := True;
            end;
            IsDupes1(Pnt1^.Dx);
         end;
      End {IsDupes1};
   Begin
      TempDupes := False;
      IsDupes1(InizioLista);
      IsDupes := TempDupes
   End {IsDupes};

   Procedure TagDupes(Pnt:ListaPtr; Var TaggedList:ListaPtr);
   begin
      if Pnt<>Nil then
      begin
         TagDupes(Pnt^.Sx,TaggedList);
         if (Pnt^.FileInfo<>Nil) and (Pnt^.FileInfo^.Nome<>'') and
            IsDupes(Pnt^.FileInfo,Pnt^.FileInfo^.Nome) and
            not Pnt^.FileInfo^.Tagged then
         begin
            Pnt^.FileInfo^.Tagged := True;
            PutInListaNo(TaggedList,Pnt^.FileInfo);
            inc(NTaggedFiles);
            inc(TaggedSize,Pnt^.FileInfo^.Size);
         end;
         TagDupes(Pnt^.Dx,TaggedList);
      end;
   end {TagDupes};

   Procedure SetNewData(Var Pnt:ListaPtr);
   Begin
      if Pnt<>Nil then
      begin
         SetNewData(Pnt^.Sx);
         if (Pnt^.FileInfo<>Nil) and not Pnt^.FileInfo^.Excluded and
            (Pnt^.FileInfo^.Nome=TempNome) then
         begin
            Pnt^.FileInfo^.Time := TempTime;
            Dec(AllSize,Pnt^.FileInfo^.Size);
            if Pnt^.FileInfo^.Tagged then
               Dec(TaggedSize,Pnt^.FileInfo^.Size);
            Pnt^.FileInfo^.Size := TempSize;
            Inc(AllSize,Pnt^.FileInfo^.Size);
            if Pnt^.FileInfo^.Tagged then
               Inc(TaggedSize,Pnt^.FileInfo^.Size)
         end;
         SetNewData(Pnt^.Dx);
      end;
   End {SetNewData};

   Procedure RemFromLista(Pnt:FileInfoPtr; Pnt1:ListaPtr);
   begin
      if Pnt1<>Nil then
      begin
         RemFromLista(Pnt,Pnt1^.Sx);
         if Pnt1^.FileInfo=Pnt then
            Pnt1^.FileInfo := Nil;
         RemFromLista(Pnt,Pnt1^.Dx);
      end;
   end {RemFromLista};

   Procedure RemTagged(Pnt:ListaPtr);
   begin
      if Pnt<>Nil then
      begin
         RemTagged(Pnt^.Sx);
         if Pnt^.FileInfo<>Nil then
         begin
            RemFromLista(Pnt^.FileInfo,InizioLista)
         end;
         RemTagged(Pnt^.Dx);
      end;
   end {RemTagged};

   Procedure GarbageCollect(Var Pnt:ListaPtr);
   Var NList:Integer;
       NewLista:ListaPtr;
      Procedure MakeNewLista(Pnt:ListaPtr);
      begin
         if (Pnt<>Nil) then
         begin
            MakeNewLista(Pnt^.Sx);
            if (Pnt^.FileInfo<>Nil) and not (Pnt^.FileInfo^.Excluded) then
            begin
               if Pnt^.FileInfo^.Nome<>'' then
               begin
                  inc(NList);
                  Pnt^.FileInfo^.NList := NList;
               end;
               PutInListaNo(NewLista,Pnt^.FileInfo);
            end;
            MakeNewLista(Pnt^.Dx);
         end;
      end {MakeNewLista};
   begin
      NewLista := Nil;
      NList := -1;
      MakeNewLista(Pnt);
      CancellaLista(Pnt);
      Pnt := NewLista;
   end {GarbageCollect};

   Procedure TagSearched(Var TaggedList:ListaPtr);
      Procedure Search1(Pnt:ListaPtr);
      Begin
         if Pnt<>Nil then
         Begin
            Search1(Pnt^.Sx);
            if (Pnt^.FileInfo<>Nil) and not Pnt^.FileInfo^.Excluded and
                (Pnt^.FileInfo^.Nome<>'') and not Pnt^.FileInfo^.Tagged then
            begin
               TempNome := Pnt^.FileInfo^.Nome;
               L := Pnt^.FileInfo^.Descrizione^.Descrizione^;
               PosDesc := 1;
               if IsSearched then
               begin
                  Pnt^.FileInfo^.Tagged := True;
                  PutInListaNo(TaggedList,Pnt^.FileInfo);
                  inc(NTaggedFiles);
                  inc(TaggedSize,Pnt^.FileInfo^.Size);
               end;
            End;
            Search1(Pnt^.Dx);
         End;
      End {Search1};
   Begin
      PosDesc := 1;
      Search1(InizioLista);
   End {TagSearched};

   Procedure InsertTagged(Var Pnt:ListaPtr; Var SearchFor:FileInfoPtr;
       TaggedList:ListaPtr; HowSort:SortType);
     Var Found:Boolean;
         TempLista:ListaPtr;
       Procedure MergeComments(Pnt:ListaPtr);
       Var LastComm:FileInfoPtr;
          Temp:DescTypePtr;
         Procedure MergeComments1(Pnt:ListaPtr);
         begin
            if Pnt<>Nil then
            begin
               MergeComments1(Pnt^.Sx);
               if (Pnt^.FileInfo<>Nil) and not (Pnt^.FileInfo^.Excluded) then
               begin
                  if Pnt^.FileInfo^.Nome='' then
                  begin
                     {E' un commento}
                     if LastComm<>Nil then
                     begin
                        {controlla se e' il riferimento}
                        if Pnt^.FileInfo=SearchFor then
                           SearchFor := LastComm;
                        Temp := Pnt^.FileInfo^.Descrizione;
                        While Temp<>Nil do
                        begin
                           L := Temp^.Descrizione^;
                           PosDesc := 1;
                           PutDescrizione(LastComm^.Descrizione);
                           Temp := Temp^.Next
                        end;
                        CancellaDescrizione(Pnt^.FileInfo^.Descrizione);
                        Dispose(Pnt^.FileInfo);
                        Pnt^.FileInfo := Nil;
                        {LastComm non lo cambia}
                     end else
                        LastComm := Pnt^.FileInfo
                  end else
                     LastComm := Nil;
               end;
               MergeComments1(Pnt^.Dx);
            end;
         end;
      begin
         LastComm := Nil;
         MergeComments1(Pnt);
      End {MergeComments};
      Procedure InsertTagged1(Pnt:ListaPtr; Var InizioLista:ListaPtr);
      begin
         If Pnt<>Nil then
         begin
            InsertTagged1(Pnt^.Sx,InizioLista);
            if (Pnt^.FileInfo<>Nil) then
            begin
               if HowSort=No then
                   PutInListaNo(InizioLista,Pnt^.FileInfo)
               else
               begin
                   Nome := Pnt^.FileInfo^.Nome;
                   PutInListaAlfa(InizioLista,Pnt^.FileInfo)
               end;
            end;
            InsertTagged1(Pnt^.Dx,InizioLista);
         end;
      end {InsertTagged1};
      Function FindLast(Var Pnt:ListaPtr): ListaPtrRef;
      begin
         if Pnt<>Nil then
         begin
            FindLast := FindLast(Pnt^.Dx)
         end else
         begin
            FindLast := Addr(Pnt);
         end;
      end;
      Procedure FoundInsPos(Var Pnt:ListaPtr);
      begin
         if Pnt<>Nil then
         begin
            FoundInsPos(Pnt^.Sx);
            if not found then
            begin
               if (Pnt^.FileInfo<>Nil) and (Pnt^.FileInfo=SearchFor) then
               begin
                  {Trovato, prima di questa poszione deve inserire la tagged list}
                  PosLista := FindLast(Pnt^.Sx);
                  Found := True
               end;
               if not Found then
                   FoundInsPos(Pnt^.Dx);
            end;
         end
      end {FoundInsPos};
   begin
      Found := False;
      FoundInsPos(InizioLista);
      if not found then
         PosLista := FindLast(InizioLista);
      InsertTagged1(TaggedList,PosLista^);
      MergeComments(InizioLista);
   end {InsertTagged};

   Procedure GetNumbers(Pnt:FileInfoPtr; Var NCurrLine,FirstFile:Integer);
   Var TempB:Boolean;
      Procedure Search(Pnt1:ListaPtr);
      begin
         if Pnt1<>Nil then
         begin
            Search(Pnt1^.Sx);
            if not TempB then
            begin
               if (Pnt1^.FileInfo<>Nil) then
               begin
                  if Pnt1^.FileInfo=Pnt then
                  begin
                     {Trovato}
                     TempB := TRue;
                  end else
                  begin
                     if not Pnt1^.FileInfo^.Excluded then
                     begin
                        Inc(FirstFile);
                        Inc(NCurrLine,NDescLines(Pnt1^.FileInfo^.Descrizione));
                     end;
                     Search(Pnt1^.Dx);
                  end
               end else
               begin
                  Search(Pnt1^.Dx);
               end;
            end;
         end;
      end {Search};
   begin
      NCurrLine := 1;
      FirstFile := 1;
      TempB := False;
      Search(InizioLista);
   end {GetNumbers};

   Procedure CopyTagged(Pnt:ListaPtr);
   Var ToMove:Boolean;
   begin
      if (Pnt<>Nil) then
      begin
         CopyTagged(Pnt^.Sx);
         if (Pnt^.FileInfo<>Nil) and not (Pnt^.FileInfo^.Excluded) and
            (Pnt^.FileInfo^.Nome<>'') then
         begin
            if FirstShell then
            begin
               FirstShell := False;
               FirstArea := True;
               Writeln;
            end;
            ToMove := DelCopied;
            if CopyFile(Pnt^.FileInfo^.Nome,
               Pnt^.FileInfo^.Size,
               Pnt^.FileInfo^.Time,
               Pnt^.FileInfo^.Descrizione,ToMove,Nil,NumberCopy)<>'' then
            begin
               if (WasAnnounce(Pnt^.FileInfo^.Nome, LocalNumero) or dosmode) and
                  (LocalNumero>=0) then
               begin
                    FillChar(Rec,SizeOf(Rec),0);
                    Move(Pnt^.FileInfo^.Nome[1],Rec.Nome[1],
                       Byte(Pnt^.FileInfo^.Nome[0]));
                    Rec.Area := NumberCopy;
                    AddAnnounceIdx(Rec);
               end;
               if NumberCopy>=0 then
                  PutInListaAree(NumberCopy,NumberCopy,UpDateFileIdx);
               if ToMove then
               begin
                  TempSize := 0;
                  TempTime := 0;
                  TempNome := Pnt^.FileInfo^.Nome;
                  SetNewData(InizioLista);
                  if localnumero>=0 then
                     PutInListaAree(LocalNumero,LocalNumero,UpDateFileIdx);
                  {cancella il file dal files.bbs}
                  cancellaDescrizione(Pnt^.FileInfo^.descrizione);
                  pnt^.FileInfo^.Descrizione := Nil;
                  L := '';
                  PosDesc := 1;
                  putdescrizione(Pnt^.FileInfo^.Descrizione);
                  dec(NFiles);
                  if Pnt^.FileInfo^.New then
                     dec(nnewfiles);
                  Pnt^.FileInfo^.Excluded := True;
               end;
            end;
         end;
         CopyTagged(Pnt^.Dx)
      end;
   end {CopyTagged};

   Procedure SetNList(Pnt:ListaPtr);
   Var NFiles:Longint;
      Procedure SetNList1(Pnt:ListaPtr);
      Begin
         if Pnt<>Nil then
         begin
            SetNList1(Pnt^.Sx);
            if (Pnt^.FileInfo<>Nil) and not (Pnt^.FileInfo^.Excluded) then
            begin
               if Pnt^.FileInfo^.Nome<>'' then
                  inc(NFiles);
               Pnt^.FileInfo^.Nlist := NFiles;
            end;
            SetNList1(Pnt^.Dx);
         end;
      End {SetNList1};
   Begin
      NFiles := -1;
      SetNList1(Pnt);
   End {SetNList};

   Procedure AddDescLine(N:Integer; Var Pnt:DescTypePtr;
      Var NextLine:String);
   Var Temp:DescTypePtr;
   begin
      If (N>1) and (Pnt<>Nil) then
      begin
         AddDescLine(N-1,Pnt^.Next,NextLine)
      end else
      begin
         New(Temp);
         GetMem(Temp^.Descrizione,length(NextLine)+1);
         Temp^.Descrizione^ := NextLine;
         Temp^.Next := Pnt;
         Pnt := Temp;
      end;
   end {AddDescLine};

   Procedure EditFBbs;
   Var
       AreaId: String;
       FirstFile,I,J:Integer;
       PrevY:Byte;
       T:DateTime;
       PrevTotSize: Real;
       PrevNTotFiles,
          PrevNTotFiles1:Longint;
       PrevSize, PrevTime:Longint;
       PrevNome:String[12];
       NLine:Integer;
       TempStr:String;
       PrevQuietMode, PrevFirstShell:Boolean;
       PrevTaggedFiles:Longint;
       AreaType, PrevLenDate, PrevDl:Integer;
       Temp:FileInfoPtr;
       TempF:File;
       Scroll:Byte;
       NextChars:String;
       PosStr:Integer;
       NextLine:String;
       S:SearchRec;
       TempFileInfoPtr:FileInfoPtr;
       Comp:Byte;
       MoveFiles:Boolean;
       TempDesc:DescTypePtr;
       {$IFDEF VIRTUALPASCAL}
       Code: Longint;
       {$ENDIF}
       MouInfo: MinfoRecType;

   Procedure HatchCurrent;
    Var I,J: Integer;
    Begin
       I := WhereY;
       if (FilesOnLine[I]<>0) and
          (Lines[FilesOnLine[I]]^.Nome<>'') and (lines[FilesOnLine[I]]^.Size<>0) then
       begin
          Lock(D0+'Tic');
          J := 1;
          while (J<=NTicAreas) and (TicAreas[J]^.Number<>LocalNumero) do
             inc(J);
          if J<=NTicAreas then
             TempStr := TicAreas[J]^.Tag
          else
             TempStr := '';
          ReadBox('Area TAG',20,TempStr);
          if TempStr<>'' then
          begin
             TempStr := Upper(TempStr);
             J := 1;
             while (J<=NTicAreas) and (TicAreas[J]^.Tag<>TempStr) do
                inc(J);
             if J<=NTicAreas then
             begin
                {E' stata trovata l'area TIC}
                TempStr := Lines[FilesOnLine[I]]^.Nome;
                ReadBox('Replace',20,TempStr);
                TempStr1 := Lines[FilesonLine[I]]^.Nome;
                K := Pos('.',TempStr1);
                if K>0 then
                   TempStr1 := Copy(TempStr1,1,K-1);
                while (TempStr1<>'') and (TempStr1[length(TempStr1)] in ['0'..'9']) do
                   dec(TempStr1[0]);
                TempStr1 := TempStr1 + '*';
                ReadBox('Magic',20,TempStr1);
                {$IFDEF NO4350}
                {$ELSE}
                if ModeFont8x8 then
                   TextMode(CO80);
                {$ENDIF}
                TextAttr := StartAttr;
                ClrScr;
                GotoXY(1,10);
                Hatch(LocalPathDown,Lines[FilesOnLine[I]]^.Nome,TempStr,TempStr1,
                   Lines[FilesOnLine[I]]^.Descrizione,
                   TicAreas[J]^.Nodes, TicAreas[J]^.Tag, TicAreas[J]^.SecTag,
                   Aka[TicAreas[J]^.Address], Lines[FilesOnLine[I]]^.Size,
                      Lines[FilesOnLine[I]]^.Time,TicAreas[j]^.AreaDesc);
                {$IFDEF NO4350}
                {$ELSE}
                if ModeFont8x8 then
                   TextMode(Font8x8+Co80);
                {$ENDIF}
             End;
          End;
          ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,AllSize);
          GotoXY(1,I);
          Unlock(D0+'Tic');
       End;
    end {HatchCurrent};


    Procedure AnnounceCurrent;
    Begin
       I := WhereY;
       if (FilesOnLine[I]<>0) and
          (Lines[FilesOnLine[I]]^.Nome<>'') and (lines[FilesOnLine[I]]^.Size<>0) then
       begin
          AreaId := '';
          ReadBox('AreaID',40,AreaId);
          if AreaId<>'' then
          begin
             J := pos(',',AreaId);
             if (J<>0) and (J<length(AreaId)) then
             begin
                Val(Copy(AreaId,J+1,length(AreaId)-J),TempWord,Code);
                if Code=0 then
                begin
                   {AreaId := copy(AreaId,1,J-1);}
                   AreaType := TempWord;
                end else
                   AreaType := 1;
             end else
                AreaType := 1;

             TempStr := AddrStr(aka[0]);
             Repeat
                Repeat
                   ReadBox('Aka',40,TempStr);
                until (TempStr<>'') and ParseAddr(TempStr,MsgOrigAddr,MsgOrigAddr);
                J := 0;
                While (J<=NAka) and not AddrEqual(MsgOrigAddr,Aka[J]) do
                   inc(J);
             until (J<=NAka);
             MsgDestAddr := MsgOrigAddr;
             if AreaType=2 then
             begin
                {Area NetMail, serve anche l'indirizzo di destinazione}
                TempStr := 'Sysop';
                ReadBox('To:',40,TempStr);
                if TempStr='' then
                   MsgTo := 'Sysop'
                else
                   MsgTo := TempStr;
                TempStr := AddrStr(MsgDestAddr);
                Repeat
                   ReadBox('Dest Address',40,TempStr);
                until (TempStr<>'') and ParseAddr(TempStr,MsgDestAddr,MsgDestAddr);
             end else
                MsgTo := 'All';

             ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);

             PostIbm := not conferma('Strip IBM chars');

             repeat
                PathAll := D0 + HexLong(ToUnixDate(GetDosDate)) + AppExt;
                Assign(AllFiles,PathAll);
                {$I-}
                Rewrite(AllFiles);
                {$I+}
             until IOResult=0;

             dec(colonne);

             PrevDl := Lines[FilesOnLine[I]]^.DownLoad;
             Lines[FilesOnLine[I]]^.DownLoad := 0;
             PrevLenDate := LenDate;
             LenDate := 0;
             if ShortSize then
                dec(Lendate,2);

             MsgSubject := Lines[FilesOnLIne[I]]^.Nome;

             HeadArea(AllFiles,Numero,NomeArea,1,Lines[FilesOnLine[I]]^.Size);
             MostraLista1(Lines[FilesOnLIne[I]],AllFiles);

             J := 1;
             While (J<=NMagic) and
                ((Magic[J]=Nil) or (Pos(LocalPathDown+Lines[FilesOnLIne[I]]^.Nome,Magic[J]^)=0)) do
                 inc(J);
             if (J<=NMagic) then
             begin
                L := Magic[J]^;
                J := Pos(' ',L);
                L := 'FREQ: '+Copy(L,1,J-1);
                Write(AllFiles,'':20);
                if not ShortSize then
                   Write(AllFiles,'  ');
                Writeln(AllFiles,L);
             end;
             Close(AllFiles);

             inc(colonne);
             Lines[FilesOnLine[I]]^.DownLoad := PrevDl;
             Lendate := PrevLenDate;

             KludgeFdn := '';
             J := 1;
             while (KludgeFdn='') and (J<=NTicAreas) do
             begin
                if (TicAreas[J]^.Number=LocalNumero) and
                    (TicAreas[J]^.Group<>'') and (TicAreas[J]^.Group[1]<>'!') then
                   KludgeFdn := TicAreas[J]^.Group;
                inc(J)
             end;

             {$IFDEF NO4350}
             {$ELSE}
             if ModeFont8x8 then
                TextMode(CO80);
             {$ENDIF}
             TextAttr := StartAttr;

             ClrScr;
             GotoXY(1,10);

             PostAnnunciNews(AreaId);
             if EraseFile(PathAll) then;

             KludgeFdn := '';

             {$IFDEF NO4350}
             {$ELSE}
             if ModeFont8x8 then
                TextMode(Font8x8+Co80);
             {$ENDIF}
          end;
          ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
          GotoXY(1,I);
       End;
    End {AnnounceCurrent};

    Procedure CheckCurrent;
    Var Comp: Byte; MoveFiles: Boolean;
    begin
       I := WhereY;
       If (FilesOnLine[I]<>0) and (Lines[FilesOnLine[I]]^.Nome<>'') and
          (Lines[FilesOnLine[I]]^.Size>0) then
       begin
          {$IFDEF NO4350}
          {$ELSE}
          if ModeFont8x8 then
             TextMode(CO80);
          {$ENDIF}
          TextAttr := StartAttr;
          ClrScr;
          GotoXY(1,10);

          Comp := 0;

          if Uncompress(LocalPathDown+Lines[FilesOnLine[I]]^.Nome,'*.*',Comp) then
          begin
             if VirusDetected(Lines[FilesOnLine[I]]^.Nome,Comp) then
             begin
                if (DirInfectedFiles<>'') then
                begin
                   {File Bad, rimuovere}
                   MoveFiles := True;
                   PathCopy := DirInfectedFiles;
                   PathCopyFBbs := DirInfectedFiles + 'Files.Bbs';
                   if CopyFile(Lines[FilesOnLine[I]]^.Nome,
                      Lines[FilesOnLine[I]]^.Size,
                      Lines[FilesOnLine[I]]^.Time,
                      Lines[FilesOnLine[I]]^.Descrizione,MoveFiles,Nil,0)<>'' then
                   begin
                      if MoveFiles then
                      begin
                         TempSize := 0;
                         TempTime := 0;
                         TempNome := Lines[FilesOnLine[I]]^.Nome;
                         SetNewData(InizioLista);
                      end
                   end;
                end;
             end;
          end else
          if Comp<>0 then
          begin
             if (DirBadFiles<>'') then
             begin
                {File Bad, rimuovere}
                MoveFiles := True;
                PathCopy := DirBadFiles;
                PathCopyFBbs := DirBadFiles + 'Files.Bbs';
                if CopyFile(Lines[FilesOnLine[I]]^.Nome,
                      Lines[FilesOnLine[I]]^.Size,
                      Lines[FilesOnLine[I]]^.Time,
                      Lines[FilesOnLine[I]]^.Descrizione,MoveFiles,Nil,0)<>'' then
                begin
                   if MoveFiles then
                   begin
                      TempSize := 0;
                      TempTime := 0;
                      TempNome := Lines[FilesOnLine[I]]^.Nome;
                      SetNewData(InizioLista);
                   end;
                end;
             end;
          end;
          {$IFDEF NO4350}
          {$ELSE}
          if ModeFont8x8 then
             TextMode(Font8x8+Co80);
          {$ENDIF}
          ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
          GotoXY(1,I);
       end;
    end {CheckCurrent};

   Procedure CopyMove;
   Var PrevDosMode: Boolean;
       PrevNFiles: Longint;
       TempFileInfoPtr: fileInfoPtr;
       i: Integer;
   begin
      PrevDosMode := DosMode;
      I := WhereY;
      if Ch=#50 then
      begin
         TempStr := 'Move'
      end else
         TempStr := 'Copy';
      FixFBbsSort := PrevSort;
      PrevNFiles := NFiles;

      if NTaggedFiles<>0 then
      begin
         if GetDestPath(TempStr+' tagged files to') then
         begin
            if (NumberCopy>=0) then
               Lock(D0+'Area'+Long2Str(NumberCopy,0));
            DelCopied := Ch = #50;
            {$IFDEF NO4350}
            {$ELSE}
            if ModeFont8x8 then
               TextMode(CO80);
            {$ENDIF}
            TextAttr := StartAttr;
            ClrScr;
            GotoXY(1,10);
            CopyTagged(TaggedList);
            if NumberCopy>=0 then
               UnLock(D0+'Area'+Long2Str(NumberCopy,0));
            {$IFDEF NO4350}
            {$ELSE}
            if ModeFont8x8 then
               TextMode(Font8x8+Co80);
            {$ENDIF}
            Dispose(TaggedList);
            NTaggedFiles := 0;
            TaggedSize := 0;
            TaggedList := Nil;
         end;
      end else
      if (FilesOnLine[I]<>0) and (Lines[FilesOnLine[I]]^.Nome<>'') then
      begin
         if GetDestPath(TempStr+' '+Lines[FilesOnLine[I]]^.Nome+' to') then
         begin
            if NumberCopy>=0 then
               Lock(D0+'Area'+Long2Str(NumberCopy,0));
            DelCopied := Ch = #50;
            {$IFDEF NO4350}
            {$ELSE}
            if ModeFont8x8 then
               TextMode(CO80);
            {$ENDIF}
            TextAttr := StartAttr;
            ClrScr;
            GotoXY(1,10);
            New(TempLista);
            TempLista^.FileInfo := Lines[FilesOnLine[I]];
            TempLista^.Sx := Nil;
            TempLista^.Dx := Nil;
            CopyTagged(TempLista);
            Dispose(TempLista);
            if NumberCopy>=0 then
               UnLock(D0+'Area'+Long2Str(NumberCopy,0));
            {$IFDEF NO4350}
            {$ELSE}
            if ModeFont8x8 then
               TextMode(Font8x8+Co80);
            {$ENDIF}
         end;
      end;

      if (NFiles<PrevNFiles) then
      begin
         ModifiedFilesBbs := True;
         {alcuni files sono stati cancellati...}
         if FilesOnLine[I]=0 then
            TempFileInfoPtr := Nil
         else
            TempFileInfoPtr := Lines[FilesOnLine[I]];
         GetNumbers(TempFileInfoPtr,NCurrLine,FirstFile);
         SkipDescLines := 0;
         J := I;
         while (I>2) and (FirstFile>1) do
         begin
            Dec(FirstFile);
            GetBuffer(FirstFile-1,ScreenLines,InizioLista);
            Dec(I,NDescLines(Lines[1]^.Descrizione));
            if I<2 then
            begin
               SkipDescLines := 2 - I;
               I := 2;
            end;
         end;
         I := J + 2 - I;
         GetBuffer(FirstFile-1,ScreenLines,InizioLista);
         setnlist(InizioLista);
      end;

      FixFBbsSort := No;
      ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
      GotoXY(1,I);
      DosMode := PrevDosMode;
   end {CopyMove};


    Procedure CR;
    begin
       {Aggiungi linea}
       I := WhereY;
       if (FilesOnLine[I]<>0)  then
       begin
          {commento}
          if (Lines[FilesOnLine[I]]^.Nome='') then
          begin
             inc(NCurrLine);
             ModifiedFilesBbs := True;
             {Aggiunge una linea vuota al commento corrente}
             NLine := DescLine[I];
             AddEmptyLine(NLine,Lines[FilesOnLine[I]]^.Descrizione);
             inc(I);
             if I>ScreenLines-1 then
             begin
                FirstFile := FirstFile + FilesOnLine[ScreenLines-1] - 1;
                GetBuffer(FirstFile-1,ScreenLines,InizioLista);
                SkipDescLines := NLine -1;
                ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
                GotoXY(1,3);
             end else
             begin
                ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
                GotoXY(1,I);
             end;
          end else
          {descrizione di file, prima riga}
          if (DescLine[I]=1) then
          begin
             inc(NCurrLine);
             ModifiedFilesBbs := true;
             {Crea una linea di commento}
             LastComm := nil;
             AddNewComment1(InizioLista,Lines[FilesOnLine[I]]);
             inc(I);
             if I>ScreenLines-1 then
             begin
                FirstFile := FirstFile + FilesOnLine[ScreenLines-1] - 1;
                if Lines[FilesOnLine[ScreenLines-2]]^.Nome<>'' then
                begin
                   {nuovo commento}
                   inc(FirstFile);
                end;
                GetBuffer(FirstFile-1,ScreenLines,InizioLista);
                SkipDescLines := 0;
                ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
             end else
             begin
                if (I=3) and (FirstFile>1) and (Lines[0]^.Nome='') then
                begin
                   Dec(FirstFile);
                   SkipDescLines := NdescLines(Lines[0]^.Descrizione) - 1;
                end;
                GetBuffer(FirstFile-1,ScreenLines,InizioLista);
                ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
                GotoXY(1,I);
             end;
          end else
          begin
             {converte in un cursor-down}
             KbdBuffer := #0 + #80
          end;
       end else
       begin
          {Aggiunge una linea vuota al Files.Bbs}
          inc(NCurrLine);
          L := ' ';
          LastComm := Nil;
          Commento;
          inc(I);
          if I>ScreenLines-1 then
          begin
             {La linea 24 non e' valida}
             FirstFile := FirstFile + FilesOnLine[ScreenLines-2];
             GetBuffer(FirstFile-1,ScreenLines,InizioLista);
             SkipDescLines := 0;
             ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
             GotoXY(1,3);
          end else
          begin
             GetBuffer(FirstFile-1,ScreenLines,InizioLista);
             ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
             GotoXY(1,I);
          end;
       end
    end {CR};

    Procedure Find;
    Var PrevFirstShell: Boolean;
        PrevY: Byte;
        Procedure Prompt;
        begin
           if (NTotFiles>PrevNTotFiles1) then
                      begin
                         Write(' * <C>ontinue, <G>oto area, <S>top ? ');
                         Repeat
                            waitevent;
                            if KeyPressed then
                            begin
                               Ch := UpCase(ReadKey);
                               if Ch=#0 then
                               begin
                                  Ch := REadkey;
                                  Ch := #0;
                               end;
                            end else
                            begin
                               MouGet(MouInfo);
                               if (MouInfo.IsDouble) and (mouInfo.cy=WhereY-1) then
                               begin
                                  if MouInfo.Cx = 4 then
                                     ch := 'C'
                                  else
                                  if MouInfo.Cx = 16 then
                                     ch := 'G'
                                  else
                                  if MouInfo.Cx = 29 then
                                     ch := 'S'
                                  else
                                     ch := #0
                               end else
                                  ch := #0;
                            end;
                         Until (Ch='C') or (Ch='G') or (Ch='S');
                         Write(#13,'':79,#13);
                         PrevNTotFiles1 := NTotFiles;
                      end else
                      if KeyPressed then
                      begin
                         Ch := ReadKey;
                         if Ch=#0 then
                         begin
                            Ch := ReadKey;
                            Ch := 'C'
                         end else
                         begin
                            if Ch<>#27 then
                               Ch := 'C'
                            else
                               Ch := 'N'
                         end;
                      end;
         end;
    begin
       I := WhereY;
       TempStr := '';
       ReadBox('Keyword to search for',50,TempStr);
       if TempStr<>'' then
       begin
          PrevFirstShell := FirstShell;
          if ParseSubject(TempStr,False,True) then
          begin
             SearchStr := TempStr;
             PrevTaggedFiles := NTaggedFiles;
             TagSearched(TaggedList);
             if (NTaggedFiles=PrevTaggedFiles) and not dosmode then
             begin
                ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
                if Conferma('Not found. Search in other areas') then
                begin
                   {$IFDEF NO4350}
                   {$ELSE}
                   if ModeFont8x8 then
                      TextMode(CO80);
                   {$ENDIF}
                   TextAttr := StartAttr;
                   ClrScr;
                   GotoXY(1,10);

                   ResetAreaFile;

                   LListStatus := MakeSearch;
                   AssignCrt(AllFiles);
                   Rewrite(AllFiles);
                   PrevQuietMode := QuietMode;
                   QuietMode := TRue;
                   PrevTotSize := TotSize;
                   TotSize := 0;
                   PrevNTotFiles := NTotFiles;
                   NTotFiles := 0;
                   Sort := Alfa;
                   ModDc := StripDC;
                   SearchMaxFiles := SearchMaxFiles1;
                   PrevNTotFiles1 := 0;
                   Ch := 'C';
                   While (Ch='C') and GetNextArea do
                   if Numero<>LocalNumero then
                   begin

                      PrevY := WhereY;
                      InvVideo;
                      GotoXY(1,1);
                      Write(' #', Numero:3,' Ё ',Nome,'':80-8-length(nome));
                      TextAttr := StartAttr;
                      GotoXY(1, PrevY);

                      MakeList(PathFbbs,PathDown,Numero,Nome,Livello,Attr,False, IsCdRom);

                      Prompt;

                   end;

                   if (Ch='C') and (LlistDb<>Nil) and conferma('Search in LListDb') then
                   begin
                      {Search in llistdb}
                      Clrscr;
                      GotoXY(1,10);
                      TempDescTypePtr := LlistDb;
                      Ch := 'C';
                      while (ch='C') and (TempDescTypePtr<>Nil) do
                      begin
                         PrevNTotFiles := NTotFiles;
                         PrevY := WhereY;
                         InvVideo;
                         GotoXY(1,1);
                         Write(' #', 0:3,' Ё ',TempDescTypePtr^.descrizione^,
                            '':80-8-length(TempDescTypePtr^.Descrizione^));
                         TextAttr := StartAttr;
                         GotoXY(1, PrevY);
                         MakeList(TempDescTypePtr^.Descrizione^,'\\',0,TempDescTypePtr^.Descrizione^,
                            0,64,NewDays > 0, False);
                         Prompt;
                         if Ch='G' then
                            Ch := 'C';
                         TempDescTypePtr := TempDescTypePtr^.Next;
                      end;
                   end;
                   Close(AllFiles);
                   NTotFiles := PrevNTotFiles;
                   TotSize := PrevTotSize;
                   QuietMode := PrevQuietMode;
                   Sort := No;
                   ModDc := NoMod;
                   LListStatus := EditFilesBbs;
                   if Ch='G' then
                   begin
                      ChangeArea := Numero;
                      KbdBuffer := #27 + 'Y';
                   end else
                      SearchStr := '';
                   {$IFDEF NO4350}
                   {$ELSE}
                   if ModeFont8x8 then
                      TextMode(Font8x8+Co80);
                   {$ENDIF}
                end;
             End else
             Begin
                SearchStr := '';
             End;
          end;
          FirstShell := PrevFirstShell;
          FirstArea := not FirstShell;
       End;
       ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
       GotoXY(1,I)
   end {Find};

   Procedure SearchDupes;
   var Rec: IdxType;
       J: Integer;
   begin
      I := WhereY;
      If (FilesOnLine[I]<>0) and (Lines[FilesOnLine[I]]^.Nome<>'') then
      begin
         fillChar(Rec,SizeOf(IdxType),0);
         move(lines[FilesOnLine[I]]^.Nome[1], Rec.Nome,
            length(lines[FilesOnLine[I]]^.Nome));
         Rec.area := localnumero;
         if SearchIdx(Rec) and (rec.area<>localnumero) then
         begin
            ChangeArea := Rec.Area;
            SearchStr := '';
            J := 1;
            while (J<=12) and (rec.Nome[j]<>#0) do
            begin
               SearchStr := SearchStr + rec.nome[j];
               inc(j);
            end;
            if ParseSubject(SearchStr,False,True) then;
            KbdBuffer := #27 + 'Y';
         end;
         ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
         GotoXY(1,I)
      end;
   end;

    Procedure DeleteCurrent(AskDel: Boolean);
    begin
       I := WhereY;
       If (FilesOnLine[I]<>0) and ((Lines[FilesOnLine[I]]^.Nome='') or
          (Lines[FilesOnLine[I]]^.Size =0) or IsDupes(Lines[FilesOnLine[I]],Lines[FilesOnLine[I]]^.Nome) or
             (not AskDel or Conferma('Delete '+Lines[FilesOnLIne[I]]^.Nome))) then
       begin
          Lines[FilesOnLine[I]]^.Excluded := True;
          Dec(NCurrLIne,DescLine[I]-1);
          if Lines[FilesOnLine[I]]^.Tagged then
          begin
             Lines[FilesOnLine[I]]^.Tagged := False;
             RemFromLista(Lines[FilesOnLine[I]],TaggedList);
             if Lines[FilesOnLine[I]]^.Nome<>'' then
             begin
                dec(NTaggedFiles);
                dec(TaggedSize,Lines[FilesOnLine[I]]^.Size);
             end;
          end;
          if Lines[FilesOnLine[I]]^.Nome<>'' then
          begin
             Dec(AllSize,Lines[FilesOnLine[I]]^.Size);
             Dec(NFiles);
             CancellaDescrizione(Lines[FilesOnLine[I]]^.Descrizione);
             Lines[FilesOnLine[I]]^.Descrizione := Nil;
             {Se esiste un duplicato, fa si' che non venga riconosciuto come orfano}
             if (Lines[FilesOnLine[I]]^.Size=0) or
                IsListed(Lines[FilesOnLine[I]]^.Nome,
                   Lines[FilesOnLine[I]]) then
             begin
                {mantiene comunque qualcosa nella descrizione}
                L := '';
                PosDesc := 1;
                PutDescrizione(Lines[FilesOnLine[I]]^.Descrizione);
             end else
             if AskDel then
             begin
                {non e' un duplicato e non e' offline}
                Assign(TempF,LocalPathDown+Lines[FilesOnLine[I]]^.Nome);
                {$I-}
                Erase(TempF);
                {$I+}
                if IOResult=0 then
                begin
                   {mantiene comunque qualcosa nella descrizione}
                   L := '';
                   PosDesc := 1;
                   PutDescrizione(Lines[FilesOnLine[I]]^.Descrizione);
                   if Lines[FilesOnLine[I]]^.Size<>0 then
                   begin
                      Writeln(LogFile,Prelog(LogStart),'Delete ',LocalPathDown+Lines[FilesOnLine[I]]^.Nome);
                      Flush(LogFile)
                   end;
                end;
             end;
             Lines[FilesOnLine[I]]^.Download := 0;
             Lines[FilesOnLine[I]]^.FreeDlTime := false;
             Lines[FilesOnLine[I]]^.FreeDlByte := false;
          end;
          RemFromLista(Lines[FilesOnLine[I]],InizioLista);
          if Lines[FilesOnLine[I]]^.Nome='' then
          begin
             {i commenti devono essere rimossi}
             CancellaDescrizione(Lines[FilesOnLine[I]]^.Descrizione);
             Dispose(Lines[FilesOnLine[I]]);
          end;
          Dec(I,DescLine[I]-1);
          SetNList(InizioLista);
          if I<2 then
          begin
             SkipDescLines := 0;
             I := 2;
          end;
          GetBuffer(FirstFile-1,ScreenLines,InizioLista);
          ModifiedFilesBbs := True
       end;
       ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
       if (FilesOnLine[I]<>0) and (Lines[FilesOnLine[I]]^.Nome='') then
       begin
          {la linea corrente e' un commento, se anche quella}
          {precedente era un commento allora fa il merge}
          if (I>2) then
          begin
             if Lines[FilesOnLine[I-1]]^.Nome='' then
             begin
                TempDesc := Lines[FilesOnLine[I]]^.Descrizione;
                PosDesc := 1;
                While TEmpDesc<>Nil do
                begin
                   L := TempDesc^.Descrizione^;
                   PutDescrizione(Lines[FilesOnLine[i-1]]^.Descrizione);
                   TempDesc := TempDesc^.Next;
                end;
                CancellaDescrizione(Lines[FilesOnLine[I]]^.Descrizione);
                Lines[FilesOnLine[I]]^.Descrizione := Nil;
                Lines[FilesOnLine[I]]^.Excluded := True;
                GetBuffer(FirstFile-1,ScreenLines,InizioLista);
                ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
             end;
          end else
          if (FirstFile>1) then
          begin
             if (Lines[0]^.Nome='') then
             begin
                Dec(FirstFile);
                Inc(SkipDescLines,NDescLines(Lines[0]^.Descrizione));
                TempDesc := Lines[FilesOnLine[I]]^.Descrizione;
                PosDesc := 1;
                While TEmpDesc<>Nil do
                begin
                   L := TempDesc^.Descrizione^;
                   PutDescrizione(Lines[0]^.Descrizione);
                   TempDesc := TempDesc^.Next;
                end;
                CancellaDescrizione(Lines[FilesOnLine[I]]^.Descrizione);
                Lines[FilesOnLine[I]]^.Descrizione := Nil;
                Lines[FilesOnLine[I]]^.Excluded := True;
                GetBuffer(FirstFile-1,ScreenLines,InizioLista);
                ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
             end;
          end;
       end;
       GotoXY(1,I);
    end {DEleteCurrent};


    Procedure EditCurrentLine;
    Begin
       I := WhereY;
       If FilesOnLine[I]<>0 then
       begin
          NLine := DescLine[I];
          TempStr := GetDesc(NLine,Lines[FilesOnLine[I]]^.Descrizione);
          if Lines[FilesOnLine[I]]^.Tagged then
             HighVideo
          else
          if (Lines[FilesOnLine[I]]^.Nome<>'') and (Lines[FilesOnLine[I]]^.Size=0) then
             LowVideo
          else
             NormVideo;
          EditLineFBbs(StartDesc[I],TempStr,PosStr,
             Lines[FilesOnLine[I]]^.Nome<>'',
             DescLine[I]=1,Lines[FilesOnLine[I]]^.FreeDlByte,
             Lines[FilesOnLine[I]]^.FreeDlTime,
             Lines[FilesOnLine[I]]^.Download,
             ScreenLines,SkipDescLines,NextLine,
             LocalNumero,NomeArea,NFiles,AllSize,ModifiedFilesBbs,TextAttr);
          if NLine=1 then
          begin
             J := 1;
             while (J<=length(TempStr)) and (tempStr[J]=' ') do
                inc(J);
             if (J<=length(TempStr)) then
             begin
                if pos(TempStr[J],LdChar)>0 then
                begin
                   {potrebbe essere la continuazione della descrizione del}
                   {file precedente}
                   if (I>2) then
                   begin
                      if Lines[FilesOnLine[I-1]]^.Nome<>'' then
                      begin
                         delete(TempStr,1,J);
                         if TempStr='' then
                            TempStr := '?';
                         PosDesc := 1;
                         while (TempStr<>'') do
                         begin
                            L := TempStr;
                            PutDescrizione(Lines[FilesOnLIne[I-1]]^.Descrizione);
                            if not RimDesc(NLine,Lines[FilesOnLine[I]]^.Descrizione) then
                            begin
                               Lines[FilesOnLine[I]]^.Excluded := True;
                               if Lines[FilesOnLine[I]]^.Tagged then
                               begin
                                  Lines[FilesOnLine[I]]^.Tagged := False;
                                  RemFromLista(Lines[FilesOnLine[I]],TaggedList);
                                  if Lines[FilesOnLine[I]]^.Nome<>'' then
                                  begin
                                     dec(NTaggedFiles);
                                     dec(TaggedSize,Lines[FilesOnLine[I]]^.Size);
                                  end;
                               end;
                               RemFromLista(Lines[FilesOnLine[I]],InizioLista);
                               CancellaDescrizione(Lines[FilesOnLine[I]]^.Descrizione);
                               Dispose(Lines[FilesOnLine[I]]);
                               {Esce dal ciclo}
                               TempStr := '';
                            end else
                            begin
                               {controlla la successiva linea del commento}
                                TempStr := Lines[FilesOnLine[I]]^.Descrizione^.Descrizione^;
                                J := 1;
                                while (J<=length(TempStr)) and (tempStr[J]=' ') do
                                   inc(J);
                                if (J<=length(TempStr)) then
                                begin
                                   if pos(TempStr[J],LdChar)>0 then
                                   begin
                                      Delete(TempStr,1,J);
                                      if TempStr='' then
                                         TempStr := '?';
                                   end else
                                      TempStr := '';
                                end else
                                   TempStr := '';
                            end;
                         end;
                         GetBuffer(FirstFile-1,ScreenLines,InizioLista);
                         ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
                         GotoXY(1,I);
                      end else
                         SetDesc(NLine,Lines[FilesOnLine[I]]^.Descrizione,TempStr);
                   end else
                   begin
                      {E' la prima riga}
                      if (FirstFile>1) and (Lines[0]^.Nome<>'') then
                      begin
                         Dec(FirstFile);
                         SkipDescLines := NDescLines(Lines[0]^.Descrizione);
                         delete(TempStr,1,J);
                         if TempStr='' then
                            TempStr := '?';
                         PosDesc := 1;
                         while (TempStr<>'') do
                         begin
                            L := TempStr;
                            PutDescrizione(Lines[0]^.Descrizione);
                            if not RimDesc(NLine,Lines[FilesOnLine[I]]^.Descrizione) then
                            begin
                               Lines[FilesOnLine[I]]^.Excluded := True;
                               if Lines[FilesOnLine[I]]^.Tagged then
                               begin
                                  Lines[FilesOnLine[I]]^.Tagged := False;
                                  RemFromLista(Lines[FilesOnLine[I]],TaggedList);
                                  if Lines[FilesOnLine[I]]^.Nome<>'' then
                                  begin
                                     dec(NTaggedFiles);
                                     dec(TaggedSize,Lines[FilesOnLine[I]]^.Size);
                                  end;
                               end;
                               RemFromLista(Lines[FilesOnLine[I]],InizioLista);
                               CancellaDescrizione(Lines[FilesOnLine[I]]^.Descrizione);
                               Dispose(Lines[FilesOnLine[I]]);
                               {Esce dal ciclo}
                               TempStr := '';
                            end else
                            begin
                               {controlla la successiva linea del commento}
                                TempStr := Lines[FilesOnLine[I]]^.Descrizione^.Descrizione^;
                                J := 1;
                                while (J<=length(TempStr)) and (tempStr[J]=' ') do
                                   inc(J);
                                if (J<=length(TempStr)) then
                                begin
                                   if pos(TempStr[J],LdChar)>0 then
                                   begin
                                      Delete(TempStr,1,J);
                                      if TempStr='' then
                                         TempStr := '?';
                                   end else
                                      TempStr := '';
                                end else
                                   TempStr := '';
                            end;
                         end;
                         GetBuffer(FirstFile-1,ScreenLines,InizioLista);
                         ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
                         GotoXY(1,I);
                      end else
                         SetDesc(NLine,Lines[FilesOnLine[I]]^.Descrizione,TempStr);
                   end;
                end else
                   SetDesc(NLine,Lines[FilesOnLine[I]]^.Descrizione,TempStr);
             end else
                SetDesc(NLine,Lines[FilesOnLine[I]]^.Descrizione,TempStr);
          end else
             SetDesc(NLine,Lines[FilesOnLine[I]]^.Descrizione,TempStr);
       end;
    end {EditCurrentLine};

    Procedure NormalChar;
    Var J: Integer;
    Begin
       I := WhereY;
       if FilesOnLine[I]=0 then
       begin
          {era l'ultima riga}
          if (WhereX>1) and (Ch<>#32) then
          begin
             L := ' ';
             LastComm := Nil;
             Commento;
             KbdBuffer := #0 + #205 + Ch;
             GetBuffer(FirstFile-1,ScreenLines,InizioLista);
             ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
             GotoXY(1,I);
          end else
             inc(PosStr);
       end else
       if (Ch<>' ') and (Ch<>'\') and (Ch<>'/') then
       begin
          Ch := UpCase(CH);
          if (FilesOnLine[I]<>0) and (DescLine[I]=1) and (Lines[FilesOnLine[I]]^.Nome<>'') and
             (PosStr <= length(Lines[FilesOnLine[I]]^.Nome) + 1) then
          begin
             TempNome := Lines[FilesOnLIne[I]]^.Nome;
             TempStr := TempNome;
             J := Pos('.',TempStr);
             if PosStr<=Length(TempStr) then
             begin
                if (Ch<>'.') or (J=0) then
                TempStr := Copy(TempStr,1,PosStr-1) + Ch +
                   Copy(TempStr,PosStr,Length(TempStr)-PosStr+1)
             end else
             begin
                if (Ch<>'.') then
                begin
                   TempStr := TempStr + ch                                   end else
                if (J=0) then
                begin
                   J := GetComp(PathDown+TempNome);
                   if (J>0) and (J<128) then
                   begin
                      TempStr := TempStr + Ch + Packer[J]^.Ext;
                   end else
                      TempStr := TempStr + Ch + '$$$';
                end;
             end;
             if (TempStr<>'') and (TempStr[length(TempStr)]='.') then
                dec(TempStr[0]);
             J := pos('.',TempStr);
             if J=10 then
             begin
                delete(TempStr,9,1)
             end else
             if (J>0) then
             begin
                if (length(TempStr)>J+3) then
                    dec(TempStr[0]);
             end else
             if length(TempStr)>8 then
                TempStr := Copy(TempStr,1,8);
             if (TempStr<>'') and (TempStr<>TempNome) then
             begin
                Assign(TempF,PathDown+TempNome);
                {FileMode := FmReadWrite;}
                if (Lines[FilesOnLine[I]]^.Size=0) then
                begin
                   TempSize := 0;
                   TempTime := 0;
                   SetNewData(InizioLista);
                   Lines[FilesOnLine[I]]^.Nome := TempStr;
                   TempNome := TempStr;
                   FindFirst(PathDown+TempStr,Archive+ReadOnly,S);
                   if DosError=0 then
                   begin
                      TempSize := S.Size;
                      TempTime := S.Time;
                      {$IFDEF OS2}
                      FindClose(S);
                      {$ENDIF}
                   end else
                   begin
                      TempSize := 0;
                      TempTime := 0;
                   end;
                   SetNewData(InizioLista);
                   ModifiedFilesBbs := True;
                   ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
                   GotoXY(1,I);
                end else
                begin
                   KbdBuffer := '';
                   for J := 1 to PosStr  do
                      KbdBuffer := KbdBuffer + #0 + #77;
                   ReadBox('Rename ' + TempNome, 12, TempStr);
                   TempStr := Upper(TempStr);
                   if (TempStr<>'') and (TempStr<>TempNome) then
                   begin
                      {$I-}
                      Rename(TempF,PathDown+TempStr);
                      {$I+}
                      if IOResult=0 then
                      begin
                         if wasAnnounce(TempNome, LocalNumero) then
                         begin
                            FillChar(Rec,SizeOf(Rec),0);
                            Move(TempStr[1],Rec.Nome[1],
                               Byte(TempStr[0]));
                            Rec.Area := LocalNumero;
                            AddAnnounceIdx(Rec);
                         end;
                         TempSize := 0;
                         TempTime := 0;
                         SetNewData(InizioLista);
                         Lines[FilesOnLine[I]]^.Nome := TempStr;
                         TempNome := TempStr;
                         FindFirst(PathDown+TempStr,Archive+ReadOnly,S);
                         if DosError=0 then
                         begin
                            TempSize := S.Size;
                            TempTime := S.Time;
                            {$IFDEF OS2}
                            FindClose(S);
                            {$ENDIF}
                         end else
                         begin
                            TempSize := 0;
                            TempTime := 0;
                         end;
                         SetNewData(InizioLista);
                         ModifiedFilesBbs := True;
                      end;
                   end;
                   ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
                   GotoXY(1,I);
                end
             end;
          end;
          Inc(PosStr)
       end else
          Inc(PosStr);
    end {NormalChar};

    Procedure PgDown;
    Begin
       if FilesOnLine[WhereY]<>0 then
       begin
          I := WhereY;
          Scroll := ScreenLines - 2;
          while (I<ScreenLines-1) and (FilesOnLine[I]<>0) do
          begin
             inc(I);
             inc(NCurrLine);
             dec(Scroll);
          end;
          if (I<ScreenLines-1) or (FilesOnLine[I]=0) then
          begin
             Scroll := 0;
             GotoXY(1,I)
          end;
          if Scroll>0 then
          begin
             I := NDescLines(Lines[FilesOnLine[ScreenLines-1]]^.Descrizione);
             while (Scroll>0) and (DescLine[ScreenLines-1]<I) do
             begin
                dec(I);
                dec(Scroll);
                inc(SkipDescLines);
                inc(NCurrLine);
             end;
             if Scroll>0 then
             begin
                FirstFile := FirstFile + FilesOnLine[ScreenLines-1];
                GetBuffer(FirstFile-1,ScreenLines,InizioLista);
                SkipDescLines := 0;
                ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
                dec(Scroll);
                inc(NCurrLine);
                I := 2;
                while (Scroll>0) and (FilesOnLine[I]<>0) do
                begin
                   inc(I);
                   inc(NCurrLine);
                   dec(Scroll);
                end;
                GotoXY(1,I)
             end else
             begin
                ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
                GotoXY(1,ScreenLines-1);
             end;
          end;
       end;
    end {PgDown};

    Procedure DelChar;
    Var J: Integer;
    begin
           if PosStr>1 then
           begin
              I := WhereY;
              if (FilesOnLine[I]<>0) and (DescLine[I]=1) and (Lines[FilesOnLine[I]]^.Nome<>'') and
                 (PosStr <= length(Lines[FilesOnLine[I]]^.Nome) + 1)
                then
              begin
                 TempNome := Lines[FilesOnLIne[I]]^.Nome;
                 TempStr := TempNome;
                 Delete(TempStr,PosStr-1,1);
                 if (TempStr<>'') and (TempStr[length(TempStr)]='.') then
                    Dec(TempStr[0]);
                 J := pos('.',TempStr);
                 if (J=0) and (length(TempStr)>8) then
                    TempStr := Copy(TempStr,1,8);
                 if (TempStr<>'') and (TempNome<>TempStr) then
                 begin
                    Assign(TempF,PathDown+TempNome);
                    {FileMode := FmReadWrite;}
                    if (Lines[FilesOnLine[I]]^.Size=0) then
                    begin
                       TempSize := 0;
                       TempTime := 0;
                       SetNewData(InizioLista);
                       Lines[FilesOnLine[I]]^.Nome := TempStr;
                       TempNome := TempStr;
                       FindFirst(PathDown+TempStr,Archive+ReadOnly,S);
                       if DosError=0 then
                       begin
                          TempSize := S.Size;
                          TempTime := S.Time;
                          {$IFDEF OS2}
                          Findclose(S);
                          {$ENDIF}
                       end else
                       begin
                          TempSize := 0;
                          TempTime := 0;
                       end;
                       SetNewData(InizioLista);
                       ModifiedFilesBbs := True;
                       ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
                       GotoXY(1,I);
                    end else
                    begin
                       KbdBuffer := '';
                       for J := 1 to PosStr-2 do
                          kbdBuffer := KbdBuffer + #0 + #77;
                       ReadBox('Rename ' + Tempnome, 12, tempstr);
                       TempStr := Upper(TempStr);
                       if (TempStr<>'') and (TempStr<>TempNome) then
                       begin
                          {$I-}
                          Rename(TempF,PathDown+TempStr);
                          {$I+}
                          if IOResult=0 then
                          begin
                             if wasAnnounce(TempNome, LocalNumero) then
                             begin
                                FillChar(Rec,SizeOf(Rec),0);
                                  Move(TempNome[1],Rec.Nome[1],
                                     Byte(TempNome[0]));
                                  Rec.Area := LocalNumero;
                                  AddAnnounceIdx(Rec);
                             end;
                             TempSize := 0;
                             TempTime := 0;
                             SetNewData(InizioLista);
                             Lines[FilesOnLine[I]]^.Nome := TempStr;
                             TempNome := TempStr;
                             FindFirst(PathDown+TempStr,Archive+ReadOnly,S);
                             if DosError=0 then
                             begin
                                TempSize := S.Size;
                                TempTime := S.Time;
                                {$IFDEF OS2}
                                findclose(S);
                                {$ENDIF}
                             end else
                             begin
                                TempSize := 0;
                                TempTime := 0;
                             end;
                             SetNewData(InizioLista);
                             ModifiedFilesBbs := True;
                          end;
                       end;
                       ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
                       GotoXY(1,I);
                    end;
                 end;
              end;
              dec(PosStr)
           end else
           if NCurrLine>1 then
           begin
              KbdBuffer := #0 + #72 + #0 + #205 + #0 + #79
           end;
     end;

     Procedure SendCurrent;
     Var
        HowSend: SendMode;
     begin
        I := WhereY;
        if (FilesOnLine[i]<>0) and (Lines[FilesOnLine[I]]^.Nome<>'') and
          (Lines[FilesOnLine[I]]^.Size<>0) then
        begin
           TempStr := '';
           Repeat
               ReadBox('Send To:',40,TempStr);
           until (TempStr='') or ParseAddr(TempStr, TempAddr, TempAddr);
           if TempStr<>'' then
           begin
              ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
              if Conferma('Delete ' + Lines[FilesOnLine[i]]^.Nome + ' after sent') then
                 HowSend := SendDelete
              else
                 HowSend := SendOnly;
              SendFile(TempAddr, LocalpathDown + Lines[FilesOnLine[I]]^.Nome, 'H',
                 HowSend, '');
           end;
           ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
           gotoxy(1,i);
        end;
     end;

     Procedure Detag(Pnt:ListaPtr; TagState: Boolean);
     begin
        if Pnt<>Nil then
        begin
           Detag(Pnt^.Sx, TagState);
           if (Pnt^.FileInfo<>Nil) and (pnt^.FileInfo^.Tagged <>TagState) then
           begin
              Pnt^.FileInfo^.Tagged := TagState;
              if TagState then
              begin
                 if Pnt^.FileInfo^.Nome<>'' then
                 begin
                    Inc(NTaggedFiles);
                    Inc(TaggedSize, Pnt^.FileInfo^.Size);
                 end;
                 PutInListaNo(TaggedList, Pnt^.FileInfo);
              end else
              begin
                 if Pnt^.FileInfo^.Nome<>'' then
                 begin
                    Dec(NTaggedFiles);
                    Dec(TaggedSize, Pnt^.FileInfo^.Size);
                 end;
                 RemFromLista(Pnt^.FileInfo, TaggedList);
              end;
           end;
           Detag(Pnt^.Dx, TagState);
        end;
     end {Detag};

     Procedure Down;
     begin
        if FilesOnLine[WhereY]<>0 then
        begin
           Inc(NCurrLine);
           I := WhereY;
           if I<ScreenLines-1 then
           begin
              GotoXY(1,I+1);
           end else
           begin
              Scroll := (ScreenLines - 2) div 2;
              I := i - scroll + 2;
              FirstFile := FirstFile + FilesOnLine[Scroll+1] -1;
              SkipDescLines := DescLine[Scroll+1] -1;
              GetBuffer(FirstFile-1,ScreenLines,InizioLista);
              ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
              {inc(NCurrLine);}
              GotoXY(1,I);
           end;
        end;
     end;

begin

  {$IFDEF NO4350}
  {$ELSE}
  if ModeFont8x8 then
     TextMode(Font8x8 + Co80);
  {$ENDIF}

  ScreenLines := Hi(WindMax) - Hi(WindMin) + 1;

  if dosmode then
     ImportOrphans(InizioLista);
  GetBuffer(0,ScreenLines,InizioLista);
  KbdBuffer := '';
  PosStr := 1;
  NextLine := '?';
  TaggedList := Nil;
  TaggedSize := 0;
  NTaggedFiles := 0;

  GarbageCollect(InizioLista);

  FirstFile := 1;
  SkipDescLines := 0;
  NCurrLine := 1;

  if SearchStr<>'' then
  begin
     TagSearched(TaggedList);
     if (TaggedList<>Nil) then
     begin
        {si posiziona sul primo file taggato}
        GetNumbers(taggedList^.FileInfo,NCurrLine,FirstFile);
        GetBuffer(FirstFile-1,ScreenLines,InizioLista);
     end;
     SearchStr := ''
  end;

  ClrScr;
  ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);

  repeat
     {Scrive le informazioni sul file nell'ultima riga}
     PrevY := WhereY;
     GotoXY(1,ScreenLines);
     InvVideo;
     if ModifiedFilesBbs then
        Write(#15)
     else
        Write(' ');

     if FilesOnLine[PrevY]<>0 then
     begin
        if Lines[FilesOnLine[PrevY]]^.Nome='' then
        begin
           Write('Comment Line');
        end else
        begin
           if Lines[FilesOnLine[PrevY]]^.Size=0 then
           begin
              Write(Lines[FilesOnLine[PrevY]]^.Nome,
                 '':13-length(Lines[FilesOnLine[PrevY]]^.Nome),
                 ' ',OffLineStr)
           end else
           begin
              UnPackTime(Lines[FilesOnLine[PrevY]]^.Time,T);
              MyDateStr(T);
              if ShortSize then
              begin
                Write(Lines[FilesOnLine[PrevY]]^.Nome,
                 '':13-length(Lines[FilesOnLine[PrevY]]^.Nome),
                 Lines[FilesOnLine[PrevY]]^.Size div 1024:5,'k  ',PrevDataStr);
              end else
              begin
                Write(Lines[FilesOnLine[PrevY]]^.Nome,
                 '':13-length(Lines[FilesOnLine[PrevY]]^.Nome),
                 Lines[FilesOnLine[PrevY]]^.Size:8,'  ',PrevDataStr);
              end;
           end;
        end;
     end else
     begin
        Write('End of Files.Bbs');
     end;
     Write('':40-WhereX,MemAvail:8,NTaggedFiles:6,
        BytesStr(TaggedSize):12,PosStr:7,':',NCurrLine);
     Write('':80-WhereX);
     GotoXY(PosStr,PrevY);

     if FilesOnLine[PrevY]=0 then
        NormVideo
     else
     begin
        if Lines[FilesOnLine[PrevY]]^.Tagged then
           HighVideo
        else
           NormVideo;
     end;
     waitevent;
     if KeyPressed then
     begin
        ch := ReadKey;
        if ch=#0 then
        begin
           ch := ReadKey;
           case ch of
              #59:{F1=Help}
                 begin
                    I := WhereY;
                    ShowHelp;
                    ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
                    if (KbdBuffer=#0#84) or (KbdBuffer=#0#85) then
                    begin
                       if PosStr >= StartDesc[i] then
                          KbdBuffer := #0#205 + KbdBuffer
                       else
                          KbdBuffer := '';
                    end;
                    gotoxy(1,i);
                 end;
              #48:{Alt-B=Get Desc from LList.Db}
                 Begin
                    SearchDupes;
                    {
                    I := WhereY;
                    if (FilesOnLine[I]<>0) and
                       (Lines[FilesOnLine[I]]^.Nome<>'') then
                    begin
                       L := GetDescFromDB(Lines[FilesOnLine[I]]^.Nome);
                       if L<>'' then
                       begin
                          ModifiedFilesBbs := True;
                          PosDesc := 1;
                          PutDescrizione(Lines[FilesonLine[I]]^.Descrizione);
                          ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
                          gotoxy(1,i)
                       end else
                          Beep;
                    end;
                    }
                 End;
              #35:{Alt-H=Hatch}
                 Begin
                    HatchCurrent;
                 End;
              #30:{Alt-A=Announce}
                 Begin
                    AnnounceCurrent;
                 End;
              #60:{F2=Save}
                 if ModifiedFilesBbs then
                 begin
                    FixFBbs1 := RewriteFbbs;
                    if FixFbbs1 then
                    begin
                       if not DosMode then
                          PutInListaAree(LOcalNumero,LocalNumero,UpDateFileIdx);
                       LlistStatus := FixFBbs;
                       if FixFBbsHeader then
                       begin
                          {aggiunge un nuovo header}
                          TempWord := HdrStyle;
                          HdrStyle := 1;
                          HeadArea(VariText,LocalNumero,NomeArea,NFiles,AllSize);
                          HdrStyle := TempWord;
                       end;
                       MostraLista(InizioLista);
                       LListStatus := EditFilesBbs;
                       CloseFbbs;
                       ModifiedFilesBbs := False;
                       FixFBbs1 := False;
                    end;
                 end;
              #62,#61:{F4=Move tagged}
                 begin
                    I := WhereY;
                    If ((FilesOnLine[I]=0) or
                      (not Lines[FilesOnLIne[I]]^.Tagged and (DescLine[I]=1))) and
                         (TaggedList<> Nil)  then
                    begin
                      ModifiedFilesBbs := True;
                      RemTagged(TaggedList);
                      if FilesOnLine[I]=0 then
                         TempFileInfoPtr := Nil
                      else
                         TempFileInfoPtr := Lines[FilesOnLine[I]];
                      if ch=#62 then
                      begin
                         InsertTagged(InizioLista,TempFileInfoPtr,
                            TaggedList,No);
                      end else
                      begin
                         InsertTagged(InizioLista,TempFileInfoPtr,
                            TaggedList,Alfa);
                      end;
                      DeTag(InizioLista, False);
                      GarbageCollect(InizioLista);
                      GetNumbers(TempFileInfoPtr,NCurrLine,FirstFile);
                      SkipDescLines := 0;
                      J := I;
                      while (I>2) and (FirstFile>1) do
                      begin
                         Dec(FirstFile);
                         GetBuffer(FirstFile-1,ScreenLines,InizioLista);
                         Dec(I,NDescLines(Lines[1]^.Descrizione));
                         if I<2 then
                         begin
                            SkipDescLines := 2 - I;
                            I := 2;
                         end;
                      end;
                      I := J + 2 - I;
                      GetBuffer(FirstFile-1,ScreenLines,InizioLista);
                      CancellaLista(TaggedList);
                      NTaggedFiles := 0;
                      TaggedSize := 0;
                      TaggedList := Nil;
                      SetNList(InizioLista);
                      ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
                      gotoxy(1,i);
                    end;
                 end;
              #67:{Dos-Shell}
                 Begin
                    I := WhereY;
                    {$IFDEF NO4350}
                    {$ELSE}
                    if ModeFont8x8 then
                       TextMode(CO80);
                    {$ENDIF}
                    TextAttr := StartAttr;
                    ClrScr;
                    GotoXY(1,10);
                    DosShell;
                    {$IFDEF NO4350}
                    {$ELSE}
                    if ModeFont8x8 then
                       TextMode(Font8x8+Co80);
                    {$ENDIF}
                    ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
                    gotoxy(1,i);
                 End;
              #17:{Alt-W=Find string}
                 Begin
                    Find;
                 End;
              #46,#50:{Alt-C/Alt-M=Copy/Move current/tagged}
                 begin
                    CopyMove;
                 end;
              #71:{Home}
                 begin
                    PosStr := 1;
                 end;
              #79:{End}
                 begin
                    if FilesOnLine[WhereY]<>0 then
                    begin
                       KbdBuffer := #0 + #205 + #0 + #79
                    end;
                 end;
              #129:{Alt-0=Tag missing files}
                 begin
                    I := WhereY;
                    TagMissing(InizioLista,TaggedList,NTaggedFiles,taggedSize);
                    ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
                    gotoxy(1,i);
                 end;
              #34:{Alt-G=Tag dupes files}
                 begin
                    I := WhereY;
                    TagDupes(InizioLista,TaggedList);
                    ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
                    gotoxy(1,i);
                 end;
              #49:{Alt-N=Tag new files}
                 begin
                    I := WhereY;
                    TagNew(TaggedList,InizioLista,NTaggedFiles,TaggedSize);
                    ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
                    gotoxy(1,i);
                 end;
              #22:{Alt-U=UnTag all files}
                 begin
                    I := WhereY;
                    DeTag(InizioLista, NTaggedFiles = 0);
                    ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
                    gotoxy(1,i);
                 end;
              #16:{Alt-Q=Mark to announce}
                 if not dosmode then
                 begin
                    I := WhereY;
                    FillChar(Rec,SizeOf(Rec),0);
                    Move(Lines[FilesOnLine[I]]^.Nome[1],Rec.Nome[1],
                       Byte(Lines[FilesOnLine[I]]^.Nome[0]));
                    Rec.Area := LocalNumero;
                    AddAnnounceIdx(Rec);
                    ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
                    GotoXY(1, I);
                 end;
              #20:{Alt-T=Tag current files}
                 begin
                    I := WhereY;
                    if FilesOnLIne[I]<>0 then
                    begin
                       if Lines[FilesOnLine[I]]^.Tagged then
                       begin
                          {Un-Tag}
                          Lines[FilesOnLine[I]]^.Tagged := False;
                          RemFromLista(Lines[FilesOnLIne[I]],TaggedList);
                          if Lines[FilesOnLine[I]]^.Nome<>'' then
                          begin
                             dec(NTaggedFiles);
                             dec(TaggedSize,Lines[FilesOnLine[I]]^.Size);
                          end;
                       end else
                       begin
                          Lines[FilesOnLine[I]]^.Tagged := True;
                          PutInListaNo(TaggedLIst,Lines[FilesOnLine[I]]);
                          if Lines[FilesOnLine[I]]^.Nome<>'' then
                          begin
                             inc(NTaggedFiles);
                             inc(TaggedSize,Lines[FilesOnLine[I]]^.Size);
                          end;
                       end;
                       {Va al file successivo}
                       Scroll := NDescLines(Lines[FilesOnLine[I]]^.Descrizione) -
                          DescLine[I] + 1;
                       inc(NCurrLine,Scroll);
                       inc(I,Scroll);
                       if I>ScreenLines - 1 then
                       begin
                          {il file successivo inizia alla pagina seguente}
                          FirstFile := FirstFile + FilesOnLine[ScreenLines - 1];
                          SkipDescLines := 0;
                          I := 2;
                          GetBuffer(FirstFile-1,ScreenLines,InizioLista);
                       end;
                       ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
                       gotoxy(1,i);
                    end;
                 end;
              #32:{Alt-D=cancella file e descrizione}
                 begin
                    DeleteCurrent(True);
                 end;
              #31:{Alt-S=Send File}
                 SendCurrent;
              #203:{Alt-M=Merge Descrizione}
                 begin
                    I := WhereY;
                    MergeDesc(DescLine[I],Lines[FilesOnLine[I]]^.Descrizione);
                    ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
                    gotoxy(1,i);
                    ModifiedFilesBbs := True
                 end;
              #24:{Alt-O=Import Orphans}
                 begin
                    I := WhereY;
                    ImportOrphans(InizioLista);
                    GetBuffer(FirstFile-1,ScreenLines,InizioLista);
                    ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
                    gotoxy(1,i);
                 end;
              #25:{Alp-P=Comprime le linee di descrizione}
                 begin
                    I := WhereY;
                    If (FilesOnLine[I]<>0) and (Lines[FilesOnLine[I]]^.Nome<>'') then
                    begin
                       ModifiedFilesBBs := True;
                       PackDesc(Lines[FilesOnLine[I]]^.Descrizione,True);
                       Dec(NCurrLine,DescLine[I]-1);
                       Dec(I,DescLine[I]-1);
                       if I<2 then
                       begin
                          Inc(SkipDescLines,I-2);
                          I := 2;
                       end;
                       ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
                       gotoxy(1,i);
                    end;
                 end;
              #204:{Alt-A=Insert a description line BEFORE}
                 begin
                    I := WhereY;
                    if (FilesOnLine[I]<>0) and (Lines[FilesOnLIne[I]]^.Nome<>'') then
                    begin
                       ModifiedFilesBbs := True;
                       AddDescLine(DescLine[I],Lines[FilesOnLIne[I]]^.Descrizione,
                          NextLine);
                       ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
                       gotoxy(1,i);
                    end;
                    NextLine := '?';
                 end;
              #202:{Alt-N=Insert a description line AFTER}
                 begin
                    I := WhereY;
                    if (FilesOnLine[I]<>0) then
                    begin
                       ModifiedFilesBbs := True;
                       AddDescLine(DescLine[I]+1,Lines[FilesOnLIne[I]]^.Descrizione,
                          NextLine);
                       ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
                       GotoXY(1,I);
                    end;
                    NextLine := '?';
                 end;
              #201:{Alt-Y=Delete description line}
                 begin
                    I := WhereY;
                    If (FilesOnLine[I]<>0) then
                    begin
                       ModifiedFilesBBs := True;
                       NLine := DescLine[I];
                       if (NDescLines(Lines[FilesOnLine[I]]^.Descrizione)=1) or
                         not RimDesc(NLine,Lines[FilesOnLine[I]]^.Descrizione) then
                       begin
                          {Cancellazione totale}
                          DeleteCurrent(False)
                       end else
                       begin
                          ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
                          GotoXY(1,I);
                       end;
                    end;
                 end;
              #200:{va all'inizio della descrizione}
                 begin
                    PosStr := StartDesc[WhereY];
                 end;
              #23:{Alt-I=Import File_Id.Diz}
                 begin
                    I := WhereY;
                    If (FilesOnLine[I]<>0) and (Lines[FilesOnLine[I]]^.Nome<>'') and
                       (Lines[FilesOnLine[I]]^.Size>0) then
                    begin
                       {$IFDEF NO4350}
                       {$ELSE}
                       if ModeFont8x8 then
                          TextMode(CO80);
                       {$ENDIF}
                       TextAttr := StartAttr;
                       ClrScr;
                       GotoXY(1,10);
                       Comp := 0;
                       if ImportDesc(LocalPathDown+Lines[FilesOnLIne[I]]^.Nome,Comp,
                           Lines[FilesOnLine[I]]^.Descrizione) then
                       begin
                          {$IFDEF NO4350}
                          {$ELSE}
                          if ModeFont8x8 then
                             TextMode(Font8x8+Co80);
                          {$ENDIF}
                          ModifiedFilesBbs := True;
                          Dec(NCurrLine,DescLine[I]-1);
                          Dec(I,DescLine[I]-1);
                          if I<2 then
                          begin
                             SkipDescLines := 0;
                             I := 2;
                          end;
                       end else
                       begin
                          {$IFDEF NO4350}
                          {$ELSE}
                          if ModeFont8x8 then
                             TextMode(Font8x8+Co80);
                          {$ENDIF}
                       end;
                       ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
                       GotoXY(1,I);
                    end;
                 end;
              #18:{Alt-E=Update file}
                 begin
                    I := WhereY;
                    if (FilesOnLine[I]<>0) and (Lines[FilesOnLine[I]]^.Nome<>'') then
                    begin
                       if UpDate(LocalPathDown+Lines[FilesOnLine[I]]^.Nome) then
                       begin
                          TempTime := ActDate;
                          TempSize := Lines[FilesOnLine[I]]^.Size;
                          TempNome := Lines[FilesOnLine[I]]^.Nome;
                          SetNewData(InizioLista);
                          ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
                          GotoXY(1,I);
                       end;
                    end;
                 end;
              #44:{Alt-Z=Check Virus}
                 begin
                    CheckCurrent;
                 end;
              {$IFDEF NO4350}
              {$ELSE}
              #37:{alt-K, switch 25 - 43/50 lines}
                 begin
                    I := WhereY;
                    ModeFont8X8 := not ModeFont8X8;
                    if ModeFont8x8 then
                    begin
                       TextMode(Font8x8 + Co80);
                    end else
                    begin
                       TextMode(CO80);
                    end;
                    ScreenLines := Hi(WindMax) - Hi(WindMin) +1;
                    if I >= ScreenLines then
                    begin
                       {nel nuovo schermo, non rientra nella pagina}
                       Inc(SkipDescLines, I - ScreenLines + 1);
                       GetBuffer(FirstFile-1,ScreenLines,InizioLista);
                       I := ScreenLines - 1;
                    end;
                    ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
                    GotoXY(1,I);
                 end;
              {$ENDIF}
              #19:{Alt-R=Change to Repack}
                 begin
                    I := WhereY;
                    If (FilesOnLine[I]<>0) and (Lines[FilesOnLine[I]]^.Nome<>'') and
                       (Lines[FilesOnLine[I]]^.Size>0) then
                    begin
                       TempStr := Repack;
                       ReadBox('Packer',3,TempStr);
                       if length(TempStr)=3 then
                       begin
                          Repack := Upper(TempStr);
                          {$IFDEF NO4350}
                          {$ELSE}
                          if ModeFont8x8 then
                             TextMode(CO80);
                          {$ENDIF}
                          TextAttr := StartAttr;
                          ClrScr;
                          GotoXY(1,10);
                          TempStr1 := Lines[FilesOnLine[I]]^.Nome;
                          PrevSize := Lines[FilesOnLine[I]]^.Size;
                          Comp := 0;
                          if ChangeToRepack(LocalPathDown,TempStr1,Comp,PrevSize,
                             Lines[FilesOnLine[I]]^.Time) then
                          begin
                             if wasAnnounce(TempNome, LocalNumero) then
                             begin
                                FillChar(Rec,SizeOf(Rec),0);
                                Move(lines[FilesOnLine[i]]^.Nome[1],Rec.Nome[1],
                                   Byte(Lines[filesonline[i]]^.nome[0]));
                                Rec.Area := LocalNumero;
                                AddAnnounceIdx(Rec);
                             end;
                             PrevTime := Lines[FilesOnLine[I]]^.Time;
                             TempNome := Lines[FilesOnLIne[I]]^.Nome;
                             TempSize := 0;
                             TempTime := 0;
                             SetNewData(InizioLista);
                             Lines[FilesOnLine[I]]^.Nome := TempStr1;
                             TempNome := TempStr1;
                             TempSize := PrevSize;
                             TempTime := PrevTime;
                             SetNewData(InizioLista);
                             ModifiedFilesBbs := True;
                          end;
                          {$IFDEF NO4350}
                          {$ELSE}
                          if ModeFont8x8 then
                             TextMode(Font8x8+Co80);
                          {$ENDIF}
                       end;
                       ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
                       GotoXY(1,I);
                    end;
                 end;
              #104..#113:{Alt-F<N>}
                 begin
                    I := WhereY;
                    If (FilesOnLine[I]<>0) and (Lines[FilesOnLine[I]]^.Nome<>'') and
                       (ExternalShell[ord(ch)-103]<>'') and
                       (Lines[FilesOnLine[I]]^.Size>0) then
                    begin
                       {$IFDEF NO4350}
                       {$ELSE}
                       if ModeFont8x8 then
                          TextMode(CO80);
                       {$ENDIF}
                       TextAttr := StartAttr;
                       ClrScr;
                       GotoXY(1,10);
                       ExecuteExternalShell(Ord(Ch)-103,
                          LocalPathDown+Lines[FilesOnLine[I]]^.Nome);
                       {$IFDEF NO4350}
                       {$ELSE}
                       if ModeFont8x8 then
                          TextMode(Font8x8+Co80);
                       {$ENDIF}
                       {La shell potrebbe avere modificato il file}
                       FindFirst(LocalPathDown+Lines[FilesOnLine[I]]^.Nome,
                          Archive+ ReadOnly,S);
                       if DosError<>0 then
                       begin
                          S.Size := 0;
                          S.Time := 0;
                       end
                       {$IFDEF OS2}
                       else findclose(S)
                       {$ENDIF}
                       ;

                       TempSize := S.Size;
                       TempTime := S.Time;
                       TempNome := Lines[FilesOnLine[I]]^.Nome;
                       SetNewData(InizioLista);
                       ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
                       GotoXY(1,I)
                    end;
                 end;
              #47:{Alt-V=View Content}
                 begin
                    I := WhereY;
                    If (FilesOnLine[I]<>0) and (Lines[FilesOnLine[I]]^.Nome<>'') and
                       (Lines[FilesOnLine[I]]^.Size>0) then
                    begin
                       ViewCompressed(LocalPathDown+Lines[FilesOnLine[I]]^.Nome,Output);
                       {La shell potrebbe avere modificato il file}
                       FindFirst(LocalPathDown+Lines[FilesOnLine[I]]^.Nome,
                          Archive+ ReadOnly,S);
                       if DosError<>0 then
                       begin
                          S.Size := 0;
                          S.Time := 0;
                       end
                       {$IFDEF OS2}
                       else findclose(S)
                       {$ENDIF}
                       ;
                       TempSize := S.Size;
                       TempTime := S.Time;
                       TempNome := Lines[FilesOnLine[I]]^.Nome;
                       SetNewData(InizioLista);
                    end;
                    ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
                    GotoXY(1,I);
                 end;
              #63:{F5=Look at Files.Bbs}
                 begin
                    I := WhereY;
                    If (FilesOnLine[I]<>0) then
                    begin
                       NormVideo;
                       ClrScr;
                       GotoXY(1,10);
                       MostraLista1(Lines[FilesOnLIne[I]],Output);
                       Presskey;
                    end;
                    ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
                    GotoXY(1,I);
                 end;
              #77:begin
                     if PosStr<78 then
                        inc(PosStr);
                  end;
              #75:begin
                     if PosStr>1 then
                        dec(PosStr);
                  end;
              #83:begin
                     I := WhereY;
                     if (FilesOnLine[I]<>0) and (DescLine[I]=1) and (Lines[FilesOnLine[I]]^.Nome<>'') and
                        (PosStr <= length(Lines[FilesOnLine[I]]^.Nome))
                       then
                     begin
                        TempNome := Lines[FilesOnLIne[I]]^.Nome;
                        TempStr := TempNome;
                        Delete(TempStr,PosStr,1);
                        if (TempStr<>'') and (TempStr[length(TempStr)]='.') then
                           dec(TempStr[0]);
                        J := pos('.',TempStr);
                        if (J=0) and (length(TempStr)>8) then
                           TempStr := Copy(TempStr,1,8);
                        if (TempStr<>'') and (TempNome<>TempStr) then
                        begin
                           Assign(TempF,PathDown+TempNome);
                           {FileMode := FmReadWrite;}
                           if (Lines[FilesOnLine[I]]^.Size=0) then
                           begin
                              TempSize := 0;
                              TempTime := 0;
                              SetNewData(InizioLista);
                              Lines[FilesOnLine[I]]^.Nome := TempStr;
                              TempNome := TempStr;
                              FindFirst(PathDown+TempStr,Archive+ReadOnly,S);
                              if DosError=0 then
                              begin
                                 TempSize := S.Size;
                                 TempTime := S.Time;
                                 {$IFDEF OS2}
                                 findclose(S);
                                 {$ENDIF}
                              end else
                              begin
                                 TempSize := 0;
                                 TempTime := 0;
                              end;
                              SetNewData(InizioLista);
                              ModifiedFilesBbs := True;
                              ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
                              GotoXY(1,I);
                           end else
                           begin
                              KbdBuffer := '';
                              for J := 1 to PosStr - 1 do
                                 KbdBuffer := KbdBuffer + #0 + #77;
                              ReadBox('Rename ' + TempNome, 12, TempStr);
                              TempStr := Upper(TempStr);
                              if (TempStr<>'') and (TempStr<>TempNome) then
                              begin
                                 {$I-}
                                 Rename(TempF,PathDown+TempStr);
                                 {$I+}
                                 if IOResult=0 then
                                 begin
                                    if wasAnnounce(TempNome, LocalNumero) then
                                    begin
                                       FillChar(Rec,SizeOf(Rec),0);
                                       Move(TempStr[1],Rec.Nome[1],
                                          Byte(TempStr[0]));
                                       Rec.Area := LocalNumero;
                                       AddAnnounceIdx(Rec);
                                    end;
                                    TempSize := 0;
                                    TempTime := 0;
                                    SetNewData(InizioLista);
                                    Lines[FilesOnLine[I]]^.Nome := TempStr;
                                    TempNome := TempStr;
                                    FindFirst(PathDown+TempStr,Archive+ReadOnly,S);
                                    if DosError=0 then
                                    begin
                                       TempSize := S.Size;
                                       TempTime := S.Time;
                                       {$IFDEF OS2}
                                       Findclose(S);
                                       {$ENDIF}
                                    end else
                                    begin
                                       TempSize := 0;
                                       TempTime := 0;
                                    end;
                                    SetNewData(InizioLista);
                                    ModifiedFilesBbs := True;
                                 end;
                              end;
                              ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
                              GotoXY(1,I);
                           end;
                        end;
                     end;
                  end;
              #205:{Alt-E=Edit}
                 begin
                    EditCurrentLine;
                 end;
              #72:{up}
                 if NCurrLine<>1 then
                 begin
                    I := WhereY;
                    dec(NCurrLine);
                    if I>2 then
                    begin
                       GotoXY(1,I-1);
                    end else
                    begin
                       {convertire in un Page-Up!}
                       dec(i);
                       Scroll := (ScreenLines - 2) div 2;
                       while (Scroll>0) do
                       begin
                          while (SkipDescLines>0) and (Scroll>0) do
                          begin
                             {dec(NCurrLine);}
                             dec(SkipDescLines);
                             dec(Scroll);
                             inc(i);
                          end;
                          if (Scroll>0) then
                          begin
                             if FirstFile>1 then
                             begin
                                dec(FirstFile);
                                GetBuffer(FirstFile-1,ScreenLines,InizioLista);
                                {dec(NCurrLine);}
                                dec(Scroll);
                                inc(i);
                                SkipDescLines := NDescLines(Lines[1]^.Descrizione)-1;
                             end else
                                Scroll := 0;
                          end;
                       end;
                       ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
                       GotoXY(1, I);
                    end;
                 end;
              #73:{page-up}
                 if NCurrLine>1 then
                 begin
                    Scroll := ScreenLines - 2;
                    I := WhereY;
                    if I>2 then
                    begin
                       dec(Scroll,I-2);
                       dec(NCurrLine,I-2);
                    end;
                    if NCurrLine>1 then
                    begin
                       while (Scroll>0) do
                       begin
                          while (SkipDescLines>0) and (Scroll>0) do
                          begin
                             dec(NCurrLine);
                             dec(SkipDescLines);
                             dec(Scroll);
                          end;
                          if (Scroll>0) then
                          begin
                             if FirstFile>1 then
                             begin
                                dec(FirstFile);
                                GetBuffer(FirstFile-1,ScreenLines,InizioLista);
                                dec(NCurrLine);
                                dec(Scroll);
                                SkipDescLines := NDescLines(Lines[1]^.Descrizione)-1;
                             end else
                                Scroll := 0;
                          end;
                       end;
                       ShowBuffer(SkipDescLines,ScreenLines,LocalNumero,NomeArea,NFiles,allsize);
                    end else
                       GotoXY(1,2);
                 end;
              #81:{Page-Down}
                 PgDown;
              #80:{Down}
                 Down;

              else
                 Beep;
              end
           end else
           if ch=#25 then
           begin
              KbdBuffer := #0 + #201
           end else
           if ch=#8 then
           begin
              DelChar;

           end else
           if Ch=#13 then
           begin
              CR;

           end else
           if Ch>=#32 then
           begin
              NormalChar;
           end;

     end else
     begin
        {premuto il mouse}
        MouGet(MouInfo);
        if MouInfo.Cy=0 then
        begin
           {prima riga, stampa il menu'...}
           Kbdbuffer := #0 + #59;
        end else
        if MouInfo.cx=79 then
        begin
           {ultima colonna}
           if MouInfo.cy = 1 then
              KbdBuffer := #0 + #73
           else
           if MouInfo.cy = screenlines - 2 then
              KbdBuffer := #0 + #81;
        end else
        if MouInfo.cy < screenlines - 1 then
        begin
           PosStr := MouInfo.cx + 1;
           I := MouInfo.Cy + 1;
           Inc(NCurrLine, I - WhereY);
           if FilesOnLine[i]=0 then
           begin
              while (i>1) and (FilesOnLine[i-1]=0) do
              begin
                 dec(i);
                 dec(nCurrLine);
              end;
           end;
           if MouInfo.IsDouble then
              KbdBuffer := #0 + #47;
           GotoXY(1, I);
        end;
        Ch := #0;
     end;
     if not moucheck and (KbdBuffer='') and (FilesOnLine[WhereY]<>0) and (PosStr >= StartDesc[WhereY]) then
        KbdBuffer := #0 + #205;
  until (ch=#27);

  if ModifiedFilesBbs and
     Conferma('Files.Bbs was modified; save now') then
  begin
     FixFbbs1 := RewriteFbbs;
     if FixFbbs1 then
     begin
        if not dosmode then
           PutInListaAree(LOcalNumero,LocalNumero,UpDateFileIdx);
        LlistStatus := FixFBbs;
        if FixFBbsHeader then
        begin
           {aggiunge un nuovo header}
           TempWord := HdrStyle;
           HdrStyle := 1;
           HeadArea(VariText,LocalNumero,NomeArea,NFiles,AllSize);
           HdrStyle := TempWord;
        end;
        MostraLista(InizioLista);
        LListStatus := EditFilesBbs;
        CloseFbbs;
        ModifiedFilesBbs := False;
        FixFBbs1 := False;
     end
  end;
  {$IFDEF NO4350}
  {$ELSE}
  if ModeFont8x8 then
     TextMode(CO80);
  {$ENDIF}
  NormVideo;
  ClrScr;
  GotoXY(1,1);

  CancellaLista(TaggedList);
end {EditFilesBbs};


   Procedure RemoveComments(Pnt:ListaPtr);
   begin
      if Pnt<>Nil then
      begin
         RemoveComments(Pnt^.Sx);
         if (Pnt^.FileInfo<>Nil) and (Pnt^.FileInfo^.Nome='') then
         begin
            {Questo e' un commento}
            CancellaDescrizione(Pnt^.FileInfo^.Descrizione);
            Dispose(Pnt^.FileInfo);
         end;
         RemoveComments(Pnt^.Dx);
      end;
   end {RemoveComments};


Begin

   if bbs=Ra250 then
      fb := new(FbManagePtr, Init(LocalNumero));

   if (LocalNumero>=0) then
      Lock(D0+'Area'+Long2Str(LOcalNumero,0));

   MakeNew := MakeNew and (LlistStatus=MakeListCmp) and not IsCdRom;

   AllSize := 0;
   NewSize := 0;
   NFiles := 0;
   NNewFiles := 0;
   TotDownload := 0;

   DupesExcluded := 0;
   OffLIneExcluded := 0;
   NOrfani := 0;

   if NoDlPath then
   begin
      Unknow := Attr and 2 <> 0;
      Know := Attr and 4 <> 0;
      Protected := Attr and 8 <> 0;
   end else
   begin
      Unknow := True;
      Know := True;
      Protected := True;
   end;

   FirstShell := not quietmode;

   if (Attr and 64<>0) or (LListStatus=Announce) then
      LenDate := 0
   else
      LenDate := Length(PrevDataStr) + 1;

   if ShortSize then
      dec(LenDate,2);

   If not QuietMode then
   begin
      if Not FirstArea then
      begin
         {fa in modo che non scorra la prima riga, con i report}
         inc(WindMin, 256);
         writeln(#13'   ц');
         {ristabilisce le dimensioni originali della finestra}
         dec(WindMin, 256);
      end else FirstArea := False;
      Write('   юд',LOcalNumero:4,' - ',NomeArea,'':52-length(NomeArea));
   end else
   begin
      FirstArea := False;
   end;

   {Crea Albero, in ordine senza duplicati!}
   First := Nil;
   InizioLista := Nil;
   ListaNewFiles := Nil;
   PosLista := Addr(InizioLista);

   if (LListStatus=MakeListCmp) and (MaxBest1>0) then
   begin
      MinDl := Best^[1].DownLoad
   end else
      MinDl := MaxInt;

   if (LListStatus<>MakeSearch) then
   begin
      FindFirst(LocalPathDown+'*.*',archive+readonly,S);
      While DosError = 0 do
      begin
         TempNome := S.Name;
         TempTime := S.Time;
         TempSize := S.Size;
         if (TempSize>0) and
             (
               (LListStatus<>Announce)
                 or
               (
                (
                 not IsInIndex(S.Name,LocalNumero,FilesIdxTot,Right1)
                    or
                 IsInIndex(S.Name,LocalNumero,AnnounceIdx,RightAnnounceIdx)
                ) and
                (
                 (Filter=Nil) or FileMatchFilter(S.Name, Filter)
                )
               )
             ) then
            PutInAlbero(First);
         FindNext(S);
      end;
   end;

   {Mette descrizioni e aggiunge OffLine files}
   if (First<>Nil) or (OffLIne) or
      (LlistStatus=MakeSearch) then
   begin
      if OpenFbbs then
      begin
         LastDesc := Nil;
         LastComm := Nil;
         TempPCB := False;
         while GetDescLine(L) do
         Begin
            Len := Length(L);
            if (L='') then
            begin
               posdesc := 1;
               commento;
            end else
            if (L[1]=' ') then
            begin
               J := 2;
               while (J<=len) and (L[J]=' ') do
                  inc(J);
               if (J<=len) and (Pos(L[J],LdChar)>0) then
               begin
                  {se LastDesc=Nil, il file a cui si riferisce la
                  descrizione era stato scartato}
                  if (LastDesc<>Nil) then
                  begin
                     inc(J);
                     if TempPCB and (J<=len) and (L[J]=' ') then
                        inc(J);
                     PosDesc := J;
                     PutDescrizione(LastDesc);
                  end;
               end else
               begin
                  {era una linea di commento}
                  PosDesc := 2;
                  Commento;
               end;
            end else
            if (L[1]<>'%') and (L[1]<>'!') then
            begin
               I := 1;
               while (I<=len) and (L[I]<>' ') do
               begin
                  TempNome[I] := UpCase(L[I]);
                  inc(I);
               end;
               Byte(TempNome[0]) := I - 1;
               while (I<=len) and (L[I]=' ') do
                  inc(I);
               J := I;
               {ignora i successivi due campi, che contengono SIZE e DATA}
               {ignora SIZE}
               while (I<=len) and (L[I] in ['0'..'9']) do
                  inc(I);
               if (I<=Len) and (L[I]=' ') then
               begin
                  while (I<=len) and (L[I]=' ') do
                     inc(I);
                  {ignora DATA}
                  while (I<=len) and (L[I] in ['0'..'9','-']) do
                     inc(I);
                  if (I<=Len) and (L[I]=' ') then
                  begin
                     while (I<=len) and (L[I]=' ') do
                        inc(I);
                     TempPCB := TRue
                  end else
                  begin
                     I := J;
                     TempPCB := False
                  end;
               end else
               begin
                  I := J;
                  TempPCB := False
               end;
               if I<=Len then
               begin
                  {read download counter}
                  if pos(L[I],DlLimit1)>0 then
                  begin
                     {posizione dopo DC}
                     J := I + 1;
                     {salta gli spazi iniziali}
                     while (J<=len) and (L[J]=' ') do
                        inc(J);
                     TempDownLoad := 0;
                     While (J<=Len) and (L[J] in ['0'..'9']) do
                     begin
                        TempDownLoad := TempDownLoad * 10 + ord(L[J]) - Ord('0');
                        inc(J);
                     end;
                     while (J<=Len) and (L[J]=' ') do
                        inc(J);

                     if (J<=len) and (pos(L[J],DlLimit2)>0) then
                     begin
                        repeat
                           inc(J)
                        until (J>len) or (L[J]<>' ');
                        if ModDc=StripDc then
                        begin
                           TempDownLoad := 0
                        end else
                        if (ModDc=DecDc) and (TempDownLoad>0) then
                        begin
                           Dec(TempDownLoad);
                        end;
                     end else
                     begin
                        TempDownLoad := 0;
                        J := I;
                     end;
                  end else
                  begin
                     Tempdownload := 0;
                     J := I
                  end;
               end Else
               begin
                  J := I;
                  TempDownLoad := 0;
               end;
               I := J;
               {delete /t /b /tb for free time/byte download}
               TempFreeDlTime := false;
               TempFreeDlByte := False;
               if (I<len) and (L[I]='/') then
               begin
                  inc(i);
                  if upcase(L[I])='B' then
                  begin
                     inc(i);
                     TempFreeDlByte := True;
                     while (I<=len) and (L[I]=' ') do
                        inc(I);
                  end else
                  if upcase(L[I])='T' then
                  begin
                     inc(i);
                     TempFreeDlTime := True;
                     if (I<=Len) and (upcase(L[I])='B') then
                     begin
                        inc(i);
                        TempFreeDlByte := True
                     end;
                     while (I<=len) and (L[I]=' ') do
                        inc(I);
                  end else
                     dec(i);
               end;
               PosDesc := I;
               if (MinDl<TempDownLoad) then
               begin
                  PutInBest;
               end;
               if (LListStatus=MakeSearch) then
               begin
                  if (NFiles<SearchMaxFiles) and IsSearched then
                  begin
                     if LocalpathDown='\\' then
                     begin
                        TempSize := 0;
                        I := PosDesc;
                        while (I<=length(L)) and (L[i] in ['0'..'9']) do
                        begin
                           TempSize := TempSize * 10 + ord(l[i]) - ord('0');
                           inc(i);
                        end;
                        if (TempSize>0) then
                        begin
                           {letta con successo la dimensione}
                           if (i<=length(L)) and (upcase(L[i])='K') then
                           begin
                              TempSize := tempSize + 1024;
                              inc(i);
                           end;
                           {ignora gl spazi}
                           while (i<=length(l)) and (L[i]=' ') do
                               inc(i);
                           posdesc := i;
                        end;
                        Descrivi(First);
                     end else
                     begin
                        findfirst(LocalPathDown+TempNome,Archive+Readonly,S);
                        if DosError=0 then
                        begin
                           TempSize := S.Size;
                           TempTime := S.Time;
                           {$IFDEF OS2}
                           Findclose(S);
                           {$ENDIF}
                           Descrivi(First)
                        end else
                        if OffLine then
                        begin
                           TempSize := 0;
                           TempTime := 0;
                           Descrivi(First);
                        end;
                     end;
                  end else
                     LastDesc := Nil
               end else
               begin
                  TempSize := 0;
                  TempTime := 0;
                  Descrivi(First)
               end;
            end;
         End;
         CloseFbbs;
      End;
   End;

   ExcludeOrfani(First);
   if (LListStatus=Announce) and (NFiles>0) then
   begin
      ExcludeAnnounce(First);
      if NFiles=0 then
      begin
         {Commenti non ce ne sono}
         CancellaLista(InizioLIsta);
         InizioLista := Nil;
      end;
   end;

   TotSize := TotSize + AllSize;
   TotNewSize := TotNewSize + NewSize;
   Inc(NTotFiles,NFiles);
   Inc(NTotNewFiles,NNewFiles);

   Report;

   if (LListStatus=FixFbbs) then
   begin
      FixFBbs1 := RewriteFbbs;
      if FixFbbs1 then
      begin
         SetTextBuf(VariText,VariBuf^,SizeTxtBuf);
         if sort<>no then
            SetNList(InizioLista);
         if FixFBbsHeader then
         begin
            {aggiunge un nuovo header}
            TempWord := HdrStyle;
            HdrStyle := 1;
            HeadArea(VariText,LocalNumero,NomeArea,NFiles,AllSize);
            HdrStyle := TempWord;
         end;
      end;
   end;

   {Albero Completato, ora rilegge e cancella}
   if (NFiles>0) or (LListStatus=EditFilesBbs) or (LListStatus=FixFBbs) then
   begin
      Writeln(LogFile,PreLog(LogWork),LocalNumero:4,' - ',NomeArea,' (',NFiles,')');
      Flush(LogFile);
      if (LListStatus=Announce) then
         PutInListaAree(LocalNumero,LocalNumero,UpDateFileIdx);
      if (LListStatus=FixFBbs) and ((NOrfani>0) or (OffLineExcluded>0)) then
         PutInListaAree(LocalNumero,LocalNumero,UpDateFileIdx);

      if (LListStatus<>FixFBBs) and
         (LListStatus<>FileIdx) and
         (LListStatus<>EditFilesBbs) then
      begin
         {Aggiunge area a OKFILE list};
         if (LListStatus=MakeListCmp) and not NoDlPath and
            (PathAvail<>'') then
         begin
            Write(OkFile,LocalPathDown,'*.*');
            if (OkFilePwd<>'') and (livello>=LevPwd) then
               writeln(OkFile,' !',OkFilePwd)
            else
               writeln(OkFile);
         end;
         {Scrive header dell'area}
         HeadArea(AllFiles,LocalNumero,NomeArea,NFiles,AllSize);
         if (NNewFiles>0) and MakeNew then
            HeadArea(NewFiles,LocalNumero,NomeArea,NNewFiles,NewSize);
      end;

      Status := MakeAllFiles;

      if LlistStatus=EditFilesBbs then
      begin
         ModifiedFilesBbs := False;
         EditFBbs;
      end else
         MostraLista(InizioLista);

      if MakeNew then
      begin
         Status := MakeNewFiles;
         MostraLista(ListaNewFiles);
      end;

   end;

   RemoveComments(InizioLista);
   CancellaLista(InizioLista);
   CancellaLista(ListaNewFiles);
   CancellaAlbero(first);

   if (LListStatus=FixFbbs) then
   begin
      if FixFBbs1 then
      begin
         CloseFbbs;
      end else
      begin
         writeln(LogFile,Prelog(LogError),'Can''t write Files.Bbs');
         Flush(LOgFile);
         if FirstShell then
            Writeln;
         Writeln(' * Can''t write Files.Bbs');
         FirstArea := True;
      end;
   end;

   if Bbs=Ra250 then
      Dispose(fb, Done);

   if (LocalNumero>=0) then
      UnLock(D0+'Area'+Long2Str(LocalNumero,0));

end {MakeList};

end.
