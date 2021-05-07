Unit LLView;

{$I LL.DEF}

INTERFACE

USES
  Dos;


  PROCEDURE View(Name : PathStr);

IMPLEMENTATION


Uses
   Crt, LLGEN, LLParseS, LLTEnd, LLText, llmouse;


  PROCEDURE View(Name : PathStr);

  Const
    Home   =#71;
    EndKey =#79;
    Right  =#77;
    Left   =#75;
    Up     =#72;
    PgUp   =#73;
    Down   =#80;
    PgDn   =#81;

    MaxNL=49;

    NullStr:Byte=0;

    MoveChar : SET OF CHAR =
       [Home, Up, PgUp, Left, Right, EndKey, Down, PgDn];
  TYPE
    VPageLinesType = ARRAY[1..MaxNL] OF ^String;
    VPagePtr = ^VPageRec;
    VPageRec = RECORD
                 Key  : INTEGER;                                 { PageNumber }
                 Pg   : VPageLinesType;
                 Next : VPagePtr;
                 Last : VPagePtr;
               END;
  VAR
    CurrPage, FirstPg, LastPg, TempPtr : VPagePtr;
    BufferStart               : INTEGER;
    PagesInBuffer             : INTEGER;
    TempPage, LastPageInFile  : INTEGER;
    Line, Place               : BYTE;
    Reply                     : CHAR;
    NewScr                    : BOOLEAN;
    TempStr                   : STRING;
    Source                    : TEXT;
    FileBuffer                : Pointer;
    SkipLines                 : Byte;
    PageSize                  : Integer;
    PrevRead                  : INteger;
    MouInfo: MinfoRecType;

    D:DirStr; N:NameStr; E:ExtStr;
    ShortName: String;

    NL                        : Integer;

    Found: Boolean;

    {indice fino a 10000 pagine}
    {1=Pagina 1, 2=Pagina 11, 3= Pagina21, ...}

    Size, Time: longint;
    T: dateTime;

    S: SearchRec;

  { --------------------------------- }

  Function IsSearched(Var L:String):Boolean;
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
              if SearchIn[P] in Pnt^.Keyword[J] then
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
            (Not Pnt^.IsPath and (Booyer1(Pnt^.SearchString,L,Pnt^.SearchString^.PreQM,
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



  PROCEDURE DeleteViewPage(VAR FirstPtr, LastPtr : VPagePtr; OldKey : INTEGER);
  VAR
    DelPtr : VPagePtr;                              { FirstPtr and LastPtr  }
    Line   : Byte;
  BEGIN                                             { must be initialized   }
    IF (FirstPtr = NIL) THEN DelPtr := NIL          { to NIL before calling }
    ELSE IF (OldKey = FirstPtr^.Key) THEN           { this procedure the    }
      BEGIN                                         { first time.           }
        DelPtr := FirstPtr;
        FirstPtr := FirstPtr^.Next;
        IF (FirstPtr <> NIL) THEN FirstPtr^.Last := NIL;
        IF (FirstPtr = NIL) THEN LastPtr := NIL;
      END
    ELSE IF (OldKey = LastPtr^.Key) THEN
      BEGIN
        DelPtr := LastPtr;
        LastPtr := LastPtr^.Last;
        IF (LastPtr <> NIL) THEN LastPtr^.Next := NIL;
      END
    ELSE
      BEGIN
        DelPtr := FirstPtr;
        WHILE (DelPtr <> NIL) AND (DelPtr^.Key <> OldKey) DO
          DelPtr := DelPtr^.Next;
        IF (DelPtr <> NIL) THEN        { DelPtr is NIL if OldKey is not found }
          BEGIN
            DelPtr^.Next^.Last := DelPtr^.Last;
            DelPtr^.Last^.Next := DelPtr^.Next;
          END;
      END;
    IF (DelPtr <> NIL) THEN
    begin
       for I := 1 to NL do
          if DelPtr^.Pg[I]<>Nil then
             FreeMem(DelPtr^.Pg[I],length(DelPtr^.Pg[I]^) + 1);
       DISPOSE(DelPtr);
    end;
  END;
  { --------------------------------- }

    PROCEDURE ReadPage(PageNum : INTEGER);
    VAR
      Line    : BYTE;
      TempStr : String;
    BEGIN
      New(TempPtr);
      Line := 1;
      WHILE not eof(Source) and (Line <= NL) DO
        BEGIN
          READLN(Source, TempStr);
          if TempStr<>'' then
          begin
             GetMem(TempPtr^.Pg[Line],length(TempStr)+1);
             TempPtr^.Pg[Line]^ := TempStr;
          end else
             TempPtr^.Pg[line] := Nil;
          Inc(Line);
        END;
      for line := line to NL do
      begin
         TempPtr^.Pg[Line] := Nil;
      end;
      TempPtr^.Key := PageNum;
      if FirstPg=Nil then
      begin
         FirstPg := TempPtr;
         TempPtr^.Next := Nil;
         TempPtr^.Last := Nil;
      end else
      begin
         LastPg^.Next := TempPtr;
         TempPtr^.Last := LastPg;
         TempPtr^.Next := Nil;
      end;
      LastPg := TempPtr;
    END;
  { --------------------------------- }

PROCEDURE WritePage(Position : BYTE); forward;


    PROCEDURE FillBuffer(PageNum, PrevRead : INTEGER);
    VAR
      TempPage : INTEGER;
      Line     : BYTE;
    BEGIN

      PagesInBuffer := 0;

      BufferStart := PageNum - PrevRead;
      IF (BufferStart < 1) THEN
         BufferStart := 1;

      TempPage := 1;

      {$IFDEF VIRTUALPASCAL}
      if LastPageinFile=-1 then
      begin
         {legge e mostra subito la prima pagina}
         if not eof(Source)
           AND (MaxAvail > PageSize + 8192) then
         BEGIN
           ReadPage(TempPage);
           CurrPage := LastPg;
           Inc(TempPage);
           Inc(PagesInBuffer);
           WritePage(place);
           newscr := true;
         END;
      end else
      {$ENDIF}
      begin
         WHILE (FirstPg <> NIL) DO                                { Clear Buffer }
           DeleteViewPage(FirstPg, LastPg, FirstPg^.Key);
         Close(Source);
         while not shOpenTextFile(Source, Name) do;
         SetTextBuf(Source, FileBuffer^, SizeTxtBuf);
         {se questa condizione e' valida, gli offsets sono gia' validi}
         WHILE (TempPage < BufferStart) DO                { Skip to Buffer Start }
           BEGIN
             FOR Line := 1 TO NL DO READLN(Source, TempStr);
             Inc(TempPage);
           END;
      end;

      WHILE not eof(Source)
         AND (MaxAvail > PageSize + 8192) DO
        BEGIN
          ReadPage(TempPage);
          IF (TempPage = PageNum) THEN
            BEGIN
              CurrPage := LastPg;
            END;
          Inc(TempPage);
          Inc(PagesInBuffer);
        END;
      if LastPageInFile=-1 then
      begin
         LastPageInFile := TempPage-1;
         Line := 1;
         WHILE NOT EOF(Source) DO
         BEGIN
           IF (Line > NL) THEN
             BEGIN
               Line := 1;
               Inc(LastPageInFile);
             END;
           READLN(Source, TempStr);
           Inc(Line);
         END;
      end;
    END;
  { --------------------------------- }


    PROCEDURE WritePage(Position : BYTE);
    VAR
      Line    : BYTE;
      WorkStr : STRING;
      I, Posizione1, Posizione2: Integer;
    BEGIN

      if (LastPageInFile=-1) or not keypressed then
      begin
         HideCursor;
         InvVideo;
         GotoXY(1,1);
         Write(' LLIST ',Versione);
         Write('':81-WhereX);
         NormVideo;

         Line := SkipLines + 1;

         repeat
             if line>skipLines then
             begin
                if CurrPage^.Pg[Line]=Nil then
                   WorkStr := ''
                else
                begin
                   WorkStr := ExpandTabs(CurrPage^.Pg[Line]^);
                   if position>1 then
                      delete(WorkStr,1,Position-1);
                end;
             end else
             begin
                if (Line=1) and (CurrPage^.Next=Nil) and (CurrPage^.Key<LastPageInFile) then
                   FillBuffer(CurrPage^.Key,PrevRead);
                if CurrPage^.Next<>Nil then
                begin
                   if CurrPage^.Next^.Pg[Line]=Nil then
                      WorkStr := ''
                   else
                   begin
                      WorkStr := ExpandTabs(CurrPage^.Next^.Pg[Line]^);
                      if position>1 then
                         delete(WorkStr,1,Position-1);
                   end;
                end else
                   WorkStr := '';
             end;

             if length(WorkStr)>79 then
             begin
                WorkStr[0] := #79;
                WorkStr[79] := '¯';
             end;

             WRITEln(WorkStr,'':79-length(WorkStr));
             if line=Nl then
                line := 1
             else
                Inc(Line);
         until (Line=SkipLines+1);
         InvVideo;
         WRITE(' ',ShortName,'':13-length(Name));
         if ShortSize then
          begin
             Write(Size div 1024:5,'k  ',PrevDataStr);
          end else
          begin
             Write(Size:8,'  ',PrevDataStr);
          end;

         Write('':38-WhereX,#26#24#25#27, ' <Home> <End> <Esc> F G',
            Position:8,':',longint(CurrPage^.Key - 1) * NL + 1 + SkipLines);
         Write('':80-WhereX);
         NormVideo;

         {ora scrive l'ascensore :-)}

         if LastPageInFile=-1 then
         begin
            Posizione1 := 1;
            Posizione2 := 1;
         end else
         begin
            Posizione1 := Longint(CurrPage^.Key) * (NL -3) div
                LastPageInFile + 1;
            if Posizione1 > NL-1 then
                Posizione1 := NL-1;
            Posizione2 := Longint(CurrPage^.Key+1) * (NL - 3) div
                LastPageInFile + 1;
            if Posizione2 > NL-1 then
                Posizione2 := NL-1;
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

         for I := POsizione2 + 1 to NL-2 do
         begin
            GotoXY(80,I+2);
            Write('°');
         end;

         GotoXY(80,NL+1);
         Write(#31);

         NewScr := FALSE;
         ShowCursor;
      end;
    END;
  { --------------------------------- }


  BEGIN


   FindFirst(Name,Archive+ReadOnly,S);
   if DosError=0 then
   begin
       Size := S.Size;
       Time := S.Time;
       {$IFDEF OS2}
       Findclose(S);
       {$ENDIF}

       NL := Hi(WindMax) - Hi(WindMin)  + 1 - 2;

       if NL>MaxNL then
          NL := MaxNL;

       PageSize := 256 * NL;
       PrevRead := (MemAvail div PageSize) div 2;

       FSplit(Name, D, N , E);
       ShortName := N + E;

       FirstPg := NIL;
       LastPg := NIL;
       CurrPage := NIL;
       NewScr := TRUE;
       SkipLines := 0;

       if shOpenTextFile(Source, Name) then
       begin
          GETMEM(FileBuffer, SizeTxtBuf);
          SetTextBuf(Source, FileBuffer^, SizeTxtBuf);
          UnPackTime(Time,T);
          MydateStr(T);

          LastPageInFile := -1;
          FirstPg := Nil;
          LastPg := Nil;
          Place := 1;
          FillBuffer(1,0);

          Repeat
             if NewScr then
                WritePage(Place);
             waitevent;
             if keypressed then
             begin
                Reply := ReadKey;
                if Reply=#0 then
                begin
                   Reply := ReadKey;
                   NewScr := (Reply IN MoveChar);
                   CASE Reply OF
                     PgDn : IF (CurrPage^.Key < LastPageInFile) THEN
                            begin
                               IF (CurrPage^.Next = NIL)
                                 THEN FillBuffer(CurrPage^.Key + 1, PrevRead)
                               ELSE CurrPage := CurrPage^.Next;
                               if CurrPage^.Key=LastPageInFile then
                                  SkipLines := 0;
                            END;
                     Down :
                        if (SkipLInes<NL-1) then
                        begin
                          if CurrPage^.Key < LastPageInFile then
                             inc(SkipLines);
                        end else
                        if CurrPage^.Key < LastPageInFile then
                        begin
                           IF (CurrPage^.Next <> NIL) THEN
                           begin
                              CurrPage := CurrPage^.Next;
                           end else
                           begin
                              FillBuffer(CurrPage^.Key +1, PrevREad)
                           end;
                           SkipLInes := 0
                        END;
                     PgUp :    BEGIN
                                  IF (CurrPage^.Key > 1) THEN
                                  begin
                                    IF (CurrPage^.Last = NIL)
                                       THEN FillBuffer(CurrPage^.Key - 1, PrevRead)
                                    ELSE CurrPage := CurrPage^.Last;
                                  end else
                                    SkipLines := 0;
                                END;
                     Up :  if SkipLines=0 then
                           begin
                              IF (CurrPage^.Key > 1) THEN
                              begin
                                IF (CurrPage^.Last = NIL)
                                   THEN FillBuffer(CurrPage^.Key - 1, PrevRead)
                                ELSE CurrPage := CurrPage^.Last;
                                SkipLines := NL-1
                              end;
                           end else
                           begin
                              dec(SkipLines);
                           end;
                     Home : BEGIN
                              Place := 1;
                              IF (BufferStart > 1) THEN
                                 FillBuffer(1,0)
                              ELSE
                                 CurrPage := FirstPg;
                              SkipLines := 0;
                            END;
                     EndKey : BEGIN
                                Place := 1;
                                IF (BufferStart + PagesInBuffer - 1 < LastPageInFile) then
                                    FillBuffer(LastPageInFile, PrevRead)
                                ELSE
                                    CurrPage := LastPg;
                                SkipLines := 0;
                              END;
                     Left : begin
                              if Place>8 then
                                 dec(Place,8);
                            end;
                     Right : begin
                              if Place<200 then
                                 inc(Place,8);
                             end;

                   END;
                end else
                Case UpCase(Reply) of
                   'F':begin
                          TempStr := '';
                          ReadBox('Search',50,TempStr);
                          if pos('"', TempStr)=0 then
                             TempStr := '"' + TempStr + '"';
                          if ParseSubject(TempStr,False,True) then
                          begin
                             WritePage(Place);
                             TempPage := CurrPage^.Key;
                             {cerca nella pagina corrente}
                             I := SkipLines+1;
                             while (I<=NL) and
                                ((CurrPage^.Pg[I]=Nil) or not IsSearched(CurrPage^.Pg[I]^)) do
                               inc(I);
                             Found := (I<=NL);
                             if found then
                                SkipLines := I-1;
                             if not found and (I>NL) and (CurrPage^.Key<LastPageInFile) then
                             Repeat
                               {pagina successiva}
                               IF (CurrPage^.Next = NIL)
                                 THEN FillBuffer(CurrPage^.Key + 1,0)
                               ELSE CurrPage := CurrPage^.Next;
                               I := 1;
                               while (I<=NL) and
                                   ((CurrPage^.Pg[I]=Nil) or not IsSearched(CurrPage^.Pg[I]^)) do
                                  inc(I);
                               Found := (I<=NL);
                               if found then
                                  SkipLines := I-1;
                             until Found or (CurrPage^.Key=LastPageInFile);
                             if not found then
                             begin
                                if CurrPage^.Key<>TempPage then
                                begin
                                   {ripristina la pagina precednte}
                                   if (BufferStart<=TempPage) and (BufferStart + PagesInBuffer -1>=TempPage) then
                                   begin
                                      CurrPage := FirstPg;
                                      While (TempPage>BufferStart) do
                                      begin
                                         CurrPage := CurrPage^.Next;
                                         dec(TempPage);
                                      end;
                                   end else
                                      FillBuffer(TempPage,PrevRead);
                                end;
                                Beep;
                                NewScr := TRue
                             end else
                                NewScr := True
                          end else
                             NewScr := True
                        end;
                    'G':begin
                           TempPage := (CurrPage^.Key-1) * NL + 1 + SkipLines;
                           ReadBoxInteger('Goto line', 0, (LastPageInFile-1)*NL+1, TempPage);
                           WritePage(Place);
                           if (TempPage<>0) then
                           begin
                              SkipLines := (TempPage-1) mod NL;
                              TempPage := (TempPage-1) div NL + 1;
                              if CurrPage^.Key<>TempPage then
                              begin
                                 {va alla nuova pagina}
                                 if (BufferStart<=TempPage) and (BufferStart + PagesInBuffer -1>=TempPage) then
                                 begin
                                    CurrPage := FirstPg;
                                    While (TempPage>BufferStart) do
                                    begin
                                       CurrPage := CurrPage^.Next;
                                       dec(TempPage);
                                    end;
                                 end else
                                    FillBuffer(TempPage,PrevRead);
                                 NewScr := TRue
                              end;
                           end;
                        end;
                end;
             end else
             begin
                mouget(mouinfo);
                if (MouInfo.Cy = Nl + 1) then
                begin
                   if MouInfo.Cx = 37 then
                   begin
                      KbdBuffer := #0 + Right
                   end else
                   if MouInfo.Cx = 38 then
                   begin
                      KbdBuffer := #0 + Up
                   end else
                   if MouInfo.Cx = 39 then
                   begin
                      KbdBuffer := #0 + Down
                   end else
                   if MouInfo.Cx = 40 then
                   begin
                      KbdBuffer := #0 + Left
                   end else
                   if MouInfo.IsDouble then
                   begin

                      if (MouInfo.Cx >= 43) and (mouInfo.Cx <= 46) then
                      begin
                         KbdBuffer := #0 + Home;
                         Reply := #0;
                      end else
                      if (MouInfo.Cx >= 50) and (mouInfo.Cx <= 52) then
                      begin
                         KbdBuffer := #0 + Endkey;
                         Reply := #0;
                      end else
                      if (MouInfo.Cx >= 56) and (mouInfo.Cx <= 58) then
                      begin
                         Reply := #27;
                      end else
                      if (MouInfo.Cx = 61) then
                      begin
                         KbdBuffer := 'F';
                         Reply := #0;
                      end else
                      if (MouInfo.Cx = 63) then
                      begin
                         KbdBuffer := 'G';
                         Reply := #0;
                      end else
                         Reply := #0;
                   end else
                      Reply := #0;
                end else
                if (MouInfo.Cx = 79) then
                begin
                   if MouInfo.Cy = 1 then
                   begin
                      KbdBuffer := #0#73
                   end else
                   if MouInfo.Cy = NL then
                   begin
                      KbdBuffer := #0#81
                   end;
                   Reply := #0;
                end else
                   Reply := #0;
                end;
          UNTIL (Reply = #27);
          WHILE (FirstPg <> NIL) DO
             DeleteViewPage(FirstPg, LastPg, FirstPg^.Key);
          close(Source);

          FREEMEM(FileBuffer, SizeTxtBuf);
       end;
   end;
End {View};

END.

