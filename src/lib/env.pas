unit env{ironment};

interface

uses
  ShlObj,
  SysUtils,
  Windows;

const
  DIRECTORY_SEPARATOR='\';
  DRIVE_SEPARATOR=':';
  LINE_ENDING=#13#10;
  LINE_BREAK=LINE_ENDING;

  SOFTWARE_NAME='deptocom';
  SOFTWARE_REGISTRYKEY='Software'+DIRECTORY_SEPARATOR+SOFTWARE_NAME+DIRECTORY_SEPARATOR;
  STDOUTPUT_FILE='stdout.txt';//default (tentamos redirecionar a saída padrão para esse arquivo)
  LOG_SUFFIX='.log';//default
  LOG_FILE=SOFTWARE_NAME+LOG_SUFFIX;//default
  BINARIES_FOLDER_NAME='bin';//default
  DATA_FOLDER_NAME='data';//default
  TABLE_SUFFIX='.dat';//default
  HISTORY_TABLE_SUFFIX='.h.dat';//default
  LOGIN_TABLE='usr.dat';//default

  //CUSTOM RUNTIME ERROR CODES
  RUNERR_NO_SOFTWARE_REGISTRYKEY  = 51;
  RUNERR_NO_LOGFILE               = 52;
  RUNERR_NO_TMPDIR                = 53;
  RUNERR_NO_DATADIR               = 54;
  RUNERR_NO_LOGINTABLE            = 55;

  //LOG-LEVEL FLAGS
  LL_FTL='F';//FATAL
  LL_ERR='E';//ERROR
  LL_WRN='W';//WARNING
  LL_INF='I';//INFO
  LL_DBG='D';//DEBUG

  //LOG START OF MESSAGE
  LSTX='#';

  //PROCESSOR ARCHITECTURES
  //v. https://learn.microsoft.com/en-us/windows/win32/api/sysinfoapi/ns-sysinfoapi-system_info
  PROCESSOR_ARCHITECTURE_INTEL    = 0;     //x86
  PROCESSOR_ARCHITECTURE_ARM      = 5;     //ARM
  PROCESSOR_ARCHITECTURE_IA64     = 6;     //Intel Itanium-based
  PROCESSOR_ARCHITECTURE_AMD64    = 9;     //x64 (AMD or Intel)
  PROCESSOR_ARCHITECTURE_ARM64    = 12;    //ARM64
  PROCESSOR_ARCHITECTURE_UNKNOWN  = $ffff; //Unknown architecture.

type
  float=single;
  int8=shortint;
  int16=smallint;
  int32=integer;

  Edeptocom = class(Exception);

  LogLevel = (llFatal=0,llError,llWarning,llInfo,llDebug);

  SpecialDirID = (
    sidDesktop=CSIDL_DESKTOP,
    sidMyDocuments=CSIDL_PERSONAL,
    sidFavorites=CSIDL_FAVORITES,
    sidStartup=CSIDL_STARTUP,
    sidStartMenu=CSIDL_STARTMENU,
    sidFonts=CSIDL_FONTS,
    sidAppData=CSIDL_APPDATA
  );

  ProcessorArchitecture = (
    archAMD64=PROCESSOR_ARCHITECTURE_AMD64,
    archARM=PROCESSOR_ARCHITECTURE_ARM,
    archARM64=PROCESSOR_ARCHITECTURE_ARM64,
    archIA64=PROCESSOR_ARCHITECTURE_IA64,
    archIntel=PROCESSOR_ARCHITECTURE_INTEL,
    archUnknown=PROCESSOR_ARCHITECTURE_UNKNOWN
  );

  _OSVERSIONINFOA = record
    dwOSVersionInfoSize: DWORD;
    dwMajorVersion: DWORD;
    dwMinorVersion: DWORD;
    dwBuildNumber: DWORD;
    dwPlatformId: DWORD;
    szCSDVersion: array[0..127] of AnsiChar;
    wServicePackMajor: WORD;
    wServicePackMinor: WORD;
    wSuiteMask: WORD;
    wProductType: BYTE;
    wReserved: BYTE;
  end;

  _OSVERSIONINFO = _OSVERSIONINFOA;
  TOSVersionInfoA = _OSVERSIONINFOA;
  TOSVersionInfo = TOSVersionInfoA;
  OSVERSIONINFOA = _OSVERSIONINFOA;

  WindowsEdition = (
    w95=4,
    wNT4,
    w98,
    w2000,
    wME,
    wXP,
    wXP64,
    wSERVER2003,
    wHOMESERVER,
    wSERVER2003R2,
    wVISTA,
    wSERVER2008,
    wSERVER2008R2,
    w7,
    wSERVER2012,
    w8
  );

const
  LogLevelFlag:array[llFatal..llDebug] of char = (LL_FTL,LL_ERR,LL_WRN,LL_INF,LL_DBG);
  LogLevelLabel:array[llFatal..llDebug] of string = ('FATAL','ERROR','WARNING','INFO','DEBUG');

  //v. https://learn.microsoft.com/en-us/windows/win32/sysinfo/operating-system-version
  WindowsEditionName:array[low(WindowsEdition)..high(WindowsEdition)] of string = (
    'Windows 95',
    'Windows NT 4.0',
    'Windows 98',
    'Windows 2000',    
    'Windows Millennium',
    'Windows XP',
    'Windows XP x64',
    'Windows Server 2003',
    'Windows Home Server',
    'Windows Server 2003 R2',
    'Windows Vista',
    'Windows Server 2008',
    'Windows Server 2008 R2',
    'Windows 7',
    'Windows Server 2012',
    'Windows 8'
  );

function GetUnitName(const o:TObject):shortstring;

function GetSpecialDir(const sid:SpecialDirID):ansistring;

function QueryRegistryValue(const nome:ansistring; out valor:ansistring; const key:ansistring=SOFTWARE_REGISTRYKEY; const rootkey:HKEY=HKEY_CURRENT_USER):boolean;
function SetRegistryValue(const nome, valor : ansistring; const key:ansistring=SOFTWARE_REGISTRYKEY; const rootkey:HKEY=HKEY_CURRENT_USER):boolean;

function PID:cardinal;

function GetConsoleWindow:HWND; stdcall; external kernel32;
procedure HideConsole;
procedure ShowConsole;
function ConsoleIsVisible:boolean;

procedure GetNativeSystemInfo(var lpSystemInformation: TSystemInfo); stdcall;
function PROCESSOR_ARCHITECTURE:ProcessorArchitecture;
function NUMBER_OF_PROCESSORS:cardinal;

function GetVersionEx(var lpVersionInformation: TOSVersionInfo): BOOL; stdcall;
  external kernel32 name 'GetVersionExA';
function WINDOWS_VERSION_INFO:TOSVersionInfo;
function WINDOWS_MAJOR_VERSION:cardinal;
function WINDOWS_MINOR_VERSION:cardinal;
function WINDOWS_BUILD_NUMBER:cardinal;
function WINDOWS_VERSION:string;
function WINDOWS_EDITION:WindowsEdition;

function NUMBER_OF_DISPLAY_MONITORS:cardinal;
function SCREEN_SIZE:TSize;
function OS_USER:ansistring;
function COMPUTERNAME:ansistring;
function LOGFILENAME:ansistring;
function LOGDIR:ansistring;
function DEPTOCOMDIR:ansistring;
function BINDIR:ansistring;
function DATADIR:ansistring;
function TMPDIR:ansistring;
function STDOUTPUTFILE:ansistring;
function CURRENT_TIMESTAMP:ansistring;

procedure LogFatal(const msg:ansistring; const errorCode:int32; const flushmsg:boolean=FALSE);
procedure LogError(const msg:ansistring; const flushmsg:boolean=FALSE);overload;
procedure LogError(const e:Exception; const flushmsg:boolean=FALSE);overload;
procedure LogWarn(const msg:ansistring; const flushmsg:boolean=FALSE);
procedure LogInfo(const msg:ansistring; const flushmsg:boolean=FALSE);
procedure LogDebug(const msg:ansistring; const flushmsg:boolean=FALSE);
procedure Log(const level:LogLevel; const msg:ansistring; const flushmsg:boolean=FALSE; errorCode:int32=0);

implementation

uses
  ActiveX,
  Registry,
  threads,
  TypInfo;

var
  _LOGFILENAME,
  _DEPTOCOMDIR,
  _BINDIR,
  _DATADIR,
  _TMPDIR
    :ansistring;
  stdoutFile
    :string='';
  logfile
    :textfile;
  logfileOK
    :boolean=FALSE;
  consoleVisible
    :boolean=FALSE;
  StdOutputFileOK
    :boolean=FALSE;

procedure OutputWriteLn(const arg:string);
begin
  if (isConsole and consoleVisible) or ((not isConsole) and StdOutputFileOK) then
    WriteLn(arg);
end;

function GetUnitName(const o:TObject):shortstring;
var
  tpdt:PTypeData;
begin
  result:='';
  try
    if (o<>NIL) and (o.ClassInfo<>NIL) then begin
      tpdt:=GetTypeData(o.ClassInfo);
      if tpdt<>NIL then
        result:=tpdt^.UnitName;
    end;
  except
    // o<>NIL
    // mas não aponta para um objeto (aponta para uma área de memória inadequada)
    raise Edeptocom.Create('env.GetUnitName(TObject): invalid pointer');
  end;
end;

function GetUnitName2(const o:TObject):shortstring;
begin
  result:=GetUnitName(o);
  if result<>'' then
    result:=result+'.';
end;

function GetSpecialDir(const sid:SpecialDirID):ansistring;
var
  alloc:imalloc;
  specialdir:pItemIdList;
  buf:array[0..MAX_PATH] of char;
begin
  if SHGetMalloc(alloc)=NOERROR then
  begin
    SHGetSpecialFolderLocation(0,integer(sid),specialdir);
    SHGetPathFromIDList(specialdir,@buf[0]);
    alloc.Free(specialdir);
    result:=ansistring(buf);
  end;
end;

//cria a pasta (chave) Computador\HKEY_CURRENT_USER\Software\deptocom no registro do Windows, se ela não existe
procedure CreateSoftwareRegistryKey;
var
  reg:TRegistry;
begin
  reg:=TRegistry.Create(KEY_ALL_ACCESS);
  try
    reg.rootkey:=HKEY_CURRENT_USER;
    if reg.OpenKey(SOFTWARE_REGISTRYKEY,TRUE) then
      reg.CloseKey;
  finally
    reg.Free;
  end;
end;

function QueryRegistryValue(const nome:ansistring; out valor:ansistring; const key:ansistring=SOFTWARE_REGISTRYKEY; const rootkey:HKEY=HKEY_CURRENT_USER):boolean;
var
  reg:TRegistry;
begin
  result:=FALSE;
  try
    reg:=TRegistry.Create(KEY_QUERY_VALUE);
    try
      reg.rootkey:=rootkey;
      if not reg.OpenKey(key,FALSE) then Exit;
      try
        if reg.ValueExists(nome) then begin
          valor:=reg.ReadString(nome);
          result:=TRUE;
        end;
      finally
        reg.CloseKey;
      end;
    finally
      reg.Free;
    end;
  except
    on e:Exception do
      if logFileOK then
        LogError(e)
      else OutputWriteLn(SOFTWARE_NAME+': env.QueryRegistryValue: '+e.Classname+': '+e.message);
  end;
end;

function SetRegistryValue(const nome, valor : ansistring; const key:ansistring=SOFTWARE_REGISTRYKEY; const rootkey:HKEY=HKEY_CURRENT_USER):boolean;
var
  reg:TRegistry;
begin
  result:=FALSE;
  try
    reg:=TRegistry.Create(KEY_SET_VALUE);
    try
      reg.rootkey:=rootkey;
      if not reg.OpenKey(key,FALSE) then Exit;
      reg.WriteString(nome,valor);
      reg.CloseKey;
      result:=TRUE;
    finally
      reg.Free;
    end;
  except
    on e:Exception do
      if logFileOK then
        LogError(e)
      else OutputWriteln(SOFTWARE_NAME+': env.SetRegistryValue: '+e.Classname+': '+e.message);
  end;
end;

function PID:cardinal;
begin
  result:=GetCurrentProcessId;
end;

procedure HideConsole;
begin
  if isConsole and consoleVisible then begin
    ShowWindow(GetConsoleWindow,SW_HIDE);
    consoleVisible:=FALSE;
  end;
end;

procedure ShowConsole;
begin
  if isConsole and (not consoleVisible) then begin
    ShowWindow(GetConsoleWindow,SW_NORMAL);
    consoleVisible:=TRUE;
  end;
end;

function ConsoleIsVisible:boolean;
begin
  result:=consoleVisible;
end;

procedure GetNativeSystemInfo; stdcall;
  external kernel32 name 'GetNativeSystemInfo';

function PROCESSOR_ARCHITECTURE:ProcessorArchitecture;
var
  sysinfo:TSystemInfo;
  majorVersion,
  minorVersion
    :cardinal;
begin
  majorVersion:=WINDOWS_MAJOR_VERSION;
  minorVersion:=WINDOWS_MINOR_VERSION;

  sysinfo.wProcessorArchitecture:=PROCESSOR_ARCHITECTURE_UNKNOWN;
  if (majorVersion=5) and (minorVersion=0) {Windows 2000} then
    GetSystemInfo(sysinfo)
  else
  if (majorVersion > 5) or ((majorVersion=5) AND (minorVersion>0)) then
    GetNativeSystemInfo(sysinfo);

  case sysinfo.wProcessorArchitecture of
    PROCESSOR_ARCHITECTURE_INTEL:result:=archIntel;
    PROCESSOR_ARCHITECTURE_ARM:result:=archARM;
    PROCESSOR_ARCHITECTURE_IA64:result:=archIA64;
    PROCESSOR_ARCHITECTURE_AMD64:result:=archAMD64;
    PROCESSOR_ARCHITECTURE_ARM64:result:=archARM64;
    else result:=archUnknown;
  end;
end;

function NUMBER_OF_PROCESSORS:cardinal;
var
  sysinfo:TSystemInfo;
begin
  GetSystemInfo(sysinfo);
  result:=sysinfo.dwNumberOfProcessors;
end;

const
  SM_CMONITORS = 80;
  SM_SERVERR2 = 89;
  VER_SUITE_WH_SERVER = $00008000;
  VER_NT_WORKSTATION = $0000001;

var
  dwVersion
    :DWORD=0;
  dwMajorVersion,
  dwMinorVersion,
  dwBuild
    :DWORD;

//v. https://learn.microsoft.com/pt-br/windows/win32/api/sysinfoapi/nf-sysinfoapi-getversionexa
//[NOTA: Há de funcionar apenas para sistemas >= Windows 2000 e <= Windows 8]
function WINDOWS_VERSION_INFO:TOSVersionInfo;
  function GetOSVersionInfo(out osvi:TOSVersionInfo):boolean;
  begin
    ZeroMemory(@osvi,SizeOf(osvi));
    osvi.dwOSVersionInfoSize:=SizeOf(TOSVersionInfo);
    result:=GetVersionEx(osvi)<>BOOL(0);
  end;
begin
  GetOSVersionInfo(result);
end;

function WINDOWS_MAJOR_VERSION:cardinal;
begin
  if dwVersion=0 then
    WINDOWS_VERSION;
  result:=dwMajorVersion;
end;

function WINDOWS_MINOR_VERSION:cardinal;
begin
  if dwVersion=0 then
    WINDOWS_VERSION;
  result:=dwMinorVersion;
end;

function WINDOWS_BUILD_NUMBER:cardinal;
begin
  if dwVersion=0 then
    WINDOWS_VERSION;
  result:=dwBuild;
end;

function WINDOWS_VERSION:string;
begin
  if dwVersion=0 then begin
    dwMajorVersion:=Win32MajorVersion;
    dwMinorVersion:=Win32MinorVersion;
    dwBuild:=Win32BuildNumber;
    dwVersion:=GetVersion;//v. https://learn.microsoft.com/pt-br/windows/win32/api/sysinfoapi/nf-sysinfoapi-getversion
    dwMajorVersion:=DWORD(LOBYTE(LOWORD(dwVersion)));
    dwMinorVersion:=DWORD(HIBYTE(LOWORD(dwVersion)));
    if dwVersion<$80000000 then
      dwBuild:=DWORD(HIWORD(dwVersion));
  end;
  result:=format('%d.%d.%d',[dwMajorVersion,dwMinorVersion,dwBuild]);
end;

function WINDOWS_EDITION:WindowsEdition;
var
  wv:TOSVersionInfo;
  majorVersion,
  minorVersion,
  platformID
    :DWORD;
  isServerR2,
  isNTWorkstation,
  isAMD64,
  isVerSuiteWHServer
    :boolean;
begin
  if dwVersion=0 then
    WINDOWS_VERSION;

  majorVersion:=dwMajorVersion;
  minorVersion:=dwMinorVersion;
  platformID:=Win32Platform;

  result:=WindowsEdition(0);
  if majorVersion=4 then begin
    case minorVersion of
      0:
        if platformID=VER_PLATFORM_WIN32_NT then
          result:=wNT4
        else
          result:=w95;
      10:result:=w98;
      90:result:=wME;
    end;
  end else
  if (majorVersion=5) or ((majorVersion=6) and (minorVersion<3)) then begin
    wv:=WINDOWS_VERSION_INFO;
    platformID:=wv.dwPlatformId;
    isServerR2:=GetSystemMetrics(SM_SERVERR2)<>0;
    isVerSuiteWHServer:=(wv.wSuiteMask and VER_SUITE_WH_SERVER)<>0;
    isNTWorkstation:=wv.wProductType=VER_NT_WORKSTATION;
    isAMD64:=PROCESSOR_ARCHITECTURE=archAMD64;
    case majorVersion of
      5:case minorVersion of
        0:result:=w2000;
        1:result:=wXP;
        2:begin
          if isServerR2 then
            result:=wSERVER2003R2
          else
          if isNTWorkstation and isAMD64 then
            result:=wXP64
          else
          if isVerSuiteWHServer then
            result:=wHOMESERVER
          else
          if not isServerR2 then
            result:=wSERVER2003
        end;
      end;
      6:case minorVersion of
        0:
          if isNTWorkstation then
            result:=wVista
          else
            result:=wSERVER2008;
        1:
          if isNTWorkstation then
            result:=w7
          else
            result:=wSERVER2008R2;
        2:
          if isNTWorkstation then
            result:=w8
          else
            result:=wSERVER2012;
      end;
    end;
  end;
end;

function NUMBER_OF_DISPLAY_MONITORS:cardinal;
begin
  result:=GetSystemMetrics(SM_CMONITORS);
  if result=0 then begin
    result:=1;
    LogError('env.NUMBER_OF_DISPLAY_MONITORS: the call GetSystemMetrics(SM_CMONITORS) failed... we set result to 1');
  end;
end;

function SCREEN_SIZE:TSize;
begin
  result.cx:=GetSystemMetrics(SM_CXSCREEN);
  result.cy:=GetSystemMetrics(SM_CYSCREEN);
end;

function OS_USER:ansistring;
var
  userNameBuffer:array[0..255] of char;
  sizeBuffer:dword;
begin
  sizeBuffer:=256;
  getUserName(userNameBuffer,sizeBuffer);
  result:=ansistring(userNameBuffer);
end;

function COMPUTERNAME:ansistring;
var
  compuname:array[0..256] of char;
  size:dword;
begin
  size:=256;
  GetComputerName(compuname,size);
  result:=compuname;
end;

function LOGFILENAME:ansistring;
begin
  result:=_LOGFILENAME;
end;

function LOGDIR:ansistring;
begin
  if _LOGFILENAME='' then
    result:=''
  else
    result:=ExtractFileDir(_LOGFILENAME);
end;

function DEPTOCOMDIR:ansistring;
begin
  result:=_DEPTOCOMDIR;
end;

function BINDIR:ansistring;
begin
  result:=_BINDIR;
end;

function DATADIR:ansistring;
begin
  result:=_DATADIR;
end;

function TMPDIR:ansistring;
begin
  result:=_TMPDIR;
end;

function STDOUTPUTFILE:ansistring;
begin
  result:='';
  if (not isConsole) and StdOutputFileOK then
    result:=stdoutFile;
end;

function CURRENT_TIMESTAMP:ansistring;
begin
  result:=FormatDatetime('yyyymmddhhnnsszzz',now);
end;

procedure LogFatal(const msg:ansistring; const errorCode:int32; const flushmsg:boolean=FALSE);
var
  line:ansistring;
begin
  line:=
    CURRENT_TIMESTAMP
    +LL_FTL
    +OS_USER
    +LSTX
    +'err:'+IntToStr(errorCode)+':'
    +msg;
  WriteLn(logfile,line);
  if flushmsg then
    flush(logfile);
  Runerror(errorCode);
end;

procedure LogError(const msg:ansistring; const flushmsg:boolean=FALSE);
var
  line:ansistring;
begin
  line:=
    CURRENT_TIMESTAMP
    +LL_ERR
    +OS_USER
    +LSTX
    +msg;
  WriteLn(logfile,line);
  if flushmsg then
    flush(logfile);
end;

procedure LogError(const e:Exception; const flushmsg:boolean=FALSE);
begin
  LogError(GetUnitName2(e)+e.classname+': '+e.message);
end;

procedure LogWarn(const msg:ansistring; const flushmsg:boolean=FALSE);
var
  line:ansistring;
begin
  line:=
    CURRENT_TIMESTAMP
    +LL_WRN
    +OS_USER
    +LSTX
    +msg;
  WriteLn(logfile,line);
  if flushmsg then
    flush(logfile);
end;

procedure LogInfo(const msg:ansistring; const flushmsg:boolean=FALSE);
var
  line:ansistring;
begin
  line:=
    CURRENT_TIMESTAMP
    +LL_INF
    +OS_USER
    +LSTX
    +msg;
  WriteLn(logfile,line);
  if flushmsg then
    flush(logfile);
end;

procedure LogDebug(const msg:ansistring; const flushmsg:boolean=FALSE);
var
  line:ansistring;
begin
  line:=
    CURRENT_TIMESTAMP
    +LL_DBG
    +OS_USER
    +LSTX
    +msg;
  WriteLn(logfile,line);
  if flushmsg then
    flush(logfile);
end;

procedure Log(const level:LogLevel; const msg:ansistring; const flushmsg:boolean=FALSE; errorCode:int32=0);
begin
  case level of
    llFatal:LogFatal(msg,errorCode,flushmsg);
    llError:LogError(msg,flushmsg);
    llWarning:LogWarn(msg,flushmsg);
    llInfo:LogInfo(msg,flushmsg);
    llDebug:LogDebug(msg,flushmsg);
    else raise Edeptocom.Create('env.Log: level de log desconhecido: '+IntToStr(Ord(level)));
  end;
end;

procedure SetStdOutputFile;
var
  stdof:string;
begin
  if not isConsole then begin
    try if not QueryRegistryValue('stdoutputfile',stdof) then                           //podemos configurar um arquivo
    raise Edeptocom.Create('Falha na consulta [stdoutputfile] ao registro do Windows'); //de nosso gosto no registro do Windows;
    except stdof:=''; end;                                                              //se algo der errado, tentamos um nome de
    if Trim(stdof)='' then stdof:=GetCurrentDir+DIRECTORY_SEPARATOR+STDOUTPUT_FILE;     //arquivo previamente definido (STDOUTPUT_FILE)
    AssignFile(System.Output,stdof);
    if FileExists(stdof) then
      Append(System.Output)
    else
      Rewrite(System.Output);
    Write;//dummy test
    StdOutputFileOK:=TRUE;
    stdoutFile:=stdof;
    SetRegistryValue('stdoutputfile',stdoutFile);
  end;
end;

procedure CloseStdOutputFile;
begin
  if (not isConsole) and StdOutputFileOK then
    CloseFile(System.Output);
  stdoutFile:='';
  StdOutputFileOK:=FALSE;
end;

var
  straux
    :ansistring='';
  errcode
    :int32=0;
  folderOK
    :boolean=FALSE;

initialization
  consoleVisible:=isConsole;
  RunAsync(SetStdOutputFile);
  Sleep(100);

  //verifica o diretório (chave) do software no registro do Windows
  //e o arquivo de log da aplicação
  //(sem um arquivo de log, não iniciamos a aplicação!)
  errcode:=RUNERR_NO_SOFTWARE_REGISTRYKEY;
  logfileOK:=FALSE;
  try
    CreateSoftwareRegistryKey;
    errcode:=RUNERR_NO_LOGFILE;
    try
      if not QueryRegistryValue('logfile',_LOGFILENAME) then
        OutputWriteLn(SOFTWARE_NAME+': env: initialization: nao conseguimos consultar o valor de logfile no registro do Windows');
    except
      on e:Exception do OutputWriteLn(SOFTWARE_NAME+
        ': env: initialization: nao conseguimos consultar o valor de logfile no registro do Windows: '+
        e.Classname+': '+e.message);
    end;
    _LOGFILENAME:=Trim(_LOGFILENAME);
    if _LOGFILENAME='' then begin
      _LOGFILENAME:=GetCurrentDir+DIRECTORY_SEPARATOR+LOG_FILE;
      try
        if not SetRegistryValue('logfile',_LOGFILENAME) then
          OutputWriteLn(SOFTWARE_NAME+': env: initialization: nao conseguimos registrar logfile='+_LOGFILENAME+' no registro do Windows');
      except
        on e:Exception do OutputWriteLn(SOFTWARE_NAME+': env: initialization: nao conseguimos registrar logfile='
          +_LOGFILENAME+' no registro do Windows: '+e.Classname+': '+e.message);
      end;
    end;
    AssignFile(logfile,_LOGFILENAME);
    if FileExists(_LOGFILENAME) then
      Append(logfile)
    else
      Rewrite(logfile);
    Write(logfile);//dummy test
    logfileOK:=TRUE;
    errcode:=0;
    //ARQUIVO DE LOG OK!
  except
    on e:Exception do begin
      OutputWriteLn(SOFTWARE_NAME+': env: initialization: nao conseguimos criar um arquivo de log para a aplicacao: '+e.Classname+': '+e.message);
      Runerror(errcode);
    end;
  end;

  //verifica o diretório da aplicação:
  //diretório raiz, se for o caso,
  //e diretório de binários
  try
    _BINDIR:=GetCurrentDir;
    folderOK:=LowerCase(ExtractFilename(_BINDIR))=LowerCase(BINARIES_FOLDER_NAME);
    if folderOK then
      _DEPTOCOMDIR:=ExtractFileDir(_BINDIR)
    else
      _DEPTOCOMDIR:=_BINDIR;
    if not SetRegistryValue('bindir',_BINDIR) then
      raise Edeptocom.Create('não foi possível registrar o diretório de arquivos binários (executáveis, bibliotecas) [bindir] no registro do Windows');
    if not SetRegistryValue('deptocomdir',_DEPTOCOMDIR) then
      raise Edeptocom.Create('não foi possível registrar o diretório do software [deptocomdir] no registro do Windows');
  except
    on e:Exception do
      LogWarn(SOFTWARE_NAME+': env: initialization: '+e.Classname+': '+e.message,TRUE);
  end;

  //verifica a existência de um diretório para arquivos temporários:
  //não existindo, tenta criá-lo;
  //não existindo e não sendo possível criá-lo, lança o runerror RUNERR_NO_TMPDIR (FATAL!);
  //existindo, mas não sendo possível ler ou/e criar arquivos no diretório, lança também o RUNERR_NO_TMPDIR runerror (FATAL!)
  errcode:=RUNERR_NO_TMPDIR;
  folderOK:=FALSE;
  try
    if not QueryRegistryValue('tmpdir',_TMPDIR) then
      raise Edeptocom.Create('falha em consultar o diretório de arquivos temporários [tmpdir] no registro do Windows')
    else
      errcode:=0;
  except
    on e:Exception do
      LogWarn(SOFTWARE_NAME+': env: initialization: '+e.Classname+': '+e.message,TRUE);
  end;
  folderOK:=not(errcode=RUNERR_NO_TMPDIR);
  try
    if not folderOK then begin
      straux:=GetSpecialDir(sidAppData);
      //APENAS POR COMPLETUDE! NÃO OCORRE!
      if not DirectoryExists(straux) then begin
        LogWarn(SOFTWARE_NAME+': env: initialization: o diretório '+straux+' não existe',TRUE);
        straux:=GetSpecialDir(sidMyDocuments);
        //TAMBÉM APENAS POR COMPLETUDE! NÃO OCORRE!
        if not DirectoryExists(straux) then
          LogWarn(SOFTWARE_NAME+': env: initialization: o diretório '+straux+' não existe',TRUE);
      end;
      _TMPDIR:=straux+DIRECTORY_SEPARATOR+SOFTWARE_NAME;
      if not DirectoryExists(_TMPDIR) then
        if not ForceDirectories(_TMPDIR) then begin
          _TMPDIR:=_DEPTOCOMDIR+DIRECTORY_SEPARATOR+'temp';
          if not DirectoryExists(_TMPDIR) then
            if not ForceDirectories(_TMPDIR) then
              raise Edeptocom.Create('NO TEMPORARY DIRECTORY');
        end;
      //else TEMOS O NOSSO DIRETÓRIO DE ARQUIVOS TEMPORÁRIOS!

      //tentamos registrar o diretório de arquivos temporários no registro do Windows,
      //na chave do software
      try
        if not SetRegistryValue('tmpdir',_TMPDIR) then
          raise Edeptocom.Create('não foi possível registrar o diretório de arquivos temporários [tmpdir] no registro do Windows');
      except
        on e:Exception do
          LogWarn(SOFTWARE_NAME+': env: initialization: '+e.Classname+': '+e.message,TRUE);
          //ainda que não tenhamos conseguido registrar o diretório
          //nós o temos e é possível iniciar a aplicação
          //emitimos apenas um aviso no arquivo de log
      end;
    end;

    //testar aqui os direitos de leitura e escrita no diretório de arquivos temporários

    folderOK:=TRUE;
  except
    on e:Exception do begin
      LogFatal(SOFTWARE_NAME+': env: initialization: '+e.Classname+': '+e.message+': não foi possível criar um diretório para arquivos temporários',
      RUNERR_NO_TMPDIR,TRUE); //sem um diretório para arquivos temporários
                              //não podemos iniciar o programa
    end;
  end;

  //verificar diretório de dados aqui
  errcode:=RUNERR_NO_DATADIR;
  folderOK:=FALSE;

  straux:='';
  errcode:=0;
  folderOK:=FALSE;
finalization
  if logfileOK then
    CloseFile(logfile);
  CloseStdOutputFile;
end.
