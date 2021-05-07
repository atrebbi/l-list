Unit LLTend;

{$I LL.Def}

Interface

PROCEDURE readbox (int:STRING; MaxLen:byte; VAR a:STRING);
PROCEDURE readboxinteger (int:STRING; minimo,massimo:integer; VAR num:integer);
PROCEDURE readboxlong (int:STRING; minimo,massimo:longint; VAR num:longint);
Function Conferma(Int:String):Boolean;
Procedure BoxMessage(Int:String);

Implementation

Uses Crt, LLGen, llmouse;

PROCEDURE readbox (int:STRING; MaxLen:byte; VAR A:STRING);
Const X=12; Y=10;
Var
    I:Integer;
    Ch:Char;
    Cr,Escape:Boolean;
    Worker:String;
    WidthWin:Byte;
    PosStr:Byte;
    FirstKey: Boolean;
    PrevAttr : Byte;
    MouInfo: MinfoRecType;

Begin

   PrevAttr := TextAttr;
   normvideo;

   WidthWin := MaxLen;
   if length(Int)>WidthWin then
      WidthWin := length(Int);
   Inc(WidthWin,4);

   GotoXY(10,8);
   Write(FrameChars[3], FrameChars[1], Button);
   for I := 6 to WidthWin-1 do
      Write(FrameChars[1]);
   Write(FrameChars[4]);

   GotoXY(10,9);
   Write(FrameChars[2],' ',Int);
   for I := 3 + length(Int) to WidthWin-1 do
      Write(' ');
   Write(FrameChars[2]);

   GotoXY(10,10);
   Write(FrameChars[2],'':WidthWin-2,FrameChars[2]);

   GotoXY(10,11);
   Write(FrameChars[5]);
   for I := 2 to WidthWin-1 do
      Write(FrameChars[1]);
   Write(FrameChars[6]);

   GotoXY(12,10);

   Cr := False;
   Escape := False;

   Worker := A;
   PosStr := 1;
   FirstKey := True;


  REPEAT                  { Until ESC or (CR) entered }

    HideCursor;
    GotoXY(X,Y);
    Write(Worker);
    for I := length(Worker)+1 to MaxLen do
       Write('°');
    GotoXY(X+PosStr-1,Y);
    ShowCursor;

    waitevent;

    if keypressed then
    begin
       Ch := ReadKey;
       case ch of
          #0:begin
               Ch := Readkey;
               case Ch of
                  #75:if PosStr>1 then
                         dec(PosStr);
                  #77:if PosStr<=Length(Worker) then
                         inc(PosStr);
                  #83:if PosStr<=length(Worker) then
                         delete(Worker,PosStr,1);
                  #79:{fine}
                      PosStr := length(Worker) +1;
                  #71:{home}
                      PosStr := 1;
               end;
            end;
          #32..#255:
            begin
               if FirstKey then
               begin
                  Worker := '';
               end;
               if PosStr>length(Worker) then
               begin
                  if (Length(Worker)<MaxLen) then
                  begin
                     Worker := Worker + Ch;
                     inc(PosStr)
                  end;
               end else
               begin
                  Worker := Copy(Worker,1,PosStr-1) + Ch +
                     Copy(Worker,PosStr,length(Worker)-PosStr+1);
                  if length(Worker)>MaxLen then
                     Worker := Copy(Worker,1,MaxLen);
                  inc(PosStr);
               end;
            end;
          #27:Escape := True;
          #13:Cr := True;
           #8:Begin
                 if PosStr>1 then
                 begin
                    Delete(Worker,PosStr-1,1);
                    Dec(PosStr);
                 end;
              end;
        end;
     end else
     begin
       MouGet(MouInfo);
       if (MouInfo.cx = 12) and (MouInfo.cy = 7) then
       begin
          Escape := True
       end else
       if (MouInfo.cy = 9) and (MouInfo.cx + 2 > x) then
       begin
          if MouInfo.cx < x + maxlen - 1 then
          begin
             if MouInfo.IsDouble then
                cr := true
             else
             begin
                PosStr := MouInfo.cx + 2 - x;
                if PosStr > length(Worker) + 1 then
                begin
                   PosStr := length(worker) + 1
                end;
             end;
          end;
       end;
     end;
     FirstKey := False;

  Until Cr or Escape;

  if Cr then
     A := Worker
  else
     A := '';

  TextAttr := PrevAttr;

END {readbox};


PROCEDURE readboxinteger (int:STRING; minimo,massimo:integer; VAR num:integer);
VAR
    {$IFDEF VIRTUALPASCAL}
    Code: Longint;
    {$ELSE}
    Code:Word;
    {$ENDIF}
    a: STRING;
Begin
   if Minimo<=Massimo then
   begin
      Str(Num,A);
      Repeat
         ReadBox(Int,10,A);
         if A='' then
         begin
            Num := 0;
            Code := 0;
         end else
            Val(A,Num,Code);
      until (Code=0) and (Num>=Minimo) and (Num<=Massimo);
   end;
END {readboxinteger};

PROCEDURE readboxlong (int:STRING; minimo,massimo:longint; VAR num:longint);
VAR
    {$IFDEF VIRTUALPASCAL}
    Code: Longint;
    {$ELSE}
    Code:Word;
    {$ENDIF}
    a: STRING;
Begin
   if Minimo<=Massimo then
   begin
      Str(Num,A);
      Repeat
         ReadBox(Int,12,A);
         if A='' then
         begin
            Num := 0;
            Code := 0;
         end else
            Val(A,Num,Code);
      until (Code=0) and (Num>=Minimo) and (Num<=Massimo);
   end;
END {readboxlong};


Function Conferma(Int:String):Boolean;
Var
    I, WidthWin : INteger;
    PrevAttr: Byte;
    MouInfo: MinfoRecType;
    Temp: Boolean;

Begin

   PrevAttr := TextAttr;
   normvideo;

   WidthWin := Length(Int) + 14;

   HideCursor;
   GotoXY(40-WidthWin div 2,12);
   Write(FrameChars[3]);
   for I := 2 to WidthWin-1 do
      Write(FrameChars[1]);
   Write(FrameChars[4]);

   GotoXY(40-WidthWin div 2,13);
   Write(FrameChars[2],' ',Int,'':11, frameChars[2]);

   GotoXY(40-WidthWin div 2,14);
   Write(FrameChars[5]);
   for I := 2 to WidthWin-1 do
      Write(FrameChars[1]);
   Write(FrameChars[6]);

   GotoXY(40 + WidthWin div 2 - 11, 13);
   Write('[Y]');
   GotoXY(40 + WidthWin div 2 - 7, 13);
   Write('[N]');
   ShowCursor;

   Temp := False;
   Repeat
      InvVideo;
      if Temp then
      begin
         GotoXY(40 + WidthWin div 2 - 10, 13);
         Write('Y');
      end else
      begin
         GotoXY(40 + WidthWin div 2 - 6, 13);
         Write('N');
      end;

      waitevent;
      NormVideo;
      if Temp then
      begin
         GotoXY(40 + WidthWin div 2 - 10, 13);
         Write('Y');
      end else
      begin
         GotoXY(40 + WidthWin div 2 - 6, 13);
         Write('N');
      end;
      if KeyPressed then
      begin
         Ch := Upcase(ReadKey);
         if Ch = #0 then
         begin
            ch := Readkey;
            if (ch = #75) or (ch = #77) then
               Temp := not temp;
            ch := #0;
         end else
         if ch = #13 then
         begin
            if temp then
               ch := 'Y'
            else
               ch := 'N';
         end;
      end else
      begin
         MouGet(MouInfo);
         if MouInfo.cy = 12 then
         begin
            if MouInfo.cx = 40 + WidthWin div 2 - 11 then
            begin
               Temp := True;
               if MouInfo.IsDouble then
                  ch := 'Y'
               else
                  ch := #0;
            end else
            if MouInfo.cx = 40 + WidthWin div 2 - 7 then
            begin
               Temp := false;
               if MouInfo.IsDouble then
                  ch := 'N'
               else
                  ch := #0;
            end else
               ch := #0;
         end else
            ch := #0;
      end;
   until (Ch='Y') or (ch='N');

   Conferma := Ch='Y';

   TextAttr := PrevAttr;

End {Conferma};


Procedure BoxMessage(Int:String);
Var
    I, WidthWin : INteger;
    PrevAttr: Byte;
Begin

   HideCursor;
   PrevAttr := TextAttr;
   normvideo;

   WidthWin := Length(Int) + 4;

   GotoXY(40-WidthWin div 2,12);
   Write('Þ');
   for I := 2 to WidthWin-1 do
      Write('ß');
   Write('Ý');

   GotoXY(40-WidthWin div 2,13);
   Write('Þ ',Int,' Ý');

   GotoXY(40-WidthWin div 2,14);
   Write('Þ');
   for I := 2 to WidthWin-1 do
      Write('Ü');
   Write('Ý');

   Ch := ReadKey;
   if Ch=#0 then
      Ch := ReadKey;

   TextAttr := PrevAttr;
   ShowCursor;
End {Conferma};


end.
