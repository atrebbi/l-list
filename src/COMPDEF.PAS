{definisce i compattatori}
   inc(NPacker);
   New(Packer[NPacker]);
   Packer[NPacker]^.Ext := 'ZIP';
   {$IFDEF OS2}
   Packer[NPacker]^.Pack := 'ZIP -rk9E';
   Packer[NPacker]^.Unpack := 'UNZIP -Cdxo';
   Packer[NPacker]^.Delete := 'ZIP -d';
   {$ELSE}
   Packer[NPacker]^.Pack := 'PKZIP -a -r -p -wHS -)';
   Packer[NPacker]^.Delete := 'PKZIP -d -a -r -p -wHS -)';
   Packer[NPacker]^.UnPack := 'PKUNZIP -d -)';
   {$ENDIF}
   Packer[NPacker]^.Id := #$50#$4B#$03#$04;
   Packer[NPacker]^.OffSet := 0;

   inc(NPacker);
   New(Packer[NPacker]);
   Packer[NPacker]^.Ext := 'ARJ';
   {$IFDEF OS2}
   Packer[NPacker]^.Pack := 'ARJ a -a+ -r+ -y+ -jm1';
   Packer[NPacker]^.UnPack := 'ARJ x -y+ -jg+';
   Packer[NPacker]^.Delete := 'ARJ d -y+ -jg+';
   {$ELSE}
   Packer[NPacker]^.Pack := 'ARJ a -a+ -r+ -y+ -jm1';
   Packer[NPacker]^.UnPack := 'ARJ x -y+ -jg+';
   Packer[NPacker]^.Delete := 'ARJ d -y+ -jg+';
   {$ENDIF}
   Packer[NPacker]^.Id := #$60#$EA;
   Packer[NPacker]^.OffSet := 0;

   inc(NPacker);
   New(Packer[NPacker]);
   Packer[NPacker]^.Ext := 'LZH';
   {$IFDEF OS2}
   Packer[NPacker]^.Pack := 'LH a';
   Packer[NPacker]^.Delete := 'LH d';
   Packer[NPacker]^.UnPack := 'LH x';
   {$ELSE}
   Packer[NPacker]^.Pack := 'LHA a /a+ /r+ /x+';
   Packer[NPacker]^.UnPack := 'LHA x /a+';
   Packer[NPacker]^.Delete := 'LHA d /a+';
   {$ENDIF}
   Packer[NPacker]^.Id := #$2D#$6C#$68;
   Packer[NPacker]^.OffSet := 2;

   inc(NPacker);
   New(Packer[NPacker]);
   Packer[NPacker]^.Ext := 'RAR';
   {$IFDEF OS2}
   Packer[NPacker]^.Pack := 'RAR a -r -y -s -std';
   Packer[NPacker]^.UnPack := 'RAR x -r -y -std';
   Packer[NPacker]^.Delete := 'RAR d -r -y -std';
   {$ELSE}
   Packer[NPacker]^.Pack := 'RAR a -r -y -s -std';
   Packer[NPacker]^.UnPack := 'RAR x -r -y -std';
   Packer[NPacker]^.Delete := 'RAR d -r -y -std';
   {$ENDIF}
   Packer[NPacker]^.Id := #$52#$61#$72#$21#$1A;
   Packer[NPacker]^.OffSet := 0;

   inc(NPacker);
   New(Packer[NPacker]);
   Packer[NPacker]^.Ext := 'UC2';
   {$IFDEF OS2}
   Packer[NPacker]^.Pack := 'UC a -s';
   Packer[NPacker]^.UnPack := 'UC x -s -f';
   Packer[NPacker]^.Delete := 'UC d -s -f';
   {$ELSE}
   Packer[NPacker]^.Pack := 'UC a -s';
   Packer[NPacker]^.UnPack := 'UC x -s -f';
   Packer[NPacker]^.Delete := 'UC d -s -f';
   {$ENDIF}
   Packer[NPacker]^.Id := #$55#$43#$32#$1A;
   Packer[NPacker]^.OffSet := 0;

