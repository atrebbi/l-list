UNIT LLOVR;

{$DEFINE OVRXMS}

{$IFDEF OS2}
   'Errore, non serve con OS2'
{$ENDIF}

{$IFDEF DPMI}
   'Errore, non serve con DPMI'
{$ENDIF}


{$I LL.Def}

INTERFACE

USES   OVERLAY,                   { TURBO (tm) overlay manager unit    }
       DOS;                       { extended Pascal support            }

IMPLEMENTATION

{$IFDEF OVRXMS}
Const
  ovrNoXMSDriver = -7;                 { No XMS driver installed }
  ovrNoXMSMemory = -8;                 { Insufficient XMS memory available }

Procedure OvrInitXMS; External;
{$L OVERXMS.OBJ}
{$ENDIF}

BEGIN          { Initialization section }
   OvrInit(ParamStr(0));
   IF OvrResult <> OvrOk THEN
   begin
       RunError(OvrResult);
   end;
   {$IFDEF OVRXMS}
   OvrInitXms;
   if OvrResult<>OvrOk then
      OvrInitEms;
   {$ELSE}
   OvrInitEms;
   {$ENDIF}
   OvrSetRetry(OvrGetBuf div 3);
END.
