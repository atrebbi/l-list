Unit MkDupes;

{
Copyright 1996 by Alessandro Trebbi, tutti i diritti riservati
}

interface

uses mkfile, mkglobt;

Type
  DupesType=Record
     Addr: AddrType;
     MsgID: longint;
  end;

type
  tree = ^node;
  node    = Record
    key   : DupesType;
    bal   : -1..+1; { bal = h(right) - h(left) }
    left,
    right : tree
  end;

  CheckDupePtr=^CheckDupe;
  CheckDupe = object
     root: tree;
     h, inserted, addinfile: boolean;
     DupesFile: File;
     Constructor Init(Filename: String; maxdupes: longint);
     Function MsgID2Dupes(Var Dup: DupesType; MSGIDkludge: string): boolean;
     Function IsDupes(Dup: DupesType): Boolean;
     Destructor done;
     Procedure insert(k : DupesType; Var t : tree);
  end;


implementation


Procedure checkDupe.insert(k : DupesType; Var t : tree);

   Procedure ll(Var t : tree);
   Var
     p : tree;
   begin
     p := t^.left;
     t^.left  := p^.right;
     p^.right := t;
     t := p;
   end;

   Procedure rr(Var t : tree);
   Var
      p : tree;
   begin
     p := t^.right;
     t^.right := p^.left;
     p^.left  := t;
     t := p;
   end;

   Procedure lr(Var t : tree);
   begin
     rr(t^.left);
     ll(t);
   end;

   Procedure rl(Var t : tree);
   begin
     ll(t^.right);
     rr(t);
   end;

  Procedure balanceleft(Var t : tree);
  begin
    Case t^.bal of
      +1 :
        begin
          t^.bal := 0;
          h := False;
        end;
       0 : t^.bal := -1;
      -1 :
        begin { rebalance }
          if t^.left^.bal = -1 then
          begin { single ll rotation }
            ll(t);
            t^.right^.bal := 0;
          end
          else { t^.left^.bal  = +1 }
          begin  { double lr rotation }
            lr(t);
            if t^.bal = -1 then
              t^.right^.bal := +1
            else
              t^.right^.bal := 0;
            if t^.bal = +1 then
              t^.left^.bal := -1
            else
              t^.left^.bal := 0;
          end;
          t^.bal := 0;
          h := False;
        end;
    end;
  end;

  Procedure balanceright(Var t : tree);
  begin
    Case t^.bal of
      -1 :
        begin
          t^.bal := 0;
          h := False;
        end;
       0 : t^.bal := +1;
      +1 :
        begin { rebalance }
          if t^.right^.bal = +1 then
          begin { single rr rotation }
            rr(t);
            t^.left^.bal := 0
          end
          else { t^.right^.bal  = -1 }
          begin  { double rl rotation }
            rl(t);
            if t^.bal = -1 then
              t^.right^.bal := +1
            else
              t^.right^.bal := 0;
            if t^.bal = +1 then
              t^.left^.bal := -1
            else
              t^.left^.bal := 0;
          end;
          t^.bal := 0;
          h := False;
        end;
    end;
  end;


begin { insert }
  if t = nil then
  begin
    new(t);
    t^.key   := k;
    t^.bal   := 0;
    t^.left  := nil;
    t^.right := nil;
    h := True;
    inserted := true;
    if addInFile then
       BlockWrite(DupesFile,k,sizeOf(DupesType));
  end
  else
  if (k.msgid < t^.key.msgid) then
  begin
    insert(k, t^.left);
          if h then
      balanceleft(t);
  end
  else
  if (k.msgid > t^.key.msgid) then
  begin
    insert(k, t^.right);
    if h then
      balanceright(t);
  end else
  begin
     {stesso msgid, controlla address}
     if AddrEqual(k.addr, t^.key.addr) then
     begin
        inserted := false;
     end else
     if AddrLess(k.addr, t^.key.addr) then
     begin
       insert(k, t^.left);
             if h then
         balanceleft(t);
     end
     else
     begin
       insert(k, t^.right);
       if h then
         balanceright(t);
     end;
  end;
end;


Constructor CheckDupe.Init(Filename: String; maxdupes: longint);
Type DupArray=Array[1..1] of DupesType;
var
   fm: word;
   size: longint;
   p:pointer;
   i: integer;
   maxsize: longint;
begin
   maxsize := maxdupes * sizeof(dupesType);
   root := nil;
   fm := filemode;
   filemode := fmReadWrite_DA;
   Assign(DupesFile, Filename);
   {$I-}
   reset(DupesFile,1);
   {$I+}
   if IOResult=0 then
   begin
      getmem(p,maxsize);
      size := filesize(Dupesfile);
      if size>maxsize then
      begin
         seek(DupesFile,size-maxsize);
         blockread(dupesfile,p^,maxsize);
         seek(Dupesfile,0);
         blockwrite(Dupesfile,P^,maxsize);
         truncate(Dupesfile);
         size := maxsize;
      end else
      begin
         blockread(dupesfile,p^,size);
      end;
      AddInFile := False;
      for i:=1 to size div sizeof(dupesType) do
      begin
         {$R-}
         insert(dupArray(p^)[i], root);
         {$R+}
      end;
      freemem(p,maxsize);
   end else
      rewrite(DupesFile,1);
   AddInFile := True;
end;


Destructor checkdupe.done;
    procedure Deltree(Var T: tree);
    begin
       if t<>nil then
       begin
          deltree(t^.left);
          deltree(t^.right);
          dispose(t);
       end;
    end;
begin
   close(DupesFile);
   deltree(root);
end;


function CheckDupe.MsgID2Dupes(Var Dup: DupesType; MSGIDkludge: string): boolean;
var I: word;
    tempB: boolean;
begin
   I := pos(' ',MsgIdKludge);
   delete(MsgidKludge,1,i);
   I := pos(' ',MsgIdKludge);
   if ParseAddr(Copy(MsgIdKludge,1,I-1), Dup.Addr, Dup.Addr) then
   begin
      delete(MsgIdKludge,1,i);
      Dup.MsgId := 0;
      tempB := True;
      for I := 1 to length(MsgidKludge) do
      if TempB then
      begin
         Dup.MsgId := Dup.MsgId*16;
         case upcase(MsgIdKludge[i]) of
            '0':;
            '1':inc(Dup.Msgid,1);
            '2':inc(Dup.Msgid,2);
            '3':inc(Dup.Msgid,3);
            '4':inc(Dup.Msgid,4);
            '5':inc(Dup.Msgid,5);
            '6':inc(Dup.Msgid,6);
            '7':inc(Dup.Msgid,7);
            '8':inc(Dup.Msgid,8);
            '9':inc(Dup.Msgid,9);
            'A':inc(Dup.Msgid,10);
            'B':inc(Dup.Msgid,11);
            'C':inc(Dup.Msgid,12);
            'D':inc(Dup.Msgid,13);
            'E':inc(Dup.Msgid,14);
            'F':inc(Dup.Msgid,15);
           else
            tempB := False;
         end;
      end;
      MsgId2Dupes := TempB;
   end else
      MsgId2Dupes := false;
end;


Function CheckDupe.IsDupes(Dup: DupesType): Boolean;
begin
   {ricavo i dati dal msgidkludge}
   insert(Dup, root);
   IsDupes := not inserted;
end;

begin
end.

