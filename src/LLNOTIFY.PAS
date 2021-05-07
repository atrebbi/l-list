Program LLNotify;

{
forza l'invio del report, modificando la data del primo file inviato
}

Uses
     Dos;

Type
     TicDupeType=Record
        Name:String[12];
        AreaTag:String[20];
        Ignora:Array[1..8] of char;
        Size,Time:Longint;
        Received:Boolean
     End;

Var
     TicDupe: TicDupeType;
     F: File of TicDupeType;
     T1: DateTime;

begin

   Assign(F,'Tic.Dup');
   {$I-}
   Reset(F);
   {$I+}
   if IOResult=0 then
   begin
      if not eof(F) then
      begin
         Read(F,TicDupe);
         if TicDupe.Name='' then
         begin
            seek(F,TicDupe.Size div SizeOf(TicDupeType));
            Read(F,TicDupe);
         end;
         UnpackTime(TicDupe.Time,T1);
         {di questo devo cambiare la data, e quindi riscriverlo}
         Dec(T1.Month);
         PackTime(T1, TicDupe.Time);
         Seek(F,FilePos(F)-1);
         Write(F,TicDupe);
      end;
      close(F)
   end;
end.
