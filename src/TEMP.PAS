notdv:

    { Do we have an EGA or VGA?  If so, and we are not in monochrome mode
       and we are not in DESQview then setup to draw a 'true' mouse cursor
       on an EGA/VGA }
    egavga := (vseg <> $b000) and (not desqview) and isegavga;

    if (egavga) then
    begin
      { We are going to use our 'true' mouse cursor and we need pixel
         resolution, not character resolution from the mouse driver
         (In text mode, the mouse driver only returns coordinates in multiples
         of 8, which we don't want.  We want multiples of 1, i.e. pixel
         resolution).  To get the mouse driver to return coordinates in pixel
         resolution, we 'trick' it into thinking it's in graphics mode by
         setting the low memory byte indicating mode to mode 6 (CGA 640x200x2).
         Then we reset the mouse driver.  The mouse driver will get the video
         mode then act as if it was in graphics mode, not text mode. }
      savevmode := mem[$40:$49];
      mem[$40:$49] := 6; { Does this work ?!?!?!?!? }

      { Reset driver for change in video mode to take effect. }
      asm
        sub ax,ax
        int 33h
      end;
      { Now that we've tricked the mouse driver into a grapics mode thereby
         causing it to give us pixel resolutions, put the old mode back. }
      mem[$40:$49] := savevmode;
    end;

    { Set up max x and y ranges. }

    maxx := mcols * 8 - 1; { Pixels horizontally }
    maxy := mrows * points - 1; { Pixels vertically }

    asm
      mov dx,[maxx]     { Pixels horizontally }
      mov ax,7        { mouse driver function 7 -- set max x range }
      sub cx,cx       { Minimum range }
      int 33h

      mov dx,[maxy]     { Pixels veritcally }
      mov ax,8        { mouse driver function 8 -- set max y range }
      sub cx,cx       { Minimum range }
      int 33h

    { Now install user routine }

      mov ax,cs
      mov es,ax
      mov dx, offset mousehandler
    { Setup up bits for calling routine }
      mov cx,LEFTBPRESS or LEFTBRELEASE or RIGHTBPRESS or RIGHTBRELEASE or MIDBPRESS or MIDBRELEASE or MOUSEMOVE;
      mov ax,12       { Function 12 -- set user routine }
      int 33h
    end;
    mousex := 0;
    mousey := 0;
    mousepx := 0;  { change by djm }
    mousepy := 0;  { change by djm }
    asm
      mov cx,[mousex]   { xcoord }
      mov dx,[mousey]   { ycoord }
      mov ax,4    { mouse driver function 4 -- set mouse position }
      int 33h
    end;
    MOUshow; { Call it twice just to make sure }

    dec(mousefreeze); { Handler can get into business, now }
  end
end;