
C:
cd \LLIST

set MAGVER=2
set MINVER=15

@echo Const > LLComp.Def
@echo     Versione: String[16] = 'v%MAGVER%.%MINVER%';>>LLcomp.Def
@echo     CompYear = '1993-96';>>LLComp.Def
@echo     CompDate = 'Compiled on 11-07-96';>>LLComp.Def
@echo     RegisteredOnly = True;>>LLComp.Def

Tpc LList /EC:\VP\OUT /L /B /$G+
Copy /b c:\Vp\Out\llist.exe + c:\Vp\Out\Llist.Ovr C:\LORA\LLIST\Llist.Exe

REM BpcOs2 LList /EC:\TEMP -CO /L /B
REM copy c:\temp\llist.exe d:\lora\llist\LListP.exe
Call VpVio LLIST /B
Copy \Vp\Out\Llist.Exe \Lora\Llist\LlistP.Exe

C:
cd \lora\llist

REM pkzip \lora\fnewarea\llist\llist\llst190d llist.exe whatsnew.200
REM pkzip \lora\fnewarea\llist\llist\llst190s llistp.exe whatsnew.200

REM \llist\bdiff llist.org llist.exe
REM \llist\bdiff llistp.org llistp.exe

REM copy llist.exe llist.org
REM copy llistp.exe llistp.org

zip llistcfg llist.cfg llistmsg.ita raid.hlp

REM pkzip C:\lora\FnewArea\llist\llistbdf\llst%MAGVER%%MINVER%u llist.bdf llistp.bdf whatsnew.210
del C:\lora\fnewarea\llist\llistexe\*.zip
zip C:\lora\FNewArea\llist\llistexe\llst%MAGVER%%MINVER%e llist.exe llistp.exe whatsnew.210 llistcfg.zip
REM llistp fixfbbs area 306-308
REM llistp hatch C:\lora\fnewarea\llist\llistbdf\llst%MAGVER%%MINVER%u.zip LLISTBDF
llistp hatch C:\Lora\fnewarea\llist\llistexe\llst%MAGVER%%MINVER%e.Zip LLISTBETA

