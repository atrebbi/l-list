Unit LLComp;

{$I LL.Def}

Interface

Uses Crt, Dos,
   MkFile,
   LLGen, LLTEND, LLVIEW, LLEXEC, LLSHELL, LLMOUSE;

Procedure ViewCompressed(CompressedFile:String; var AllFiles:Text);

Implementation

Procedure ViewCompressed(CompressedFile:String; var AllFiles:Text);
var F:File;
    Temp:Byte;
    FSize, FPos:Longint;
    fm:word;
    Z: Integer;
    CSize, USize: Longint;
    Entries: DescTypePtr;
    EntriesRef: ^DescTypePtr;
    NEntries : Integer;
    {$IFDEF VIRTUALPASCAL}
    Result: Longint;
    {$ELSE}
    Result: Word;
    {$ENDIF}


 Procedure CompHeader;
 begin
     if lliststatus<>EditFilesBbs then
     begin
        WriteLn(AllFiles, '   Name           Length      Size  Saved  Method    Path');
        WriteLn(AllFiles,'   ',RepeatStr('Ä',54));
     end;
 end {CompHeader};

 Procedure InFileInfo(Name:String; USize,CSize:Longint; Method:String);
 var D:DirStr;
     Perc:Real;
     I : Integer;
 begin
    if Usize>0 then
       Perc := 100-CSize/USize*100
    else
       Perc := 0;
    for I:=1 to length(Name) do
    begin
       Name[I] := UpCase(Name[I]);
       If Name[I]='/' then Name[I]:='\';
    end;
    I := Length(Name);
    while (I>0) and (Name[I]<>'/') and (Name[I]<>'\') and (Name[I]<>':') do
       dec(I);
    if I>0 then
    begin
       D := Copy(Name,1,I);
       delete(Name,1,I);
       if D[length(D)]='\' then
          dec(D[0]);
    end else
       D := '';
    if D<>'' then
       Method := Method + RepeatStr(' ',10-length(Method)) + D;
    L := Name + RepeatStr(' ',13-length(Name)) +
       Long2Str(USize,8) + Long2Str(CSize,10) +
       Long2Str(Round(Perc),5) + '%   ' + Method;
    if llistStatus=EditFilesBbs then
    begin
       POsDesc := 1;
       PutDescrizione(EntriesRef^);
       EntriesRef := Addr(EntriesRef^^.Next);
    end else
    begin
       WriteLn(AllFiles,'   ',L);
    end;
 end {inFileInfo};

 Procedure Error;
 begin
    if llistStatus<>EditFilesBbs then
       WriteLn(AllFiles,'   * Error in compressed file');
 end {Error};

 Procedure CompFooter;
   var Perc:Real;
 begin
     if llistStatus<>EditFilesBbs then
     begin
        if USize>0 then
           Perc := 100-CSize * 100 / USize
        else
           Perc := 0;
        WriteLn(AllFiles,'   ',RepeatStr('Í',54));
        Writeln(AllFiles,z:4, ' Files  ',
           USize:12,
                CSize:10,
                Round(Perc):5,'%');
     end;
 end {CompFooter};

 Procedure ZipView(Var F:File);  { View the ZIP file }
   Const
     SIG = $04034B50;                  { Signature }
   Var
     FHdr     :
       Record                 { Zip File Header }
              Signature : LongInt;
              Version,GPBFlag,Compress,Date,Time : Word;
              CRC32,CSize,USize : LongInt;
              FNameLen,ExtraField : Word;
       End;
     S   : String;
     Method:String[8];

 Begin
     z := 0; uSize := 0; cSize := 0; { Init variables }

     CompHeader;
     Repeat
       BlockRead(F,FHdr,SizeOf(FHdr),Result);
       if (Result=SizeOf(FHdr)) and (Fhdr.Signature=Sig) then
       begin
          BlockRead(F,s[1],FHdr.FNameLen,Result);
          if (Result=FHdr.FNameLen) then
          begin
             Byte(s[0]) := FHdr.FNameLen;
             inc(z);
             Case FHdr.Compress of
                0: Method := 'Stored';
                1: Method := 'Shrunk';
                2: Method := 'Reduced1';
                3: Method := 'Reduced2';
                4: Method := 'Reduced3';
                5: Method := 'Reduced4';
                6: Method := 'Imploded';
                7: Method := 'Deflated';
                8: Method := 'DeflatX';
               else
                   Method := 'Unknown';
             end;
             InFileInfo(S,FHdr.USize,FHdr.CSize,Method);
             Inc(USize,FHdr.USize);  { Increment size uncompressed }
             Inc(CSize,FHdr.CSize);  { Increment size compressed }
             FPos := FPos + SizeOf(FHdr) + FHdr.FNameLen +
                FHdr.CSize + FHdr.ExtraField;
             if FPos<FSize then
                Seek(F, FPos);
          end else
          begin
             {forza l'uscita}
             FPos := FSize;
          end;
       end
     Until (Fpos>=FSize) or (FHdr.Signature<>Sig); { No more files }
     CompFooter;
 End {ZipView};


 Procedure ArjView(Var F:File);
 Const ID=$EA60;

 Var
   FHdr   :
     Record  { ArjFileHeader }
       HeadId,HdrSize:Word;
       HeadSize,VerNum,MinVerNum,HostOS,ArjFlag,Method,Ftype,Reserved : Byte;
       FileTime,PackSize,OrigSize,FileCRC : LongInt;
       FilePosF,FileAcc,HostData : Word;
     End;
   s  : String;
   Method : String[8];
 Begin
   z := 0;
   USize := 0;
   CSize := 0;   { Init variables }
   CompHeader;
   BlockRead(F,FHdr,SizeOf(FHdr),Result);
   if (Result=SizeOf(FHdr)) then
   begin
      FPos := FPos + FHdr.HdrSize + 10;
      if FPos<FSize then
      begin
         Seek(F,FPos);
         Repeat
            BlockRead(F,FHdr,SizeOf(FHdr),Result);
            if (Result=SizeOf(FHdr)) and (FHdr.HdrSize>0) then
            begin
               if (FHdr.HeadId=Id) then
               begin
                  Blockread(F,S[1],255,Result);
                  S[0] := Chr(Result);
                  S[0] := Chr(pos(#0,S) -1);
                  inc(z);
                  Case FHdr.Method Of             { Get compression method }
                      0 : Method := 'Stored';
                      1 : Method := 'Most';
                      2 : Method := '2nd Most';
                      3 : Method := '2nd Fast';
                      4 : Method := 'Fastest';
                   else
                        Method := 'Unknown';
                  End;
                  InFileInfo(S,FHdr.OrigSize,FHdr.PackSize,Method);
                  Inc(USize,FHdr.OrigSize); { Increase total uncompressed size }
                  Inc(CSize,FHdr.PackSize); { Increase total compressed size }
                  FPos := FPos + FHdr.HdrSize + FHdr.PackSize + 10;
                  if FPos<FSize then
                  begin
                     Seek(F,FPos)
                  end else
                  begin
                     {fine del file, forza l'uscita}
                     FHdr.HDrSize := 0
                  end;
               end else
               begin
                  {Bad ID, forza l'uscita}
                  FHdr.HDrSize := 0
               end;
            End;
         Until (FHdr.HdrSize = 0);  { No more files? }
      end;
   end;
   CompFooter;
 End;


 Procedure LzhView(Var F:File); { View the LZH file }
 var
   Fhdr : record  { Lzh file header }
     Headsize,Headchk : byte;
     HeadID1 : array[1..3] of char;
     Method, HeadId2: Char;
     Packsize,Origsize,Filetime : longint;
     Attr : word;
     filename : String[12];
     f32 : PathStr;
     dt : DateTime;
   end;

 begin
   CompHeader;
   z  :=  0;
   CSize  :=  0;
   USize := 0;
   repeat
     BlockRead(f,fhdr,sizeof(fhdr),result);
     if (result=SizeOf(FHdr)) and (FHdr.HeadId1='-lh') and
        (fhdr.HeadSize<>0) then
     begin
        inc(z);
        inc(USize,Fhdr.OrigSize);            { Increase Uncompressed Size }
        inc(CSize,Fhdr.PackSize);
        InFileInfo(fhdr.filename,fhdr.origsize,fhdr.packSize,
           copy(Fhdr.HeadId1,2,2)+Fhdr.Method);
        FPos := FPos + fhdr.headsize + 2 + fhdr.packsize;
        if FPos<FSize then
           Seek(F,FPos);
     end else
     begin
        {Bad, forza l'uscita}
        FHdr.HeadSize := 0
     end;
   until (FPos>=FSize) or (fhdr.headsize=0);
   CompFooter;
 End {LzhView};


 Procedure ArcView(Var F:File);
 Const Id=$1A;
 Var FHdr:
      Record
         HeadId,Compression:Byte;
         FileName:Array[1..13] of Char;
         CSize:LongInt;
         FileDate,FileTime,Crc:Word;
         USize:Longint;
      End;
     S,Method:String;
 begin
    USize := 0;
    CSize := 0;
    Z := 0;
    CompHeader;
    repeat
       BlockRead(F,FHdr,SizeOf(FHdr),Result);
       if (Result=SizeOf(FHdr)) and (FHdr.HeadId=Id) and
          (FHdr.Compression>0) then
       begin
          inc(Z);
          case FHdr.Compression of
             1,2:Method := 'Stored';
             3:Method := 'Packed';
             4:Method := 'Squeezed';
             5..8:Method := 'Crunched';
             9:Method := 'Squashed';
             10:Method := 'Crushed';
             11:Method := 'Distill';
           else
             Method := 'Unknown';
          end;
          S[0] := #13;
          move(FHdr.FileName,S[1],13);
          S[0] := chr(pos(#0,S)-1);
          inc(USize,FHdr.USize);
          inc(CSize,FHdr.CSize);
          InFileInfo(S,FHdr.USize,FHdr.CSize,Method);
          FPos := FPos + SizeOf(FHdr) + FHdr.CSize;
          if FPos<FSize then
          begin
             Seek(F,FPos)
          end else
             FHdr.Compression := 0;
       end else
          FHdr.Compression := 0;
    until (FHdr.Compression=0);
    CompFooter;
 end {ArcView};


 Procedure RarView(Var F:File);
    Var
       ArcHeader:Record
           Head_Crc: Word;
           Head_Type: Byte;
           Head_Flags, Head_Size, Reserved1: Word;
           Reserved2: Longint;
       end;
       FHDr:Record
           Head_Crc: Word;
           Head_Type: Byte;
           Head_Flags, Head_Size: Word;
           Pack_Size, Unp_Size: Longint;
           Host_OS: Byte;
           File_CRC, FTIme: Longint;
           Unp_Ver, Method: Byte;
           Name_Size: Word;
           Attr: Longint;
       end;
       S, Method : String;
 Begin
    CompHeader;
    USize := 0; CSize := 0; Z := 0;
    {skip header, 7 bytes "Rar!..."}
    inc(FPos,7);
    if (FPos<FSize) then
    begin
       Seek(F,FPos);
       {ora legge l'header principlae}
       BlockRead(F,ArcHeader,SizeOf(ArcHeader),Result);
       {e lo salta}
       if (Result=SizeOf(ArcHeader)) then
       begin
          FPos := FPos + ArcHeader.Head_Size;
          {ora iniziano le info sui files...}
          while (FPos<FSize) do
          begin
             Seek(F,FPos);
             BlockRead(F,FHdr,SizeOf(FHdr),Result);
             if (Result=SizeOf(FHdr)) then
             begin
                if (FHdr.Head_Type=$74) then
                begin
                   BlockRead(F,S[1],FHdr.Name_Size,Result);
                   if (Result=FHdr.Name_Size) then
                   begin
                      S[0] := Chr(FHdr.Name_Size);
                      {controlla se e' una DIR, eventualmente aggiusta il nome}
                      if (FHdr.Attr AND Directory <> 0) then
                      begin
                         if (S[length(S)]<>'\') and (S[length(S)]<>'/') then
                            S := S + '\';
                      end;
                      Inc(USize, FHdr.Unp_Size);
                      Inc(CSize, FHdr.Pack_Size);
                      Inc(Z);
                      Case FHdr.Method of
                         $30: Method := 'Stored';
                         $31: Method := 'Fastest';
                         $32: Method := 'Fast';
                         $33: Method := 'Normal';
                         $34: Method := 'Good';
                         $35: Method := 'Best';
                        else
                         Method := 'Unknown';
                      end;
                      InFileInfo(S,FHdr.Unp_Size, FHdr.Pack_Size, Method);
                      FPos := FPos + FHdr.Head_Size + FHdr.Pack_Size;
                   end else
                   begin
                      Fpos := FSize
                   end;
                end else
                begin
                   FPos := FPos + FHdr.Head_Size;
                end;
             end else
             begin
                FPos := FSize
             end;
          end;
       end;
    end;
    CompFooter;
 End {RarView};

 Procedure ViewEntries;
 Var
     Ch:Char;
     NEntry, I, SkipEntries: Integer;
     CurrFile, Currline: String;
     NL : INteger;
     FirstScreenEntry: DescTypePtr;
     MouInfo: MinfoRecType;
     PrevSize, PrevTime: Longint;
     S: SearchRec;

     procedure removeEntry(N: Integer);
     Var
        TempDescTypePtr, TempDescTypePtr1 : DescTypePtr;
        I: Integer;
     begin
        TempDescTypePtr := FirstScreenEntry;
        for I := 1 to N - 1 do
           TempDescTypePtr := TempDescTypePtr^.Next;
        if TempDescTypePtr^.Next<>Nil then
        begin
           freemem(TempDescTypePtr^.Descrizione, length(TempDescTypePtr^.descrizione^) + 1);
           TempDescTypePtr^.Descrizione := TempDescTypePtr^.Next^.descrizione;
           TempDescTypePtr1 := TempDescTypePtr^.Next^.Next;
           Dispose(TempDescTypePtr^.Next);
           TempDescTypePtr^.Next := TempDescTypePtr1;
        end;
     end;

     procedure UpdateEntry(N: Integer; USize, DCSize: Longint);
     Var
        TempDescTypePtr, TempDescTypePtr1 : DescTypePtr;
        I: Integer;
        OldCSize: Longint;
        {$IFDEF VIRTUALPASCAL}
        Code: Longint;
        {$ELSE}
        Code: Word;
        {$ENDIF}
        TempStr: String;
     begin
        TempDescTypePtr := FirstScreenEntry;
        for I := 1 to N - 1 do
           TempDescTypePtr := TempDescTypePtr^.Next;
        TempStr := TempDescTypePtr^.Descrizione^;
        {Nome}
        I := pos(' ', TempStr);
        delete(TempStr,1,I);
        StripLeadingSpace(TEmpStr);
        {comnincia UNcompressed}
        I := pos(' ',TempStr);
        Delete(TempStr,1,I);
        StripLeadingSpace(TempStr);
        {Comincia UnComp}
        I := Pos(' ', TempStr);
        Val(Copy(TempStr,1,I-1), OldCSize, Code);
        Inc(OldCSize, DCSize);
        TempDescTypePtr^.Descrizione^ :=
           Copy(TempDescTypePtr^.Descrizione^,1,13) + Long2Str(USize,8) +
              Long2Str(OldCSize,10) +
              Long2Str(OldCSize * 100 div USize, 5) +
              Copy(TempDescTypePtr^.Descrizione^, 37, Length(TempDescTypePtr^.Descrizione^) - 36);
     end;



     Procedure GetCurrEntry;
     Var TempDescTypePtr: DescTypePtr;
         I: Integer;
     begin
        TempDescTypePtr := FirstScreenEntry;
        I := NEntry - SkipEntries;
        while (I>1) do
        begin
           TempDescTypePtr := TempDescTypePtr^.Next;
           dec(I);
        end;
        CurrLine := TempDescTypePtr^.Descrizione^;
        CurrFile := CurrLine;
        if pos(' ',CurrFile)>1 then
        begin
           if length(CurrFile)>=51 then
           begin
              CurrFile := Copy(CurrFile,51,length(CurrFile)-50) + '\'
                + Copy(CurrFile,1,Pos(' ',CurrFile)-1);
           end else
           begin
              CurrFile := Copy(CurrFile,1,Pos(' ',CurrFile)-1);
           end;
        end else
           CurrFile := '';
        if length(currLine) > 79 then
           CurrLine[0] := #79;
     end;

     Procedure DisplayEntries;
     Var I: Integer;
         TempDescTypePtr: DescTypePtr;
     Begin
        HideCursor;
        InvVideo;
        GotoXY(1,1);
        TempStr := CompressedFile;
        if length(TempStr)>52 then
           TempStr[0] := Chr(52);
        Write(' ',Packer[Temp]^.Ext,'³':3,' ',TempStr,'':52-length(TempStr),
           Z:8, BytesStr(FSize):12);
        NormVideo;
        TempDescTypePtr := Entries;
        For I := 1 to SkipEntries do
           TempDescTypePtr := TempDescTypePtr^.Next;
        FirstScreenEntry := TempDescTypePtr;
        for I := SkipEntries+1 to SkipEntries + NL do
        begin
           if (TempDescTypePtr<>Nil) and (I<=Z) then
           begin
              TempStr := TempDescTypePtr^.Descrizione^;
              if length(TempStr)>79 then
                 TempStr[0] := #79;
              Writeln(TempStr,'':79-length(TempStr));
              TempDescTypePtr := TempDescTypePtr^.Next;
           end else
              Writeln('':79);
        end;

        {ora scrive l'ascensore :-)}

         GotoXY(80,2);
         Write(#30);

         For I := 1 to (NEntry * (NL-2) div Z) -1 do
         begin
            GotoXY(80,I+2);
            Write('°');
         end;

         GotoXY(80, NEntry * (NL-2) div z + 2);
         Write('²');

         for I := (NEntry * (NL-2) div Z) + 1 to NL - 2 do
         begin
            GotoXY(80,I+2);
            Write('°');
         end;

         GotoXY(80,NL+1);
         Write(#31);
        ShowCursor;
     End;

     Procedure ShowHelp;
     Const
        MenuItem: Byte = 1;
        MaxItems = 6;
        MenuItems: Array[1..maxitems] of string [38] =
           ('F1    = View this help',   'Alt-R = Execute current file',
            'Alt-V = View current file','Alt-F<n> = Execute shell <n>',
            '<ESC> = Exit viewer',      'Alt-D = Delete current file');
        MenuChar: Array[1..maxitems] of string[2] =
           (#0#59, #0#19,
            #0#47, '',
            #27, #0#32);
     Var I : Integer;
         ch: Char;
     begin
        for i := 1 to maxitems do
        if message[199+i]<>nil then
        begin
           menuitems[i]:=message[199+i]^;
           freemem(message[199+i],length(message[199+i]^)+1);
           message[199+i]:=nil;
        end;
        HideCursor;
        GotoXY(1,2);
        Write(FrameChars[3], FrameChars[1], Button);
        for J := 6 to 79 do
           Write(FrameChars[1]);
        Write(FrameChars[4]);

        for I := 1 to MaxItems div 2 do
        begin
           Write(FrameChars[2], ' ',menuitems[I * 2 -1],'':38 - length(menuitems[i* 2-1]),
              menuitems[I * 2],'':38 - length(menuitems[i* 2]),' ', FrameChars[2]);
        end;

        Write(FrameChars[5]);
        for J := 2 to 79 do
           Write(FrameChars[1]);
        Write(FrameChars[6]);

        repeat
           GotoXY(3 + 38 * ((Menuitem + 1) mod 2), 2 + (menuitem + 1) div 2);
           invvideo;
           Write(menuitems[menuitem],'':38 - length(menuitems[menuitem]));
           waitevent;
           GotoXY(3 + 38 * ((Menuitem + 1) mod 2), 2 + (menuitem + 1) div 2);
           normvideo;
           Write(menuitems[menuitem],'':38 - length(menuitems[menuitem]));
           if keypressed then
           begin
              ch := readkey;
              if ch = #0 then
              begin
                 ch := readkey;
                 case ch of
                    #77: if menuitem < maxitems then
                            inc(menuitem);
                    #75: if menuitem > 1 then
                            dec(menuitem);
                    #72: if menuitem > 2 then
                            dec(menuitem,2);
                    #80: if menuitem < maxitems - 1 then
                            inc(menuitem,2);
                 end;
              end;
           end else
           begin
              MouGet(MouInfo);
              if (MouInfo.cy = 1) and (mouinfo.cx = 3) then
              begin
                 ch := #27;
              end else
              if (MouInfo.cy > 1) and (mouinfo.cy < maxitems div 2 + 2) and
                (MouInfo.cx > 0) and (mouinfo.cx < 79) then
              begin
                 menuitem := (mouinfo.cy - 1) * 2;
                 if mouinfo.cx < 40 then
                    dec(menuitem);
                 if MouInfo.IsDouble then
                    ch := #13
                 else
                    ch := #0;
              end;
           end;
        until (ch=#13) or (ch=#27);
        if ch=#13 then
           KbdBuffer := MenuChar[menuitem];
        ShowCursor;
     end;
 Begin
     NEntry := 1;
     SkipEntries := 0;
     NL := Hi(WindMax) - Hi(WindMin) + 1 - 2;
     DisplayEntries;
     Repeat
        GetCurrEntry;
        InvVideo;
        TempStr := CurrFile;
        if length(TempStr)>70 then
           TempStr[0] := #70;
        GotoXY(1, NL + 2);
        Write(' ',TempStr,'':70-length(TempStr),'1:',NEntry);
        Write('':80-whereX);
        GotoXY(1, 1 + NEntry - SkipEntries);
        Write(CurrLine, '':79 - length(currLine));
        NormVideo;
        waitevent;
        GotoXY(1, 1 + NEntry - SkipEntries);
        Write(CurrLine, '':79 - length(currLine));
        if keypressed then
        begin
           ch := ReadKey;
           if Ch=#0 then
           begin
              Ch := ReadKey;
              case ch of
                 #59: begin
                         ShowHelp;
                         DisplayEntries;
                      end;
                 #71: Begin {home}
                         NEntry := 1;
                         if SkipEntries > 0 then
                         begin
                            SkipEntries := 0;
                            DisplayEntries
                         end;
                      end;
                 #79: begin
                         NEntry := Z;
                         if NEntry - NL > SkipEntries then
                         begin
                            SkipEntries := NEntry - NL;
                            DisplayEntries
                         end;
                      end;
                 #72: if NEntry>1 then
                      begin
                         dec(NEntry);
                         if NEntry<=SkipEntries then
                         begin
                            SkipEntries := NEntry - NL div 2;
                            if SkipEntries < 0 then
                               SkipEntries := 0;
                            DisplayEntries
                         end;
                      end;
                 #73: begin
                         dec(NEntry,NL);
                         if NEntry<=0 then
                            NEntry := 1;
                         if NEntry<=SkipEntries then
                         begin
                            SkipEntries := NEntry -1;
                            DisplayEntries
                         end;
                      end;
                 #80: if Nentry<Z then
                      begin
                         inc(NEntry);
                         if NEntry - NL > SkipEntries then
                         begin
                            SkipEntries := NEntry - NL div 2;
                            if SkipEntries < 0 then
                               SkipEntries := 0;
                            DisplayEntries
                         end;
                      end;
                 #81: begin
                         inc(NEntry,NL);
                         if NEntry>Z then
                            NEntry := Z;
                         if NEntry - NL > SkipEntries then
                         begin
                            SkipEntries := NEntry - NL;
                            DisplayEntries
                         end;
                      end;
                 #104..#113:{Alt-F<N>}
                 if (CurrFile<>'') and (ExternalShell[ord(ch)-103]<>'') then
                 begin
                    {$IFDEF NO4350}
                    {$ELSE}
                    if ModeFont8x8 then
                       TextMode(CO80);
                    {$ENDIF}
                    TextAttr := StartAttr;
                    ClrScr;
                    GotoXY(1,10);
                    if Uncompress(CompressedFile,CurrFile,Temp) then
                    begin
                       FindFirst(TempDir + CurrFile, Archive + ReadOnly, S);
                       PrevSize := S.Size;
                       PrevTime := S.Time;
                       {$IFDEF VIRTUALPASCAL}
                       FindClose(S);
                       {$ENDIF}
                       ExecuteExternalShell(Ord(Ch)-103,
                          TempDir + CurrFile);
                       FindFirst(TempDir + CurrFile, Archive + ReadOnly, S);
                       if Doserror=0 then
                       begin
                          {$IFDEF VIRTUALPASCAL}
                          FindClose(S);
                          {$ENDIF}
                          if ((S.Size <> PrevSize) or (S.Time <> PrevTime)) and
                             Conferma('"' + CurrFile + '" was modified; recompress') then
                          begin
                             PrevSize := S.Size;
                             TextAttr := StartAttr;
                             ClrScr;
                             GotoXY(1,10);
                             Compress(Compressedfile, TempDir + CurrFile, Temp);
                             {Nuova dimensione del file compresso}
                             FindFirst(CompressedFile, Archive + ReadOnly, S);
                             {$IFDEF VIRTUALPASCAL}
                             FindClose(S);
                             {$ENDIF}
                             UpdateEntry(NEntry, PrevSize, S.Size - FSize);
                             FSize := S.Size;
                          end;
                       end else
                          KbdBuffer := #0#32;
                    end;
                    {$IFDEF NO4350}
                    {$ELSE}
                    if ModeFont8x8 then
                       TextMode(Font8x8+Co80);
                    {$ENDIF}
                    DisplayEntries;
                 end;
                 #32:{Alt-D=Delete}
                 if (CurrFile<>'') and Conferma('Delete ' + CurrFile)then
                 begin
                    {$IFDEF NO4350}
                    {$ELSE}
                    if modefont8x8 then
                       TextMode(CO80);
                    {$ENDIF}
                    TextAttr := StartAttr;
                    ClrScr;
                    GotoXY(1,10);
                    if DelCompressed(CompressedFile,CurrFile,Temp) then
                    begin
                       RemoveEntry(NEntry);
                       Dec(Z);
                       if (NEntry>Z) then
                          NEntry := Z;
                       if NEntry <= SkipEntries then
                          SkipEntries := NEntry -1;
                    end;
                    {$IFDEF NO4350}
                    {$ELSE}
                    if modefont8x8 then
                       textmode(font8x8 + co80);
                    {$ENDIF}
                    if Z>0 then
                    begin
                       FindFirst(CompressedFile, Archive + ReadOnly, S);
                       {$IFDEF VIRTUALPASCAL}
                       FindClose(S);
                       {$ENDIF}
                       FSize := S.Size;
                       DisplayEntries
                    end else
                    begin
                       if EraseFile(CompressedFile) then;
                    end;
                 end else
                    DisplayEntries;
                 {Alt-V}
                 #47:
                 {uncompress il file, e lancia il viewer interno}
                 if (CurrFile<>'') then
                 begin
                    {$IFDEF NO4350}
                    {$ELSE}
                    if modefont8x8 then
                       TextMode(CO80);
                    {$ENDIF}
                    TextAttr := StartAttr;
                    ClrScr;
                    GotoXY(1,10);
                    if Uncompress(CompressedFile,CurrFile,Temp) then
                    begin
                       {$IFDEF NO4350}
                       {$ELSE}
                       if modefont8x8 then
                          textmode(font8x8 + co80);
                       {$ENDIF}
                       FindFirst(TempDir + CurrFile, Archive + ReadOnly, S);
                       PrevSize := S.Size;
                       PrevTime := S.Time;
                       {$IFDEF VIRTUALPASCAL}
                       FindClose(S);
                       {$ENDIF}
                       TempDir := TempDir + 'Z#\';
                       if MakePath(Copy(TempDir,1,length(TempDir)-1)) then;
                       ViewCompressed(Copy(TempDir,1,length(TempDir)-3)+CurrFile, Output);
                       {
                       RmDir(Copy(TempDir,1,length(TempDir)-1));
                       }
                       Dec(TempDir[0],3);
                       Clrscr;
                       FindFirst(TempDir + CurrFile, Archive + ReadOnly, S);
                       if dosError=0 then
                       begin
                          {$IFDEF VIRTUALPASCAL}
                          FindClose(S);
                          {$ENDIF}
                          if ((S.Size <> PrevSize) or (S.Time <> PrevTime)) and
                             Conferma('"' + CurrFile + '" was modified; recompress') then
                          begin
                             PrevSize := S.Size;
                             TextAttr := StartAttr;
                             ClrScr;
                             GotoXY(1,10);
                             Compress(Compressedfile, TempDir + CurrFile, Temp);
                             {Nuova dimensione del file compresso}
                             FindFirst(CompressedFile, Archive + ReadOnly, S);
                             {$IFDEF VIRTUALPASCAL}
                             FindClose(S);
                             {$ENDIF}
                             UpdateEntry(NEntry, PrevSize, S.Size - FSize);
                             FSize := S.Size;
                          end;
                       end else
                          KbdBuffer := #0#32;
                    end;
                    {$IFDEF NO4350}
                    {$ELSE}
                    if modefont8x8 then
                       textmode(font8x8 + co80);
                    {$ENDIF}
                    DisplayEntries;
                 end;
                 #19:
                 {uncompress il file, e lancia il viewver interno}
                 if (CurrFile<>'') and
                   ((pos('.COM',CurrFile)=length(CurrFile)-3)
                    or (pos('.EXE',CurrFile)=length(CurrFile)-3)
                    or (pos('.BAT',CurrFile)=length(CurrFile)-3)
                    {$IFDEF OS2}
                    or (pos('.CMD',CurrFile)=length(CurrFile)-3)
                    {$ENDIF}
                   )
                    then
                 begin
                    {$IFDEF NO4350}
                    {$ELSE}
                    if modefont8x8 then
                       TextMode(CO80);
                    {$ENDIF}
                    TextAttr := StartAttr;
                    ClrScr;
                    GotoXY(1,10);
                    if Uncompress(CompressedFile,CurrFile,Temp) then
                    begin
                       TempStr := '';
                       ReadBox('Optional parameters',40,TempStr);
                       if TempStr<>'' then
                          TempStr := ' ' + TempStr;
                       ClrScr;
                       GotoXY(1,10);
                       Execute(TempDir+CurrFile+TempStr);
                       PressKey;
                    end;
                    {$IFDEF NO4350}
                    {$ELSE}
                    if modefont8x8 then
                       textmode(font8x8 + co80);
                    {$ENDIF}
                    DisplayEntries;
                 end;
              end;
           end
        end else
        begin
           mouget(mouinfo);
           if MouInfo.cx = 79 then
           begin
              if mouinfo.cy = 1 then
              begin
                 Kbdbuffer := #0 + #73;
              end else
              if mouinfo.cy = NL then
              begin
                 Kbdbuffer := #0 + #81;
              end;
           end else
           if mouinfo.cy=0 then
           begin
              KbdBuffer := #0 + #59;
           end else
           begin
              NEntry := mouInfo.cy + SkipEntries;
              if NEntry > Z then
              begin
                 NEntry := Z;
              end else
              if MouInfo.IsDouble then
                 KbdBuffer := #0 + #47;
           end;
           ch := #0;
        end;
     until (Ch=#27) or (Z=0);
 end;

begin
   Assign(F,CompressedFile);
   fm := FileMode;
   FileMode := FmReadOnly_DW;
   {$I-}
   Reset(F,1);
   {$I+}
   if IOResult=0 then
   begin
      Temp := GetCompressor(F);
      if Temp >= 128 then
      begin
         Close(F);
         if LlistStatus=EditFilesBbs then
         begin
            BoxMessage(GraficFileInfo);
         end;
      end else
      begin
         Entries := Nil;
         EntriesRef := Addr(Entries);
         FSize := FileSize(F);
         FPos := FilePos(F);
         if Temp=0 then
         begin
            Close(F);
            if (LListStatus=EditFilesBbs) then
            begin
               View(CompressedFile);
            end;
         end else
         if Packer[Temp]^.Ext='ZIP' then
         begin
            ZipView(F);
            Close(F);
            if LlistStatus=EditFilesBbs then
               ViewEntries;
         end else
         if Packer[Temp]^.Ext='ARJ' then
         begin
            ArjView(F);
            Close(F);
            if LlistStatus=EditFilesBbs then
               ViewEntries;
         end else
         if (Packer[Temp]^.Ext='LHA') or (Packer[Temp]^.Ext='LZH') then
         begin
            LzhView(F);
            Close(F);
            if LlistStatus=EditFilesBbs then
               ViewEntries;
         end else
         if (Packer[Temp]^.Ext='ARC') or (Packer[Temp]^.Ext='PAK') then
         begin
            ArcView(F);
            Close(F);
            if LlistStatus=EditFilesBbs then
               ViewEntries;
         end else
         if (Packer[Temp]^.Ext='RAR') then
         begin
            RarView(F);
            Close(F);
            if LlistStatus=EditFilesBbs then
               ViewEntries;
         end else
         begin
            Close(F);
            if (LListStatus=EditFilesBbs) then
            begin
               View(CompressedFile);
            end;
         end;
         CancellaDescrizione(Entries);
      end;
   end;
   filemode := fm;
end {ViewCompressed};

end.
