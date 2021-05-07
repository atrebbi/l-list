
C:
cd \LLIST

set MAGVER=1
set MINVER=03

echo Const versione:string[16]='%MAGVER%.%MiNVER%';>MSGUTVER.DEF
        

Tpc Msgutil /EC:\VP\OUT /L /B /$G+
Copy c:\Vp\Out\msgutil.exe C:\LORA\msgutil\msgutil.exe

Call VpVio msgutil /B
Copy \Vp\Out\msgutil.Exe \Lora\msgutil\msgutilP.Exe

C:
cd \lora\msgutil

pkzip C:\lora\FNewArea\ldn\lora\msgut%MAGVER%%MINVER% msgutil?.exe msgutil.doc *.cfg file_id.diz

