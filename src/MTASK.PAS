Unit MTask;

{$I LL.DEF}

Interface

Const
   Dos = 0;
   Dv  = 1;
   Win = 2;
   Os2 = 3;

Var
   Ops: Byte;

Procedure Sleep;

Implementation

{$IFDEF OS2}
uses
   os2base;

Procedure Sleep;
begin
   dossleep(55);
end;

{$ELSE}
Uses
   Crt;

PROCEDURE Sleep; Assembler; {Gives up remainder of clock cycle
                                 under dos, windows, os/2 }
  asm
    CMP ops,dos { Compare to DOS }
    JE @MSDOS    { Jump if = }
    CMP ops,dv   { Compare to Desqview }
    JE @DESQVIEW { Jump if = }
    CMP ops,win { Compare to Windows }
    JE @WINOS2   { Jump if = }
    CMP ops,os2 { Compart OS/2 }
    JE @WINOS2   { Jump if = }
    JMP @NONE    { None found, Jump to End }

 @MSDOS:
    INT 28h   { Interupt 28h }
    JMP @NONE { Jump to the end }

 @DESQVIEW:
    MOV ax,1000h { AX = 1000h }
    INT 15h      { Call Interupt 15h }
    JMP @NONE    { Jump to the end }

 @WINOS2:
    MOV AX, 1680h { AX = 1680h }
    INT 2Fh       { Call Interupt 2Fh for Win-OS/2 TimeSlice }

 @NONE:
end;
{$ENDIF}

{$IFDEF OS2}
{$ELSE}
PROCEDURE checkos; Assembler;
{ Currently Supports DesqView, Microsoft Windows and IBM's OS/2 }

asm
  mov ops, dos { Default DOS }
  mov ah, 30h   { AH = 30h }
  int 21h  { dos version }
  cmp al, 14h
  jae @IBMOS2 { Jump if >= to 20 }


  mov ax,2B01h
  mov cx,4445h
  mov dx,5351h
  int 21h { Desqview Installed? }
  cmp al, 255
  jne @DesqView { Jump if AL <> 255 }

  mov ax,160Ah
  int 2Fh { Windows Install?}
  cmp ax, 0h
  je @Windows { If = Jump to Windows }
  jmp @Finish { Nothing found, go to the end }

@IBMOS2:
  mov Ops,os2  { Set OS Value }
  jmp @Finish

@DesqView:
  mov ops,dv   { Set OS Value }
  jmp @Finish

@Windows:
  mov ops,win  { Set OS Value }
  jmp @Finish

@FINISH:
end; { checkos }

{$ENDIF}

begin
   {$IFDEF OS2}
   Ops := Os2;
   {$ELSE}
   CheckOs;
   {$ENDIF}
end.
