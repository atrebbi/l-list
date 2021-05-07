Unit MKOpen; {Open a message area using an MsgAreaId}

{$I MKB.Def}

{
     MKOpen - Copyright 1993 by Mark May - MK Software
     You are free to use this code in your programs, however
     it may not be included in Source/TPU function libraries
     without my permission.

     Mythical Kingom Tech BBS (513)237-7737 HST/v32
     FidoNet: 1:110/290
     Rime: ->MYTHKING
     You may also reach me at maym@dmapub.dma.org
}


Interface

Uses MKMsgAbs;

Function OpenMsgArea(Var Msg: AbsMsgPtr; MsgAreaId: String): Boolean;
Function OpenOrCreateMsgArea(Var Msg: AbsMsgPtr; MsgAreaId: String): Boolean;
Function CloseMsgArea(Var Msg: AbsMsgPtr): Boolean;
Function InitMsgPtr(Var Msg: AbsMsgPtr; MsgAreaId: String): Boolean;
Function DoneMsgPtr(Var Msg: AbsMsgPtr): Boolean;
{Zone di default per la base fido, viene utilizzata nella InitMsgPtr}
Procedure SetDefaultZone(DZ: Word);
{queste servono per la successiva Tag2AreaId}
Procedure SetPathHudson(P: String);
Procedure SetDefaultPathAreasBbs(P: String);
{converte un Tag in un AreaId, serve per lo pseudo AreaId T<AREATAG>}
Procedure ParseAreasBbsLine(L: String; Var Tag, AreaId: String);
Function Tag2AreaId(Tag, PathAreasBbs:String): String;

Implementation

Uses MkString, MKMsgHud, MKMsgFid, MKMsgSqu, {MkMsgEzy,} MkMsgJam,
   LLText;

Const
   DefaultZone: Word=1;
   PathHudson: String='';
   DefaultPathAreasBbs: String='Areas.Bbs';

{ Area ids begin with identifier for msg base type }
{ The following characters are already reserved    }
{   B = PC-Board            }
{   E = Ezycomm             }
{   F = Fido *.Msg          }
{   H = Hudson              }
{   I = ISR - msg fossil    }
{   J = JAM                 }
{   M = MK-Merlin           }
{   P = *.PKT               }
{   Q = QWK/REP             }
{   R = Renegade            }
{   S = Squish              }
{   W = Wildcat             }

{ io inoltre uso T per indicare il TAG echomail dell'area }
{ questo va convertito poi in un normale Area id leggendo }
{ un file di testo in formato Areas.Bbs                   }


Function OpenMsgArea(Var Msg: AbsMsgPtr; MsgAreaId: String): Boolean;
  Begin
  If InitMsgPtr(Msg, MsgAreaId) Then
  Begin
      If Msg^.OpenMsgBase <> 0 Then
      Begin
         OpenMsgArea := False;
         If DoneMsgPtr(Msg) Then;
      End else
         OpenMsgArea := True;
  End Else
      OpenMsgArea := False;
  End;


Function OpenOrCreateMsgArea(Var Msg: AbsMsgPtr; MsgAreaId: String): Boolean;
  Begin
  If InitMsgPtr(Msg, MsgAreaId) Then
  Begin
    {se l'area non esiste, la crea}
    If (Msg^.MsgBaseExists or
        (Msg^.CreateMsgBase(0, 0) = 0)) and
       (Msg^.OpenMsgBase = 0) Then
    Begin
       OpenOrCreateMsgArea := True;
    End else
    begin
       If DoneMsgPtr(Msg) Then;
       OpenOrCreateMsgArea := False;
    end;
  End else
     OpenOrCreateMsgArea := False;
  End;


Function CloseMsgArea(Var Msg: AbsMsgPtr): Boolean;
  Begin
  If Msg <> Nil Then
    Begin
    CloseMsgArea := (Msg^.CloseMsgBase = 0);
    If DoneMsgPtr(Msg) Then;
    End
  Else
    CloseMsgArea := False;
  End;


Function InitMsgPtr(Var Msg: AbsMsgPtr; MsgAreaId: String): Boolean;
  Var
     MT: MsgMailType;
Begin
  Msg := Nil;
  MT := mmtNormal;
  if Upcase(MsgAreaId[1])='T' then
  begin
     MsgAreaId := Tag2AreaId(Copy(MsgAreaId,2,length(MsgAreaId)-1),
        DefaultPathAreasBbs);
     MT := mmtEchoMail;
  end;
  if MsgAreaId<>'' then
  begin
     Case UpCase(MsgAreaId[1]) of
       'H': Msg := New(HudsonMsgPtr, Init);
       'S': Msg := New(SqMsgPtr, Init);
       'F': begin
               Msg := New(FidoMsgPtr, Init);
               FidoMsgPtr(Msg)^.FM^.DefaultZone := DefaultZone;
            end;
       {'E': Msg := New(EzyMsgPtr, Init);}
       'J': Msg := New(JamMsgPtr, Init);
       End;
     if Msg<>Nil then
     begin
        Msg^.SetMsgPath(Copy(MsgAreaId, 2, length(MsgAreaId) -1));
        Msg^.SetMailType(MT);
        InitMsgPtr := True
     end else
        InitMsgPtr := False;
  end else
     InitMsgPtr := False;
End;


Function DoneMsgPtr(Var Msg: AbsMsgPtr): Boolean;
  Begin
  If Msg <> Nil Then
    Dispose(Msg, Done);
  Msg := Nil;
  End;


Procedure SetDefaultZone(DZ : Word);
Begin
   DefaultZone := DZ;
End;


Procedure SetPathHudson(P: String);
begin
   PathHudson := P
end;


Procedure ParseAreasBbsLine(L: String; Var Tag, AreaId: String);
Var I: Integer;
    {$IFDEF VIRTUALPASCAL}
    Code: Longint;
    {$ELSE}
    Code: Word;
    {$ENDIF}
Begin
   I := pos(';',L);
   if I>0 then
      L[0] := chr(I-1);
   L := StripLead(L, ' ');
   I := pos(' ',L);
   if I>0 then
   begin
      AreaId := Upper(Copy(L,1,I-1));
      delete(L,1,I);
      L := StripLead(L, ' ');
      {subito il Tag, se e' valido processa l'AreaId}
      I := pos(' ',L);
      if I>0 then
         L[0] := chr(I-1);
      Tag := Upper(L);
      if (Tag='') or (Tag='!') then
      begin
         Tag := '';
         AreaId := ''
      end else
      begin
         Val(AreaId,I,Code);
         if (Code=0) then
         begin
            {era un numero, allora e' Hudson}
            if (PathHudson<>'') and (I>0) and (I<=200) then
            begin
               while length(AreaId)<3 do
                  AreaId := '0' + AreaId;
               AreaId := 'H' + AreaId + PathHudson
            end else
               AreaId := '';
         end else
         if AreaId[1]='$' then
         begin
            {Area Squish}
            AreaId[1] := 'S'
         end else
         if (AreaId[1]='J') and (AreaId[2]<>':') then
         begin
            {Area Jam}
            {va gia' bene, Non deve essere modificato}
         end else
         if (AreaId[1]='G') and (AreaId[2]<>':') then
         begin
            {Area Gold, non supportata}
            AreaId := '';
         end else
         begin
            {Fido Area}
            AreaId := 'F' + AreaId;
         end;
      end;
   end else
   begin
      Tag := '';
      AreaId := '';
   end;
end;


Function Tag2AreaId(Tag, PathAreasBbs:String):String;
Var
   Found : Boolean;
   VariText: Text;
   L, TempTag, TempAreaId: String;
Begin
   TempAreaId := '';
   if Tag<>'' then
   begin
      Tag := Upper(Tag);
      if PathAreasBbs='' then
         PathAreasBbs := DefaultPathAreasBbs;
      if shOpenTextFile(VariText,PathAreasBbs) then
      begin
         Found := False;
         while not found and not eof(VariText) do
         begin
            readln(VariText,L);
            ParseAreasBbsLine(L,TempTag,TempAreaId);
            found := TempTag=Tag;
         end;
         close(VariText);
      end;
   end;
   Tag2AreaId := TempAreaId;
end {Tag2AreaId};


Procedure SetDefaultPathAreasBbs(P: String);
begin
   DefaultPathAreasBbs := P
end;


End.
