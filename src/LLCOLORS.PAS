Unit LLColors;

{$I LL.Def}

Interface

Uses Crt, Mkstring, LLGen, LLMouse;

Function GetColor:Integer;
Function GetAscii: String;
Procedure SetColor(A:Integer);
Function GetColorStr(A:Byte):String;

Implementation

Const AnsiStr:Array[0..7] of Char=('0','4','2','6','1','5','3','7');

Function GetColor: Integer;
Const Color:Integer=7;
Var
   I,K:INteger;
   Ch:Char;
   MouInfo: MinfoRecType;
Begin
   GotoXY(40,5);
   NormVideo;
   Write(FrameChars[3],FrameChars[1],Button);
   for K := 6 to 17 do
      write(FrameChars[1]);
   Write(FrameChars[4]);
   for I := 1 to 8 do
   begin
      GotoXY(40,5+I);
      NormVideo;
      Write(FrameChars[2]);
      for K := 1 to 16 do
      begin
         TextAttr := (I-1) * 16 + (k-1);
         Write(#4);
      end;
      NormVideo;
      Write(FrameChars[2]);
   end;
   GotoXY(40,14);
   Write(FrameChars[5]);
   for K := 2 to 17 do
      write(FrameChars[1]);
   Write(FrameChars[6]);
   repeat
      GotoXY(41+color mod 16,6 + color div 16);
      TextAttr := Color;
      Write('ð'#8);
      waitevent;
      Write(#4);
      if KeyPressed then
      begin
         ch := ReadKey;
         if ch=#0 then
         begin
            Ch := Readkey;
            case ch of
               #77:if color<127 then inc(color);
               #75:if color>0 then dec(Color);
               #72:if color>=16 then dec(Color,16);
               #80:if color<=127-16 then inc(color,16);
            end;
         end;
      end else
      begin
         MouGet(MouInfo);
         if (MouInfo.Cx = 42) and (MouInfo.cy = 4) then
            ch := #27
         else
         if (MouInfo.Cy >= 5) and (MouInfo.Cy <= 12) and
            (MouInfo.Cx >= 40) and (mouInfo.Cx <= 55) then
         begin
             Color := (MouInfo.Cy - 5) * 16 + MouInfo.Cx - 40;
             if MouInfo.IsDouble then
                Ch := #13
             else
                Ch := #0;
         end else
            ch := #0;
      end;
   until (ch=#27) or (ch=#13);
   if Ch=#13 then
      GetColor := Color
   else
      GetColor := -1;
End {GetColor};


Function GetAscii: String;
Const A:Char=' ';
Var
   I,K:INteger;
   Ch:Char;
   TempStr:String;
   MouInfo: MinfoRecType;
Begin
   GotoXY(40,5);
   NormVideo;
   Write(FrameChars[3], frameChars[1], Button);
   for K := 6 to 33 do
      write(FrameChars[1]);
   Write(FrameChars[5]);
   for I := 1 to 7 do
   begin
      GotoXY(40,5+I);
      Write(FrameChars[2]);
      for K := 0 to 31 do
      begin
         Write(Chr(I*32+K));
      end;
      Write(FrameChars[2]);
   end;
   GotoXY(40,13);
   Write(FrameChars[5]);
   for K := 2 to 33 do
      write(FrameChars[1]);
   Write(FrameChars[6]);
   repeat
      GotoXY(44,13);
      Write(' Char: ',A,' Ascii: ',Ord(A):3,' ');
      GotoXY(41 + Ord(A) mod 32,5 + Ord(A) div 32);
      waitevent;
      if Keypressed then
      begin
         ch := ReadKey;
         if ch=#0 then
         begin
            Ch := Readkey;
            case ch of
               #77:if A<#255 then inc(A);
               #75:if A>#32 then dec(A);
               #72:if A>=#64 then dec(A,32);
               #80:if A<=Chr(255-32) then inc(A,32);
            end;
         end;
      end else
      begin
         MouGet(mouInfo);
         If (MouInfo.Cx = 42) and (MouInfo.Cy = 4) then
         begin
            ch := #27
         end else
         if (MouInfo.Cy >= 5) and (MouInfo.Cy <= 11) and
            (MouInfo.Cx >= 40) and (mouInfo.Cx <= 71) then
         begin
             A := Chr((MouInfo.Cy - 4) * 32 + MouInfo.Cx - 40);
             if MouInfo.IsDouble then
                Ch := #13
             else
                Ch := #0;
         end else
            ch := #0;
      end;
   until (ch=#27) or (ch=#13);
   if Ch=#13 then
      GetAscii := A
   else
      GetAscii := '';
End {GetAscii};



Function GetAnsiStr(TextAttr:Byte):String;
Var TempStr:String;
Begin
   TempStr := #27'[0;';
   {Bright}
   if (TextAttr mod 16) >= 8 then
      TempStr := TempStr + '1;';
   {Blink}
   If TextAttr >= 128 then
      TempStr := TempStr + '5;';
   {ForeGround}
   GetAnsiStr := TempStr + '3' + AnsiStr[TextAttr mod 8] +
      ';4' + AnsiStr[(TextAttr Div 16) mod 8] + 'm';
End {GetAnsiStr};

Function GetAvtStr(TextAttr:Byte):String;
Begin
   if TextAttr<32 then
      GetAvtStr := #22#1#16 + chr(128+TextAttr)
   else
      GetAvtStr := #22#1 + chr(TextAttr);
End {GetAvtStr};

Function GetPCBStr(TextAttr:Byte):String;
Begin
   GetPCBStr := '@X' + HexByte(TextAttr);
End {GetPCBStr};

Procedure SetColor(A:Integer);
Var I:ColourType;
    Temp:Byte;
begin
   case A of
      {TTY}
      0:begin
         for I := ColDef to ColInfo do
            AnsiCol[I] := '';
        end;
      {ANSI}
      1:begin
         for I := ColDef to ColInfo do
         begin
            AnsiCol[I] := GetAnsiStr(NumCol[I]);
         end;
        end;
      {AVATAR}
      2:Begin
         for I := ColDef to ColInfo do
         begin
            AnsiCol[I] := GetAvtStr(NumCol[I]);
         end;
        end;
   end;
end {SetColor};



Function GetColorStr(A:Byte):String;
Var Color:Integer;
Begin
   if A>0 then
   begin
      Color := GetColor;
      if Color>=0 then
      begin
         if ColorId=#22#1 then
         begin
            GetColorStr := GetAvtStr(Color)
         end else
         if ColorId='@X' then
         begin
            GetColorStr := GetPCBStr(Color)
         end else
            GetCOlorStr := '';
      end else
         GetColorStr := '';
   end else
      GetColorStr := '';
End {GetColorStr};


end.
