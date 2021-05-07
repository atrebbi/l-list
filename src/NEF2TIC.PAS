{
; formato del TicArea.Cfg

FileArea area1 d:\file\area1 O #2:332/500 I2:332/596 C555
FileArea AREA2 d:\file\area2 O S2:332/504.1 10:10/0 *100/1
FileArea Area3 d:\file\area3 I O2:5/1 3/1 332/504.2 .3

; a couple of typical areas

FileArea area4 d:\file\area4 O I2:332/1 501 502 503 504.1 .2 .3 .4 .5 505 506
FileArea AREA5 d:\file\area5 O I2:332/1 504.1 .2 .3 .4 333/100 1:2/3
}

Uses
    MkGlobT, MkString;

Var TICAREA, TIC: Text;
    TicAreaLine: String;
    PrevAddr, Addr: AddrType;

    I : Integer;
    Tag, Flag, Download, LocalFlag: String;

    TempStr: String;

Begin
   assign(TicArea, 'TicArea.Cfg');
   {$I-}
   reset(TicArea);
   {$I+}
   if IOResult=0 then
   begin
      Assign(Tic, 'Tic.Cfg');
      {$I-}
      Rewrite(Tic);
      {$I+}
      if IOResult=0 then
      begin
         while not eof(TicArea) do
         begin
            ReadLn(TicArea, TicAreaLine);
            I := pos(';', TicAreaLine);
            if I>0 then
               TicAreaLine[0] := chr(i-1);
            TicAreaLine := Upper(StripBoth(TicAreaLine,' '));
            if pos('FILEAREA ',TicAreaLine)=1 then
            begin
               {definizione area TIC}
               Delete(TicAreaLine,1,9);
               TicAreaLine := StripLead(TicAreaLine, ' ');
               {segue il nome dell'area}
               I := pos(' ',TicAreaLine);
               Tag := Copy(TicAreaLine, 1, I-1);
               delete(TicAreaLine, 1, I);
               TicAreaLine := StripLead(TicAreaLine, ' ');
               {download path}
               I := pos(' ',TicAreaLine);
               Download := Copy(TicAreaLine, 1, I-1);
               AddBackSlash(Download);
               delete(TicAreaLine, 1, I);
               TicAreaLine := StripLead(TicAreaLine, ' ');
               {flag}
               I := pos(' ',TicAreaLine);
               Flag := Copy(TicAreaLine, 1, I-1);
               if Flag='O' then
                  Flag := ''
               else if Flag='I' then
                  Flag := '*&'
               else if flag='*' then
                  Flag := '*';
               delete(TicAreaLine, 1, I);
               TicAreaLine := StripLead(TicAreaLine, ' ');
               {intanto scrive la prima parte dell'area, segue quindi la}
               {lista dei nodi}
               Writeln(Tic,'AREA ',Download,' ',Tag);
               if Flag<>'' then
                  Writeln(Tic,#9'Local LLIST Flag ',Flag);
               while (TicAreaLine<>'') do
               begin
                  I := pos(' ',TicAreaLine);
                  if I>0 then
                     TempStr := Copy(TicAreaLine, 1, I-1)
                  else
                     TempStr := TicAreaLine;
                  Delete(TicAreaLine, 1, length(TempStr));
                  TicAreaLine := StripLead(TicAreaLine, ' ');
                  {il primo char e' un flag?}
                  if TempStr[1]='O' then
                     LocalFlag := ''
                  else
                  if TempStr[1]='I' then
                  begin
                     LocalFlag := '*&';
                     delete(TempStr,1,1);
                  end else
                  if TempStr[1]='O' then
                  begin
                     LocalFlag := '';
                     Delete(TempStr,1,1);
                  end else
                  if TempStr[1]='*' then
                  begin
                     LocalFlag := '*';
                     Delete(TempStr,1,1);
                  end else
                     LocalFlag := Flag;
                  if ParseAddr(TempStr, PrevAddr, Addr) then
                  begin
                     if LocalFlag<>'' then
                        LocalFlag := ' ' + LocalFlag;
                     Writeln(Tic,#9,AddrStr(Addr),' PASSWORD', LocalFlag);
                     PrevAddr := Addr
                  end;
               end;
               Writeln(Tic);
            end;
         end;
         Close(Tic);
      end;
      close(TicArea);
   end;
end.