Unit LLUUE;

Interface

{$I LL.Def}

Procedure UUEncode (Var AllFiles:Text; Nome:String; Method:Byte);
 {Method: 0=UUencode, 1=XXEncode}

Implementation

Uses
   MkFile,
    LLGen;

Procedure UUEncode (Var AllFiles:Text; Nome:String; Method:Byte);

Const
  SP = Byte(' ');

Type
  TTriplet = Array[0..2] of Byte;
  TKwartet = Array[0..3] of Byte;

var Triplets: Array[1..15] of TTriplet;
    kwar: TKwartet;
    FileName: String[12];
    {$IFDEF VIRTUALPASCAL}
    i: longint;
    {$ELSE}
    i: Word;
    {$ENDIF}
    j: Integer;
    f: File;

    procedure Triplet2Kwartet(Triplet: TTriplet; var Kwartet: TKwartet);
    var i: Integer;
    begin
      Kwartet[0] := (Triplet[0] SHR 2);
      Kwartet[1] := ((Triplet[0] SHL 4) AND $30) +
                    ((Triplet[1] SHR 4) AND $0F);
      Kwartet[2] := ((Triplet[1] SHL 2) AND $3C) +
                    ((Triplet[2] SHR 6) AND $03);
      Kwartet[3] := (Triplet[2] AND $3F);

      case Method of
      0: {UUEncode}
         for i:=0 to 3 do
         begin
           if Kwartet[i] = 0 then Kwartet[i] := $40;
           Inc(Kwartet[i],SP)
         end;
      1: {XXEncode}
         for i:=0 to 3 do
         begin {+-01..89ABC...XYZabc...xyz}
           if Kwartet[I]=0 then
              Kwartet[I] := ord('+')
           else if Kwartet[I]=1 then
              Kwartet[I] := Ord('-')
           else if Kwartet[I]<=11 then
              Kwartet[I] := Ord('0') + Kwartet[I] - 2
           else if Kwartet[I]<=37 then
              Kwartet[I] := Ord('A') + Kwartet[I] - 12
           else
              Kwartet[I] := Ord('a') + Kwartet[I] - 38;
         end;
      end;

    end {Triplet2Kwartet};

begin

  Assign(f,PathDown+Nome);
  {
  FileMode := FmReadOnly + FmDenyWrite;
  }
  {$I-}
  reset(f,1);
  {$I+}
  if IOREsult=0 then
  begin
     {Tira via la DIR dal nome}
     writeln(AllFiles,'begin 0777 ',Nome);
     repeat
       FillChar(Triplets,SizeOf(Triplets),0);
       BlockRead(f,Triplets,SizeOf(Triplets),i);
       write(AllFiles,Char(SP+i));
       for j:=1 to (i+2) div 3 do
       begin
         Triplet2Kwartet(Triplets[j],kwar);
         write(AllFiles,Char(kwar[0]),Char(kwar[1]),Char(kwar[2]),Char(kwar[3]))
       end;
       writeln(AllFiles)
     until (i < SizeOf(Triplets));
     if Method=0 then
        Writeln(AllFiles,#96#96)
     else
        Writeln(AllFiles,'++');
     writeln(AllFiles,'end');
     close(f);
  end;
end {UUEncode};

end.
