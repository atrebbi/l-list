Unit LLMGIDX;

{$I LL.Def}

Interface

Uses LLGEN, LLMouse, Dos, Crt;

Procedure MergeIdx;
Procedure AddAnnounceIdx(Var NewRec: IdxType);
Function SearchIdx(var SearchRec: IdxType): Boolean;

implementation

Uses
   mkFile;

Procedure AddAnnounceIdx(Var NewRec: IdxType);
Var
   Rec, Temp: IdxType;
   Idx: File;
   FoundPos: Boolean;
   fm : word;
Begin
   Lock(D0+'Announce');
   Assign(Idx, D0 + 'Announce.Idx');
   fm := filemode;
   filemode := fmReadWrite_DA;
   {$I-}
   Reset(Idx,1);
   {$I+}
   if IOResult<>0 then
   begin
      {il file non esisteva, allora lo crea}
      Rewrite(Idx,1);
      BlockWrite(Idx, NewRec, SizeOf(IdxType));
      Close(Idx);
   end else
   begin
      {scorre il file fino a che non trova la posizione in cui inserire il}
      {nuovo record}
      FoundPos := False;
      While not FoundPos and not eof(Idx) do
      begin
         BlockRead(Idx, Rec, SizeOf(IdxType));
         if (Rec.Nome>NewRec.Nome) or
             ((Rec.Nome=NewRec.Nome) and (Rec.Area>=NewRec.Area)) then
            FoundPos := True;
      end;
      if not FoundPos then
      begin
         {e' arrivato alla fine del file, lo aggiunge in coda}
         BlockWrite(Idx, NewRec, SizeOf(IdxType))
      end else
      if (Rec.Nome<>NewRec.Nome) or (Rec.Area<>NewRec.Area) then
      begin
         {il record non era presente}
         {deve fare un ciclo per inserirlo alla posizione corrente}
         While not eof(Idx) do
         begin
            Seek(Idx, FilePos(Idx)-SizeOf(IdxType));
            BlockWrite(Idx, NewRec, SizeOf(IdxType));
            NewRec := Rec;
            BlockRead(Idx, Rec, SizeOf(IdxType));
         end;
         Seek(Idx, FilePos(Idx)-SizeOf(IdxType));
         BlockWrite(Idx, NewRec, SizeOf(IdxType));
         BlockWrite(Idx, Rec, SizeOf(IdxType));
      end;
      Close(idx);
   end;
   filemode := fm;
   Unlock(D0+'Announce');
End {AddAnnounceIdx};


procedure MergeIdx;
var Ind2,Ind1,Ind3:Longint;
   Rec1,Rec2,Rec11:IdxType;
   ReadFrom:Longint;
   {$IFDEF VIRTUALPASCAL}
   Result1, TempWord: Longint;
   {$ELSE}
   Result1:Word;
   {$ENDIF}
   X:IdxType;
   BufTempIdx,BufAllIdx:^Recs;

    procedure GetRec1(var Rec1:IdxType);
       Procedure GetRec11;
       Var PrevPos:Longint;
       begin
          if Ind1<Result1 then
          begin
             Rec1 := BufTempIdx^[Ind1];
             inc(Ind1)
          end else
          begin
             PrevPos := FilePos(FilesIdxTot);
             if (ReadFrom>=0) then
             begin
                Seek(FilesIdxTot,ReadFrom);
                if not eof(FilesIdxTot) then
                begin
                   blockRead(FilesIdxTot,BufTempIdx^,LenRead1*SizeOf(IdxType),Result1);
                   if (Result1>0) then
                   begin
                      Ind1 := 0;
                      Rec1 := BufTempIdx^[Ind1];
                      inc(Ind1);
                      Result1 := Result1 div SizeOf(IdxType);
                      if (Result1=LenRead1) and not eof(FilesIdxTot) then
                         ReadFrom := FilePos(FilesIdxTot)
                      else
                         ReadFrom := -1;
                   end else
                   begin
                      rec1.nome[1] := #0;
                      ReadFrom := -1;
                   end;
                end else
                begin
                   rec1.nome[1] := #0;
                   ReadFrom := -1;
                end;
             end else
             begin
                rec1.nome[1] := #0;
                ReadFrom := -1;
             end;
             seek(FilesIdxTot,PrevPos);
          end;
          If FirstMerge then
          begin
             if (rec1.Nome<Rec11.Nome) or
                ((Rec1.Nome=Rec11.Nome) and (Rec1.Area<Rec11.Area)) then
               Rec1.Nome[1] := #0;
             Rec11 := Rec1;
          end;
       end {GetRec11};
    begin
       repeat
          GetRec11;
       until (Rec1.Nome[1]=#0) or not FirstMerge or
          not ((Aree = Nil) or IsInLista(Rec1.Area,Aree))
    end {GetRec1};
    procedure GetRec2(var Rec2:IdxType);
    begin
       {Prende un record dal Buffer}
       if Ind2<Nidx1 then
       begin
          Rec2 := Buf4^[Ind2];
          inc(Ind2)
       end else
       begin
          rec2.nome[1] := #0;
       end;
    end {GetRec2};
    Procedure SaveBufferIdx;
    begin
        BlockWrite(FilesIdxTot,BufAllIdx^,Ind3 * SizeOf(IdxType));
        Ind3 := 0;
    end {SaveBufferIdx};
    Procedure SaveRecAll(Rec:IdxType);
    begin
        BufAllIdx^[Ind3] := Rec;
        inc(Ind3);
        if Ind3=LenRead1 then
           SaveBufferIdx;
    end {SaveRecAll};

begin

   if (NIdx1>0) or FirstMerge then
   begin

      GetMem(BufTempIdx,LenRead1 * SizeOf(IdxType));
      GetMem(BufAllIdx,LenRead1 * SizeOf(IdxType));

      {si posiziona all'inizio del file di indice}
      ReadFrom := 0;
      Seek(FilesIdxTot,0);

      Ind1 := 0;
      Ind2 := 0;
      Ind3 := 0;

      Result1 := 0;
      FillChar(Rec11,SizeOf(Rec11),0);
      GetRec1(Rec1);
      GetRec2(Rec2);
      if Rec1.Nome[1]=#0 then
      begin
         while Rec2.Nome[1]<>#0 do
         begin
             SaveRecAll(Rec2);
             GetRec2(Rec2);
         end;
      end else
      if Rec2.Nome[1]=#0 then
      begin
         while Rec1.Nome[1]<>#0 do
         begin
             SaveRecAll(Rec1);
             GetRec1(Rec1);
         end;
      end else
      while (Rec1.Nome[1]<>#0) do
      begin
         if ((rec1.nome<rec2.nome) or ((Rec1.Nome=Rec2.Nome) and (Rec1.Area<Rec2.Area))) then
         begin
            SaveRecAll(Rec1);
            GetRec1(Rec1);
            if Rec1.Nome[1]=#0 then
            begin
               while Rec2.Nome[1]<>#0 do
               begin
                  SaveRecAll(Rec2);
                  GetRec2(Rec2);
               end;
            end;
         end else
         begin
            SaveRecAll(Rec2);
            GetRec2(Rec2);
            if Rec2.Nome[1]=#0 then
            while Rec1.Nome[1]<>#0 do
            begin
               SaveRecAll(Rec1);
               GetRec1(Rec1);
            end;
         end;
      end;

      if Ind3>0 then
         SaveBufferIdx;

      Truncate(FilesIdxTot);

      {Azzera l'indice del buffer, che e' stato salvato}
      NIdx1 := 0;
      FirstMerge := False;

      FreeMem(BufTempIdx,LenRead1 * SizeOf(IdxType));
      FreeMem(BufAllIdx,LenRead1 * SizeOf(IdxType));

   end;
end {MergeIdx};


Function SearchIdx(var SearchRec: IdxType): Boolean;
Const SizeBuf=10;
      XWin=30;
      YWin=5;
var Idx: File;
    fm:word;
    Buf: Array[1..10] of IdxType;
    PrevAttr: Byte;
    L,R,M,Right1, PosBuf: Longint;
    Rec: IdxType;
       {$IFDEF VIRTUALPASCAL}
       Result: Longint;
       {$ELSE}
       Result: word;
       {$ENDIF}
    MouInfo: MinfoRecType;

   Procedure WriteRec(i: Integer);
   begin
         GotoXY(XWin+1,YWin+I);
         for j := 1 to 12 do
         begin
            if buf[i].nome[j]<>#0 then
               Write(Buf[i].nome[j])
            else
               Write(' ');
         end;
         write(Buf[i].Area:6);
   end;

   Procedure LoadBuffer(FPos: Longint);
   var I, j: Word;
       {$IFDEF VIRTUALPASCAL}
       Result: Longint;
       {$ELSE}
       Result: word;
       {$ENDIF}
   begin
      seek(Idx, FPos-1);
      blockread(Idx, Buf, SizeBuf, Result);
      if (result<sizebuf) then
      begin
         fillchar(buf[result+1], (sizebuf - result) * sizeof(idxType), 0);
      end;
      for i := 1 to sizeBuf do
      begin
         writeRec(i);
      end;
   end;

begin
   Lock(D0 + 'FileIdx');
   Lock(D0 + 'Announce');
   Assign(Idx, PathIdx);
   fm := filemode;
   filemode := fmReadWrite_DA;
   {$I-}
   Reset(Idx,SizeOf(IdxType));
   {$I+}
   if IOResult=0 then
   begin

      PrevAttr := TextAttr;
      normvideo;

      HideCursor;
      GotoXY(XWin, YWin);
      Write(FrameChars[3], FrameChars[1], Button);
      for I := 6 to 19 do
         Write(FrameChars[1]);
      Write(FrameChars[4]);

      for I := 1 to SizeBuf do
      begin
         GotoXY(XWin,YWin+I);
         Write(FrameChars[2],FrameChars[2]:19);
      end;

      GotoXY(XWin, YWin + SizeBuf + 1);
      Write(FrameChars[5]);
      for I := 2 to 19 do
         Write(FrameChars[1]);
      Write(FrameChars[6]);

      {cerca il record...}
      Right1 := FileSize(Idx);
      if Right1 >= 1 then
      begin
         R := Right1;
         L := 1;
         while (L<=R) do
         begin
            M := (L + R) div 2;
            Seek(Idx,M-1);
            BlockRead(Idx,Rec,1,result);
            if Rec.Nome<SearchRec.Nome then
            begin
               L := M + 1;
            end else
            if Rec.Nome>SearchRec.Nome then
            begin
               R := M - 1
            end else
            begin
               R := L - 1;
            end;
         end;
      end else
         M := 1;

      PosBuf := 1;
      while (M>1) and (posBuf<sizebuf div 2) do
      begin
         dec(M);
         inc(posBuf);
      end;

      loadbuffer(M);

      repeat
         invVideo;
         Writerec(PosBuf);
         WaitEvent;
         NormVideo;
         WriteRec(posBuf);
         if KeyPressed then
         begin
            Ch := Upcase(ReadKey);
            if Ch = #0 then
            begin
               ch := Readkey;
               case ch of
                  #72:begin
                         dec(PosBuf);
                         if PosBuf=0 then
                         begin
                            if (M>1) then
                            begin
                               dec(M);
                               LoadBuffer(M);
                            end;
                            PosBuf := 1;
                         end;
                      end;
                  #80:begin
                         inc(posBuf);
                         if posBuf>sizeBuf then
                         begin
                            if (M<right1) then
                            begin
                               inc(M);
                               loadBuffer(M);
                            end;
                            PosBuf := SizeBuf;
                         end;
                      end;
               end;
            end;
         end else
         begin
            MouGet(MouInfo);
            if (MouInfo.cx = XWIn+2) and (mouinfo.cy=Ywin-1) then
            begin
               ch := #27;
            end else
            if (MouInfo.cx >= Xwin) and (mouinfo.cx < Xwin + 18) and
               (MouInfo.cy >= YWin) and (mouinfo.cy < YWin + SizeBuf) then
            begin
               PosBuf := mouinfo.cy - YWin + 1;
               if MouInfo.IsDouble then
               begin
                  ch := #13
               end else
                  ch := #0;
            end else
               ch := #0;
         end;
      until (ch=#13) or (ch=#27);
      searchRec := buf[posBuf];
      SearchIdx := ch=#13;
      TextAttr := PrevAttr;
      close(Idx);
   end else
      SearchIdx := False;

   filemode := fm;
   Unlock(D0 + 'Announce');
   Unlock(D0 + 'FileIdx');
end;


end.
