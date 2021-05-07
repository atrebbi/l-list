Unit LLMenu;

{$I Mkb.Def}

Interface

Function GetMenuKeys:String;

Implementation

Uses Tend;

Function GetMenuKeys:String;
Begin
   if Menu then
   {interpreta, mettendo le keys in GetMenuKeys};
   Case opzione(0) of
      1:begin {edit}
           case opzione(1) of
              1:begin {macro}
                   if Opzione(2)=11 then
                      GetMenuKeys := #0 + #84
                   else
                   if Opzione(2)=12 then
                      GetMenuKeys := #0 + #85
                   else
                      GetMenuKeys := #0 + chr(Opzione(2)+93);
                end;
              2:begin {pack}
                   GetMenuKeys := #0 + #25
                end;
              3:begin {extract file_id.diz}
                   GetMenuKeys := #0 + #23
                end;
              4:begin {increase dl}
                   GetMenuKeys := #0 + #120;
                end;
              5:begin {decrease dl}
                   GetMenuKeys := #0 + #121
                end;
              6:begin {toggle free}
                   GetMenuKeys := #0 + #33
                end;
              7:begin {delete line}
                   GetMenuKeys := #0 + #21
                end;
              8:begin {delete file}
                   GetMenuKeys := #0 + #32
                end;
           end;
        end;
      2:begin {tag}
           case opzione(1) of
              1:begin {tag/untag current}
                   GetMenuKeys := #0 + #20;
                end;
              2:begin {tag missing}
                   GetMenuKeys := #0 + #129
                end;
              3:begin {untag all}
                   GetMenuKeys := #0 + #22
                end;
              4:begin {move tagged}
                   GetMenuKeys := #0 + #62
                end;
              5:begin {Sort tagged}
                   GetMenuKeys := #0 + #61
                end;
              6:begin {Tag new files}
                   GetMenuKeys := #0 + #49
                end;
           end;
        end;
      3:begin {file}
           case opzione(1) of
               1:begin {save}
                    GetMenuKeys := #0 + #60
                 end;
               2:begin {exit editor}
                    GetMenuKeys := #27
                 end;
               else
                 GetMenuKeys := '';
           end;
        end;
      4:begin {tools}
           case opzione(1) of
              1:begin {external shell}
                   GetMenuKeys := #0 + chr(Opzione(2)+103);
                end;
              2:begin {check virus}
                   GetMenuKeys := #0 + #44
                end;
              3:begin {internal viewer}
                   GetMenuKeys := #0 + #47
                end;
              4:begin {look at files.bbs}
                   GetMenuKeys := #0 + #63
                end;
              5:begin {adopt orphans}
                   GetMenuKeys := #0 + #24
                end;
           end;
        end;
      5:begin {help}
           GetMenuKeys := #0 + #59
        end;
      else
        GetMenuKeys := '';
   end;


End {GetMenuKeys};



Begin

   {menu' per files.bbs editor}

   {Inizializzazione Menu'}
   {
   F1    = View this help                Ctrl-Y = delete current line
   F2    = Save Files.Bbs                F5    = Look at Files.Bbs
   F10   = Menu'
   Alt-V = View content                  Alt-I = Import File_Id.Diz
   Alt-P = Rewrap description            Alt-T = Tag/Untag current file
   Alt-0 = Tag missing files             Alt-U = Untag all files
   F4    = Move tagged files
   Alt-F = Toggle free time/Byte dl      Alt-D = Delete file and description
   Alt-S = Show status window            Alt-O = Adopt orphan files
   Alt-1/Alt-2 = Increase/Decrease dl    Alt-Z = Check for virus
   }

   Nomefile := 'LLIST';

   SetMenu(0,'edit/tag/file/tools/help f1');
   SetMenu(1,'macro{macro 1/macro 2/macro 3/macro 4/macro 5/macro 6/macro 7/macro 8/macro 9/macro 10/avatar code/ansi code}//'+
      'rewrap description//extract file_id.diz//increase dl/decrease dl//toggle free time-byte dl//delete line/delete file');
   SetMenu(2,'tag-untag current file/tag missing//untag all files//move tagged files f4'+
      '/sort&move tagged f3/tag new files');
   Setmenu(3,'save f2/exit editor');
   Setmenu(4,'external shell{shell 1/shell 2/shell 3/shell 4/shell 5/shell 6/shell 7/shell 8/shell 9/shell 10}/check virus'+
      '/internal viewer/look at files.bbs f5/adopt orphans');
   SetHotKey('help',1,5,0,0,0);
   SetHotKey('save',2,3,1,0,0);
   SetHotKey('look',5,4,4,0,0);
   SetHotKey('mtag',4,2,4,0,0);
   Sethotkey('smtag',3,2,6,0,0);

end.