Unit LLMagic;

{$I LL.Def}

Interface

Uses LLGEN, Dos, MkString;

Function MagicAll(Magic:String):String;
Function MagicOk(Magic:String):String;
Function ExpandMagic(Magic:StringRef):String;

Implementation

Function ExpandMagic(Magic:StringRef):String;
var MagicPath:String;
    S:SearchRec;
    I,J:integer;
    FTime:Longint;
    Temp :String;
    D:DirStr; N:NameStr; E:ExtStr;
begin
   {magic non deve essere modificato}
   if (Magic=Nil) or (Magic^='') then
     ExpandMagic := ''
   else
   begin
     I := Pos(' ',Magic^);
     if I=0 then
     begin
        ExpandMagic := ''
     end else
     begin
        inc(I);
        While (I<=length(Magic^)) and (Magic^[I]=' ') do
           inc(I);
        if (I<=length(Magic^)) then
        begin
           J := Pos(' ',Copy(Magic^,I,length(Magic^)-I+1));
           if J=0 then
              J := length(Magic^) - I + 2;
           dec(J);
           {Inizia Ricerca}
           FTime := -1;
           Temp := '';
           FindFirst(Copy(Magic^,I,J),Archive+ReadOnly,S);
           while DosError=0 do
           begin
              If S.Time>=FTime then
              begin
                 Temp := S.Name;
                 Ftime := S.Time
              end;
              findnext(S);
           end;
           if Temp='' then
              ExpandMagic := ''
           else
           begin
              FSplit(Copy(Magic^,I,J),D,N,E);
              if D[length(D)]<>'\' then
                 D := D + '\';
              Temp := D + Temp;
              ExpandMagic := Copy(Magic^,1,I-1) + Upper(Temp) + Copy(Magic^,I+j,length(Magic^)-I-J+1);
           end;
        end else
           ExpandMagic := '';
     end;
   end;
end {ExpandMagic};



Function MagicAll(Magic:String):String;
Var I,J:Integer;
    Desc:String;
    D : DirStr; N:NameStr; E:ExtStr;
    Function FillSpace(S:String):String;
    begin
       S := Copy(S,1,12);
       while length(S)<12 do
          S := S + ' ';
       FillSpace := S;
    end {FillName};
begin
   {Nome}
   I := pos(' ',Magic);
   inc(I);
   while (I<=length(magic)) and (Magic[I]=' ') do
      inc(I);
   {I = inizio path}
   J := pos(' ',Copy(Magic,I,length(magic)-I+1));
   if J=0 then
   begin
      FSplit(Copy(Magic,I,length(Magic)-I+1),D,N,E);
      MagicAll :=  FillSpace(Copy(Magic,1,I-1)) +' ³ ' + FillSpace(N+E) + '   ' +
         OrfanoStr(N+E);
   end else
   begin
      FSplit(Copy(Magic,I,J),D,N,E);
      Inc(J);
      while (J<=length(Magic)) and (Magic[I+J-1]=' ') do
         inc(J);
      if Pos('!',Copy(Magic,I+J-1,length(Magic)-I-J+2))=0 then
         MagicAll := FillSpace(Copy(Magic,1,I-1))+' ³ '+FillSpace(N+E) +'   '+
            Copy(Magic,I+J-1,length(Magic)-I-J+2)
      else
         MagicAll := '';
   end;
end {MagicAll};

Function MagicOk(Magic:String):String;
Var I,J:Integer;
    Desc:String;
begin
   {Nome}
   I := pos(' ',Magic);
   inc(I);
   while (I<=length(magic)) and (Magic[I]=' ') do
      inc(I);
   {I = inizio path}
   J := I;
   while (I<=length(magic)) and (Magic[I]<>' ') do
      inc(I);
   {I = Fine Path + 1}
   if I>Length(magic) then
      MagicOk := Magic
   else
   begin
      J := pos('!',Copy(magic,I,length(magic)-I+1));
      if J=0 then
         MagicOk := Copy(Magic,1,I-1)
      else
         MagicOk := Copy(Magic,1,I-1) + ' ' + Copy(magic,I+J-1,length(Magic)-I-J+2);
   end;
end {MagicOk};

end.
