
unit llmouse;

interface

{ Mouse information record }
type
  minforectype = record
    buttonstat : word;
    cx, cy : integer;
    isdouble : boolean;
    ticks: longint;
  end;

Const
  LEFTBPRESS     =2;
  RIGHTBPRESS    =8;
  MIDBPRESS      =32;

Function MOUPresent: Boolean;

{ Hide the mouse cursor }
procedure MOUhide;

{ Show the mouse cursor }
procedure MOUshow;

{ return TRUE if there are events waiting in the buffer. }
function MOUcheck:boolean;

{ get and remove next event from the buffer. }
procedure MOUget(var mouinforec:minforectype);

implementation

uses
  {$IFDEF VIRTUALPASCAL}
  os2base,
  {$ENDIF}
  Crt;

Const
{ Bit defines for mouse driver function 12 -- define handler. }
  MOUSEMOVE      =1;

const
  mousehidden    : boolean = TRUE;           { Is the mouse on? Additive flag }
  mouseinstalled : boolean = FALSE; { Is the mouse installed? }

var
  lastevent      : minforectype;

{$IFDEF VIRTUALPASCAL}
{$ELSE}
var
  Ticks : longint absolute $0040 : $006c;

const
  mousepx : Word = 0;
  mousepy : Word = 0;

const
  mousefreeze: integer = 0;           { Is mouse frozen in place? }

{$ENDIF}
Var
  OldExitProc: Pointer;

const
  MOUSEBUFFERSIZE = 16;
  mbufin : integer = 0;
  mbufout: integer = 0; { Mouse buffer pointers }
var
  mbuf : array [0..MOUSEBUFFERSIZE-1] of minforectype; { Mouse buffer }

{$IFDEF VIRTUALPASCAL}
Var
  hmou: word;
{$ENDIF}

Function MOUPresent: Boolean;
begin
   MOUPresent := MouseInstalled;
end;

{$IFDEF OS2}
{$ELSE}
{**********************************************}
{ 26-Oct-1990 - dk                             }
{                                              }
{  Mouse handler -- called from mouse driver.  }
{                                              }
{**********************************************}
{$S-} { Turn off stack checking }
procedure mousehandler; far;
{ This function is called whenever a button is pressed.  Do not call this
   function directly!!
}
var
  conditionmask:integer;
begin
  { Get our data segment }
  asm
    push ds
    push ax
    mov ax, seg @data
    mov ds, ax
    pop ax
    mov conditionmask,ax
    mov mousepx, cx
    mov mousepy, dx
  end;

  if (mousefreeze = 0) then
  begin
    if (conditionmask and MOUSEMOVE) = 0 then
    begin
       if (((mbufin + 1) mod MOUSEBUFFERSIZE) = mbufout) then
       begin { Buffer full? }
         sound(1760); { Make some noise. }
         delay(10);
         nosound;
       end else
       begin
         mbuf[mbufin].buttonstat := conditionmask;
         mbuf[mbufin].cx := mousepx div 8;
         mbuf[mbufin].cy := mousepy div 8;
         mbuf[mbufin].Ticks := Ticks;
         mbufin := (mbufin + 1) mod MOUSEBUFFERSIZE;
       end;
    end;
  end;
  asm
    pop ds;
  end;
end;
{$S+} { Turn on stack checking }
{$ENDIF}

{**************************}
{ 26-Oct-1990 - dk         }
{                          }
{  Hide the mouse cursor.  }
{                          }
{**************************}
procedure MOUhide;
{$IFDEF VIRTUALPASCAL}
Var
   Protectarea: NoPtrRect;
{$ENDIF}
{ This function turns off the mouse cursor, the mouse still responds
   to button presses }
begin
  if mouseinstalled and not mousehidden then
  begin
     {$IFDEF VIRTUALPASCAL}
     if MoucHeck then;
     ProtectArea.Col := 0;
     Protectarea.Row := 0;
     ProtectArea.cRow := 24;
     ProtectArea.cCol := 79;
     mouremoveptr(ProtectArea, hmou);
     {$ELSE}
     asm
       mov ax,3
       int 33h
       mov cx, [mousepx]
       mov dx, [mousepy]
       mov ax,2
       int 33h
       sub ax,ax
       int 33h
     end;
     {$ENDIF}
     mousehidden := true; { indicate it's hidden now }
  end;
end;

{**************************}
{ 26-Oct-1990 - dk         }
{                          }
{  Show the mouse cursor.  }
{                          }
{**************************}
procedure MOUshow;
  {$IFDEF VIRTUALPASCAL}
var
  mouloc: ptrloc;
  {$ENDIF}
begin
  if mouseinstalled and mousehidden then
  begin
     mousehidden := false;
     {$IFDEF OS2}
     mouflushque(hmou);
     moudrawptr(hmou);
     {$ELSE}
     inc(mousefreeze); { Make sure handler doesn't do things, yet }
     asm
       mov cx,[mousepx]   { xcoord }
       mov dx,[mousepy]   { ycoord }
       mov ax,4        { mouse driver function 4 -- set mouse position }
       int 33h
       mov ax,cs
       mov es,ax
       mov dx, offset mousehandler
       mov cx,LEFTBPRESS or RIGHTBPRESS or MIDBPRESS or MOUSEMOVE;
       mov ax,12       { Function 12 -- set user routine }
       int 33h
       mov ax,1        { Function 1 -- mouse visibile }
       int 33h
     end;
     dec(mousefreeze); { Reactivate handler }
     {$ENDIF}
  end;
end;

{***********************************************************}
{ 27-Oct-1990 - dk                                          }
{                                                           }
{  Returns true if there is something in the mouse buffer.  }
{                                                           }
{***********************************************************}
function MOUcheck:boolean;
{$IFDEF VIRTUALPASCAL}
var
   MouseQInfo: MouQueInfo;
   WaitFlag: Word;
   Event: MouEventInfo;
   I: Word;
{$ENDIF}
begin
  if not mouseinstalled then
  begin
     MouCheck := false;
  end else
  begin
     {$IFDEF OS2}
     MouGetNumQueEl(MouseQInfo, hmou);
     WaitFlag := mou_noWait;
     for I := 1 to MouseQInfo.cevents do
     begin
        if moureadeventque(Event, waitFlag, hmou)=0 then
        begin
           case event.fs of
              mouse_bn1_down:
              begin
                 if (((mbufin + 1) mod MOUSEBUFFERSIZE) = mbufout) then
                 begin { Buffer full? }
                   playsound(1760, 10); { Make some noise. }
                 end else
                 begin
                   mbuf[mbufin].buttonstat := LEFTBPRESS;
                   mbuf[mbufin].cx := event.col;
                   mbuf[mbufin].cy := event.row;
                   mbuf[mbufin].Ticks := event.time div 55;
                   mbufin := (mbufin + 1) mod MOUSEBUFFERSIZE;
                 end;
              end;
              mouse_bn2_down:
              begin
                 if (((mbufin + 1) mod MOUSEBUFFERSIZE) = mbufout) then
                 begin { Buffer full? }
                   playsound(1760, 10); { Make some noise. }
                 end else
                 begin
                   mbuf[mbufin].buttonstat := RIGHTBPRESS;
                   mbuf[mbufin].cx := event.col;
                   mbuf[mbufin].cy := event.row;
                   mbuf[mbufin].Ticks := event.time div 55;
                   mbufin := (mbufin + 1) mod MOUSEBUFFERSIZE;
                 end;
              end;
              mouse_bn3_down:
              begin
                 if (((mbufin + 1) mod MOUSEBUFFERSIZE) = mbufout) then
                 begin { Buffer full? }
                   playsound(1760, 10); { Make some noise. }
                 end else
                 begin
                   mbuf[mbufin].buttonstat := MIDBPRESS;
                   mbuf[mbufin].cx := event.col;
                   mbuf[mbufin].cy := event.row;
                   mbuf[mbufin].Ticks := event.time div 55;
                   mbufin := (mbufin + 1) mod MOUSEBUFFERSIZE;
                 end;
              end;
           end;
        end;
     end;
     {$ENDIF}
     MOUcheck := mbufin <> mbufout;
  end;
end;

{**************************************************************}
{ 26-Oct-1990 - dk                                             }
{                                                              }
{  Get (and remove) the mouse event at the head of the queue.  }
{                                                              }
{**************************************************************}
procedure MOUget(var mouinforec:minforectype);
{$IFDEF VIRTUALPASCAL}
var
    mouptr: ptrloc;
{$ENDIF}
begin
  if (not mouseinstalled) then
    exit;
  if (mbufin <> mbufout)
    {$IFDEF VIRTUALPASCAL}
       or MouCheck
    {$ENDIF}
    then
  begin { if something is in buffer }
    if (@mouinforec <> nil) then
      mouinforec := mbuf[mbufout];
    mbufout := (mbufout + 1) mod MOUSEBUFFERSIZE;
    MouInfoRec.IsDouble :=
     (MouInfoRec.Ticks - LastEvent.Ticks <= 5) and
     (MouInfoRec.cx = LastEvent.cx) and
     (MouInfoRec.cy = LastEvent.cy) and
     (MouInfoRec.buttonstat = LastEvent.buttonstat) and
     not LastEvent.IsDouble;
    Lastevent := mouinforec;
  end else
  begin
    { Nothing to pull, just report mouse position }
    {$IFDEF VIRTUALPASCAL}
    MouGetPtrPos(mouptr, hmou);
    mouinforec.cx := mouptr.col;
    mouinforec.cy := mouptr.row;
    {$ELSE}
    asm
      mov ax,3
      int 33h
      mov cx, [mousepx]
      mov dx, [mousepy]
    end;
    mouinforec.cx := mousepx div 8;
    mouinforec.cy := mousepy div 8;
    {$ENDIF}
    mouinforec.buttonstat := 0;
    mouinforec.isdouble := false;
  end;
end;

Procedure NewExitProc; Far;
begin
  ExitProc := OldExitProc;
  MOUhide;
  {$IFDEF VIRTUALPASCAL}
  if MouseInstalled then
     mouclose(hmou);
  {$ENDIF}
end;

begin
  OldExitProc := ExitProc;
  ExitProc := @NewExitProc;
  lastevent.cx := 0;
  lastevent.cy := 0;
  lastevent.isdouble := false;
  lastevent.buttonstat := 0;
  {$IFDEF OS2}
  MouseInstalled := MouOpen(Nil, hmou) = 0;
  {$ELSE}
  asm
    sub ax,ax;    { Mouse driver function 0 -- reset and detect }
    int 33h
    mov mouseinstalled, AL;
  end;
  {$ENDIF}
end.


