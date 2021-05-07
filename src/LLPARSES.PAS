Unit LLParseS;

{$I LL.Def}

Interface

Uses Dos, Crt, MkGlobt,
   MkFile,
    LLGEN;

Function ParseSubject({Var} S:String; AltriFiles, Mute:Boolean):Boolean;
Function IsSearched(Var TempNome, L:String; PosDesc: Byte):Boolean;

Implementation

Function IsSearched(Var TempNome, L:String; PosDesc:Byte):Boolean;
var I:Byte;
   Function Booyer(Pnt:SearchTypeRef):Boolean;
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
end {IsSearched};

Function ParseSubject({Var} S:String; AltriFiles, Mute:Boolean):Boolean;
   Function QM (N:Byte):String;
   begin
      QM := RepeatStr('?',N);
   end {QM};
var I,J,K,L,PreQMTmp:Integer;
    TempStr, TempStr1: String;
    Temp1:SearchStringTypeRef;
    AndFound,IgnoreAnd:Boolean;
    IsPathTmp,FixedTmp,ContinuesTmp,PositiveTmp,FirstString:Boolean;
    Temp: SearchStringTypeRef;
    InvalidS: String;
    PrevS: String;

    Function AlreadySearched(Keyword,MsgTo:String; DestAddr:AddrType):Boolean;
    Var  DupesFile:File;
         Dupes:DupesType;
         fm:Word;
         Trovato:Boolean;
         {$IFDEF VIRTUALPASCAL}
         TempWord: Longint;
         {$ELSE}
         TempWord: Word;
         {$ENDIF}
    begin
       if (llistStatus=MakeSearch) then
       begin
          fm := FileMode;
          FileMode := fmReadWrite_DA;
          Assign(DupesFile,D0+'FSearch.Dup');
          {$I-}
          Reset(DupesFile,1);
          {$I+}
          if IOResult<>0  then
          begin
              {$I-}
              Rewrite(DupesFile,1);
              {$I+}
              if IOREsult=0 then;
          end else
          begin
             Trovato := False;
             while not Trovato and not eof(DupesFile) do
             begin
                Blockread(DupesFile,Dupes,SizeOf(Dupes),TempWord);
                if (TempWord=SizeOf(Dupes)) and
                   (Dupes.Name=MsgTo) and
                    (AddrEqual(Dupes.Address,DestAddr))
                    and (Dupes.Keyword=Keyword) then
                begin
                   Trovato := True;
                   PrevNumero := Dupes.LastArea;
                   if AltriFiles then
                   begin
                      {Cancella record, poi lo riscrivera' alla fine}
                      seek(DupesFile,FilePos(DupesFile)-1);
                      fillchar(Dupes,SizeOf(Dupes),0);
                      BlockWrite(DupesFile,Dupes,SizeOf(Dupes),TempWord);
                   end
                end;
             end;
          end;
          close(DupesFile);
          filemode := fm;
          AlreadySearched := Trovato;
       end else
          AlreadySearched := False;
    end {AlreadySearched};

    Function MakeBooyer(Pnt:SearchStringTypeRef):Byte;
    {Ritorna la lunghezza della stringa}
    var J, K:Integer;
        Ch:Char;
    begin
       for K := 0 to 255 do
          Pnt^.Booyer[K] := Pnt^.LenCurrent;
       for J:=1 to Pnt^.lencurrent-1 do
       begin
          if Pnt^.Keyword[J]=[#0..#255] then
          begin
             for K := 0 to 255 do
                Pnt^.Booyer[K] := Pnt^.LenCurrent - j;
          end else
          begin
             Ch := #0;
             Repeat
                if ch in Pnt^.Keyword[J] then
                   Pnt^.Booyer[ord(Ch)] := Pnt^.lencurrent - J;
                if Ord(ch)<255 then
                   inc(ch);
             until (CH=#255);
          end;
       end;
      if Pnt^.Next<>Nil then
      begin
         inc(Pnt^.PostQM, Pnt^.Next^.PreQM);
         Pnt^.Next^.PreQM := 0;
         if Pnt^.Next^.LenCurrent=0 then
         begin
            {Stringa vuota, puo' essere solo l'ultima, altrimenti
            non sarebbe stata inserita}
            dispose(Pnt^.Next);
            Pnt^.Next := Nil;
            Pnt^.LenOther := 0;
         end else
            Pnt^.LenOther := MakeBooyer(Pnt^.Next);
      end else
         Pnt^.LenOther := 0;
      MakeBooyer := Pnt^.PreQM + Pnt^.lencurrent + Pnt^.PostQM + Pnt^.LenOther;
    end {MakeBooyer};
(*
    Function GetSearchStr(Pnt1:SearchTypeRef):String;
    var
        TempStr:String;

        Function GetSearchStr1(Pnt2:SearchStringTypeRef):String;
        Var Ch:Char;
            TempStr, TempStr1:String;
            I : Integer;
        begin
           if Pnt2<>Nil then
           begin
              TempStr := '';
              for I := 1 to Pnt2^.lenCurrent do
              begin
                 TempStr1 := '';
                 if Pnt2^.Keyword[I]=[#0..#255] then
                 begin
                    TempStr1 := '?';
                 end else
                 begin
                    if #0 in Pnt2^.Keyword[I] then
                    begin
                       {assume un range negativo}
                       TempStr1 := '!';
                       CH := #255;
                       repeat
                          inc(CH);
                          if not (ch in Pnt2^.Keyword[I]) then
                          begin
                             {se e' intermedio in un range non lo mette}
                             if ch in ['a'..'z'] then
                             begin

                             end else
                             if (
                                 {eclude lower case, primo e ultimo carattere}
                                 ((Ch>#0) and (Ch < Chr(Ord('a')-1)))
                                    or
                                 ((Ch>Chr(Ord('z')+1)) and (ch<#255))
                                )
                              and
                                 not (Chr(Ord(ch)-1) in Pnt2^.Keyword[I]) and
                                 not (Chr(Ord(ch)+1) in Pnt2^.Keyword[I]) then
                             begin

                             end else
                             begin
                                if (ch=#0) or (Chr(Ord(Ch)-1) in Pnt2^.Keyword[I]) then
                                   TempStr1 := TempStr1 + ch
                                else
                                   TempStr1 := TempStr1 + '-' + ch
                             end;
                          end;
                       until (CH=#255);
                    end else
                    begin
                       Ch := #255;
                       repeat
                          inc(CH);
                          if ch in Pnt2^.Keyword[I] then
                          begin
                             {se e' intermedio in un range non lo mette}
                             if ch in ['a'..'z'] then
                             begin

                             end else
                             if (
                                 {eclude lower case, primo e ultimo carattere}
                                 ((Ch>#0) and (Ch < Chr(Ord('a')-1)))
                                    or
                                 ((Ch>Chr(Ord('z')+1)) and (ch<#255))
                                )
                              and
                                 (Chr(Ord(ch)-1) in Pnt2^.Keyword[I]) and
                                 (Chr(Ord(ch)+1) in Pnt2^.Keyword[I]) then
                             begin

                             end else
                             begin
                                if (ch=#0) or not (Chr(Ord(Ch)-1) in Pnt2^.Keyword[I]) then
                                   TempStr1 := TempStr1 + ch
                                else
                                   TempStr1 := TempStr1 + '-' + ch
                             end;
                          end;
                       until (CH=#255);
                    end;
                    if length(TempStr1)>1 then
                       TempStr1 := '[' + TempStr1 + ']';
                 end;
                 TempStr := TempStr + TempStr1;
              end;
              if Pnt2^.Next<>Nil then
              begin
                 GetSearchStr1 := QM(Pnt2^.PreQM) +
                    TempStr + QM(Pnt2^.PostQM) + '*' +
                       GetSearchStr1(Pnt2^.Next);
              end else
              begin
                 GetSearchStr1 := QM(Pnt2^.PreQM) +
                    TempStr + QM(Pnt2^.PostQM);
              end;
           end else
              GetSearchStr1 := '';
        end {GetSearchStr1};

    begin

       TempStr := GetSearchStr1(Pnt1^.SearchString);
       if not pnt1^.IsPath then
       begin
          if pos(' ',TempStr)=0 then
             TempStr := '/' + TempStr
          else
             TempStr := '"' + TempStr + '"';
       end else
       begin
          if not Pnt1^.Fixed then
          begin
             TempStr := '*' + TempStr
          end;
          if Pnt1^.Continues then
             TempStr := TempStr + '*'
       end;

       if Pnt1^.Negative then
          TempStr := '~' + TempStr;

       if Pnt1^.AndSearch=Nil then
       begin
          GetSearchStr := TempStr
       end else
       begin
          GetSearchStr := TempStr +
            ' AND ' + GetSearchStr(Pnt1^.AndSearch)
       end;
    end {GetSearchStr};
*)
    Procedure Remove(Var Pnt:SearchTypeRef);
       Procedure Remove1(Var Pnt:SearchStringTypeRef);
       begin
          if Pnt<>Nil then
          begin
             Remove1(Pnt^.Next);
             Dispose(Pnt);
          end;
       End {Remove1};
    begin
       if Pnt<>Nil then
       begin
          Remove(Pnt^.AndSearch);
          Remove1(Pnt^.SearchString);
          Dispose(Pnt);
          Pnt := Nil
       end;
    end {Remove};

    Procedure AddString(Var Pnt:SearchTypeRef; Pnt1:SearchStringTypeRef;
       IsPathTmp, IsFixedTmp, ContinuesTmp, PositiveTmp:Boolean;
       Len:Byte);
    Begin
       If (Pnt=Nil) then
       begin
          New(Pnt);
          Pnt^.IsPath := IsPathTmp;
          Pnt^.Fixed := FixedTmp;
          Pnt^.Continues := ContinuesTmp;
          Pnt^.Negative := not PositiveTmp;
          Pnt^.SearchString := Pnt1;
          Pnt^.AndSearch := Nil;
          Pnt^.Len := Len;
       end else
       begin
          AddString(Pnt^.AndSearch,Pnt1,IsPathTmp,FixedTmp,ContinuesTmp,PositiveTmp,Len)
       End;
    End;

    Function alloc(var Temp1: SearchStringTypeRef): SearchStringTypeRef;
    begin
       if Temp1=Nil then
       begin
          New(Temp1);
          Alloc := Temp1;
       end else
          Alloc := Alloc(Temp1^.Next);
    end;

    Procedure RemoveLast(Var Pnt: SearchStringTypeRef);
    begin
       if Pnt^.Next<>Nil then
          RemoveLast(Pnt^.Next)
       else
       begin
          Dispose(Pnt);
          Pnt := NIl;
       end;
    end;

begin

   if not mute then
   begin
      Writeln(' * Request for: ',S);
      Writeln(LogFile,PreLog(LogWork),'Request for: ',S);
      Flush(LOgFile);
   end;

   PrevS := S;

   ViewContents := VcNo;
   UUEncodeFound := False;
   XXEncodeFound := False;

   PrevNumero := -1;

   {tira via le stringhe gia' configurate};
   NStringSearch := 0;
   for I:=1 to NMaxSearch do
      Remove(Search[I]);

   for I:=1 to length(S) do
      S[I] := upcase(S[I]);
   while (S<>'') and (S[length(S)]=' ') do
      dec(S[0]);

   StripLeadingSpace(S);

   AndFound := False;
   IgnoreAnd := True;
   InvalidS := '';

   while (S<>'') and (S<>'~') do
   begin
      PositiveTmp := S[1]<>'~';
      if not positiveTmp then
         Delete(S,1,1);

      if S[1]='"' then
      begin
         delete(S,1,1);
         I := pos('"',S);
         IsPathTmp := False;
         FixedTmp := False;
         ContinuesTmp := True;
      end else
      begin
         if (S[1]='\') or (S[1]='/') then
         begin
            delete(S,1,1);
            IsPathTmp := False;
            FixedTmp := False;
            ContinuesTmp := True;
            if (S<>'') and (S[1]='"') then
            begin
               delete(S,1,1);
               I := pos('"',S);
            end else
               I := pos(' ',S);
         end else
         begin
            IsPathTmp := True;
            FixedTmp := True;
            ContinuesTmp := True;
            I := pos(' ',S);
         end;
      end;
      if I=0 then
         I := length(S) + 1;
      {Stringa di ricerca}
      TempStr := Copy(S,1,I-1);
      {resto del subject}
      if I>length(S) then
         S := ''
      else
      begin
         delete(S,1,I);
         StripLeadingSpace(S)
      end;

      {ora processa la keyword}
      if TempStr='' then
      begin
         {Stringa vuota,forse ""}
      end else
      if TempStr[1]='-' then
      begin
         if TempStr='-VC' then
         begin
            ViewContents := VcAll
         end else
         if TempStr='-VCN' then
         begin
            ViewContents := VcNew
         end else
         if TempStr='-UUE' then
         begin
            UUEncodeFound := True;
            XXEncodeFound := False;
         end else
         if TempStr='-XXE' then
         begin
            XXEncodeFound := True;
            UUEncodeFound := False
         end else
         begin
            if not mute then
            begin
               Writeln(' * Unknown flag ',TempStr);
               Writeln(LogFile,Prelog(LogError),'Unknown flag ',TempStr);
               Flush(LogFile);
            end;
         end;
      end else
      if (TempStr='AND') or (TempStr='&') then
      begin
         if not IgnoreAnd then
            AndFound := True;
      end else
      if (TempStr='OR') or (TempStr='|') then
      begin
         AndFound := False;
      end else
      if AndFound or (NStringSearch<NMaxSearch) then
      begin
         if AndFound and (NStringSearch>0) then
         begin
            {Niente}
         end else
         begin
            {Controlla la stringa attuale}
            if NStringSearch>0 then
            begin
               If (LListStatus=MakeSearch) and
                  (Search[NStringSearch]^.Len<MinLenSearchStr) then
               begin
                  {
                  InvalidS := InvalidS + ' [' +
                     GetSearchStr(Search[NStringSearch]) + ']';
                  }
                  Remove(Search[NStringSearch]);
                  Dec(NStringSearch);
               end;
            end;
            inc(NStringSearch);
         end;

         Temp1 := Nil;

         FirstString := True;

         PreQMTmp := 0;
         while (TempStr<>'') do
         begin
            Temp := Alloc(Temp1);
            Temp^.PreQM := PreQMTmp;
            PreQMTmp := 0;
            Temp^.PostQM := 0;
            Temp^.Next := Nil;
            J := pos('*',TempStr);
            if J=0 then
            begin
               J := length(TempStr) + 1;
               if IsPathTmp then
                  ContinuesTmp := False
            end;
            K := J-1; {lunghezza della sotto-keyword}
            TempStr1 := Copy(TempStr,1,K);
            {Setta PreQM}
            while (TempStr1<>'') and (TempStr1='?') do
            begin
               inc(Temp^.PreQM);
               delete(TempStr1,1,1);
            end;
            {Setta PostQM}
            while (TempStr1<>'') and (TempStr1[length(TempStr1)]='?') do
            begin
               inc(Temp^.PostQM);
               dec(TempStr1[0]);
            end;
            L := 0;
            while (L<20) and (TempStr1<>'') do
            begin
               inc(L);
               if TempStr1[1]='[' then
               begin
                  delete(TempStr1,1,1);
                  if (TempStr1<>'') and (TempStr1[1]='!') then
                  begin
                     {Stringa negativa}
                     Delete(TempStr1,1,1);
                     Temp^.Keyword[L] := [#0..chr(ord('a')-1),chr(ord('z')+1)..#255];
                     while (TempStr1<>'') and (TempStr1[1]<>']') do
                     begin
                        if (length(TempStr1)>=3) and (TempStr1[2]='-') and
                           (TempStr1[3]<>']') then
                        begin
                           {specifica un range}
                           for Ch := UpCase(TempStr1[1]) to UpCase(TempStr1[3]) do
                              Temp^.Keyword[L] := Temp^.Keyword[L] - [ Ch ];
                           delete(TempStr1,1,3);
                        end else
                        begin
                           Temp^.Keyword[L] := Temp^.Keyword[L] - [ UpCase(TempStr1[1]) ];
                           delete(TempStr1,1,1);
                        end;
                     end;
                  end else
                  begin
                     Temp^.Keyword[L] := [];
                     while (TempStr1<>'') and (TempStr1[1]<>']') do
                     begin
                        if (length(TempStr1)>=3) and (TempStr1[2]='-') and
                           (TempStr1[3]<>']') then
                        begin
                           {specifica un range}
                           for Ch := UpCase(TempStr1[1]) to UpCase(TempStr1[3]) do
                              Temp^.Keyword[L] := Temp^.Keyword[L] + [ Ch ];
                           delete(TempStr1,1,3);
                        end else
                        begin
                           Temp^.Keyword[L] := Temp^.Keyword[L] + [ UpCase(TempStr1[1]) ];
                           delete(TempStr1,1,1);
                        end;
                     end;
                  end;
                  if (TempStr1<>'') then
                     delete(TempStr1,1,1);
               end else
               begin
                  if TempStr1[1]='?' then
                     Temp^.Keyword[L] := [#0..#255]
                  else
                     Temp^.Keyword[L] := [ UpCase(TempStr1[1]) ] ;
                  delete(TempStr1,1,1);
               end;
               for Ch := 'A' to 'Z' do
               if Ch in Temp^.Keyword[L] then
               begin
                  {aggiunge il corrispondente in lower-case}
                  Temp^.Keyword[L] := Temp^.Keyword[L] + [ chr(ord(ch) + 32) ]
               end;
               if (Temp^.Keyword[L]=[]) then
                  dec(L);
            end;
            Temp^.LenCurrent := L;
            Delete(TempStr,1,J);

            if Temp^.LenCurrent=0 then
            begin
               if TempStr='' then
               begin
                  {era l'ultima stringa, la mette comunque}
                  {verra' tolta successivamente}
                  ContinuesTmp := True;
               end else
               begin
                  PreQMTmp := Temp^.PreQM;
                  RemoveLast(Temp1);
               end;
               if FirstString then
                  FixedTmp := False;
               FirstString := False;
            end;
         end;

         I := MakeBooyer(Temp1);
         AddString(Search[NStringSearch],Temp1,
            IsPathTmp, FixedTmp, ContinuesTmp, PositiveTmp,I);

         IgnoreAnd := False;
         AndFound := False;
      end;
   end;

   {Controlla la stringa attuale}
   if NStringSearch>0 then
   begin
      If (LListStatus=MakeSearch) and
         (Search[NStringSearch]^.Len<MinLenSearchStr) then
      begin
         {
         InvalidS := InvalidS + ' [' +
            GetSearchStr(Search[NStringSearch]) + ']';
         }
         Remove(Search[NStringSearch]);
         Dec(NStringSearch);
      end;
   end;

   if NStringSearch>0 then
   begin
      {
      TempStr := GetSearchStr(Search[1]);
      for I := 2 to NStringSearch do
         TempStr := TempStr + ' ' + GetSearchStr(Search[I]);
      S := TempStr;
      }
      S := PrevS;
      if AlreadySearched(S,MsgTo,MsgDestAddr) then
      begin
         if AltriFiles and (PrevNumero>-1) then
         begin
            if not mute then
            begin
               Writeln(' * Continues search from area ',PrevNumero+1);
               Writeln(LogFile,PreLog(LogWork),
                  'Continues search from area ',PrevNumero+1);
               Flush(LogFile);
            end;
         end else
         begin
            if AltriFiles then
            begin
               if not mute then
               begin
                  Writeln(' * Info missing, can''t continue search');
                  Writeln(LogFile,PreLog(LogError),
                     'Info missing, can''t continue search');
                  Flush(LOgFile)
               end;
            end else
            begin
               if not mute then
               begin
                  Writeln(' * Search already done');
                  Writeln(LogFile,PreLog(LogError),
                     'Search already done');
                  Flush(LogFile)
               end;
            end;
            for I:=1 to NStringSearch do
            begin
               remove(Search[I]);
               Search[I] := Nil
            end;
            NStringSearch := 0;
         end;
      end;

      if NStringSearch>0 then
      begin
         {
         if not mute then
         begin
            Writeln(' * Search for: ',S);
            Writeln(LogFile,PreLog(LogWork),'Search for: ',S);
            Flush(LogFile);
         end;
         }
         ParseSubject := True;
      end;

   end;

   if NStringSearch=0 then
   begin
      ParseSubject := False;
      if not mute then
      begin
         writeln(' * Invalid string search');
         writeln(LogFile,PreLog(LogError),'Invalid string search');
         Flush(LogFile);
      end;
   end else
      MaxBytesUUEncode := MaxBytesUUEncode1

end {ParseSubject};

end.
