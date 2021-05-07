Program ascii;

uses CRT;

var ch:char;

begin

   repeat
      ch := readkey;
      writeln(ord(ch));
   until (ch=#27);

end.
