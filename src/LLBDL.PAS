Unit LLBDL;
{$I LL.Def}

Interface

Uses LLGEN, LLColors, Dos, Crt;

Procedure WriteBdlBBS (Var AllFiles:Text);
Procedure CreateBdlBbs(Col:Byte);

Implementation

Procedure WriteBdlBBS (Var AllFiles:Text);
Const LenDesc=51;
Var I,J,P:Integer;
Begin

   writeln(AllFiles,AnsiCol[ColBdlFrame],HdrStr);
   writeln(AllFiles,AnsiCol[ColBdlFrame],
      'º ',Ansicol[ColInfo],'No.  Name          Dl.   Description','':40,AnsiCol[ColBdlFrame],'º');
   writeln(AllFiles,AnsiCol[ColBdlFrame],'Ì',RepeatStr('Í',77),'¹');

   I := MaxBest1;

   while (I>=1) and (Best^[I].Nome<>'') do
   begin
      if length(Best^[I].Descrizione)>LenDesc then
      begin
         P := LenDesc + 1;
         while (P>0) and (Best^[I].Descrizione[P]<>' ') do
            dec(P);
         While (P>0) and (Best^[I].Descrizione[P]=' ') do
            dec(P);
         if P=0 then
            P := LenDesc;
      end else
         P := length(Best^[I].Descrizione);
      writeln(AllFiles,AnsiCol[ColBdlFrame],'º',AnsiCol[ColInfo],' ',MaxBest1 + 1 - I:2,'.  ',
         AnsiCol[ColName],Best^[I].Nome,'':13-length(Best^[I].Nome),
         AnsiCol[ColSizeU],Best^[I].DownLoad:4,'':3,
         AnsiCol[ColInfo],Copy(Best^[I].Descrizione,1,P),'':LenDesc-P,
         AnsiCol[ColBdlFrame],'º');
      dec(I);
   end;
   while I>=1 do
   begin
      Writeln(AllFiles,AnsiCol[ColBdlFrame],'º','º':78);
      dec(I);
   end;
   writeln(AllFiles,AnsiCol[ColBdlFrame],FtrStr);
end {WriteBdlBbs};



Procedure CreateBdlBbs(Col:Byte);
Const ExtBdl:Array[0..2] of String[3]=('ASC','ANS','AVT');
Var D:DirStr; N:NameStr; E:ExtStr;
begin
   SetColor(Col);
   FSplit(PathBdl,D,N,E);
   PathBdl := D + N + '.' + ExtBdl[Col];
   assign(VariText,PathBdl);
   SetTextBuf(VariText,VariBuf^,SizeTxtBuf);
   {$I-}
   Rewrite(variText);
   {$I+}
   if IOResult=0 then
   begin
      WriteBDlBbs(VariText);
      Close(VariText);
   end;
end {CreateBdlBBS};

end.
