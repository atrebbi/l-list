Program MakeReq;

Uses Dos;

var
    S:SearchRec;
    F: File;

begin
   FindFirst('*.Req', Archive + ReadOnly, S);
   While dosError = 0 do
   begin
      assign(F, Copy(S.Name, 1, pos('.', S.name)) + 'ILO');
      Rewrite(F);
      Close(F);
      FindNext(S);
   end;
end.
