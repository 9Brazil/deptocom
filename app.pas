unit app;

interface

uses
  shlobj,
  sysutils,
  windows;

const
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

function getSpecialDir(const dirNum:csid):ansistring;
function queryRegistryValue(const nome:ansistring; out valor:ansistring; const key:ansistring=SOFTWARE_REGISTRYKEY; const rootkey:HKEY=HKEY_CURRENT_USER):boolean;
function setRegistryValue(const nome, valor : ansistring; const key:ansistring=SOFTWARE_REGISTRYKEY; const rootkey:HKEY=HKEY_CURRENT_USER):boolean;
function OS_USER:ansistring;
function COMPUTERNAME:ansistring;
function LOGFILENAME:ansistring;
function DEPTOCOMDIR:ansistring;
function BINDIR:ansistring;
function DATADIR:ansistring;
function TMPDIR:ansistring;
procedure logdebug(const msg:ansistring);
procedure logerror(const msg:ansistring);overload;
procedure logerror(const e:exception);overload;
procedure logfatal(const msg:ansistring; const errorCode:int32);
procedure loginfo(const msg:ansistring);
procedure logwarn(const msg:ansistring);

implementation

uses
  activex,
  registry;

//cria a pasta (chave) Computador\HKEY_CURRENT_USER\Software\deptocom no registro do Windows, se ela não existe
procedure createSoftwareRegistryKey;
var
  reg:tregistry;
begin
  reg:=tregistry.create(KEY_ALL_ACCESS);
  try
    reg.rootkey:=HKEY_CURRENT_USER;
    reg.openkey(SOFTWARE_REGISTRYKEY,true);
    reg.closekey;
  finally
    reg.free;
  end;
end;

function queryRegistryValue(const nome:ansistring; out valor:ansistring; const key:ansistring=SOFTWARE_REGISTRYKEY; const rootkey:HKEY=HKEY_CURRENT_USER):boolean;
var
  reg:tregistry;
begin
  reg:=tregistry.create(KEY_QUERY_VALUE);
  try
    reg.rootkey:=rootkey;
    result:=reg.openkey(key,false);
    if not result then exit;
    result:=reg.valueexists(nome);
    if result then
      valor:=reg.readstring(nome);
    reg.closekey;
  finally
    reg.free;
  end;
end;

function setRegistryValue(const nome, valor : ansistring; const key:ansistring=SOFTWARE_REGISTRYKEY; const rootkey:HKEY=HKEY_CURRENT_USER):boolean;
var
  reg:tregistry;
begin
  reg:=tregistry.create(KEY_SET_VALUE);
  try
    reg.rootkey:=rootkey;
    result:=reg.openkey(key,false);
    if not result then exit;
    reg.writestring(nome,valor);
    reg.closekey;
    result:=true;
  finally
    reg.free;
  end;
end;

function getSpecialDir(const dirNum:csid):ansistring;
var
  alloc:imalloc;
  specialdir:pItemIdList;
  buf:array[0..MAX_PATH] of char;
begin
  if SHGetMalloc(alloc)=NOERROR then
  begin
    SHGetSpecialFolderLocation(0,integer(dirnum),specialdir);
    SHGetPathFromIDList(specialdir,@buf[0]);
    alloc.free(specialdir);
    result:=ansistring(buf);
  end;
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
 getComputerName(compuname,size);
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

procedure logdebug(const msg:ansistring);
var
  line:ansistring;
begin
  line:=
    formatdatetime('[dd/mm/yyyy hh:nn:ss.zzz]',now)
    +'['+OS_USER+']'
    +'[DEBUG] '
    +msg;
  writeln(logfile,line);
end;

procedure logerror(const msg:ansistring);
var
  line:ansistring;
begin
  line:=
    formatdatetime('[dd/mm/yyyy hh:nn:ss.zzz]',now)
    +'['+OS_USER+']'
    +'[ERROR] '
    +msg;
  writeln(logfile,line);
end;

procedure logerror(const e:exception);
var
  line:ansistring;
begin
  line:=
    formatdatetime('[dd/mm/yyyy hh:nn:ss.zzz]',now)
    +'['+OS_USER+']'
    +'[ERROR] '
    +e.classname+': '+e.message;
  writeln(logfile,line);
end;

procedure logfatal(const msg:ansistring; const errorCode:int32);
var
  line:ansistring;
begin
  line:=
    formatdatetime('[dd/mm/yyyy hh:nn:ss.zzz]',now)
    +'['+OS_USER+']'
    +'[FATAL]'
    +'[runerror code: '+inttostr(errorCode)+'] '
    +msg;
  writeln(logfile,line);
  runerror(errorCode);
end;

procedure loginfo(const msg:ansistring);
var
  line:ansistring;
begin
  line:=
    formatdatetime('[dd/mm/yyyy hh:nn:ss.zzz]',now)
    +'['+OS_USER+']'
    +'[INFO] '
    +msg;
  writeln(logfile,line);
end;

procedure logwarn(const msg:ansistring);
var
  line:ansistring;
begin
  line:=
    formatdatetime('[dd/mm/yyyy hh:nn:ss.zzz]',now)
    +'['+OS_USER+']'
    +'[WARN] '
    +msg;
  writeln(logfile,line);
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
    createSoftwareRegistryKey;
    logfileOK:=false;
    errcode:=RUNERR_NO_LOGFILE;
    queryRegistryValue('logfile',_LOGFILENAME);
    _LOGFILENAME:=trim(_LOGFILENAME);
    if _LOGFILENAME='' then begin
      _LOGFILENAME:=LOG_FILE;
      setRegistryValue('logfile',_LOGFILENAME);
    end;
    assignFile(logfile,_LOGFILENAME);
    if fileExists(_LOGFILENAME) then
      append(logfile)
    else
      rewrite(logfile);
    logfileOK:=true;
  except
    on e:exception do begin
      writeln(SOFTWARE_NAME+': app: initialization: '+e.classname+': '+e.message);
      runerror(errcode);
    end;
  end;

  try
    _BINDIR:=getCurrentDir;
    binfolderOK:=lowerCase(extractfilename(_BINDIR))=lowerCase(BINARIES_FOLDER_NAME);
    if binfolderOK then
      _DEPTOCOMDIR:=extractFileDir(_BINDIR)
    else
      _DEPTOCOMDIR:=_BINDIR;
    setRegistryValue('bindir',_BINDIR);
    setRegistryValue('deptocomdir',_DEPTOCOMDIR);
  except
    on e:exception do
      logwarn(SOFTWARE_NAME+': app: initialization: '+e.classname+': '+e.message);
  end;

  //verifica a existência de um diretório para arquivos temporários
  //não existindo, tenta criá-lo
  try
    straux:=getSpecialDir(csidAppData);
    //APENAS POR COMPLETUDE! NÃO OCORRE!
    if not directoryExists(straux) then begin
      logwarn(SOFTWARE_NAME+': app: initialization: o diretório '+straux+' não existe');
      straux:=getSpecialDir(csidMyDocuments);
      if not directoryExists(straux) then
        logwarn(SOFTWARE_NAME+': app: initialization: o diretório '+straux+' não existe');
    end;

    _TMPDIR:=straux+DIRECTORY_SEPARATOR+SOFTWARE_NAME;
    if not directoryExists(_TMPDIR) then
      if not forceDirectories(_TMPDIR) then begin
        _TMPDIR:=_DEPTOCOMDIR+DIRECTORY_SEPARATOR+'temp';
        if not directoryExists(_TMPDIR) then
          if not forceDirectories(_TMPDIR) then
            raise exception.create('NO TEMPORARY DIRECTORY');
      end;
  except
    on e:exception do begin
      logfatal(SOFTWARE_NAME+': app: initialization: '+e.classname+': '+e.message+': Não foi possível criar um diretório para arquivos temporários.',
      RUNERR_NO_TMPDIR);  //sem um diretório para arquivos temporários
                          //não podemos iniciar o programa
    end;
  end;

  try
    setRegistryValue('tmpdir',_TMPDIR);
  except
    on e:exception do
      logwarn(SOFTWARE_NAME+': app: initialization: '+e.classname+': '+e.message);
  end;

  straux:='';
  errcode:=0;
finalization
  if logfileOK then
    closeFile(logfile);
end.
