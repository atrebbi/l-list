Program Scan_Cd;

{$M 65520,0,655360}

{$S+,R+}

Uses {$IFDEF VIRTUALPASCAL} os2base, {$ENDIF}
   Dos;

{$I SC_CDVER.DEF}

const
      LookStr:String[12]='FILES.BBS';

type
     PathListPtr=^PathList;
     PathList=Record
        Path:PathStr;
        Next:PathListPtr
     end;
     MyRecPtr=^MyRec;
     MyRec=Record
        Name:String[12];
        Next:MyRecPtr
     end;
          FlagType=array[1..4] of byte;
          AreaFileType=Record
              Nome: Array[1..70] of char;     { Titolo area file                          }
              Numero: Integer;         { Numero area file                          }
              pathup: Array[1..40] of char;        { Path di Upload                            }
              PathDown: Array[1..40] of char;      { Path di Download                          }
              PathFBbs: Array[1..50] of char;      { CD-ROM list file name                     }
              Attr: Byte;
                                         { BIT
                                           1: Download illimitato
                                           2: norm_req
                                           3: know_req
                                           4: prot_req
                                           5: Non effettuare l'annucio di nuovi file
                                           6: Area non inserita nella ricerca globale fil
                                           7: no_filedate
                                           8: Lettura ristretta al gruppo di appartenenza
                                         }
              Gruppo: Word;            { Gruppo di appartenenza 0 = nessuno        }
              Lev: Byte;           { Minimum level to access this area         }
              FlagLev: FlagType;       { Flags settings                            }
              LevDown: Byte;       { Minimum level to download files           }
              FlagLevDown: FlagType;   { Flags settings                            }
              LevUp: Byte;         { Minimum level to upload files             }
              FlagLevUp: FlagType;     { Flags settings                            }
              list_priv: Byte;           { ???                                       }
              list_flags:FlagType;       { ???                      }
              fill: array[1..10] of Byte;
              short_name: Array[1..13] of char;    { Nome breve area                           }
              fill1: array[1..8] of Byte;
              tic_tag: Array[1..32] of char;
              tic_forward1,
              tic_forward2,
              tic_forward3: String[79];
              tic_level: Byte;
              tic_flags: LongInt;
              CdRom: Byte;
                                         { BIT
                                           1: CDRom area
                                           2:
                                           3:
                                           4:
                                           5:
                                           6:
                                           7:
                                           8:  }
              fill2: array[1..106] of Byte;
          end;
          AreaFileIdxType=Record
                 Lev:byte;
                 FlagLev:FlagType;
                 ShortName:array[1..13] of char;
                 Numero,Gruppo:Integer;
              End;
          AreaSortTypeRef=^AreaSortType;
          AreaSortType=Record
                 Nome:String[80];
                 N:Integer;
                 Next:AreaSortTypeRef
              End;


Var S:SearchRec;
    F,F1:File Of AreaFileType;
    F2:File of AreaFileIdxType;
    AreaFile:AreaFileType;
    AreaFileIdx:AreaFileIdxType;
    LastArea:Integer;
    TempStr,TempStr1,TempStr2:String;
    StartPath:PathStr;
    NewAreas:Integer;
    D:DirStr;
    QuietMode : Boolean;
    FirstArea : Boolean;
    PutVolLabel:Boolean;
    MakePurge, DelDupes, HideArea, Renumber: Boolean;
    MakeSort:(SortNo,Sortname,SortDown);

    I,J:integer;
    Lev,LevDown,LevUp,Attr:Byte;
    {$IFDEF VIRTUALPASCAL}
    Code: Longint;
    {$ELSE}
    Code:Word;
    {$ENDIF}
    NewNumeroOpzione:byte;
    DirFbbs,DirCreatedFbbs:String;
    UploadStr:String;
    Vari:Text;
    F3:File;
    Registrato:Boolean;
    CreateFbbs:Boolean;
    NewFlag:String;
    CdRom:Byte;
    LastError:Word;
    FirstPath:PathListPtr;
    Dupes, Hidden, Purged: Integer;
    AreaSortList:AreaSortTypeRef;
    VolLabel:String[11];
    Gruppo:Integer;

    LoraPath: string;

    d0: dirstr; n: namestr; e: extstr;

    TicPath: PathStr;

{$IFDEF VIRTUALPASCAL}
Procedure Rename(Var F; NewName: String);
begin
   Newname := NewName + #0;
   InOutRes := DosMove(@FileRec(F).Name, @Newname[1]);
end;

Procedure Move(Var Source; Var Dest; Count:Word);
type buffertype=array[0..0] of byte;
var I: word;
begin
   for i := 0 to count-1 do
   begin
      {$R-}
      buffertype(dest)[i] := buffertype(source)[i];
      {$R+}
   end;
end;
{$ENDIF}

Function StrLev2Lev(S:String):Byte;
Const
   StrLev:Array[1..12] of String[10]=(
         'TWIT','DISGRACE','LIMITED','NORMAL','WORTHY','PRIVEL',
         'FLAVORED','EXTRA','CLERK','ASSTSYSOP','SYSOP','HIDDEN');
Var I:Integer;
    {$IFDEF VIRTUALPASCAL}
    Code: longint;
    {$ELSE}
    Code:Word;
    {$ENDIF}
begin
   val(S,I,Code);
   if Code=0 then
   begin
      if (I>=16) and (I<=192) and (I mod 16=0) then
         StrLev2Lev := I
      else
         StrLev2Lev := 0
   end else
   begin
      for I:=1 to length(S) do
        S[I] := UpCase(S[I]);
      I := 12;
      while (I>0) and (pos(S,StrLev[I])<>1) do
         dec(I);
      StrLev2Lev := I * 16
   end;
end {StrLev2Lev};


procedure ProcessCfg;
var cfg: text;
    tmpstr, keyword: string;
    i: word;
    temp: word;
begin
   assign(cfg,d0 + 'scan_cd.cfg');
   {$I-}
   reset(cfg);
   {$I+}
   if (ioresult=0) then
   begin
      while not eof(cfg) do
      begin
         readln(cfg, tmpstr);
         I := 1;
         while (i<=length(TmpStr)) and (tmpstr[i]<>' ') do
         begin
            tmpstr[i] := upcase(TmpStr[i]);
            inc(i);
         end;
         keyword := copy(tmpstr,1,i-1);
         delete(Tmpstr,1,i);
         while (TmpStr<>'') and (TmpStr[1]=' ') do
            delete(TmpStr,1,1);
         if keyword='LEV' then
         begin
            temp := strlev2lev(TmpStr);
            if temp>0 then
               lev := temp;
         end else
         if keyword='LEVUP' then
         begin
            temp := strlev2lev(TmpStr);
            if temp>0 then
               levdown := temp;
         end else
         if keyword='LEVDOWN' then
         begin
            temp := strlev2lev(TmpStr);
            if temp>0 then
               levup := temp;
         end else
         if keyword='FLAG' then
         begin
            NewFlag := TmpStr;
            for J:=1 to length(NewFlag) do
            case UpCase(NewFlag[J]) of
               'F':Attr := Attr or 1;
               'G':Attr := Attr or 128;
               'S':Attr := Attr or 32;
               'D':Attr := Attr or 64;
               'N':Attr := Attr or 2;
               'K':Attr := Attr or 4;
               'P':Attr := Attr or 8;
               'C':CdRom := 1;
            end;
         end else
         if keyword='UPLOAD' then
         begin
            UploadStr := TmpStr;
         end;
      end;
      close(cfg);
   end;
end;



Function AddPath(Var Pnt:PathListPtr; Path:String):Boolean;
var Temp:Boolean;
    Pnt1 : ^PathListPtr;
begin
   Temp := False;
   Pnt1 := Addr(Pnt);
   while not Temp and (Pnt1^<>Nil) do
   begin
      Temp := path = Pnt1^^.Path;
      if not Temp then
         Pnt1 := addr(Pnt1^^.Next)
   end;
   if Not Temp then
   begin
      New(Pnt1^);
      Pnt1^^.Path := Path;
      Pnt1^^.Next := Nil
   end;
   AddPath := Temp
end {AddPath};

Procedure CopyFile(PathSource:String; var PathDest:String; Numero:Integer);
Const
    SizeBuf=16384;
Var
    Source,Dest:File;
    Buf:Pointer;
    {$IFDEF VIRTUALPASCAL}
    result: longint;
    {$ELSE}
    result:word;
    {$ENDIF}

begin
   getmem(buf,SizeBuf);

   str(Numero,PathDest);
   while length(pathDest)>3 do
      delete(PathDest,1,1);

   PathDest := DirFbbs + 'FILES.' + PathDest;

   assign(Source,PathSource);
   reset(Source,1);
   if PathDest[1]='\' then
      assign(Dest,D[1]+D[2]+PathDest)
   else
   if PathDest[2]<>':' then
      assign(Dest,D+'\'+PathDest)
   else
      assign(dest,PathDest);
   rewrite(Dest,1);
   while not eof(Source) do
   begin
      blockread(Source,Buf^,SizeBuf,Result);
      blockwrite(Dest,Buf^,Result);
   end;
   close(Source);
   close(Dest);
   freemem(buf,SizeBuf);
end {CopyFile};



Procedure MakeFBbs(var PathDest:String; Numero:Integer);
Var S:SearchRec;
    Dest:Text;
begin

   findfirst('*.*',Archive+ReadOnly,S);
   if DosError=0 then
   begin
      str(Numero,PathDest);
      while length(pathDest)>3 do
         delete(PathDest,1,1);

      PathDest := DirCreatedFbbs + '\FILES.' + PathDest;

      if PathDest[1]='\' then
         assign(Dest,D[1]+D[2]+PathDest)
      else
      if PathDest[2]<>':' then
         assign(Dest,D+'\'+PathDest)
      else
         assign(dest,PathDest);
      rewrite(Dest);

      while DosError=0 do
      begin
         writeln(Dest,S.Name);
         findnext(S);
      end;
      close(dest);
   end else
      PathDest := '';

end {MakeFbbs};



Procedure Append(Var S:SearchRec; Var NamePtr:MyRecPtr);
Var Temp:MyRecPtr;
begin
   {Inserisce nella lista in ordine alfabetico}
   if NamePtr=Nil then
   begin
      new(NamePtr);
      NamePtr^.Name := S.Name;
      NamePtr^.Next := Nil;
   end else
   if S.Name>NamePtr^.Name then
   begin
      append(S,NamePtr^.Next)
   end else
   begin
      {insert}
      New(Temp);
      Temp^ := NamePtr^;
      NamePtr^.Next := Temp;
      NamePtr^.Name := S.Name;
   end;
end {Append};

Procedure Remove(Var NamePtr:MyRecPtr);
begin
   if NamePtr<>Nil then
   begin
      Remove(NamePtr^.Next);
      Dispose(NamePtr);
   end;
end {Remove};


Procedure FindArea(NomeIndice:String);
var First,Temp:MyRecPtr;
    D:String;
    Created:Boolean;
    I:Integer;
begin
   GetDir(0,D);
   if not AddPath(FirstPath,D+'\') then
   begin
      FindFirst(LookStr,Archive+ReadOnly,S);
      if DosError=0 then
      begin
         {$IFDEF VIRTUALPASCAL}
         findclose(S);
         {$ENDIF}
         Created := False;
         TempStr2 := S.Name;
      end else
      if CreateFbbs then
      begin
         Created := True;
         MakeFbbs(TempStr2,LastArea+1);
      end else
         TempStr2 := '';
      if (TempStr2<>'') and (length(D)<=38) and
         (Created or (DirFBbs<>'') or (TempStr2='FILES.BBS') or
          (length(D)+length(TempStr2)<=48)) then
      begin

         fillchar(AreaFile,SizeOf(AreaFile),#0);
         inc(LastArea);
         AreaFile.Numero := LastArea;
         AreaFile.Gruppo := Gruppo;
         TempStr := D + '\' + #0;
         Move(TempStr[1],AreaFile.PathDown,length(TempStr));
         TempStr := Copy(D,4,length(D)-3)+ #0;
         if VolLabel<>'' then
            TempStr := VolLabel + ' ' + TempStr;
         I := 2;
         while I <= length(TempStr) do
         begin
            if TempStr[I] = '\' then
            begin
               TempStr[I] := ' ';
               inc(i)
            end else
            if (TempStr[I]=' ') or (TempStr[I]='_') or (TempStr[I]='-') then
            begin
               inc(i)
            end else
            begin
               if TempStr[i] in ['A'..'Z'] then
                  TempStr[I] := chr(byte(TempStr[i]) + 32);
            end;
            inc(i);
         end;
         Move(TempStr[1],AreaFile.Nome,length(TempStr));
         AreaFile.Lev := Lev;
         AreaFile.LevUp := LevUp;
         AreaFile.LevDown := LevDown;
         AreaFile.Attr := Attr;
         AreaFile.CdRom := CdRom;
         if created then
         begin
            str(AreaFile.Numero,TempStr1);
            while length(TempStr1)>3 do
               delete(TempStr1,1,1);
            TempStr1 := DirCreatedFbbs + '\FILES.' + TempStr1 + #0;
            Move(TempStr1[1],AreaFile.PathFbbs,length(TempStr1));
         end else
         if DirFbbs<>'' then
         begin
            TempStr1[0] := #40;
            Move(AreaFile.PathDown,TempStr1[1],40);
            TempStr1[0] := chr(Pos(#0,TempStr1)-1);
            CopyFile(TempStr1+TempStr2,TempStr1,AreaFile.Numero);
            TempStr1 := TempStr1 + #0;
            Move(TempStr1[1],AreaFile.PathFbbs,length(TempStr1));
         end else
         if (TempStr2<>'FILES.BBS') then
         begin
            TempStr1[0] := #40;
            Move(AreaFile.PathDown,TempStr1[1],40);
            TempStr1[0] := chr(Pos(#0,TempStr1)-1);
            TempStr1 := TempStr1 + TempStr2 + #0;
            Move(TempStr1[1],AreaFile.PathFbbs,length(TempStr1));
         end;
         if UploadStr<>'' then
         begin
            move(UploadStr[1],AreaFile.PathUp,length(UploadStr));
         end;
         {Prova a cercare la descrizione dell'area nel Descript.Ion}
         Assign(Vari,'..\Descript.Ion');
         {$I-}
         reset(Vari);
         {$I+}
         if (IOResult=0) then
         begin
            while not eof(vari) do
            begin
               readln(Vari,TempStr1);
               I := 1;
               while (I<=length(TempStr1)) and (TempStr1[I]<>' ') do
               begin
                  TempStr1[I] := UpCase(TempStr1[I]);
                  inc(I)
               end;
               if pos(NomeIndice+' ',TempStr1)=1 then
               begin
                  delete(TempStr1,1,length(NomeIndice)+1);
                  while (TempStr1<>'') and (TempStr1[1]=' ') do
                     delete(TempStr1,1,1);
                  if TempStr1<>'' then
                  begin
                     if length(TEmpStr1)>79 then
                        TempStr1[0] := #79;
                     TempStr1 := TempStr1 + #0;
                     TempStr := TempStr1;
                     Move(TempStr1[1],AreaFile.Nome,length(TempStr1));
                  end;
               end;
            end;
            close(Vari);
         end;
         Write(F1,AreaFile);

         AreaFileIdx.Lev := AreaFile.Lev;
         AreaFileIdx.FlagLev := AreaFile.FlagLev;
         Move(AreaFile.Short_Name,AreaFileIdx.ShortName,13);
         AreaFileIdx.Numero := AreaFile.Numero;
         AreaFileIdx.Gruppo := AreaFile.Gruppo;
         write(F2,AreaFileIdx);

         If not QuietMode then
         begin
            if Not FirstArea then
            begin
               writeln(#13'   ц');
            end else FirstArea := False;
            Write('   юд',LastArea:4,' - ',Copy(TempStr,1,Length(TempStr)-1));
         end;

         inc(NewAreas);
      end
   end;

   First := Nil;
   FindFirst('*.*',Directory,S);
   while DosError=0 do
   begin
      if (S.Name<>'.') and (S.Name<>'..') and (S.Attr And Directory <> 0) then
         append(S,First);
      findnext(S);
   end;
   Temp := First;
   while Temp<>Nil do
   begin
      chdir(Temp^.Name);
      FindArea(Temp^.Name);
      ChDir('..');
      Temp := Temp^.Next
   end;
   remove(First);
end {FindArea};


Procedure ProcessTicPath;
var First,Temp:MyRecPtr;
    D:String;
    Created:Boolean;
    I:Integer;
    tic: text;
    TmpStr: String;
    PathDown, tag: string;
begin
   assign(tic, ticpath);
   {$I-}
   reset(tic);
   {$I+}
   if ioresult=0 then
   begin
      firstarea := true;
      Writeln(' * Creating new areas from ',ticpath);
      while not eof(tic) do
      begin
         readln(Tic, TmpStr);
         for I := 1 to length(TmpStr) do
            TmpStr[i] := Upcase(TmpStr[i]);
         if pos('AREA ',tmpStr)=1 then
         begin
            delete(TmpStr,1,5);
            while (TmpStr<>'') and (TmpStr[1]=' ') do
               delete(TmpStr,1,1);
            I := pos(' ',TmpStr);
            if I=0 then
            begin
               PathDown := TmpStr;
               TmpStr := '';
               Tag := '';
            end else
            begin
               PathDown := Copy(TmpStr,1,I-1);
               delete(TmpStr,1,I);
               while (TmpStr<>'') and (TmpStr[1]=' ') do
                  delete(TmpStr,1,1);
               I := pos(' ',TmpStr);
               if I=0 then
                  tag := tmpStr
               else
                  tag := copy(TmpStr,1,i-1)
            end;
            if pathdown[length(PathDown)]<>'\' then
               pathDown := PathDown + '\';
            if not AddPath(FirstPath,PathDown) then
            begin
               fillchar(AreaFile,SizeOf(AreaFile),#0);
               inc(LastArea);
               AreaFile.Numero := LastArea;
               AreaFile.Gruppo := Gruppo;
               TempStr := PathDown + #0;
               Move(TempStr[1],AreaFile.PathDown,length(TempStr));
               TempStr := Copy(PathDown,4,length(PathDown)-3)+ #0;
               if VolLabel<>'' then
                  TempStr := VolLabel + ' ' + TempStr;
               I := 2;
               while I <= length(TempStr) do
               begin
                  if TempStr[I] = '\' then
                  begin
                     TempStr[I] := ' ';
                     inc(i)
                  end else
                  if (TempStr[I]=' ') or (TempStr[I]='_') or (TempStr[I]='-') then
                  begin
                     inc(i)
                  end else
                  begin
                     if TempStr[i] in ['A'..'Z'] then
                        TempStr[I] := chr(byte(TempStr[i]) + 32);
                  end;
                  inc(i);
               end;
               Move(TempStr[1],AreaFile.Nome,length(TempStr));
               Move(Tag[1],AreaFile.tic_tag,length(tag));
               AreaFile.Lev := Lev;
               AreaFile.LevUp := LevUp;
               AreaFile.LevDown := LevDown;
               AreaFile.Attr := Attr;
               AreaFile.CdRom := CdRom;
               if UploadStr<>'' then
               begin
                  move(UploadStr[1],AreaFile.PathUp,length(UploadStr));
               end;
               Write(F1,AreaFile);

               AreaFileIdx.Lev := AreaFile.Lev;
               AreaFileIdx.FlagLev := AreaFile.FlagLev;
               Move(AreaFile.Short_Name,AreaFileIdx.ShortName,13);
               AreaFileIdx.Numero := AreaFile.Numero;
               AreaFileIdx.Gruppo := AreaFile.Gruppo;
               write(F2,AreaFileIdx);

               If not QuietMode then
               begin
                  if Not FirstArea then
                  begin
                     writeln(#13'   ц');
                  end else FirstArea := False;
                  Write('   юд',LastArea:4,' - ',Copy(TempStr,1,Length(TempStr)-1));
               end;

               inc(NewAreas);
            end;
         end;
      end;
      if newareas>0 then
         writeln;
      close(Tic);
   end;
end;





procedure Istruzioni;
begin
   Writeln('Usage   : SCAN_CD [Path] [commands] [-Q]');
   Writeln;
   Writeln('Commands are : LEV <n>         - Access level of new areas');
   Writeln('               LEVDOWN <n>     - Download level of new areas');
   Writeln('               LEVUP <n>       - Upload level of new areas');
   Writeln('               GROUP <n>       - Group of new areas');
   Writeln('               FLAG <FGSDNKPC> - Attribute of new areas');
   Writeln('               F<n>            - Option on number of new areas');
   Writeln('               COPYFBBS <dir>  - Dir where copy Files.Bbs');
   Writeln('               CREATEFBBS <dir> - Dir where create Files.Bbs if not found');
   Writeln('               UPLOAD <dir>    - Upload dir of new areas');
   Writeln('               LOOK <file>     - Name of index file');
   Writeln('               LABEL           - Add disk label to area name');
   Writeln('               PURGE           - Delete invalid areas');
   Writeln('               HIDE            - Hide invalid areas');
   Writeln('               DUPES           - Delete dupes areas');
   Writeln('               RENUMBER        - Adjust area numbers');
   Writeln('               SORT:<N|D>      - Sort file areas by name or download path');
   Writeln('               TIC <ticfile>   - Import areas from standard Tic.Cfg');
   Writeln('                                 TIC can be specified instead of [Path]');
   Writeln('               -Q              - Quiet mode');
   Writeln;
   Writeln('Please refer to the documentation for a more complete command summary');
   Writeln;
   halt(1);
end {Istruzioni};



Function ValidPath(D:String):Boolean;
Var D0: DirStr;
begin
   getdir(0,D0);
   if D[length(D)]='\' then
      dec(D[0]);
   {$I-}
   chdir(D);
   {$I+}
   validpath := ioresult=0;
   chdir(d0);
end {ValidPath};


Procedure PutInLista(var Pnt:AreaSortTypeRef; Name:String; N:Integer);
Var Pnt1:^AreaSortTypeRef;
    Pnt2:AreaSortTypeRef;
begin
   Pnt1 := Addr(Pnt);
   while (Pnt1^<>Nil) and (Pnt1^^.Nome<=Name) do
   begin
      Pnt1 := Addr(Pnt1^^.Next)
   end;
   if Pnt1^=Nil then
   begin
      new(Pnt1^);
      Pnt1^^.Nome := Name;
      Pnt1^^.N := N;
      Pnt1^^.Next := Nil;
   end else
   begin
      New(Pnt2);
      Pnt2^ := Pnt1^^;
      Pnt1^^.Next := Pnt2;
      Pnt1^^.Nome := Name;
      Pnt1^^.N := N;
   end;
end {PutInLista};


Function GetVolLabel:String;
var s:searchrec;
    i:byte;
begin
   if PutVolLabel then
   begin
      findfirst('*.*',VolumeId,S);
      if DosError=0 then
      begin
         {$IFDEF VIRTUALPASCAL}
         findclose(S);
         {$ENDIF}
         i := pos('.',S.Name);
         if I>0 then
            delete(S.Name,i,1);
         GetVolLabel := S.Name
      end else
         GetVolLabel := '';
   end else
      GetVolLabel := '';
end {GetVolLabel};

begin

   {$IFDEF VIRTUALPASCAL}
   Versione := Versione + '-OS2';
   {$ELSE}
   Versione := Versione + '-DOS';
   {$ENDIF}

   {CopyRight}
   Writeln;
   Writeln('SCAN_CD; LoraBBS Scan-Disk utility, Version ',Versione);
   Writeln('         Copyright (C) 1996 by Alessandro Trebbi, All Rights Reserved');
   Writeln;


   if ParamCount=0 then
   begin
      Istruzioni;
   end else
   begin
      getdir(0,D);

      fsplit(fexpand(paramstr(0)),d0,n,e);
      if d0[length(d0)]<>'\' then
         d0 := d0 + '\';

      lorapath := getenv('LORA');
      if lorapath='' then
      begin
         writeln(' * undefined env var LORA');
         halt(1);
      end;
      if lorapath[length(lorapath)]<>'\' then
         lorapath := lorapath + '\';
      if not validpath(lorapath) then
      begin
         writeln(' * invalid env var LORA');
         halt(1);
      end;

      TicPath := '';

      StartPath := ParamStr(1);
      for I:=1 to length(StartPath) do
         StartPath[I] := UpCase(StartPath[I]);

      if startPath='TIC' then
      begin
         startpath := '';
         if paramcount>=2 then
            ticpath := paramstr(2)
         else
            istruzioni;
      end else
      begin
         if StartPath='.' then
            StartPath := D;

         if StartPath='..' then
         begin
            chdir('..');
            if DosError=0 then
               getdir(0,StartPath)
            else
               StartPath:='';
            chdir(D);
         end;

         if StartPath[1]='\' then
            StartPath := D[1] + D[2] + StartPath
         else

         if (length(StartPath)>=2) and (StartPath[2]<>':') then
            StartPath := D+ '\' + StartPath;

         if StartPath[length(StartPath)]='\' then
            delete(StartPath,length(StartPath),1);

         {$I-}
         chdir(StartPath);
         {$I+}

         if IOResult<>0 then
         begin
            StartPath := '';
         end;

         chdir(D);

      end;

      CdRom := 0;
      QuietMode := False;
      FirstArea := True;
      Lev := 176;
      LevDown := 176;
      LevUp := 176;
      Attr := 0;
      NewNumeroOpzione:=0;
      DirFbbs := '';
      UploadStr:= '';
      CreateFbbs := False;
      DirCreatedFBbs := '';
      MakePurge := False;
      DelDupes := False;
      Renumber := False;
      HideArea := False;
      Hidden := 0;
      Purged := 0;
      Dupes := 0;
      MakeSort := SortNo;
      PutVolLabel := False;
      Gruppo := 0;

      ProcessCfg;

      I := 2;
      if TicPath <>''  then
         inc(i);

      while I<=ParamCount do
      begin
         TempStr := ParamStr(I);
         for J:=1 to length(TempStr) do
            TempStr[J] := UpCase(tempStr[J]);
         if TempStr='-Q' then
            QuietMode := True
         else
         if TempStr='LEV' then
         begin
            if I<paramcount then
            begin
               inc(I);
               lev := StrLev2Lev(ParamStr(I));
               if lev=0 then
                  istruzioni
            end else
               istruzioni
         end else
         if TempStr='LEVDOWN' then
         begin
            if I<paramcount then
            begin
               inc(I);
               levdown := StrLev2Lev(ParamStr(I));
               if levdown=0 then
                  istruzioni
            end else
               istruzioni
         end else
         if TempStr='LEVUP' then
         begin
            if I<paramcount then
            begin
               inc(I);
               levup := StrLev2Lev(ParamStr(I));
               if levup=0 then
                  istruzioni
            end else
               istruzioni
         end else
         if TempStr='GROUP' then
         begin
            if I<paramcount then
            begin
               inc(I);
               val(ParamStr(I),Gruppo,Code);
               if (Code<>0) or (Gruppo<0) or (Gruppo>255) then
                  Istruzioni;
            end else
               istruzioni
         end else
         if TempStr='COPYFBBS' then
         begin
            if I<paramcount then
            begin
               inc(I);
               DirFbbs := paramstr(I);
            end else
               istruzioni
         end else
         if TempStr='UPLOAD' then
         begin
            if I<paramcount then
            begin
               inc(I);
               UploadStr := paramstr(I);
            end else
               istruzioni
         end else
         if TempStr='CREATEFBBS' then
         begin
            if I<paramcount then
            begin
               inc(I);
               DirCreatedFbbs := paramstr(I);
               CreateFbbs := True;
            end else
               istruzioni
         end else
         if TempStr='TIC' then
         begin
            if I<paramcount then
            begin
               inc(I);
               TicPath := paramstr(I);
            end else
            istruzioni
         end else
         if TempStr='LOOK' then
         begin
            if I<paramcount then
            begin
               inc(I);
               LookStr := paramstr(I);
            end else
            istruzioni
         end else
         if TempStr='F0' then
            NewNumeroOpzione := 1
         else
         if TempStr='F1' then
            NewNumeroOpzione := 2
         else
         if TempStr='F00' then
            NewNumeroOpzione := 3
         else
         if TempStr='F01' then
            NewNumeroOpzione := 4
         else
         if TempStr = 'PURGE' then
         begin
            MakePurge := True
         end else
         if TempStr = 'RENUMBER' then
         begin
            Renumber := True
         end else
         if TempStr = 'HIDE' then
         begin
            HideArea := True
         end else
         if TempStr = 'DUPES' then
         begin
            DelDupes := True
         end else
         if TempStr = 'LABEL' then
         begin
            PutVolLabel := True
         end else
         if TempStr = 'SORT:N' then
         begin
            MakeSort := SortName
         end else
         if TempStr = 'SORT:D' then
         begin
            MakeSort := SortDown
         end else
         if TempStr='FLAG' then
         begin
            if I<paramcount then
            begin
               inc(I);
               NewFlag := Paramstr(I);
               for J:=1 to length(NewFlag) do
               case UpCase(NewFlag[J]) of
                  'F':Attr := Attr or 1;
                  'G':Attr := Attr or 128;
                  'S':Attr := Attr or 32;
                  'D':Attr := Attr or 64;
                  'N':Attr := Attr or 2;
                  'K':Attr := Attr or 4;
                  'P':Attr := Attr or 8;
                  'C':CdRom := 1;
                 else
                  Istruzioni
               end;
            end else
               istruzioni
         end else
            istruzioni;
         inc(I);
      end;

      if MakePurge then
         HideArea := False;

      {Check DirFbbs}
      if DirFbbs<>'' then
      begin
         if DirFbbs[Length(DirFbbs)]<>'\' then
            DirFbbs := DirFbbs + '\';
         if validpath(dirfbbs) then
         begin
            if length(DirFBbs)>30 then
            begin
               writeln(' * Too long COPYFBBS (',DirFBbs,')');
               halt(1);
            end;
         end else
         begin
            writeln(' * Invalid COPYFBBS (',DirFbbs,')');
            halt(1);
         end;
      end;

      {Check DirCreatedFbbs}
      if DirCreatedFbbs<>'' then
      begin
         if DirCreatedFbbs[Length(DirCreatedFbbs)]<>'\' then
            DirCreatedFbbs := DirCreatedFbbs + '\';
         if validpath(dircreatedfbbs) then
         begin
            if length(DirCreatedFBbs)>30 then
            begin
               writeln(' * Too long CREATEFBBS (',DirCreatedFBbs,')');
               halt(1);
            end;
         end else
         begin
            writeln(' * Invalid CREATEFBBS (',DirCreatedFbbs,')');
            halt(1);
         end;
      end;

      {Check UploadStr}
      if UploadStr<>'' then
      begin
         if UploadStr[Length(UploadStr)]<>'\' then
            UploadStr := UploadStr + '\';
         if validpath(uploadstr) then
         begin
            if length(UploadStr)>=40 then
            begin
               writeln(' * Too long UPLOAD (',UploadStr,')');
               halt(1);
            end;
            UploadStr := UploadStr + #0;
         end else
         begin
            writeln(' * Invalid UPLOAD (',UploadStr,')');
            halt(1);
         end;
      end;

      {Check LookStr}
      for J:=1 to length(LookStr) do
         LookStr[J] := upcase(LookStr[J]);
      if (pos('\',LookStr)>0) then
      begin
         writeln('Invalid LOOK (',LookStr,')');
         halt(1);
      end;

      FirstPath := Nil;

      {Cancella vecchi Files di Back-Up}
      assign(F1,lorapath+'SysFile._Id');
      {$I-}
      erase(F1);
      {$I+}
      if ioresult<>0 then;

      assign(F1,lorapath+'SysFile._Da');
      {$I-}
      erase(F1);
      {$I+}
      if ioresult<>0 then;

      {rinomina i precedenti files come files di backup}
      assign(F1,lorapath+'SysFile.Idx');
      {$I-}
      rename(F1,lorapath+'SysFile._Id');
      {$I+}
      if ioresult<>0 then;

      assign(F1,lorapath+'SysFile.Dat');
      {$I-}
      rename(F1,lorapath+'SysFile._Da');
      {$I+}
      if ioresult<>0 then;

      LastArea := 0;

      assign(F2,lorapath+'SysFile.Idx');
      rewrite(F2);

      assign(F1,lorapath+'SysFile.Dat');
      rewrite(F1);

      assign(F,lorapath+'SysFile._Da');
      {$I-}
      reset(F);
      {$I+}

      if ioresult=0 then
      begin
         Writeln(' * Creating back-up files...');
         NewAreas := 0;
         FirstArea := True;
         while not eof(f) do
         begin
            read(F,AreaFile);
            if Renumber then
               AreaFile.Numero := LastArea + 1;
            Move(AreaFile.PathDown,TempStr[1],SizeOf(AreaFile.PathDown));
            TempStr[0] := #0;
            while TempStr[length(TempStr)+1]<>#0 do
            begin
               inc(TempStr[0]);
               TempStr[length(TempStr)] := UpCase(TempStr[length(TempStr)]);
            end;

            If not QuietMode then
            begin
               if Not FirstArea then
               begin
                  writeln(#13'   ц');
               end else FirstArea := False;
               Move(AreaFile.Nome,TempStr1[1],SizeOf(AreaFile.Nome));
               TempStr1[0] := #0;
               while TempStr1[length(TempStr1)+1]<>#0 do
               begin
                  inc(TempStr1[0]);
               end;
               Write('   юд',AreaFile.Numero:4,' - ',TempStr1,'':52-length(TempStr1));
            end;

            if MakePurge and DelDupes and AddPath(FirstPath,TempStr) then
            begin
               {Area duplicata non aggiunta}
               if not quietMode then
                  write('Purge');
               inc(Purged);
            end else
            if MakePurge and not Validpath(TempStr) then
            begin
               {Area inesistente non aggiunta}
               if not quietMode then
                  write('Purge');
               inc(Purged);
            end else
            begin
               {OK, aggiunge l'area}
               if HideArea and DelDupes and AddPath(FirstPath,TempStr) then
               begin
                  AreaFile.Lev := 192;
                  if not quietmode then
                     write('Hide');
                  inc(Hidden);
               end else
               if HideArea and not ValidPath(TempStr) then
               begin
                  AreaFile.Lev := 192;
                  if not quietMode then
                     write('Hide');
                  inc(Hidden);
               end else
               begin
                  if HideArea and (AreaFile.Lev=192) then
                     AreaFile.Lev := Lev;
                  if AreaFile.Lev=192 then
                  begin
                     if not quietmode then
                        write('Hide');
                     inc(Hidden);
                  end else
                  begin
                     if not quietmode then
                        write('Ok');
                     inc(NewAreas);
                  end
               end;
               if AddPath(FirstPath,TempStr) then;
               write(F1,AreaFile);
               AreaFileIdx.Lev := AreaFile.Lev;
               AreaFileIdx.FlagLev := AreaFile.FlagLev;
               Move(AreaFile.Short_Name,AreaFileIdx.ShortName,13);
               AreaFileIdx.Numero := AreaFile.Numero;
               AreaFileIdx.Gruppo := AreaFile.Gruppo;
               write(F2,AreaFileIdx);
               LastArea := AreaFile.Numero;
            end;

         end;

         close(F);
         if not quietmode then
            Writeln;

         if Purged>0 then
            Writeln(' * Purged ',Purged,' Areas.');
         if Dupes>0 then
            Writeln(' * Deleted ',Dupes,' dupes Areas.');
         if Hidden>0 then
            Writeln(' * Hidden ',Hidden,' Areas.');
         Writeln(' * Total of ',NewAreas,' Areas.');

      end else
         LastArea := 0;

      if NewNumeroOpzione>0 then
      begin
         inc(LastArea);
         if (NewNumeroOpzione<=2) then
         begin
            inc(LastArea,9);
            LastArea := LastArea div 10 * 10;
         end else
         begin
            inc(lastarea,99);
            LastArea := LastArea div 100 * 100;
         end;
         if NewNumeroOpzione mod 2 = 0 then
         begin
            inc(LastArea);
         end;
         dec(LastArea);
      end;

      newareas := 0;

      if ticpath<>'' then
      begin
         ProcessTicPath;
      end;

      if startpath<>'' then
      begin
         GetDir(0,D);
         chdir(StartPath);

         VolLabel := GetVolLabel;

         if StartPath[length(StartPath)]=':' then
            chdir('\');

         FirstArea := True;

         Writeln(' * Creating new areas from ',StartPath);

         getDir(0,TempStr);
         I := pos(':',TempStr);
         if I>0 then
            delete(TempStr,1,I);
         I := Pos('\',TempStr);
         while I>0 do
         begin
            delete(TempStr,1,I);
            I := Pos('\',TempStr);
         end;

         FindArea(TempStr);

         chdir(D);

         if Not QuietMode and (NewAreas>0) then
            writeln;
         writeln(' * Total of ',NewAreas,' new Areas.');

      end;

      close(F2); {file di indice completato}

      if MakeSort<>SortNo then
      begin
         AreaSortList := Nil;
         Writeln(' * Sorting Areas by name');
         seek(F1,0);
         {legge tutti i nomi}
         LastArea := -1;
         while not eof(F1) do
         begin
            inc(LastArea);
            read(F1,AreaFile);
            if MakeSort=SortName then
               Move(AreaFile.Nome,TempStr[1],SizeOf(AreaFile.Nome))
             else
               Move(AreaFile.PathDown,TempStr[1],SizeOf(AreaFile.PathDown));
            TempStr[0] := #0;
            while TempStr[length(TempStr)+1]<>#0 do
               inc(TempStr[0]);
            for I:=1 to length(TempStr) do
               TempStr[I] := UpCase(TempStr[I]);
            PutInLista(AreaSortList,TempStr,LastArea);
         end;
         close(F1);
         {controlla se esiste un file con il nome del filetemporaneo}
         assign(F1,lorapath+'_LLST_.TMP');
         {$I-}
         erase(F1);
         {$I+}
         if ioresult<>0 then;

         {mette in un file temporaneo}
         assign(F1,lorapath+'SysFile.Dat');
         rename(F1,lorapath+'_LLST_.Tmp');

         assign(F,lorapath+'_LLST_.Tmp');
         reset(F);
         assign(F1,lorapath+'SysFile.dat');
         rewrite(F1);
         assign(F2,lorapath+'SysFile.Idx');
         rewrite(F2);

         FirstArea := True;
         LastArea := 0;
         while AreaSortList<>Nil do
         begin
            inc(LastArea);
            seek(f,AreaSortList^.N);
            read(F,AreaFile);
            AreaFile.Numero := LastArea;
            write(F1,AreaFile);
            If not QuietMode then
            begin
               if Not FirstArea then
               begin
                  writeln(#13'   ц');
               end else FirstArea := False;
               Move(AreaFile.Nome,TempStr[1],SizeOf(AreaFile.Nome));
               TempStr[0] := #0;
               while TempStr[length(TempStr)+1]<>#0 do
                  inc(TempStr[0]);
               Write('   юд',AreaFile.Numero:4,' - ',TempStr,'':52-length(TempStr));
            end;
            AreaFileIdx.Lev := AreaFile.Lev;
            Move(AreaFile.Short_Name,AreaFileIdx.ShortName,13);
            AreaFileIdx.Numero := AreaFile.Numero;
            AreaFileIdx.Gruppo := AreaFile.Gruppo;
            AreaFileIdx.FlagLev := AreaFile.FlagLev;
            write(F2,AreaFileIdx);
            AreaSortList := AreaSortList^.Next
         end;
         if not quietmode then
            writeln;
         close(F1);
         close(F2);
         close(F);
         {$I-}
         erase(F);
         {$I+}
         if ioresult<>0 then;
         writeln(' * Total of ',LastArea,' Areas.');
      end;
   end;
end.
