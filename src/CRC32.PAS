UNIT crc32;

{$I MKB.Def}


INTERFACE
{ Use a type LONGINT variable to store the crc value.                     }
{ Initialise the variable to $FFFFFFFF before running the crc routine.    }
{ VERY IMPORTANT!!!! -> This routine was developed for data communications}
{ and returns the crc bytes in LOW to HIGH order, NOT byte reversed!      }
{ To turn the valu into a 'normal' LONGINT, you must reverse the bytes!   }
{ e.g.                                                                    }
{ VAR                                                                     }
{    l, crc: LONGINT;                                                     }
{    list: ARRAY[0..1023] OF BYTE;                                        }
{    counter: INTEGER;                                                    }
{                                                                         }
{ BEGIN                                                                   }
{    crc := $FFFFFFFF;                           (* initialise  *)        }
{    FillChar(list,SizeOf(list),1);              (* dummy array *)        }
{    FOR counter := 0 TO (Pred(SizeOf(list))) DO (* run thru    *)        }
{       crc := UpdC32(buf[counter],crc);         (* finding crc *)        }
{    FOR counter := 1 TO 4 DO                    (* reverse     *)        }
{       l := (l SHL 8) OR BYTE(crc);             (* the bytes   *)        }
{    (* l now contains the 'normalized' crc *)                            }
{                                                                         }

Const
  CrcSeed: longint = $FFFFFFFF;

FUNCTION UpdC32(octet: BYTE; crc: LONGINT) : LONGINT;
FUNCTION UpdC32Block(VAR Block; BlockLen: Word; crc: LONGINT) : LONGINT;

IMPLEMENTATION
(* Converted to Turbo Pascal (tm) V4.0 March, 1988 by J.R.Louvau       *)
(* Copyright (C) 1986 Gary S. Brown.  You may use this program, or     *)
(* code or tables extracted from it, as desired without restriction.   *)
(*                                                                     *)
(* First, the polynomial itself and its table of feedback terms.  The  *)
(* polynomial is                                                       *)
(* X^32+X^26+X^23+X^22+X^16+X^12+X^11+X^10+X^8+X^7+X^5+X^4+X^2+X^1+X^0 *)
(* Note that we take it "backwards" and put the highest-order term in  *)
(* the lowest-order bit.  The X^32 term is "implied"; the LSB is the   *)
(* X^31 term, etc.  The X^0 term (usually shown as "+1") results in    *)
(* the MSB being 1.                                                    *)
(*                                                                     *)
(* Note that the usual hardware shift register implementation, which   *)
(* is what we're using (we're merely optimizing it by doing eight-bit  *)
(* chunks at a time) shifts bits into the lowest-order term.  In our   *)
(* implementation, that means shifting towards the right.  Why do we   *)
(* do it this way?  Because the calculated CRC must be transmitted in  *)
(* order from highest-order term to lowest-order term.  UARTs transmit *)
(* characters in order from LSB to MSB.  By storing the CRC this way,  *)
(* we hand it to the UART in the order low-byte to high-byte; the UART *)
(* sends each low-bit to hight-bit; and the result is transmission bit *)
(* by bit from highest- to lowest-order term without requiring any bit *)
(* shuffling on our part.  Reception works similarly.                  *)
(*                                                                     *)
(* The feedback terms table consists of 256, 32-bit entries.  Notes:   *)
(*                                                                     *)
(*     The table can be generated at runtime if desired; code to do so *)
(*     is shown later.  It might not be obvious, but the feedback      *)
(*     terms simply represent the results of eight shift/xor opera-    *)
(*     tions for all combinations of data and CRC register values.     *)
(*                                                                     *)
(*     The values must be right-shifted by eight bits by the "updcrc"  *)
(*     logic; the shift must be unsigned (bring in zeroes).  On some   *)
(*     hardware you could probably optimize the shift in assembler by  *)
(*     using byte-swap instructions.                                   *)
(*     polynomial $edb88320                                            *)
(*                                                                     *)


var
  crc_32_tab: ARRAY[byte] OF LONGINT;

FUNCTION UpdC32(octet: BYTE; crc: LONGINT) : LONGINT;
BEGIN { UpdC32 }
   updC32 := crc_32_tab[lo(crc) xor octet] xor (crc shr 8);
END;

FUNCTION UpdC32Block(VAR Block; BlockLen: Word; crc: LONGINT) : LONGINT;
Var
   Blk: Array[1..1] of byte absolute block;
   i: Word;
BEGIN { UpdC32 }
   for I := 1 to Blocklen do
      crc := crc_32_tab[lo(crc) xor blk[i]] xor (crc shr 8);
   UpdC32Block := crc;
END;

Procedure makeCRC32table;
Var
  crc : LongInt;
  i,n : Word;
begin
  For i := 0 to 255 do
  begin
    crc := i;
    For n := 1 to 8 do
      if odd(crc) then
        crc := (crc shr 1) xor $EDB88320
      else
        crc := crc shr 1;
    crc_32_tab[i] := crc;
  end;
end;

begin
   makecrc32table;
END. {unit}

