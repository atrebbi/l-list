program LLKey;

{$I LL.DEF}

Uses MkString, MkMisc, Mkdos, MkGlobT, MkMsgAbs, MkOpen;

var SysopName, MsgFrom:String;
    Key:longint;
    OrigAddr, DestAddr: AddrType;
    LowerKey, UpperKey: Word;
    Ch: Char;
    TempStr: String;
    TMsg: AbsMsgPtr;
    TempDate: Longint;
    MsgId: String;
    KeyInfo: Text;
    NetAreaId: String;

Function GetKey (SysopName: String; Address: AddrType): String;
var I,KeyNumber:Integer;
    Code:word;
    TempLong,TempLong1:LongInt;
    TempStr1,TempStr2:String;
begin
    TempLong := 0;
    for I:=1 to Length(SysopName) do
       TempLong := TempLong + I * Ord(UpCase(SysopName[I]));
    inc(TempLong,Key);
    str(Key,TempSTr1);
    while length(TempStr1)<4 do
       TempStr1 := '0' + TempStr1 ;
    str(TempLong,TempStr2);
    TempStr2 := TempStr2 + TempStr1;
    while length(tempStr2)<16 do
       TempStr2 := '0' + TEmpStr2;
    GetKey := TempStr2;
end {CheckKey};

begin

   Writeln('LLIST key generator');

   if ParamCount=0 then
   begin
      Writeln;
      Writeln('Usage: ',Paramstr(0),' <NetAreaId>');
      Halt(1);
   end;

   NetAreaId := ParamStr(1);

   MsgFrom := 'Alessandro Trebbi';
   LowerKey := 1;
   Upperkey := 1999;
   OrigAddr.Zone := 2;
   OrigAddr.Net := 332;
   OrigAddr.Node := 901;
   OrigAddr.Point := 0;

   {$IFDEF STEVE}
   MsgFrom := 'Steve Stacher';
   LowerKey := 2000;
   UpperKey := 2499;
   OrigAddr.Zone := 2;
   OrigAddr.Net := 443;
   OrigAddr.Node := 888;
   OrigAddr.Point := 0;
   {$ENDIF}

   {$IFDEF GERT}
   MgsFrom := 'Gert Massheimer';
   LowerKey := 2500;
   UpperKey := 2999;
   OrigAddr.Zone := 2;
   OrigAddr.Net := 2476;
   OrigAddr.Node := 62;
   OrigAddr.Point := 0;
   {$ENDIF}

   {$IFDEF MICHAEL}
   MsgFRom := 'Michael Doyle';
   LowerKey := 3000;
   UpperKey := 3499;
   OrigAddr.Zone := 3;
   OrigAddr.Net := 690;
   OrigAddr.Node := 442;
   OrigAddr.Point := 0;
   {$ENDIF}

   Writeln('Registered to: ',MsgFrom,' ',AddrStr(OrigAddr));
   Writeln;
   Writeln('Please, write info about key:');
   Writeln;

   repeat
      write('Sysop Name: ');
      readln(SysopName);
      Write('Are you sure (Y/N)? ');
      Readln(Ch);
   until (upcase(Ch)='Y');

   repeat
      write('Address: ');
      readln(TempStr);
      if ParseAddr(TempStr,OrigAddr,DestAddr) then
      begin
         Write('Are you sure (Y/N)? ');
         Readln(Ch);
      end else
         Ch := 'N';
   until (upcase(Ch)='Y');

   repeat
      write('Key Number (',LowerKey,'-',UpperKey,'): ');
      readln(Key);
      if (Key >= LowerKey) and (Key <= UpperKey) then
      begin
         Write('Area you sure (Y/N)? ');
         ReadLn(CH);
      end else
         Ch := 'N';
   until Upcase(Ch)='Y';

   if OpenOrCreateMsgArea(TMsg, NetAreaId) then
   begin
      TMsg^.SetMailType(mmtNetMail);
      TMsg^.StartNewMsg;       {initialize for adding msg}

      Tempdate := GetDosdate;
      MsgId := Lower(HexLong(ToUnixDate(Tempdate)));

      TMsg^.SetFrom(MsgFrom);           {Set from name}
      TMsg^.SetTo(SysopName);               {Set to name}

      TMsg^.SetSubj('Your L-List key');

      TMsg^.SetDate(DateStr(TempDate));   {Set msg date mm-dd-yy}
      TMsg^.SetTime(TimeStr(TempDate));   {Set msg time hh:mm}
      TMsg^.SetEcho(True);                {Should msg be echoed}
      TMsg^.SetRefer(0);

      Tmsg^.SetLocal(True);

      Tmsg^.SetPriv(True);
      TMsg^.SetDest(DestAddr);
      TMsg^.SetOrig(OrigAddr);

      {messaggio crash}
      Tmsg^.SetCrash(True);

      TMsg^.DoKludgeLn(#1 + 'MSGID: ' + AddrStr(OrigAddr) + ' ' + MsgId);

      TMsg^.DoKludgeLn(#1 + 'PID: LListKEY');

      TMsg^.DoStringLn('Data used to generate key');
      Tmsg^.DoStringLn('SysopName: ' + SysopName);
      TMsg^.DoStringLn('');

      TMsg^.DostringLn('Your key number: ' + GetKey(SysopName,DestAddr));

      {importa un testo con le ultime info}
      Assign(KeyInfo,'LLKEY.INF');
      {$I-}
      Reset(KeyInfo);
      {$I+}
      if IoResult=0 then
      begin
         while not eof(KeyInfo) do
         begin
            ReadLn(KeyInfo, TempStr);
            Tmsg^.DoStringLn(TempStr);
         end;
         Close(KeyInfo);
      end;

      Tmsg^.DostringLn('---');

      if Tmsg^.WriteMsg<>0 then;

      if CloseMsgArea(TMsg) then;
   end;
end.