Unit LLSEARCH;
{$I LL.Def}

Interface

Uses Dos, Crt,
   MkFile,
   MkMisc, MkGlobT, LLGEN;

Procedure SearchPurge;
Procedure AddSearch(LastArea:Integer);

Implementation



Procedure SearchPurge;
Const DaysDupes=30;
Var  DupesFileOld,DupesFileNew:File;
     Dupes:DupesType;
     {fm:Word;}
     Trovato:Boolean;
     T,T1:DateTime;
     ChkDate:LongInt;
     {$IFDEF VIRTUALPASCAL}
     TempWord: Longint;
     {$ENDIF}
begin
   Writeln(' * Purge old searchs');
   Writeln(LogFile,PreLog(LogStart),'Purge old searchs');
   Flush(LogFile);
   {fm := FileMode;
   FileMode := fmReadWrite;
   }
   Assign(DupesFileOld,D0+'_LLST_.$$$');
   {$I-}
   Erase(DupesFileOld);
   {$I+}
   if IOResult=0 then;
   Assign(DupesFileOld,D0+'FSearch.Dup');

   {$I-}
   Rename(DupesFileOld,D0+'_LLST_.$$$');
   {$I+}
   if IOResult=0 then
   begin
      GetDate(T1.Year,T1.Month,T1.Day,TempWord);
      JulianToGregorian(GregorianToJulian(T1)-DaysDupes,Integer(T1.Year),
         Integer(T1.Month),Integer(T1.Day));
      T1.Hour := 0;
      T1.Min := 0;
      T1.Sec := 0;
      PackTime(T1,ChkDate);
      Assign(DupesFileOld,D0+'_LLST_.$$$');
      Reset(DupesFileOld,1);
      Assign(DupesFileNew,D0+'FSearch.Dup');
      Rewrite(DupesFileNew,1);
      while not eof(DupesFileOld) do
      begin
         Blockread(DupesFileOld,Dupes,SizeOf(Dupes),TempWord);
         if (Dupes.Time>=ChkDate) and (Dupes.Keyword<>'') then
            Blockwrite(DupesFileNew,Dupes,SizeOf(Dupes),TempWord);
      end;
      close(DupesFileOld);
      {$I-}
      Erase(DupesFileOld);
      {$I+}
      if IOResult=0 then;
      close(DupesFileNew);
   end;
   {
   filemode := fm;
   }
end {SearchPurge};


Procedure AddSearch(LastArea:Integer);
Var F:File;
    Dupes:DupesType;
    {fm:word;}
    {$IFDEF VIRTUALPASCAL}
    TempWord: Longint;
    {$ENDIF}
begin
   {
   fm := FileMode;
   }
   FillChar(Dupes,SizeOf(Dupes),0);
   Dupes.Keyword := MsgSubject;
   Dupes.Name := MsgTo;
   Dupes.Time := ActDate;
   Dupes.Address := MsgDestAddr;
   Dupes.LastArea := LastArea;
   {FileMode := fmReadWrite;}
   assign(F,D0+'FSearch.Dup');
   {$I-}
   Reset(F,1);
   {$I+}
   if IOResult=0 then
   begin
      seek(F,FileSize(F));
      blockwrite(F,Dupes,SizeOf(Dupes),TempWord);
      close(F);
   end;
   {
   FileMode := fm;
   }
end {AddSearch};

end.
