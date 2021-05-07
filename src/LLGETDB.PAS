Unit LLGetDb;

{$I LL.Def}

Interface

Function GetDescFromDB(N:String):String;

Implementation

Uses MkString, LLGen;

Function GetDescFromDB(N:String):String;
Const SizeDBBuffer=16384;
Var DB:Text;
    DbBuffer:Pointer;
    TempStr:String;
    Found:Boolean;
    I:Integer;
    N1:String;
Begin
   GetMem(DbBuffer,SizeDBBuffer);
   Assign(DB,D0 + 'LList.Db');
   SetTextBuf(DB,DBBuffer^,SizeDBBuffer);
   {$I-}
   Reset(DB);
   {$I+}
   if IOResult=0 then
   begin
      I := pos('.',N);
      if I>0 then
         N := Copy(N,1,I)
      else
         N := N + ' ';
      Found := False;
      While not found and not eof(DB) do
      begin
         ReadLn(DB,TempStr);
         if (TempStr<>'') and (TempStr[1]<>' ') then
         begin
            {contiene la descrizione di un file}
            if (pos(N,Upper(TempStr))=1) then
            begin
               I := pos(' ',TempStr);
               if I>0 then
                  Delete(TempStr,1,I)
               else
                  TempStr := '';
               StripLeadingSpace(TempStr);
               Found := TempStr<>'';
            end;
         end;
      end;
      Close(DB);
      if Found then
         GetDescFromDB := TempStr
      else
         GetDescFromDB := ''
   end else
      GetDescFromDB := '';
   FreeMem(DbBuffer,SizeDBBuffer);
End;

end.


