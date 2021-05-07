{****************************************************************************
 * PROJECT:  Mouse routines with 'real' graphic cursor in text mode.
 *****************************************************************************
 * MODULE:  PTEST.PAS
 *****************************************************************************
 * DESCRIPTION:
 *   Test program - translation of TEST.C to Turbo Pascal
 *
 *
 *****************************************************************************
 * MODIFICATION NOTES:
 *    Date     Author Comment
 * 26-Oct-1990   dk   Initial file.
 * 07-Jan-1991   dk   Fixed bugs and set up for release to Usenet.
 * 09-Jan-1991   dm   Translated to TP; uses direct writes instead of ANSI
 * 27-Jan-1991   dk   Cleaned up the translation.
 *****************************************************************************
 *
 * DISCLAIMER:
 *
 * Programmers may incorporate any or all code into their programs,
 * giving proper credit within the source. Publication of the
 * source routines is permitted so long as proper credit is given
 * to Dave Kirsch.
 *
 * Copyright (C) 1990, 1991 by Dave Kirsch.  You may use this program, or
 * code or tables extracted from it, as desired without restriction.
 * I can not and will not be held responsible for any damage caused from
 * the use of this software.
 *
 *****************************************************************************
 * This source works with Turbo Pascal 6.0
 ****************************************************************************}

uses
  Crt,
  llMouse;

var
  m : minforectype;

const
  oldmx : integer = -1;
  oldmy : integer = -1;

begin

  clrscr; { Clear the screen. }

  gotoxy(1,5);  write('Click here [þ] with left mouse button to quit.');
  gotoxy(1,7);  write('Mouse routine demonstration program [Turbo Pascal 6.0 Version].');
  gotoxy(1,8);  write('With ''true'' EGA/VGA mouse cursor.');
  gotoxy(1,9);  write('Copyright (C) 1990, 1991 by Dave Kirsch [a563@mindlink.UUCP].');
  gotoxy(1,10); write('Pascal translation by Duncan Murdoch [dmurdoch@watstat.waterloo.edu].');



  repeat
    moushow;
    while not moucheck do;
    mouhide;
      MOUget(m);
      if (m.buttonstat and LEFTBPRESS) <> 0 then
      begin
        gotoxy(1,2);
        write('Left button pressed at  ',m.cx:3,', ', m.cy:3);
      end;
      if (m.buttonstat and RIGHTBPRESS) <> 0 then
      begin
        gotoxy(1,3);
        write('Right button pressed at  ',m.cx:3,', ', m.cy:3);
      end;
      if (m.buttonstat and MIDBPRESS) <> 0 then
      begin
        gotoxy(1,4);
        write('Middle button pressed at  ',m.cx:3,', ', m.cy:3);
      end;

      if ((m.buttonstat and LEFTBPRESS) <> 0)
         and (m.cx > 11) and (m.cx < 14) and (m.cy = 4) then
      begin
        clrscr; { Clear the screen. }
        halt;
      end;

  until false;
end.
