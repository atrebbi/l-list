
C:
cd \LLIST

set MAGVER=1
set MINVER=00

echo Const versione:string[16]='%MAGVER%.%MINVER%';>sc_Cdver.def

Tpc scan_cd /EC:\VP\OUT /L /B /$G+
Copy c:\Vp\Out\scan_cd.exe C:\LORA\scan_cd

Call VpVio scan_cd /B
Copy \Vp\Out\scan_cd.Exe \Lora\scan_cd\scan_cdP.Exe

C:
cd \lora\scan_cd

pkzip C:\lora\FNewArea\ldn\lora\sc_cd%MAGVER%%MINVER% scan_cd?.exe scan_cd.doc scan_cd.cfg file_id.diz

