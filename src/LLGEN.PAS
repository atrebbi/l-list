Unit LLGEN;

Interface

{$I LL.Def}

Uses
     {$IFDEF VIRTUALPASCAL}
     Os2Base,
     {$ENDIF}

     MTask,
     Dos, Crt,

     MkMisc, MkGlobT,
        MkFile,

     LLErrMsg,

     MkString, LLMouse;

{$I LLComp.Def}

const

     NMaxllistAlias = 16;
     FrameChars : String[6] = 'อบษปศผ';
     ColorID: String[2]=#22#1;
     TicSend=1;
     TicReceive=2;
     BytesMonthDefault=512*1024;

     {$IFDEF NO4350}
     BiosRows:Byte=24;
     {$ENDIF}

     Autore='Alessandro Trebbi';
     NMaxTicGroups = 1024;
     NMaxTicNodes  = 1024;
     NMaxTicAreas  = 1024;
     NMaxPackers   = 127;
     NMaxOutBound  = 32;
     NMaxDescribe  = 1024;
     ML:Longint=65535;

     LenRead1:Word=19000 div 19 * 19; {Multiplo di 19}
     SizeTxtBuf:Word=8192;
     MaxBest=50;

     NMaxAka=50;
     NMsgAree=32;
     NMaxAnnounce=128;
     NMaxFileList=16;
     NMaxSearch=8;
     NMaxMagic=64;
     NMaxExclude=64;
     MonthStr:array[0..12,1..3] of char=
      ('???','Jan','Feb','Mar','Apr','Maj','Jun','Jul','Aug','Sep','Oct','Nov','Dec');
     NStr:Array[0..99,1..2] of Char=(
       '00','01','02','03','04','05','06','07','08','09',
       '10','11','12','13','14','15','16','17','18','19',
       '20','21','22','23','24','25','26','27','28','29',
       '30','31','32','33','34','35','36','37','38','39',
       '40','41','42','43','44','45','46','47','48','49',
       '50','51','52','53','54','55','56','57','58','59',
       '60','61','62','63','64','65','66','67','68','69',
       '70','71','72','73','74','75','76','77','78','79',
       '80','81','82','83','84','85','86','87','88','89',
       '90','91','92','93','94','95','96','97','98','99');
       FrameHdr1=' ฐฐฐฐฐฑฑฑฑฑฒฒฒฒฒÛÛÛÛÛ ';
       FrameHdr2=' ÛÛÛÛÛฒฒฒฒฒฑฑฑฑฑฐฐฐฐฐ ';

       HdrStr='ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป';
       FtrStr='ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ';
       Afa2Str='วฤฤฤฤฤยฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤาฤฤฤฤฤยฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤถ';
       Afa3Str='ศอออออฯออออออออออออออออออออออออออออออออสอออออฯออออออออออออออออออออออออออออออออผ';
       AfaL2Str='วฤฤฤฤฤยฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤถ';
       AfaL3Str='ศอออออฯอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ';
       Ok2Str='วฤฤฤฤฤฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤถ';
       Ok3Str='ศออออออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ';


Type
     LlistStatusType=(Unselected,FileIdx,Raidprocess,
       TicProcess,Announce,MakeSearch,
       FixFBbs,MakeListCmp,
       MakeListSum, CDMakeListSum,
       EditFilesBbs,HatchFile,
       LListEnd);

     DescTypePtr=^DescType;
     DescType=Record
                 Descrizione:^String;
                 Next:DescTypePtr
              End;

     StringRef=^String;
     BbsType=(Lora,Sbbs,Max300,Qbbs,PcBoard,Max,RA250,Unknown);
     SortType=(No,Alfa,Date);
     SetDataTypeRef=^SetDataType;
     SetDataType=Record
        Position,DataType:Byte;
        Next:SetDataTypeRef
     end;
     LogLevel=(LogError,LogStart,LogWork,LogDone);
     DupesType=Record
        Name:String[36];
        Address:AddrType;
        Keyword:String[80];
        Time:Longint;
        LastArea:Integer;
     end;
     ColourType=(ColDef,ColFrame,ColBdlFRame,ColFrameIn,ColName,ColSizeU,
        ColSizeC,ColInfo);

     ListaNumRef=^ListaNum;
     ListaNum=Record
                  Num1,Num2:Integer;
                  Next:ListaNumRef
               end;
     ScanMsgAreaType=Record
                AreaId1,AreaId2,MsgOrigin:PathStr;
                Aree:ListaNumRef;
                Suffix,Prefix:DescTypePtr;
                MaxBytesUUEncode:Word;
                NoIbm,SearchDb:Boolean;
             End;
     PackerType=Record
                Ext:String[3];
                Pack, Unpack, Delete:PathStr;
                Offset: LongInt;
                Id:String
             End;

     SearchStringTypeRef=^SearchStringType;
     SearchStringType=Record
                  LenCurrent:byte;
                  KeyWord:Array[1..20] of set of char;
                  Booyer:Array[Byte] of Byte;
                  PreQM,PostQM,LenOther:Byte;
                  Next:SearchStringTypeRef;
                end;
     SearchTypeRef=^SearchType;
     SearchType=Record
                  IsPath, Fixed, Continues, Negative:Boolean;
                  SearchString: SearchStringTypeRef;
                  AndSearch:SearchTypeRef;
                  Len:Byte;
                End;

     AnnounceType=Record
                {Tag:String[8];}
                {LastDate: LongInt;}
                {MsgAddress: integer;}
                MsgFrom,MsgTo: String[36];
                MsgSubject,MsgOrigin: String[80];
                KludgeFdn:NameStr;
                Suffix,Prefix:DescTypePtr;
                NoIbm,Vc,FirstTime:Boolean;
                Aree:ListaNumRef;
                CC, XC: DescTypePtr;
                Filter: DescTypePtr;
             end;
     BestType=Record
                Nome:String[12];
                DownLoad:Integer;
                Descrizione:String;
              end;
     AllBestType=Array[1..MaxBest] of BestType;

     CharType=array[1..1] of char;
     ByteType=Array[1..1] of byte;

     FlagType=Array[1..4] of byte;

     CharNome=Array[1..12] of char;
     IdxType=record
           Nome:CharNome;
           Inutile:Char;
           Area:Integer;
           Ignora:Array[1..4] of char;
        end;
     Recs=Array[0..0] of IdxType;

     TicNodeType=Record
           Node:AddrType;
           Pw:String;
           RemoteMaint, SendAnnounce,
              SendTic, Notify, TinySeenBy, RequireUplink:Boolean;
           Flavour:Char;
           Packer:String[3];
           TicLevel:Word;
           RequireTicAreas:DescTypePtr;
           RequireTicAreasRef:^DescTypePtr;
           MaxfileSize: Longint;
        end;

     AddrListTypeRef=^AddrListType;
     AddrListType=Record
           Node:AddrType;
           Mode:Byte;
           Next:AddrListTypeRef;
        end;

     OutBoundTypeRef=^OutBoundType;
     OutBoundType=Record
           Zone:Word;
           OutBound:StringRef
        End;

     TicAreaType=Record
           Tag,SecTag:String[20];
           Group:NameStr;
           AreaDesc:String;
           Number:Integer;
           Nodes:AddrListTypeRef;
           Download,PathFBbs:PathStr;
           TicLevel:Word;
           Address:Integer;
           Mode:Byte;
           Repack:String[3];
           BytesMonth:Longint;
           ReadFile_id: boolean;
        end;

     TicGroupType=Record
           Tag:NameStr;
           GroupId:DescTypePtr;
           TicLevel:Word;
           Address:Integer;
           Nodes:AddrListTypeRef;
           Aree:ListaNumRef;
           UplinkNode:Integer;
        end;

     FileListType=Record
           PathNew, PathAll, PathBdl, PathAvail, KludgeFdn: PathStr;
           Aree: ListaNumRef;
           RemoveUncompressed, CD: Boolean;
           MaxBest1: Word;
           PathHdr, PathFtr: DescTypePtr;
        end;

     DescribeType=Record
           Name: String[12];
           Desc: String;
     End;

     RaidFwdType=Record
         Tag:String[20];
         Time:Longint;
         Received:Boolean;
         Node:AddrType;
         Rsvd:Array[1..64]of char;
     end;

     AreaFileLoraType=Array[1..1] of Record
        Nome: Array[1..70] of char;     { Titolo area file                          }
        Numero: Integer;         { Numero area file                          }
        uppath: Array[1..40] of char;        { Path di Upload                            }
        PathDown: Array[1..40] of char;      { Path di Download                          }
        PathFBbs: Array[1..50] of char;      { CD-ROM list file name                     }
        Attr: Byte;
                                   { BIT
                                     1: Download illimitato
                                     2: norm_req
                                     3: know_req
                                     4: prot_req
                                     5: Non effettuare l'annucio di nuovi file
                                     6: Area non inserita nella ricerca globale fil
                                     7: no_filedate
                                     8: Lettura ristretta al gruppo di appartenenza
                                   }
        Gruppo: Word;            { Gruppo di appartenenza 0 = nessuno        }
        Lev: Byte;           { Minimum level to access this area         }
        FlagLev: FlagType;       { Flags settings                            }
        LevDown: Byte;       { Minimum level to download files           }
        FlagLevDown: FlagType;   { Flags settings                            }
        LevUp: Byte;         { Minimum level to upload files             }
        FlagLevUp: FlagType;     { Flags settings                            }
        list_priv: Byte;           { ???                                       }
        list_flags:FlagType;       { ???                      }
        fill: array[1..10] of Byte;
        short_name: Array[1..13] of char;    { Nome breve area                           }
        fill1: array[1..8] of Byte;
        tic_tag: Array[1..32] of char;
        tic_forward1,
        tic_forward2,
        tic_forward3: String[79];
        tic_level: Byte;
        tic_flags: LongInt;
        CdRom: Byte;
                                   { BIT
                                     1: CDRom area
                                     2:
                                     3:
                                     4:
                                     5:
                                     6:
                                     7:
                                     8:  }
        fill2: array[1..106] of Byte;
    end;


    AreaFileSBBSType  =Array[1..1] of  Record
         Nome:               String[60];
         PathDown:           String[79];
         Lev:                Integer;
         Flags:              Flagtype;
         PFilesSec:          Integer;   { Not yet used }
         PFlags:             Flagtype;  { Not yet used }
         Attrib:             Byte;
         Age:                Byte;
         PathFBBS:           String[67];    (* If begins with *
                                               character then the
                                               rest of the string
                                               shows the upload
                                               path *)
         ExtraSpace:         Array[1..30] of Byte;
       End;

    AreaFileMaxType= Record
       ID:LongInt;
       Struct_Len,Numero:Word;
       {parte messaggi}
       ignora:array[9..398] of char;
       {parte files}
       PathDown,UpPath,FileBar,PathFBbs,Nome:Array [1..80] of char;
       Lev:ShortInt;
    end;

    AreaFileMax300Type= Record
    {
      word cbArea;          /* Length of THIS INDIVIDUAL RECORD                0*/
      word num_override;    /* Number of overrides following this record       2*/
      word cbHeap;          /* Length of the zstr heap following the overrides 4*/
      word division;        /* Reserved for future use                         6*/

      zstr acs;             /* Access control string for this area             8*/
      zstr name;            /* String format of area's name.                  10*/
      zstr downpath;        /* Path for downloads.                            12*/
      zstr uppath;          /* Path for uploads                               14*/
      zstr filesbbs;        /* Path to FILES.BBS-like catalog for this area   16*
                  * (For FA_DIVBEGIN only, also used as name of      *
                  * custom .bbs display file.)                       */
      zstr descript;        /* The DIR.BBS-like description for file section  18*/
      zstr menuname;        /* Custom menu for this file area                 20*/
      zstr menureplace;     /* Replace this menu name with menuname from above22*/
      zstr barricade;       /* Barricade file                                 24*/
      zstr barricademenu;   /* Barricade file                                 26*/
      sdword cbPrior;       /* Offset to prior area                           28*/
      word attribs;         /* Attributes for this file area                  32*/
      sword date_style;     /* Date style override for this area              34*/
      byte rsvd1[28];       /* Reserved by Maximus for future use             36*/
    }
      cbArea, num_override, cbHeap, division,
         acs, name, downpath, uppath, filesbbs, descript, menuname,
         menureplace, barricade, barricademenu: word;
      cbPrior: Longint;
      attribs: word;
      date_style: integer;
      rsvd1: array[1..28] of byte
    end;

    SecurityRecord = Record
      Security : Word;
      Flags    : FlagType;
    End;

    AreaFileQBbsType =Array[1..1] of  Record (* FILECFG.DAT *)
       Nome,
       PathDown,
       PathFBbs    : String[66];
       AllowUploads,
       IgnoreKlimit,
       IgnoreRatio : Boolean;
       DlSec       : SecurityRecord;
       SearchSec   : SecurityRecord;
       TemplateSec : SecurityRecord;
       Spare       : Array[1..12] of Byte;
    End;

    AreaFilePCBoardType=Array[1..1] of Record
       PathFBbs, PathDown: Array[1..30] of char;
       Nome: Array[1..35] of char;
       SortType: Byte
    End;

    AreaFileRA250Type=Array[1..1] of Record
                     AreaNum,
                     Unused         : Word;
                     Name           : String[40];
                     Attrib         : Byte;

                      { Bit 0 : Include in new files scan
                            1 : Include in upload dupe scan
                                                        2 : Permit long descriptions
                            3 : Area is on CD-ROM
                            4 : All files are FREE
                            5 : Allow DLs not in FDB
                            6 : Allow users to password uploads
                            7 : Scan uploads }

                     FilePath       : String[40];
                     KillDaysDL,
                     KillDaysFD     : Word;
                     Password       : String[15];
                     MoveArea       : Word;
                     Age,
                     ConvertExt     : Byte;
                     Group          : Word;
                     Attrib2        : Byte;

                      { Bit 0 : Include in all groups }

                     DefCost,
                     UploadArea,
                     UploadSecurity : Word;
                     UploadFlags,
                     UploadNotFlags : FlagType;
                     Security       : Word;
                     Flags,
                     NotFlags       : FlagType;
                     ListSecurity   : Word;
                     ListFlags,
                     ListNotFlags   : FlagType;
                     AltGroup       : Array[1..3] of Word;
                     Device         : Byte;
                     FreeSpace      : Array[1..13] of Byte;
                   end;

     FileInfoPtr=^FileInfo;
     FileInfo=Record
                 Nome:String[12];
                 Time,Size:Longint;
                 DownLoad:Integer;
                 Descrizione:DescTypePtr;
                 New,Excluded,Dupes,FreeDlTime,FreeDlByte,
                    Tagged:Boolean;
                 NList:Integer;
                 Bal:-1..+1;
                 Sx,Dx:FileInfoPtr;
              End;
     ListaPtrRef=^ListaPtr;
     ListaPtr=^Lista;
     Lista=Record
              FileInfo:FileInfoPtr;
              Bal:-1..+1;
              Sx,Dx:ListaPtr
           End;


Const
     BbsConfigName:Array[BbsType] of String[12]=
       ('SysFile.Dat','FlSearch.Bbs','FArea.Dat',
        'FileCfg.Dat','PCBoard.Dat','Area.Dat','Files.Ra','');
     NormVideoCol: Byte=30;
     InvVideoCol:  Byte=112;
     HighVideoCol: Byte=62;
     LowVideoCol:  Byte=24;
     FBbsLen: integer=255;

Var

     StartMode: Word;
     CdRoms:String[26];
     AppExt:ExtStr;
     Tz:String;
     CurrDayOfWeek:Word;
     MaxLenDesc:Byte;
     StartMaxArea:Pointer;

     StartTime:LongInt;

     StartAttr:Byte;

     Ch:Char;

     {$IFDEF VIRTUALPASCAL}
     FileAreaToRead, FileAreaInBuffer:Longint;
     {$ELSE}
     FileAreaToRead, FileAreaInBuffer:Word;
     {$ENDIF}

     AllFilesSize:Longint;

     AreaPosBuffer:LongInt;
     {LastDateFile:File;
     Lastdate:LastDateType;}

     LdChar:String;

     NumCol:Array[ColourType] of Byte;
     AnsiCol:Array[ColourType] of string[20];

     Best:^AllBestType;

     NewDays,
        SizeAreaFile: Word;

     Code, TempWord: Word;

     D0,LoraDir,DirIn,TempDir,DirNewAreas,
        DirBadFiles,DirInfectedFiles:DirStr;

     Inbound:DescTypePtr;

     PrevMsgId:String[8];

     I,J,K,NExclude,NExcludeAnnounce,HdrStyle,Gruppo,NMagic,
        Colonne,Numero,Attr,
        NStringSearch,CurrMsgArea,NAka,NAnnounce,CurrAnnounce,
        Linea,SearchMaxFiles,SearchMaxFiles1,MinLenSearchStr,MsgHdrStyle,
        FixFBbsHdrStyle,NSearch,PrevNumero,Copied,
        MaxBest1,DcLen,NAree, NTicNodes, NTicAreas, NTicGroups,
        MaxFile_IdLines, NumberCopy, ChangeArea,
        RepackPerc,NOutBound, NFileList, CurrFileList,
        LastNumero, ExtDescPos, NDescribe, NLlistAlias:Integer;

     OutBound:Array[0..NMaxOutbound] of OutBoundTypeRef;

     PackAll, PackNew, RePack:ExtStr;

     T1:DateTime;

     AllFiles, NewFiles, FileArea, OkFile, VariText, LogFile: Text;

     AreaFile,BufAvail,BufAll,BufNew,
        VariBuf,OldExit:Pointer;

     Buf4: ^Recs;

     PathExclude,PathExcludeAnnounce:
        Array [1..NMaxExclude] of String[12];

     PathNew,PathAll,
       PathIdx,PathAvail,PathBdl,PathAnnunci,PathCopy,
       ConfigFile,PathFbbs,PathDown,PathEchoFlag,PathNetFlag,
       PathHudson,PathAreasBBS,PathCopyFBbs,
       Int,DefaultOrfanoStr,OffLineStr,KeyStr,OkFilePwd,
       Serie,KludgeFdn,MsgSubject,MsgFrom,MsgTo,
       MsgOrigin,Nome,KludgeReply,KludgeReplyTo,KludgeReplyAddr,PrevDataStr,
       LocalRaidPwd,VirusCheck,UploaderStr:PathStr;

     Prefix,Suffix,PathHdr,PathFtr:DescTypePtr;

     F,F1, FilesIdxTot: File;

     DataPattern:array[1..19] of char;

     SysopName, BBSName:String[36];

     Aree,UpDateFileIdx:ListaNumRef;

     Magic:Array[1..NMaxMagic] of StringRef;

     Sort,FixFBbsSort:SortType;

     Bbs, PrevBBS:BbsType;

     NTotFiles,PrevNTotFiles,NTotNewFiles,PrevNTotNewFiles,TempLong,
        NIdx1,PosListSum,PosListBdl,
        Livello,MaxLev,TempLev,Days,ChkDate,PrevPosIdx,LevPwd,
        ActDate,StartingMsg,MaxBytesUUEncode,MaxBytesUUEncode1,
        Right1:Longint;

     TotSize, TotNewSize: Real;

     DelDupFBbs,NoSearchExt,NewKey,EchoWritten,NetWritten,
       FirstArea,Registrato,PostIbm,IsCdRom,
       Flag,QuietMode,QuietMode1,
       Orfani,OffLine,OtherFiles,NoDlPath,FirstMerge,
       ReadFile_Id, FirstShell, UUEncodeFound, XXEncodeFound,
       SearchDb, MakeRepack,
       FixCrcTic, FixSizeTic,
          {$IFNDEF NO4350}
             ModeFont8x8,
          {$ENDIF}
       CheckFiles, ShortSize,
       LongSummary,
       H1, TicAreasModified, TicCfgModified,
       NoFirstLine, IndentDC, TicReplace,
       FixFBbsHeader, TicStopDup, TicUpdate,
       SavePCB, MailAttach, ZeroDC, PrivateSearch,
       NoAnnounceAfterTic, NoAnnounceReadFile_Id, NoPackFile_Id,
       AreaHeaderReqInfo, TICUseDesc, TICUseLDesc,
       DosMode: Boolean;

     LLIstStatus:LListStatusType;
     OtherOptions:Set Of LlistStatusType;

     ModDc:(NoMod,StripDc,DecDc);

     HatchName: PathStr;
     HatchArea, HatchDesc: String;

     ViewContents:(VcNo,VcAll,VcNew);

     TempStr,TempStr1: String;
     Packer: Array[1..NMaxPackers] of ^PackerType;
     NPacker:Integer;

     MsgOrigAddr,MsgDestAddr,TempAddr:AddrType;

     MsgArea: Array[0..NMsgAree] of ^ScanMsgAreaType;

     Aka:array[0..NMaxAka] of AddrType;

     Annunci:array[1..NMaxAnnounce+1] of ^AnnounceType;

     S:SearchRec;
     DllImit1, DlLimit2: String;

     SetData:SetDataTypeRef;
     Search:Array[1..NMaxSearch] of SearchTypeRef;

     KbdBuffer:String;

     ExternalShell : Array[1..10] of PathStr;
     Macro:Array[1..10] of string;

     L:String;
     PosDesc:Byte;
     LastDesc, LastComm:DescTypePtr;

     NetAreaId:String;

     TicNodes:Array[1..NMaxTicNodes] of ^TicNodeType;
     TicAreas:Array[1..NMaxTicAreas] of ^TicAreaType;
     TicGroups:Array[1..NMaxTicGroups] of ^TicGroupType;

     OkLines, TempDescTypePtr:DescTypePtr;

     SearchStr:String;

     CompPacker:Byte;
     FileAreaList, FileAreaListPtr, DosFileAreaList:DescTypePtr;
     FileAreaListRef:^DescTypePtr;

     FileList : Array[1..NMaxFileList] of ^FileListType;

     AreaHeaderLines, MsgAreaheaderLines,
        DirFiles, DirFilesPtr: DescTypePtr;

     LastError:Word;

     GraficFileInfo: String;

     HideLevels: DescTypePtr;

     PrevSort: SortType;

     RightAnnounceIdx: Longint;
     AnnounceIdx: File;

     Describe: Array[1..NMaxDescribe] of ^DescribeType;
     LlistAlias : Array [1..NMaxLlistAlias] of string[32];

     LlistDb, Filter: DescTypePtr;

     Button : string[3];

     DosModePath: pathStr;

Const
     LenPage=50; {valore massimo, in realta' devo guardare NScreenLines}
     Maxmessage=256;

Var  message:Array[1..maxmessage] of ^String;

Var
    Lines:Array[0..LenPage] of FileInfoPtr;
    FilesOnLine,StartDesc,DescLine:Array[1..LenPage] of integer;

    AvailableTicAreas:DescTypePtr;
    LastArea:^DescTypePtr;

    DescFiles: String;

Procedure StripLeadingSpace(Var S:String);
Function PreLog(level:LogLevel):String;
procedure PutInListaAree(Num1,Num2:Integer; Var P:ListaNumRef);
Procedure RemoveListaNum(Var Lista:ListaNumRef);
Function RepeatStr (Ch:Char; N:Byte):String;
Function Lev2Str(Lev:LonGint):String;
Function BytesStr(B:Real):String;
function IsInLista(N:Integer; P:ListaNumRef):boolean;
Procedure MyDateStr(T:DateTime);
Function StripChar(S:String):String;
Procedure ShowListaNum(P:ListaNumRef);
Function Long2Str(N:LongInt; pads:Byte):String;
Function KeyPressed : Boolean;
Function ReadKey:Char;
Function GetNextArea: Boolean;
Function GetArea(Int:String; ClearScreen:Boolean):Boolean;
Procedure ExpandWildCards(Var S:String);
Function MatchFileSpec(S1,S2: String): Boolean;
Procedure PutDescrizione(Var Pnt:DescTypePtr);
Procedure CancellaDescrizione(Var Pnt:DescTypePtr);
Function UpDate(N:String):Boolean;
Function DayOfWeekStr(N:Byte):String;
Procedure NormVideo;
Procedure HighVideo;
Procedure InvVideo;
Procedure LowVideo;
Procedure CreateFlagFile(Path:PathStr);
Procedure Lock(LockFile:String);
Procedure UnLock(LockFile:String);
Procedure ResetAreaFile;
Function AddAka(Address:AddrType): Integer;
Function Timer:LongInt;
Procedure FillScreen;
Function CopyListaAree(Pnt:ListaNumRef):ListaNumRef;
Procedure Beep;
Procedure PutInListaDate(Var Pnt:ListaPtr; Var Pnt2:FileInfoPtr);
Procedure PutInListaAlfa(Var Pnt:ListaPtr; Var Pnt2:FileInfoPtr);
Procedure PutInListaNo(Var Pnt:ListaPtr; Var Pnt2:FileInfoPtr);
Function AddNode(Var Pnt:AddrListTypeRef; Address:AddrType; TicMode:Byte): Boolean;
Procedure DeleteNodes(Pnt:AddrListTypeRef);
Function ChkGroup(A:String; Pnt:DescTypePtr):Boolean;
Function TicMode2String(TicMode:Byte):String;
Function DosValidName(A:String):String;
Function GetHex(C:Char):Byte;
Function GetCompressor(Var F:File):Byte;
Function GetComp(CompressedFile:String):Byte;
Function ExpandTabs(Var S:String) : String;
{$IFDEF VIRTUALPASCAL}
Procedure Rename(Var F; NewName: String);
{$ENDIF}
Procedure PressKey;
Procedure waitEvent;
Procedure HideCursor;
Procedure ShowCursor;
Function OrfanoStr(N: String): String;
Procedure StripAvt(Var S:String);
Function MsgToLlist(MsgTo: String): Boolean;
Function FileMatchFilter(Fname: String; Filter: DescTypePtr): Boolean;

Implementation

Function FileMatchFilter(Fname: String; Filter: DescTypePtr): Boolean;
begin
   ExpandwildCards(FName);
   while (Filter<>Nil) and not MatchFileSpec(FName, Filter^.Descrizione^) do
      Filter := Filter^.Next;
   FileMatchFilter := Filter<>Nil;
end;

Function MsgToLlist(MsgTo: String): Boolean;
Var I: Integer;
    TempB: Boolean;
begin
   I := 1;
   while (I<=NLlistAlias) and (llistAlias[i]<>MsgTo) do
      inc(i);
   MsgToLlist := I <= NLlistAlias;
end;

Procedure StripAvt(Var S:String);
Var I:Byte;
begin
   I := Pos(ColorId,S);
   while (I>0) do
   begin
      {Strip sequenze Avatar}
      if S[I+2] = #16 then
         delete(S,I,4)
      else
         delete(S,I,3);
      I := Pos(ColorId,S);
   end;
end {StripAvt};



Function OrfanoStr(N: String): String;
Var I: Integer;
begin
   ExpandWildCards(N);
   I := 1;
   while (i<=NDescribe) and not MatchFileSpec(N, Describe[I]^.Name) do
      inc(i);
   if I<=Ndescribe then
      orfanoStr := Describe[i]^.Desc
   else
      OrfanoStr := defaultorfanostr;
end;

{$IFDEF VIRTUALPASCAL}
Procedure HideCursor;
Var
   Curdata: VioCursorInfo;
begin
   VioGetCurType(Curdata, 0);
   Curdata.attr := 65535;
   VioSetCurType(Curdata, 0);
end;

Procedure ShowCursor;
Var
   Curdata: VioCursorInfo;
begin
   VioGetCurType(Curdata, 0);
   Curdata.attr := TextAttr;
   VioSetCurType(Curdata, 0);
end;

{$ELSE}
Procedure HideCursor; Assembler;
Asm
  MOV   ax,$0100
  MOV   cx,$2607
  INT   $10
end;

Procedure ShowCursor; Assembler;
Asm
  MOV   ax,$0100
  MOV   cx,$0506
  INT   $10
end;
{$ENDIF}

Procedure waitEvent;
begin
   MouShow;
   while not keypressed and not moucheck do sleep;
   MouHide;
end;

Procedure PressKey;
Var
   ch: Char;
   MouInfo: MinfoRecType;
begin
   Writeln(' * Press a key ...');
   waitevent;
   if keyPressed then
   begin
      ch := readkey;
      if ch = #0 then
         ch := readkey;
   end else
      mouget(mouInfo)
end;

{$IFDEF VIRTUALPASCAL}
Procedure Rename(Var F; NewName: String);
begin
   Newname := NewName + #0;
   InOutRes := DosMove(@FileRec(F).Name, @Newname[1]);
end;
{$ENDIF}


Function ExpandTabs(Var S:String) : String;
      Const TabStr = '        ';
      Var TempStr: String;
          I: Integer;
      begin
         TempStr := '';
         for I := 1 to length(S) do
         begin
            case S[I] of
               #9: {tab}
                  begin
                     TempStr := TempStr +
                        Copy(TabStr,1,length(TabStr) - length(TempStr) mod length(TabStr));
                  end;
               #10,#13: TempStr := TempStr + '.';
               #8:if TempStr<>'' then dec(TempStr[0]);
               #7:;
              else
               TempStr := TempStr + S[I]
            end;
         end;
         ExpandTabs := TempStr;
      end;



Function GetCompressor(Var F:File):Byte;
Const SizeBuf=1024;
Var Temp:Byte;
   TempStr:String;
   Count: Word;
   {$IFDEF VIRTUALPASCAL}
   Result: Longint;
   {$ELSE}
   Result: Word;
   {$ENDIF}
   Flag:Boolean;
   Size,Remainder:Word;
   COff:LongInt;
begin
  {Il File deve essere stato gia' aperto}
  {0=Unknown, 1=Arj, 2=Zip, 3=Lzh, 4=Sqz, 5=Arc, 6=Pak}
  Flag := False;
  Temp := 0;
  BlockRead(F,TempStr[1],128,Result);
  if (Result=128) then
  begin
   Byte(TempStr[0]) := Result;
   if ((TempStr[1]='M') and (TempStr[2]='Z')) or
      ((TempStr[1]='Z') and (TempStr[2]='M')) then
   begin
      Move(TempStr[3],Remainder,2);
      Move(TempStr[5],Size,2);
      COff := LongInt(Size-1)*512+Remainder;
      Seek(F,COff);
      BlockRead(F,TempStr[1],128,Result);
      if (Result=128) then
      begin
         if (TempStr[3]=#$60) and (TempStr[4]=#$EA) then
         begin
            {Sfx Arj 2.41}
            Inc(COff,2);
            Move(TempStr[3],TempStr[1],2);
         end;
         Seek(F,COff);
         Flag := True;
      end;
   end else
   begin
      Seek(F,0);
      Flag := True;
   end;
   if Flag then
   begin
      {Controlla formati grafici}
      if (Copy(TempStr,1,3)='GIF') then
      begin
         Temp := 128;
         {mette le altre info in GraficFileInfo}
         GraficFileInfo := Copy(TempStr,1,6) + ' ' +
            Long2Str(Ord(TempStr[8]) * 256 + Ord(TempStr[7]),0) + 'x' +
            Long2Str(Ord(TempStr[10]) * 256 + Ord(TempStr[9]),0) + 'x' +
            Long2Str( 2 SHL (ord(TempStr[11]) AND 7),0);
      end else
      if (Copy(TempStr,1,4)=#$FF#$D8#$FF#$E0) and
         (Copy(TempStr,7,5)='JFIF'#0) then
      begin
         {JPG}
         Temp := 129;
         {Search for SOF marker}
         Count := 11;
         Repeat
          inc(Count);
         Until (Count > length(TempStr)) OR
               (TempStr[Count] in [#192..#207]);
         if Count <= Length(TempStr) then
         begin
           { ReadS[Count] = first SOF marker
             Count + 1 = length high byte  \ length of APP0 data!
             Count + 2 = length low byte   /
             Count + 3 = data precision    - colors (?)
             Count + 4 = height high byte  \ heigth of picture
             Count + 5 = height low byte   /
             Count + 6 = width high byte   \ width of picture
             Count + 7 = width low byte    /
           }
           {mette le altre info in GraficFileInfo}
           GraficFileInfo := 'JPEG ' +
               Long2Str(Ord(TempStr[Count+6]) * 256 + Ord(TempStr[Count+7]),0) + 'x' +
               Long2Str(Ord(TempStr[Count+4]) * 256 + Ord(TempStr[Count+5]),0);
         end else
            GraficFileInfo := '';
      end else
      begin
         {Controlla file compressi}
         Temp := 0;
         I := 1;
         while (I<=NPacker) and (Temp=0) do
         begin
            if Packer[I]^.Id<>'' then
            begin
               TempStr1 := Copy(TempStr,Packer[I]^.Offset+1,length(Packer[I]^.ID));
               if TempStr1=Packer[I]^.Id then
                  Temp := I;
            end;
            inc(I);
         end;
      End;
   end;
 end;
 GetCompressor := Temp;
end {GetCompressor};

Function GetComp(CompressedFile:String):Byte;
Var F:File;
    fm:Word;
Begin
   Assign(F,CompressedFile);
   fm := FileMode;
   FileMode := FmReadOnly_DW;
   {$I-}
   Reset(F,1);
   {$I+}
   if IOResult=0 then
   begin
      GetComp := GetCompressor(F);
      Close(F);
   end else
      GetComp := 0;
   filemode := fm;
End {GetComp};


Function GetHex(C:Char):Byte;
begin
   case C of
     '0'..'9':GetHex := Ord(C) - Ord('0');
     'A'..'F':GetHex := Ord(C) - Ord('A') + 10;
     'a'..'f':GetHex := Ord(C) - Ord('a') + 10;
      else
     GetHex := 0
   end;
end {GetHex};


Function DosValidName(A:String):String;
Var I:Integer;
Begin
   if length(A)>8 then
      A[0] := #8;
   for I := 1 to length(A) do
   if not (A[I] in ['0'..'9','A'..'Z','-']) then
      A[I] := '_';
   DosValidName := A
End {DosValidName};


Function TicMode2String(TicMode:Byte):String;
Begin
   Case TicMode of
      TicSend:TicMode2String := ' .';
      TicReceive:TicMode2String := '*&';
      TicSend + TicReceive:TicMode2String := ' *'
    else
      TicMode2String := ' ?';
   end;
End {TicMode2String};


Function ChkGroup(A:String; Pnt:DescTypePtr):Boolean;
Begin
   while (Pnt<>Nil) and (pos(Pnt^.Descrizione^,A)<>1) do
      Pnt := Pnt^.Next;
   ChkGroup := Pnt<>Nil
End {ChkGroup};



Procedure DeleteNodes(Pnt:AddrListTypeRef);
Var Temp:AddrListTypeRef;
begin
   While Pnt<>Nil do
   begin
      Temp := Pnt;
      Pnt := Pnt^.Next;
      Dispose(Temp);
   End;
end {DeleteNodes};


Function AddNode(Var Pnt:AddrListTypeRef; Address:AddrType; TicMode:Byte): Boolean;
Var Temp:AddrListTypeRef;
    PntRef:^AddrListTypeRef;
Begin
   PntRef := Addr(Pnt);
   While (PntRef^<>Nil) and not AddrEqual(PntRef^^.Node,Address) do
      PntRef := Addr(PntRef^^.Next);
   If PntRef^<>Nil then
   begin
      AddNode := False
   end else
   begin
      New(PntRef^);
      PntRef^^.Node := Address;
      PntRef^^.Next := Nil;
      PntRef^^.Mode := TicMode;
      AddNode := True
   end;
End;




   Procedure ll1(Var t : ListaPtr);
   Var
     p : ListaPtr;
   begin
     p := t^.sx;
     t^.sx  := p^.dx;
     p^.dx := t;
     t := p;
   end {ll};

   Procedure rr1(Var t : ListaPtr);
   Var
      p : LIstaPtr;
   begin
     p := t^.dx;
     t^.dx := p^.sx;
     p^.sx  := t;
     t := p;
   end {rr};

   Procedure lr1(Var t : ListaPtr);
   begin
     rr1(t^.sx);
     ll1(t);
   end {lr};

   Procedure rl1(Var t : ListaPtr);
   begin
     ll1(t^.dx);
     rr1(t);
   end {rl};

  Procedure balanceleft1(Var t : ListaPtr; var H1:Boolean);
  begin
    Case t^.bal of
      +1 :
        begin
          t^.bal := 0;
          h1 := False;
        end;
       0 : t^.bal := -1;
      -1 :
        begin { rebalance }
          if t^.sx^.bal = -1 then
          begin { single ll rotation }
            ll1(t);
            t^.dx^.bal := 0;
          end
          else { t^.sx^.bal  = +1 }
          begin  { double lr rotation }
            lr1(t);
            if t^.bal = -1 then
              t^.dx^.bal := +1
            else
              t^.dx^.bal := 0;
            if t^.bal = +1 then
              t^.sx^.bal := -1
            else
              t^.sx^.bal := 0;
          end;
          t^.bal := 0;
          h1 := False;
        end;
    end;
  end;

  Procedure balanceright1(Var t : ListaPtr; var H1:Boolean);
  begin
    Case t^.bal of
      -1 :
        begin
          t^.bal := 0;
          h1 := False;
        end;
       0 : t^.bal := +1;
      +1 :
        begin { rebalance }
          if t^.dx^.bal = +1 then
          begin { single rr rotation }
            rr1(t);
            t^.sx^.bal := 0
          end
          else { t^.dx^.bal  = -1 }
          begin  { double rl rotation }
            rl1(t);
            if t^.bal = -1 then
              t^.dx^.bal := +1
            else
              t^.dx^.bal := 0;
            if t^.bal = +1 then
              t^.sx^.bal := -1
            else
              t^.sx^.bal := 0;
          end;
          t^.bal := 0;
          h1 := False;
        end;
    end;
  end;

   Procedure PutInListaDate(Var Pnt:ListaPtr; Var Pnt2:FileInfoPtr);
   begin
      if Pnt=Nil then
      begin
         new(Pnt);
         Pnt^.FileInfo := Pnt2;
         Pnt^.Sx := Nil;
         Pnt^.Dx := Nil;
         Pnt^.Bal := 0;
         H1 := True;
      end else
      if Pnt^.FileInfo^.Time < Pnt2^.Time then
      begin
         PutInListaDate(Pnt^.Sx,Pnt2);
         if H1 then
            balanceLeft1(Pnt,H1);
      end else
      begin
         {se e' uguale va dopo, cosi' la descrizione piu'
         nuova viene conservata}
         PutInListaDate(Pnt^.Dx,Pnt2);
         if H1 then
            balanceRight1(Pnt,H1);
      end;
   end {PutInListaDate};

   Procedure PutInListaAlfa(Var Pnt:ListaPtr; Var Pnt2:FileInfoPtr);
   begin
      if Pnt=Nil then
      begin
         new(Pnt);
         Pnt^.FileInfo := Pnt2;
         Pnt^.Sx := Nil;
         Pnt^.Dx := Nil;
         Pnt^.Bal := 0;
         H1 := True;
      end else
      if Pnt^.FileInfo^.Nome > Pnt2^.Nome then
      begin
         PutInListaAlfa(Pnt^.Sx,Pnt2);
         if H1 then
            balanceLeft1(Pnt,H1);
      end else
      begin
         {se e' uguala va dopo, cosi' la descrizione piu'
         nuova viene conservata}
         PutInListaAlfa(Pnt^.Dx,Pnt2);
         if H1 then
            balanceRight1(Pnt,H1);
      end;
   end {PutInListaAlfa};

   Procedure PutInListaNo(Var Pnt:ListaPtr; Var Pnt2:FileInfoPtr);
   begin
      if Pnt=Nil then
      begin
         new(Pnt);
         Pnt^.FileInfo := Pnt2;
         Pnt^.Sx := Nil;
         Pnt^.Dx := Nil;
         Pnt^.Bal := 0;
         H1 := True;
      end else
      begin
         PutInListaNo(Pnt^.Dx,Pnt2);
         if H1 then
            balanceRight1(Pnt,H1);
      end;
   end {PutInListaNo};



Procedure Beep;
Var I:Integer;
begin
   I := 1;
   While (I<50) and not KeyPressed do
   begin
      {$IFDEF OS2}
      PlaySound(1000, 10);
      {$ELSE}
      Sound(1000);
      Delay(10);
      NoSound;
      {$ENDIF}
      Inc(I)
   end;
end {Beep};

Function Timer:Longint;
{$IFDEF VIRTUALPASCAL}
Var Hour, Minute, Second, NoCare: Longint;
{$ELSE}
Var Hour, Minute, Second, NoCare: Word;
{$ENDIF}
Begin
   GetTime(Hour,Minute,Second,NoCare);
   Timer := Longint(Hour) * Longint(65520) +
            LongInt(Minute) * longint(1092) +
            Longint(Second) * Longint(18);
End {Timer};

Function AddAka(Address:AddrType): Integer;
Var I:Integer;
Begin
   I := 0;
   While (I<=NAka) and not AddrEqual(Aka[I],Address) do
      inc(I);
   if (I>NAka) then
   begin
      if I<=NMaxAka then
      begin
         NAka := I;
         Aka[NAka] := Address;
         AddAka := NAka
      end else
         AddAka := 0
   end else
      AddAka := I
End {AddAka};

Procedure NormVideo;
Begin
   TextAttr := NormVideoCol;
end;

Procedure HighVideo;
Begin
   TextAttr := HighVideoCol;
end;

Procedure InvVideo;
Begin
   TextAttr := InvVideoCol;
End;

Procedure LowVideo;
Begin
   TextAttr := LowVideoCol;
End;


Function DayOfWeekStr(N:Byte):String;
Begin
   Case N of
      0:DayOfWeekStr := 'Sun';
      1:DayOfWeekStr := 'Mon';
      2:DayOfWeekStr := 'Tue';
      3:DayOfWeekStr := 'Wed';
      4:DayOfWeekStr := 'Thu';
      5:DayOfWeekStr := 'Fri';
      6:DayOfWeekStr := 'Sat';
     else
        DayOfWeekStr := '???'
   end;
end;

Function UpDate(N:String):Boolean;
Var F:File;
    Fm:Byte;
Begin
   Assign(F,N);
   Fm := FileMode;
   FileMode := FmReadWrite_DA;
   {$I-}
   Reset(F);
   {$I+}
   if (IOResult=0) then
   begin
      SetFTime(F,ActDate);
      UpDate := IOREsult=0;
      close(F);
   end else
      UpDate := False;
   FileMode := Fm;
end {Update};

Procedure PutDescrizione(Var Pnt:DescTypePtr);
Var LenDesc:Integer;
    TempDesc: DescTypePtr;
begin
   if Pnt=Nil then
   begin
      New(Pnt);
      LenDesc := Length(L) - PosDesc + 1;
      if LenDesc>0 then
      begin
         GetMem(Pnt^.Descrizione,LenDesc+1);
         Pnt^.Descrizione^ := Copy(L,PosDesc,LenDesc)
      end else
      begin
         GetMem(Pnt^.Descrizione,1);
         Pnt^.Descrizione^ := '';
      end;
      Pnt^.Next := Nil;
      {Caso normale, se invece era un commento poi ci pensa
      la procedura Commento ad invertire questi due puntatori}
      LastDesc := Pnt;
      LastComm := Nil;
   end else
   begin
      TempDesc := Pnt;
      while (TempDesc^.Next<>Nil) do
         TempDesc := TempDesc^.Next;
      PutDescrizione(TempDesc^.Next)
   end;
end {PutDescrizione};

Procedure CancellaDescrizione(Var Pnt:DescTypePtr);
Var TempDesc: DescTypePtr;
begin
   while Pnt<>Nil do
   begin
      TempDesc := Pnt^.Next;
      FreeMem(Pnt^.Descrizione,Length(Pnt^.Descrizione^)+1);
      dispose(Pnt);
      Pnt := TempDesc;
   end;
end {CancellaDescrizione};

Procedure ExpandWildCards(Var S:String);
Var
    N: NameStr;
    E: ExtStr;
    I : Byte;
Begin
   I := pos('.',S);
   if (I=0) then
   begin
      N := S;
      E := '.*'
   end else
   begin
      N := Copy(S,1,I-1);
      E := Copy(S,I,length(S)-I+1)
   end;
   I := pos('*',N);
   if I>0 then
   begin
      N := Copy(N,1,I-1);
      for I := I to 8 do
         N := N + '?'
   end else
   begin
      For I := length(N)+1 to 8 do
         N := N + ' '
   end;
   I := pos('*',E);
   if I>0 then
   begin
      E := Copy(E,1,I-1);
      for I := I to 4 do
         E := E + '?'
   end else
   begin
      For I := length(E)+1 to 4 do
         E := E + ' '
   end;
   S := N + E;
End {ExpandWildCards};

Function MatchFileSpec(S1,S2: String): Boolean;
Var I:Integer;
    Flag:Boolean;
Begin
   Flag := True;
   I := 1;
   while flag and (I<=12) do
   begin
      Flag := (S2[I]='?') or (S1[I]=S2[I]);
      inc(I);
   end;
   MatchFileSpec := Flag;
end {MatchFileSpec};

Procedure FillScreen;
Var ScreenLines:Byte;
    I:Integer;
    Line: String;
begin
   Line := RepeatStr('ฐ', Lo(WindMax) - Lo(WindMin) + 1);
   ScreenLines := Hi(Windmax) - Hi(WindMin) + 1;
   NormVideo;
   HideCursor;
   GotoXY(1,1);
   InvVideo;
   Write(' LLIST ',Versione);
   Write('':81-WhereX);
   NormVideo;
   for I := 2 to ScreenLines-1 do
      Write(Line);
   dec(line[0]);
   Write(LIne);
   if not registrato then
   begin
      InvVideo;
      GotoXY(40- length(Serie) div 2, 4);
      Write(Serie);
      NormVideo;
   end;
   ShowCursor;
end {RestoreSchermo};


Function KeyPressed : Boolean;
begin
   KeyPressed := (KbdBuffer<>'') or Crt.KeyPressed
end {KeyPressed};


Function ReadKey:Char;
begin
   if KbdBuffer<>'' then
   begin
      ReadKey := KbdBuffer[1];
      Delete(KbdBuffer,1,1);
   end else
   begin
      while not Crt.KeyPressed do
         Sleep;
      ReadKey := Crt.ReadKey
   end;
end {ReadKey};


Function Long2Str(N:LongInt; pads:Byte):String;
Var TempStr:String;
begin
   Str(N:Pads,TempStr);
   Long2Str := TempStr;
end {Long2Str};


Procedure ShowListaNum(P:ListaNumRef);
begin
   if P<>Nil then
   begin
      write(' ',P^.Num1);
      write(LogFile,' ',P^.Num1);
      if P^.Num2>P^.Num1 then
      begin
         write('-',P^.Num2);
         write(LogFile,'-',P^.Num2);
      end;
      ShowListaNum(P^.Next);
   end;
end {ShowListaNum};


Function StripChar(S:String):String;
begin
   if (LListStatus=MakeSearch) or (LListStatus=Announce) then
      Delete(S,25,1);
   StripChar := S;
end {StripChar};


Procedure MyDateStr(T:DateTime);
Var S:String;
    TempP:SetDataTypeRef;
begin
    TempP := SetData;
    While TempP<>Nil do
    begin
       case TempP^.DataType of
          1:Move(Nstr[T.Day],PrevdataStr[TempP^.Position],2);
          2:Move(Nstr[T.Month],PrevdataStr[TempP^.Position],2);
          3:Move(MonthStr[T.Month],PrevdataStr[TempP^.Position],3);
          4:Move(NStr[T.Year mod 100],PrevdataStr[TempP^.Position],3);
       end;
       TempP := TempP^.Next;
    end;
    if PrevDataStr[1]='0' then
       PrevDataStr[1] := ' ';
end {MyDateStr};


function IsInLista(N:Integer; P:ListaNumRef):boolean;
begin
    while (P<>Nil) and (P^.Num2<N) do
    begin
       P := P^.Next;
    end;
    IsInLista := (P<>Nil) and (N >= P^.Num1);
end {IsInLista};


Function RepeatStr (Ch:Char; N:Byte):String;
Var TempStr:String;
begin
   TempStr := '';
   while N>0 do
   begin
      TempStr := TempStr + ch;
      dec(n);
   end;
   RepeatStr := TempStr;
end {Repeat};


Procedure StripLeadingSpace(Var S:String);
var I:Integer;
begin
   I := 1;
   while (I<=Length(S)) and ((S[I]=' ') or (S[I]=#9)) do
      inc(I);
   if I>1 then
      delete(S,1,I-1);
end {StripLeadingSpace};


Function PreLog(level:LogLevel):String;
Const Levels:array[Loglevel] of Char='!#+:';
Var T:DateTime;
    {$IFDEF VIRTUALPASCAL}
    Temp: Longint;
    {$ELSE}
    Temp:Word;
    {$ENDIF}
begin
   GetDate(T.Year,T.Month,T.Day,Temp);
   GetTime(T.Hour,T.Min,T.Sec,Temp);
   PreLog := Levels[Level]+' '+Nstr[T.Day]+' '+MonthStr[T.Month]+' '+
      Nstr[T.Hour]+':'+Nstr[T.Min]+':'+NStr[T.Sec]+' LLST ';
end {PreLog};


procedure PutInListaAree(Num1,Num2:Integer; Var P:ListaNumRef);
Var Temp:ListaNumRef;
begin
   if P<>Nil then
   begin
      if P^.Num2+1<Num1 then
      begin
         {sta oltre l'intervallo}
         PutInListaAree(Num1,Num2,P^.Next)
      end else
      if P^.Num1-1>Num2 then
      begin
         {sta prima dell'intervallo}
         new(Temp);
         Temp^ := P^;
         P^.Num1 := Num1;
         P^.Num2 := Num2;
         P^.Next := Temp;
      end else
      begin
         {
         Uno dei due nuovi estremi e' compreso in questo intervallo,
         ora lo espande
         }
         if P^.Num1>Num1 then
            P^.Num1 := Num1;
         if P^.Num2<Num2 then
            P^.Num2 := Num2;
         {ora controlla la successiva area}
         while (P^.Next<>Nil) and (P^.Next^.Num1-1<=Num2) do
         begin
            Temp := P^.Next;
            if P^.Num2<Temp^.Num2 then
               P^.Num2 := Temp^.Num2;
            P^.Next := Temp^.Next;
            Dispose(Temp);
         end;
      end;
   end else
   begin
       new(P);
       P^.Num1 := Num1;
       P^.Num2 := Num2;
       P^.Next := Nil;
   end;
end;


Function CopyListaAree(Pnt:ListaNumRef):ListaNumRef;
Var Temp:ListaNumRef;
Begin
   Temp := Nil;
   While (Pnt<>Nil) do
   begin
      PutInListaAree(Pnt^.Num1,Pnt^.Num2,Temp);
      Pnt := Pnt^.Next
   end;
   CopyListaAree := Temp;
End {CopyListaAree};


Procedure RemoveListaNum(Var Lista:ListaNumRef);
begin
   if Lista<>Nil then
   begin
      RemoveListaNum(Lista^.Next);
      Dispose(Lista);
   end;
end {RemoveListaNum};


Function Lev2Str(Lev:LonGint):String;
begin
   if BBS=Max then
   begin
      if Lev=-2 then Lev := -1;
      if Lev>8 then Dec(Lev);
      Lev := (Lev+2)*16;
   end;
   if (BBS=Lora) or (BBS=Max) then
   case lev of
      16:Lev2Str:='TWIT     ';
      32:Lev2Str:='DISGRACE ';
      48:Lev2Str:='LIMITED  ';
      64:Lev2Str:='NORMAL   ';
      80:Lev2Str:='WORTHY   ';
      96:Lev2Str:='PRIVEL   ';
     112:Lev2Str:='FLAVORED ';
     128:Lev2Str:='EXTRA    ';
     144:Lev2Str:='CLERK    ';
     160:Lev2Str:='ASSTSYSOP';
     176:Lev2Str:='SYSOP    ';
     192:Lev2Str:='HIDDEN   ';
    Else
     Lev2Str := '?????????';
   end else
     Lev2Str := Long2Str(Lev,9);
end {Lev2Str};


Function BytesStr(B:Real):String;
Type TipoType=(tb,tk,tm,tg);
Const TipoStr:Array[TipoType] of Char=(' ','K','M','G');
Var Tipo:TipoType;
    TempStr : String;
begin
   Tipo := tb;
   while (Tipo<>tg) and (B>=9999) do
   begin
      inc(Tipo);
      B := Trunc(B / 1024);
   end;
   Str(B:4:0,TempStr);
   if B=1 then
   begin
      BytesStr := TempStr + ' ' + TipoStr[Tipo] + 'byte ';
   end else
   begin
      BytesStr := TempStr + ' ' + TipoStr[Tipo] + 'bytes';
   end;
end {BytesStr};


Function GetNextArea: Boolean;
Var Fm:Word;
    TempDescTypePtr : DescTypePtr;
begin
   if (Bbs=Unknown) or DosMode then
   begin
      If FileAreaListPtr<>Nil then
      begin
         inc(Numero);
         Nome := FileAreaListPtr^.Descrizione^;
         PathDown := Nome + '\';
         PathFBbs := PathDown + 'Files.Bbs';
         Livello := 0;
         Attr := 0;
         Gruppo := 0;
         IsCdRom := (Length(PathDown)>=2) and
                          (PathDown[2]=':') and
                           (Pos(PathDown[1],CdRoms)<>0);
         FileAreaListPtr := FileAreaListPtr^.Next;
         GetNextArea := True
      end else
      begin
         GetNextArea := False;
         inc(Numero)
      end;
   end else
   begin
      PathDown := '';
      while PathDown='' do
      begin
         if (
              ((Bbs<>Max300) and
             (AreaPosBuffer*SizeAreaFile<FileAreaInBuffer)
              ) or
               not eof(F)
            ) then
         begin
            if bbs=Max300 then
            begin
               BlockRead(f,AreaFile^,6);
               I := 7;
               BlockRead(f,CharType(AreaFile^)[I],AreaFileMax300Type(AreaFile^).CbArea+
                  AreaFileMax300Type(AreaFile^).CbHeap -6);
            end else
            begin
               if SizeAreaFile*AreaPosBuffer=FileAreaInBuffer then
               begin
                  AreaPosBuffer := 1;
                  BlockRead(f,AreaFile^,SizeAreaFile*FileAreaToRead,FileAreaInBuffer);
               end else
               begin
                  inc(AreaPosBuffer);
               end;
            end;
            case Bbs of
               Lora:Begin
                       Numero := AreaFileLoraType(AreaFile^)[AreaPosBuffer].Numero;
                       Gruppo := AreaFileLoraType(AreaFile^)[AreaPosBuffer].Gruppo;
                       Livello := AreaFileLoraType(AreaFile^)[AreaPosBuffer].Lev;
                       Attr := AreaFileLoraType(AreaFile^)[AreaPosBuffer].Attr;
                       Nome[0] := #79;
                       Move(AreaFileLoraType(AreaFile^)[AreaPosBuffer].Nome,Nome[1],79);
                       Byte(Nome[0]) := Pos(#0,Nome)-1;
                       PathDown[0] := #79;
                       Move(AreaFileLoraType(AreaFile^)[AreaPosBuffer].PathDown,PathDown[1],79);
                       Byte(PathDown[0]) := Pos(#0,PathDown)-1;
                       PathDown := Upper(PathDown);
                       PathFBbs[0] := #79;
                       Move(AreaFileLoraType(AreaFile^)[AreaPosBuffer].PathFBbs,PathFBbs[1],79);
                       Byte(PathFBbs[0]) := Pos(#0,PathFBbs)-1;
                       PathFBbs := Upper(PathFBbs);
                       IsCdRom := AreaFileLOraType(AreaFile^)[AreaPosBuffer].CdRom <> 0;
                    End;
               Ra250:Begin
                       Numero := AreaFileRa250Type(AreaFile^)[AreaPosBuffer].AreaNum;
                       Gruppo := AreaFileRa250Type(AreaFile^)[AreaPosBuffer].Group;
                       Livello := AreaFileRa250Type(AreaFile^)[AreaPosBuffer].Security;
                       Attr := 0;
                       Nome := AreaFileRa250Type(AreaFile^)[AreaPosBuffer].Name;
                       PathDown := AreaFileRa250Type(AreaFile^)[AreaPosBuffer].FilePath;
                       PathDown := Upper(PathDown);
                       PathFBbs := '';
                    End;
               Max:Begin
                       {Attenzione con il type casting!!!}
                       inc(Numero);
                       StartMaxArea := Addr(CharType(AreaFile^)[(AreaPosBuffer-1)*SizeAreaFile+1]);
                       Livello := AreaFileMaxType(StartMaxArea^).Lev;
                       attr := 0;
                       Nome[0] := #79;
                       Move(AreaFileMaxType(StartMaxArea^).Nome,Nome[1],79);
                       Byte(Nome[0]) := Pos(#0,Nome)-1;
                       PathDown[0] := #79;
                       Move(AreaFileMaxType(StartMaxArea^).PathDown,PathDown[1],79);
                       Byte(PathDown[0]) := Pos(#0,PathDown)-1;
                       PathDown := Upper(PathDown);
                       PathFBbs[0] := #79;
                       Move(AreaFileMaxType(StartMaxArea^).PathFBbs,PathFBbs[1],79);
                       Byte(PathFBbs[0]) := Pos(#0,PathFBbs)-1;
                       PathFBbs := Upper(PathFBBs);
                       IsCdRom := (Length(PathDown)>=2) and
                          (PathDown[2]=':') and
                           (Pos(PathDown[1],CdRoms)<>0);
                    End;
               Max300:Begin
                       inc(Numero);
                       attr := 0;
                       I := AreaFileMax300Type(AreaFile^).CbArea+
                            AreaFileMax300Type(AreaFile^).Descript +1;
                       Nome[0] := #79;
                       Move(CharType(AreaFile^)[I],Nome[1],79);
                       Byte(Nome[0]) := Pos(#0,Nome)-1;
                       PathDown[0] := #79;
                       I := AreaFileMax300Type(AreaFile^).CbArea+
                            AreaFileMax300Type(AreaFile^).DownPath +1;
                       Move(CharType(AreaFile^)[I],PathDown[1],79);
                       Byte(PathDown[0]) := Pos(#0,PathDown)-1;
                       PathDown := Upper(PathDown);
                       PathFBbs[0] := #79;
                       I := AreaFileMax300Type(AreaFile^).CbArea+
                            AreaFileMax300Type(AreaFile^).FilesBbs +1;
                       Move(CharType(AreaFile^)[I],PathFBbs[1],79);
                       Byte(PathFBbs[0]) := Pos(#0,PathFBbs)-1;
                       PathFBbs := Upper(PathFBBs);
                       IsCdRom := (Length(PathDown)>=2) and
                          (PathDown[2]=':') and
                           (Pos(PathDown[1],CdRoms)<>0);
                       {livello}
                       TempStr[0] := #79;
                       I := AreaFileMax300Type(AreaFile^).CbArea+
                            AreaFileMax300Type(AreaFile^).Acs +1;
                       Move(CharType(AreaFile^)[I],TempStr[1],79);
                       Byte(TempStr[0]) := Pos(#0,TempStr)-1;
                       TempStr := Upper(TempStr);
                       TempDescTypePtr := HideLevels;
                       While (TempDescTypePtr<>Nil) and (TempStr<>TempDescTypePtr^.Descrizione^) do
                          TempDescTypePtr := TempDescTYpePtr^.Next;
                       if TempDescTypePtr=Nil then
                          Livello := 0
                       else
                          Livello := MaxLev;
                    End;
               SBBS:Begin
                       inc(Numero);
                       Livello := AreaFileSBBSType(AreaFile^)[AreaPosBuffer].Lev;
                       Attr := 0;
                       Nome := AreaFileSBBSType(AreaFile^)[AreaPosBuffer].Nome;
                       PathDown := Upper(AreaFileSBBSType(AreaFile^)[AreaPosBuffer].PathDown);
                       PathFBbs := Upper(AreaFileSBBSType(AreaFile^)[AreaPosBuffer].PathFBbs);
                       if (PathFBbs<>'') and (PathFBbs[1]='*') then
                          PathFBBs := '';
                       IsCdRom := (Length(PathDown)>=2) and
                          (PathDown[2]=':') and
                           (Pos(PathDown[1],CdRoms)<>0);
                    End;
               QBBS:Begin
                       inc(Numero);
                       Livello := AreaFileQBBsType(AreaFile^)[AreaPosBuffer].DlSec.Security;
                       Attr := 0;
                       Nome := AreaFileQBbsType(AreaFile^)[AreaPosBuffer].Nome;
                       PathDown := Upper(AreaFileQBbsType(AreaFile^)[AreaPosBuffer].PathDown);
                       PathFBbs := Upper(AreaFileQBbsType(AreaFile^)[AreaPosBuffer].PathFBbs);
                       IsCdRom := (Length(PathDown)>=2) and
                          (PathDown[2]=':') and
                           (Pos(PathDown[1],CdRoms)<>0);
                    End;
               PcBoard:Begin
                       inc(Numero);
                       Livello := 0;
                       Attr := 0;
                       Nome[0] := #35;
                       Move(AreaFilePcBoardType(AreaFile^)[AreaPosBuffer].Nome,Nome[1],35);
                       while (Nome<>'') and (Nome[length(Nome)]=' ') do
                          dec(Nome[0]);
                       PathDown[0] := #30;
                       Move(AreaFilePcBoardType(AreaFile^)[AreaPosBuffer].PathDown,PathDown[1],30);
                       while (PathDown<>'') and (PathDown[length(PathDown)]=' ') do
                          dec(PathDown[0]);
                       PathDown := Upper(PathDown);
                       PathFBbs[0] := #30;
                       Move(AreaFilePcBoardType(AreaFile^)[AreaPosBuffer].PathFBbs,PathFBbs[1],30);
                       while (PathFBbs<>'') and (PathFBbs[length(PathFBbs)]=' ') do
                          dec(PathFBbs[0]);
                       PathFBbs := Upper(PathFBbs);
                       IsCdRom := (Length(PathDown)>=2) and
                          (PathDown[2]=':') and
                           (Pos(PathDown[1],CdRoms)<>0);
                    End;
            end;
            if PathDown<>'' then
            begin
               if PathDown[length(PathDown)]<>'\' then
                  PathDown := PathDown + '\';
               if PathDown[1]='\' then
                  pathDown := LoraDir[1]+LoraDir[2] + PathDown
               else
               if PathDown[2]<>':' then
                  pathDown := LoraDir + '\' + PathDown;
               if PathFBbs='' then
                  PathFBbs := PathDown + 'FILES.BBS';
               if length(Nome)>52 then
               begin
                  Nome[0] := #52;
                  while (Nome<>'') and (Nome[length(Nome)]=' ') do
                     dec(Nome[0]);
               end;
               GetNextArea := True
            end;
         end else
         if (DirFilesPtr<>Nil) and (DirFilesPtr^.Next<>Nil) then
         begin
            DirFilesPtr := DirFilesPtr^.Next;
            Close(F);
            fm := FileMode;
            FileMode := FmReadOnly_DN;
            Repeat
               Assign(F,DirFilesPtr^.Descrizione^);
               {$I-}
               Reset(F,1);
               {$I+}
               LastError := IOResult;
               If LastError<>0 then
                  DirFilesPtr := DirFilesPtr^.Next;
            until (LastError=0) or (DirFilesPtr=Nil);
            FileMode := fm;
            if LastError=0 then
               PathDown := ''
            else
               PathDown := '*';
            FileAreaInBuffer := 0;
            AreaPosBuffer := 0;
         end else
            PathDown := '*';
      end;

      if PathDown='*' then
      begin
         If FileAreaListPtr<>Nil then
         begin
            inc(Numero);
            Nome := FileAreaListPtr^.Descrizione^;
            PathDown := Nome + '\';
            PathFBbs := PathDown + 'Files.Bbs';
            if length(Nome)>52 then
            begin
               Nome[0] := #52;
               while (Nome<>'') and (Nome[length(Nome)]=' ') do
                  dec(Nome[0]);
            end;
            Livello := 0;
            Attr := 0;
            Gruppo := 0;
            IsCdRom := (Length(PathDown)>=2) and
                          (PathDown[2]=':') and
                           (Pos(PathDown[1],CdRoms)<>0);
            FileAreaListPtr := FileAreaListPtr^.Next;
            GetNextArea := True
         end else
         begin
            GetNextArea := False;
            inc(Numero)
         end;
      end;
   end
end {GetNextArea};

Procedure ResetAreaFile;
   Var      fm:Word;
            S:SearchRec;
            I: Integer;
Begin
   Numero := 0;
   if (DosMode) then
   begin
      CancellaDescrizione(DosFileAreaList);
      DosFileAreaList:=NIL;
      {directories precedenti}
      I := 1;
      while (i<=length(DosModePath)) do
      begin
         if (DosModepath[i]='\') then
         begin
            L := copy(Dosmodepath,1,I-1);
            PosDesc := 1;
            PutDescrizione(DosFileAreaList);
         end;
         inc(i);
      end;
      FindFirst(DosModepath+'*.*',Directory,S);
      while (DosError=0) do
      begin
         if ((S.Attr and Directory)<>0) and (S.Name<>'.') and (S.Name<>'..') then
         begin
            L := DosModepath + S.Name;
            PosDesc := 1;
            Putdescrizione(DosFileAreaList);
         end;
         findNext(S);
      end;
      FileAreaListPtr:=DosFileAreaList;
   end else
   begin
      if DirFiles<>Nil then
      begin
         if DirFilesPtr<>DirFiles then
         begin
            if DirFilesPtr<>Nil then
               Close(F);
            fm := FileMode;
            FileMode := FmReadOnly_DN;
            DirFilesPtr := DirFiles;
            Assign(F,DirFilesPtr^.Descrizione^);
            Repeat
               {$I-}
               Reset(F,1);
               {$I+}
               LastError := IoResult;
               if LastError<>0 then
                  DirFilesPtr := DirFilesPtr^.Next;
            until (LastError=0) or (DirFilesPtr=Nil);
            FileMode := fm;
         end else
            Seek(F,0);
      end else
      if Bbs<>Unknown then
      begin
         {Azzera la posizione del file}
         Seek(F,0);
      end;
      if bbs=Max300 then
         seek(F,4);
      FileAreaListPtr := FileAreaList;
   end;
   FileAreaInBuffer := 0;
   AreaPosBuffer := 0;
   DirFilesPtr := DirFiles;
End {ResetAreaFile};

Function GetArea(Int:String; ClearScreen:Boolean):Boolean;
Const SizeBuf=32;

    I:Integer=1;
    Type BufType=Array[1..SizeBuf] of record
                           PathDown, PathFBbs, Nome:PathStr;
                           Numero:Integer;
                           Level: Longint;
                           IsCdRom:Boolean;
                           Attr: Byte;
                        end;

Var
    Buf:^BufType;
    NBuf:Integer;
    K:Integer;
    Ch:Char;
    J, SkipAreas: Integer;
    StartLine: Byte;
    MouInfo: MInfoRecType;
    PrevSkipAreas: Integer;
    AddedAreas: Integer;
    S: SearchRec;

Label Restart;

    Procedure GetBuffer;
    Var J:Integer;
        Drive: char;
    begin
       if PrevSkipAreas = SkipAreas - Sizebuf div 2 then
       begin
          for J := 1 to SizeBuf div 2 - AddedAreas do
             buf^[j] := buf^[j + sizebuf div 2];
          NBuf := SizeBuf div 2 - AddedAreas;
          Numero := buf^[nbuf].Numero;
       end else
       begin
          ResetAreaFile;
          NBuf := - SkipAreas;
       end;
       while (NBuf<SizeBuf) and GetNextArea do
       begin
          inc(NBuf);
          if NBuf>0 then
          begin
             Buf^[NBuf].PathDown := PathDown;
             Buf^[NBuf].PathFBbs := PathFBbs;
             Buf^[NBuf].Numero := Numero;
             Buf^[NBuf].Nome := Nome;
             Buf^[NBuf].IsCdRom := IsCdRom;
             Buf^[NBuf].Level := Livello;
             Buf^[NBuf].Attr := Attr;
          end;
       end;
       AddedAreas := 0;
       if dosmode then
       begin
          drive := 'A';
          while (NBuf<SizeBuf) and (drive<='Z') do
          begin
             if (dosmodepath[1]<>drive) and
               ((drive='A') or (drive='B') or (DiskSize(ord(drive)-ord('A')+1)>0)) then
             begin
                inc(NBuf);
                inc(AddedAreas);
                Buf^[NBuf].PathDown := drive + ':\';
                Buf^[NBuf].PathFBbs := drive + ':\Files.Bbs';
                Buf^[NBuf].Numero := Numero;
                Buf^[NBuf].Nome := 'Drive '+drive+':';
                Buf^[NBuf].IsCdRom := False;
                Buf^[NBuf].Level := 0;
                Buf^[NBuf].Attr := 0;
                inc(numero);
             end;
             inc(drive);
          end;
          if (Nbuf<SizeBuf) and
             ((bbs<>unknown) or (FileAreaList<>Nil)) then
          begin
             inc(NBuf);
             inc(AddedAreas);
             Buf^[NBuf].PathDown := '';
             Buf^[NBuf].PathFBbs := '';
             Buf^[NBuf].Numero := Numero;
             Buf^[NBuf].Nome := '[ BBS ]';
             Buf^[NBuf].IsCdRom := False;
             Buf^[NBuf].Level := 0;
             Buf^[NBuf].Attr := 0;
             inc(numero);
          end;
       end else
       begin
          if (NBuf<SizeBuf) and (DirBadFiles<>'') then
          begin
             inc(NBuf);
             inc(AddedAreas);
             {Bad Files}
             Buf^[NBuf].PathDown := DirBadFiles;
             Buf^[NBuf].PathFBbs := DirBadFiles + 'Files.Bbs';
             Buf^[NBuf].Numero := Numero;
             Buf^[NBuf].Nome := 'Bad';
             Buf^[NBuf].IsCdRom := False;
             Buf^[NBuf].Level := 0;
             Buf^[NBuf].Attr := 0;
             inc(numero);
          end;
          if (NBuf<SizeBuf) and (DirInfectedFiles<>'') then
          begin
             inc(NBuf);
             inc(AddedAreas);
             {Infected Files}
             Buf^[NBuf].PathDown := DirInfectedFiles;
             Buf^[NBuf].PathFBbs := DirInfectedFiles + 'Files.Bbs';
             Buf^[NBuf].Numero := Numero;
             Buf^[NBuf].Nome := 'Infected';
             Buf^[NBuf].IsCdRom := False;
             Buf^[NBuf].Level := 0;
             Buf^[NBuf].Attr := 0;
             inc(numero);
          end;
          if (Nbuf<SizeBuf) then
          begin
             inc(NBuf);
             inc(AddedAreas);
             Buf^[NBuf].PathDown := '';
             Buf^[NBuf].PathFBbs := '';
             Buf^[NBuf].Numero := Numero;
             Buf^[NBuf].Nome := '[ DOS ]';
             Buf^[NBuf].IsCdRom := False;
             Buf^[NBuf].Level := 0;
             Buf^[NBuf].Attr := 0;
             inc(numero);
          end;
       end;
       for J := 1 to NBuf do
       begin
          if J<=SizeBuf div 2 then
          begin
             GotoXY(1,J + StartLine);
             TempStr := Copy(Buf^[J].Nome,1,34);
             write(FrameChars[2]);
             if Buf^[J].Level<MaxLev then
                NormVideo
             else
                LowVideo;
             Write(Buf^[J].Numero:4,' ',TempStr,'':34-length(TempStr));
             normVideo;
          end else
          begin
             GotoXY(41,J + StartLine - SizeBuf div 2);
             TempStr := Copy(Buf^[J].Nome,1,34);
             if Buf^[J].Level<MaxLev then
                NormVideo
             else
                LowVideo;
             write(Buf^[J].Numero:4,' ',TempStr,'':34-length(TempStr));
             NormVideo;
             Write(FrameChars[2]);
          end;
       end;
       for J := NBuf+1 to SizeBuf do
       begin
          if J<=SizeBuf div 2 then
          begin
             GotoXY(1,J+StartLine);
             write(FrameChars[2],'':39);
          end else
          begin
             GotoXY(41,J + StartLine - SizeBuf div 2);
             write('':39,FrameChars[2]);
          end;
       end;
       PrevSkipAreas := SkipAreas;
    end {GetBuffer};

begin

   if ChangeArea>=0 then
   begin

      ResetAreaFile;

      I := 1;

      while GetNextArea and (Numero<ChangeArea) do
         inc(I);

      GetArea := ChangeArea = Numero;

      ChangeArea := -1;

   end else
   begin

      if (bbs=unknown) and (filearealist=nil) then
         dosmode := true;

      Restart:

      NAree := 0;
      New(Buf);
      Numero := -1;

      if ClearScreen then
      begin
         {$IFDEF NO4350}
         {$ELSE}
         if ModeFont8x8 then
            TextMode(Font8x8 + Co80);
         {$ENDIF}
         FillScreen;
      end;

      StartLine := (Hi(WindMax) - Hi(WindMin) + 1) div 2 - SizeBuf div 4;

      HideCursor;
      GotoXY(1,StartLine);
      NormVideo;
      Write(FrameChars[3], FrameChars[1], Button);
      for K := 6 to 11 do
         Write(FrameChars[1]);
      write(' ',Int,' ');
      for K := 12+length(Int)+2 to 79 do
         Write(FrameChars[1]);
      Write(FrameChars[4]);

      if dosmode then
      begin
         I := 0;
         for J := 1 to length(DosModePath) do
            if DosModePath[j]='\' then inc(i);
      end;

      SkipAreas := ((I-1) div SizeBuf) * SizeBuf;
      PrevSkipAreas := - SizeBuf;

      GetBuffer;

      Write(FrameChars[5]);
      for K := 2 to 79 do
         Write(FrameChars[1]);
      Write(FrameChars[6]);

      Repeat

         J := I - SkipAreas;

         {Scrive il path di download nell'ultima riga};
         TempStr := Buf^[J].PathDown;
         if length(TempStr)>40 then
         begin
            Delete(TempStr,4,length(TempStr)-40+4);
            while (TempStr[4]<>'\') do
               Delete(TempStr,4,1);
            Insert('...',TempStr,4);
         end;
         if TempStr<>'' then
              TempStr := ' ' + TempStr + ' ';
         for K := length(TempStr)+1 to 42 do
            TempStr := TempStr + FrameChars[1];
         GotoXY(10,StartLine + SizeBuf div 2 +1);
         Write(TempStr);

         {scrive in reverse il nome dell'area}

         if J<=SizeBuf div 2 then
         begin
            GotoXY(2,J + StartLine);
         end else
         begin
            GotoXY(41,J + StartLine - SizeBuf div 2);
         end;
         TempStr := Copy(Buf^[J].Nome,1,34);
         InvVideo;
         write(Buf^[J].Numero:4,' ',TempStr,'':34-length(TempStr));

         waitevent;

         if J<=SizeBuf div 2 then
         begin
            GotoXY(2,J + StartLine);
         end else
         begin
            GotoXY(41,J + StartLine - SizeBuf div 2);
         end;
         TempStr := Copy(Buf^[J].Nome,1,34);

         if Buf^[J].Level<MaxLev then
            normvideo
         else
            lowvideo;
         write(Buf^[J].Numero:4,' ',TempStr,'':34-length(TempStr));
         normVideo;
         if keypressed then
         begin
            ch := readkey;
            if Ch=#0 then
            begin
               Ch := ReadKey;
               case Ch of
                 #77:begin
                        inc(I,SizeBuf div 2);
                     end;
                 #73:begin
                        I := SkipAreas + 1;
                     end;
                 #75:begin
                        dec(I,SizeBuf div 2);
                     end;
                 #81:begin
                        I := SkipAreas + NBuf
                     end;
                 #80:begin
                        inc(I);
                     end;
                 #72:begin
                        dec(I);
                     end;
               end;
               if I<=SkipAreas then
               begin
                  if SkipAreas>0 then
                  begin
                     Dec(SkipAreas, SizeBuf); {qui c'era un -sizebuf div 2}
                     if SkipAreas<0 then
                        SkipAreas := 0;
                     GetBuffer;
                  end else
                     I := 1;
               end else
               if I>SkipAreas+NBuf then
               begin
                  if (NBuf<SizeBuf) then
                  begin
                     I := SkipAreas + NBuf;
                  end else
                  begin
                     inc(SkipAreas, SizeBuf div 2);
                     GetBuffer;
                     if I > SkipAreas + NBuf then
                        I := SkipAreas + NBuf;
                  end;
               end;
            end;
         end else
         begin
            {mouse event}
            mouget(mouInfo);
            if (mouInfo.ButtonStat <> 0) and
               (mouinfo.cy >= startline - 1) and
               (mouinfo.cy <= startline + sizebuf div 2 -1) then
            begin
               {premuto nella zona valida!}
               if mouinfo.cy = startline-1 then
               begin
                  if mouinfo.cx = 3 then
                     ch := #27
                  else
                     ch := #0;
               end else
               if mouinfo.cx=0 then
               begin
                  Kbdbuffer := #0 + #75;
                  ch := #0;
               end else
               if mouinfo.cx=79 then
               begin
                  Kbdbuffer := #0 + #77;
                  ch := #0;
               end else
               begin
                  {e' stata selezionata un'area}
                  I := Skipareas + (mouinfo.cy + 1 - startline);
                  if mouinfo.cx >= 40 then
                     i := i + SizeBuf div 2;
                  if I <= skipAreas + NBuf then
                  begin
                     if MouInfo.IsDouble then
                        ch := #13
                     else
                        ch := #0;
                  end else
                  begin
                     I := SkipAreas + NBuf;
                     ch := #0;
                  end;
                  J := i - skipareas;
               end;
            end else
               ch := #0;
         end;
      until (Ch=#27) or (Ch=#13);

      ShowCursor;

      GetArea := Ch<>#27;

      PathDown := Buf^[J].PathDown;
      PathFBbs := Buf^[J].PathFBbs;

      Numero := Buf^[J].Numero;
      Nome := Buf^[J].Nome;
      IsCdRom := Buf^[J].IsCdRom;
      Attr := Buf^[J].Attr;
      Livello := Buf^[J].Level;

      Dispose(Buf);

      if ClearScreen then
      begin
         {$IFDEF NO4350}
         {$ELSE}
         if Modefont8x8 then
            TextMode(Co80);
         {$ENDIF}
      end;

      if (ch<>#27) then
      begin
         if dosMode then
         begin
            if (Nome='[ BBS ]') then
            begin
               DosMode := false;
               I := 1;
               goto restart;
            end else
            if (PathDown<>DosModePath) then
            begin
               DosModePath := PathDown;
               goto restart;
            end;
            DosModePath := PathDown;
            Numero := -1;
         end else
         if (Nome='[ DOS ]') and (PathDown='') then
         begin
            DosMode := True;
            goto restart;
         end;
      end;

      if dosmode then
         i := 1;

   end;
end {GetArea};


Procedure CreateFlagFile(Path:PathStr);
var F:File;
    fm: Word;
begin
   if Path<>'' then
   begin
      fm := FileMode;
      FileMode := FmReadWRite_DA;
      assign(F,Path);
      {$I-}
      Rewrite(F);
      {$I+}
      if IOResult=0 then
      begin
         close(F);
      end else
      begin
         writeln(' * Can''t write flag file ',Path);
         writeln(LogFile,PreLog(LogError),'Can''t write flag file ',Path);
         Flush(LogFile);
      end;
      FileMode := Fm;
   end;
end {CreateFlagFile};

Procedure Lock(LockFile:String);
Var F:File;
    LastError:Word;
Begin
   if Ops<>0 then
   begin
      CreateFlagFile(LockFile+AppExt);
      Assign(F,LOckFile+AppExt);
      {$I-}
      Rename(F,LockFile+'.Bsy');
      {$I+}
      LastError := IOResult;
      if LastError<>0 then
      begin
         Writeln(' * Wait ',LockFile,'.Bsy');
         Writeln(LogFile,Prelog(LogError),'Wait ',LockFile,'.Bsy');
         Flush(LogFile);
         Repeat
            CreateFlagFile(LockFile+AppExt);
            Assign(F,LOckFile+AppExt);
            {$I-}
            Rename(F,LockFile+'.Bsy');
            {$I+}
            LastError := IOResult;
         until (LastError=0);
      end;
   end;
End {Lock};


Procedure UnLock(LockFile:String);
Begin
   if Ops<>0 then
   begin
      if EraseFile(LOckFile+ '.Bsy') then;
   End;
End {UnLock};


begin
   KbdBuffer := '';
   StartAttr := TextAttr;
   if MOUPresent then
   begin
      Button := '[þ]'
   end else
      Button := FrameChars[1] + FrameChars[1] + FrameChars[1];
end.
