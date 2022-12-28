unit env;

interface

uses
  shlobj,
  sysutils,
  windows;

const
  DWMAPI = 'DWMAPI.DLL';

  DIRECTORY_SEPARATOR='\';

  SOFTWARE_NAME='deptocom';
  SOFTWARE_REGISTRYKEY='Software'+DIRECTORY_SEPARATOR+SOFTWARE_NAME+DIRECTORY_SEPARATOR;
  LOG_SUFFIX='.log';
  LOG_FILE=SOFTWARE_NAME+LOG_SUFFIX;
  BINARIES_FOLDER_NAME='bin';//default
  DATA_FOLDER_NAME='data';//default
  TABLE_SUFFIX='.dat';
  HISTORY_TABLE_SUFFIX='.h.dat';

  //CUSTOM RUNTIME ERROR CODES
  RUNERR_NO_SOFTWARE_REGISTRYKEY=51;
  RUNERR_NO_LOGFILE=52;
  //RUNERR_INVALID_BINDIR=53;
  RUNERR_NO_TMPDIR=54;

type
  float=single;
  int8=shortint;
  int16=smallint;
  int32=integer;

  csid=(
    csidDesktop=CSIDL_DESKTOP,
    csidMyDocuments=CSIDL_PERSONAL,
    csidFavorites=CSIDL_FAVORITES,
    csidStartup=CSIDL_STARTUP,
    csidStartMenu=CSIDL_STARTMENU,
    csidFonts=CSIDL_FONTS,
    csidAppData=CSIDL_APPDATA
  );

function GetSpecialDir(const dirNum:csid):ansistring;

function QueryRegistryValue(const nome:ansistring; out valor:ansistring; const key:ansistring=SOFTWARE_REGISTRYKEY; const rootkey:HKEY=HKEY_CURRENT_USER):boolean;
function SetRegistryValue(const nome, valor : ansistring; const key:ansistring=SOFTWARE_REGISTRYKEY; const rootkey:HKEY=HKEY_CURRENT_USER):boolean;

function GetConsoleWindow:HWND; stdcall; external kernel32;
procedure HideConsole;
procedure ShowConsole;

function SCREEN_SIZE:TSize;
function OS_USER:ansistring;
function COMPUTERNAME:ansistring;
function LOGFILENAME:ansistring;
function DEPTOCOMDIR:ansistring;
function BINDIR:ansistring;
function DATADIR:ansistring;
function TMPDIR:ansistring;

procedure LogDebug(const msg:ansistring);
procedure LogError(const msg:ansistring);overload;
procedure LogError(const e:Exception);overload;
procedure LogFatal(const msg:ansistring; const errorCode:int32);
procedure LogInfo(const msg:ansistring);
procedure LogWarn(const msg:ansistring);

implementation

uses
  activex,
  registry;

function GetSpecialDir(const dirNum:csid):ansistring;
var
  alloc:imalloc;
  specialdir:pItemIdList;
  buf:array[0..MAX_PATH] of char;
begin
  if SHGetMalloc(alloc)=NOERROR then
  begin
    SHGetSpecialFolderLocation(0,integer(dirnum),specialdir);
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
    reg.OpenKey(SOFTWARE_REGISTRYKEY,true);
    reg.CloseKey;
  finally
    reg.Free;
  end;
end;

function QueryRegistryValue(const nome:ansistring; out valor:ansistring; const key:ansistring=SOFTWARE_REGISTRYKEY; const rootkey:HKEY=HKEY_CURRENT_USER):boolean;
var
  reg:TRegistry;
begin
  reg:=TRegistry.Create(KEY_QUERY_VALUE);
  try
    reg.rootkey:=rootkey;
    result:=reg.OpenKey(key,false);
    if not result then Exit;
    result:=reg.ValueExists(nome);
    if result then
      valor:=reg.ReadString(nome);
    reg.CloseKey;
  finally
    reg.Free;
  end;
end;

function SetRegistryValue(const nome, valor : ansistring; const key:ansistring=SOFTWARE_REGISTRYKEY; const rootkey:HKEY=HKEY_CURRENT_USER):boolean;
var
  reg:TRegistry;
begin
  reg:=TRegistry.Create(KEY_SET_VALUE);
  try
    reg.rootkey:=rootkey;
    result:=reg.OpenKey(key,false);
    if not result then Exit;
    reg.WriteString(nome,valor);
    reg.CloseKey;
    result:=true;
  finally
    reg.Free;
  end;
end;

procedure HideConsole;
begin
  if isConsole then
    ShowWindow(GetConsoleWindow,SW_HIDE);
end;

procedure ShowConsole;
begin
  if isConsole then
    ShowWindow(GetConsoleWindow,SW_NORMAL);
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

var
  _LOGFILENAME,
  _DEPTOCOMDIR,
  _BINDIR,
  _DATADIR,
  _TMPDIR
    :ansistring;

function LOGFILENAME:ansistring;
begin
  result:=_LOGFILENAME;
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

var
  logfile
    :textfile;

procedure LogDebug(const msg:ansistring);
var
  line:ansistring;
begin
  line:=
    FormatDatetime('[dd/mm/yyyy hh:nn:ss.zzz]',now)
    +'['+OS_USER+']'
    +'[DEBUG] '
    +msg;
  Writeln(logfile,line);
end;

procedure LogError(const msg:ansistring);
var
  line:ansistring;
begin
  line:=
    FormatDatetime('[dd/mm/yyyy hh:nn:ss.zzz]',now)
    +'['+OS_USER+']'
    +'[ERROR] '
    +msg;
  Writeln(logfile,line);
end;

procedure LogError(const e:Exception);
var
  line:ansistring;
begin
  line:=
    FormatDatetime('[dd/mm/yyyy hh:nn:ss.zzz]',now)
    +'['+OS_USER+']'
    +'[ERROR] '
    +e.classname+': '+e.message;
  Writeln(logfile,line);
end;

procedure LogFatal(const msg:ansistring; const errorCode:int32);
var
  line:ansistring;
begin
  line:=
    FormatDatetime('[dd/mm/yyyy hh:nn:ss.zzz]',now)
    +'['+OS_USER+']'
    +'[FATAL]'
    +'[runerror code: '+IntToStr(errorCode)+'] '
    +msg;
  Writeln(logfile,line);
  Runerror(errorCode);
end;

procedure LogInfo(const msg:ansistring);
var
  line:ansistring;
begin
  line:=
    FormatDatetime('[dd/mm/yyyy hh:nn:ss.zzz]',now)
    +'['+OS_USER+']'
    +'[INFO] '
    +msg;
  Writeln(logfile,line);
end;

procedure LogWarn(const msg:ansistring);
var
  line:ansistring;
begin
  line:=
    FormatDatetime('[dd/mm/yyyy hh:nn:ss.zzz]',now)
    +'['+OS_USER+']'
    +'[WARN] '
    +msg;
  Writeln(logfile,line);
end;

var
  straux
    :ansistring;
  errcode
    :int32;
  binfolderOK,
  logfileOK
    :boolean;

initialization
  errcode:=RUNERR_NO_SOFTWARE_REGISTRYKEY;
  try
    CreateSoftwareRegistryKey;
    logfileOK:=false;
    errcode:=RUNERR_NO_LOGFILE;
    QueryRegistryValue('logfile',_LOGFILENAME);
    _LOGFILENAME:=Trim(_LOGFILENAME);
    if _LOGFILENAME='' then begin
      _LOGFILENAME:=LOG_FILE;
      SetRegistryValue('logfile',_LOGFILENAME);
    end;
    AssignFile(logfile,_LOGFILENAME);
    if FileExists(_LOGFILENAME) then
      Append(logfile)
    else
      Rewrite(logfile);
    logfileOK:=true;
  except
    on e:Exception do begin
      Writeln(SOFTWARE_NAME+': env: initialization: '+e.Classname+': '+e.message);
      Runerror(errcode);
    end;
  end;

  try
    _BINDIR:=GetCurrentDir;
    binfolderOK:=LowerCase(ExtractFilename(_BINDIR))=LowerCase(BINARIES_FOLDER_NAME);
    if binfolderOK then
      _DEPTOCOMDIR:=ExtractFileDir(_BINDIR)
    else
      _DEPTOCOMDIR:=_BINDIR;
    SetRegistryValue('bindir',_BINDIR);
    SetRegistryValue('deptocomdir',_DEPTOCOMDIR);
  except
    on e:Exception do
      LogWarn(SOFTWARE_NAME+': env: initialization: '+e.Classname+': '+e.message);
  end;

  //verifica a existência de um diretório para arquivos temporários
  //não existindo, tenta criá-lo
  try
    straux:=GetSpecialDir(csidAppData);
    //APENAS POR COMPLETUDE! NÃO OCORRE!
    if not DirectoryExists(straux) then begin
      LogWarn(SOFTWARE_NAME+': env: initialization: o diretório '+straux+' não existe');
      straux:=GetSpecialDir(csidMyDocuments);
      if not DirectoryExists(straux) then
        LogWarn(SOFTWARE_NAME+': env: initialization: o diretório '+straux+' não existe');
    end;

    _TMPDIR:=straux+DIRECTORY_SEPARATOR+SOFTWARE_NAME;
    if not DirectoryExists(_TMPDIR) then
      if not ForceDirectories(_TMPDIR) then begin
        _TMPDIR:=_DEPTOCOMDIR+DIRECTORY_SEPARATOR+'temp';
        if not DirectoryExists(_TMPDIR) then
          if not ForceDirectories(_TMPDIR) then
            raise Exception.Create('NO TEMPORARY DIRECTORY');
      end;
  except
    on e:Exception do begin
      LogFatal(SOFTWARE_NAME+': env: initialization: '+e.Classname+': '+e.message+': Não foi possível criar um diretório para arquivos temporários.',
      RUNERR_NO_TMPDIR);  //sem um diretório para arquivos temporários
                          //não podemos iniciar o programa
    end;
  end;

  try
    SetRegistryValue('tmpdir',_TMPDIR);
  except
    on e:Exception do
      LogWarn(SOFTWARE_NAME+': env: initialization: '+e.Classname+': '+e.message);
  end;

  straux:='';
  errcode:=0;
finalization
  if logfileOK then
    CloseFile(logfile);
end.
