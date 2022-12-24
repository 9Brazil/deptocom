unit app;

interface

uses
  shlobj,
  sysutils,
  windows;

const
  DIRECTORY_SEPARATOR='\';

  SOFTWARE_NAME='deptocom';
  LOG_SUFFIX='.log';
  LOG_FILE=SOFTWARE_NAME+LOG_SUFFIX;
  REGISTRY_MAINKEY='Software'+DIRECTORY_SEPARATOR+SOFTWARE_NAME+DIRECTORY_SEPARATOR;
  BINARIES_FOLDER_NAME='bin';//default
  DATA_FOLDER_NAME='data';//default
  TABLE_SUFFIX='.dat';
  HISTORY_TABLE_SUFFIX='.h.dat';

  //CUSTOM RUNTIME ERROR CODES
  RUNERR_NO_REGISTRY_MAINKEY=51;
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

function specialdir(const dirnum:csid):ansistring;
function queryregistryvalue(const nome:ansistring; out valor:ansistring; const key:ansistring=REGISTRY_MAINKEY; const rootkey:HKEY=HKEY_CURRENT_USER):boolean;
function setregistryvalue(const nome, valor : ansistring; const key:ansistring=REGISTRY_MAINKEY; const rootkey:HKEY=HKEY_CURRENT_USER):boolean;
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

//cria a pasta (chave) Computador\HKEY_CURRENT_USER\Software\deptocom no registro do Windows, se ela n�o existe
procedure createmainkey;
var
  reg:tregistry;
begin
  reg:=tregistry.create(KEY_ALL_ACCESS);
  try
    reg.rootkey:=HKEY_CURRENT_USER;
    reg.openkey(REGISTRY_MAINKEY,true);
    reg.closekey;
  finally
    reg.free;
  end;
end;

function queryregistryvalue(const nome:ansistring; out valor:ansistring; const key:ansistring=REGISTRY_MAINKEY; const rootkey:HKEY=HKEY_CURRENT_USER):boolean;
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

function setregistryvalue(const nome, valor : ansistring; const key:ansistring=REGISTRY_MAINKEY; const rootkey:HKEY=HKEY_CURRENT_USER):boolean;
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

function specialdir(const dirnum:csid):ansistring;
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
  computerName:array[0..256] of char;
  size:dword;
begin
 size:=256;
 getComputerName(computerName,size);
 result:=computerName;
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
begin

end;

procedure logerror(const msg:ansistring);
var
  line:ansistring;
begin
  line:=
    formatdatetime('[dd/mm/yyyy hh:nn:ss.zzz]',now)
    +'['+COMPUTERNAME+'\'+OS_USER+']'
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
    +'['+COMPUTERNAME+'\'+OS_USER+']'
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
    +'['+COMPUTERNAME+'\'+OS_USER+']'
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
    +'['+COMPUTERNAME+'\'+OS_USER+']'
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
    +'['+COMPUTERNAME+'\'+OS_USER+']'
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
  errcode:=RUNERR_NO_REGISTRY_MAINKEY;
  try
    createmainkey;
    logfileOK:=false;
    errcode:=RUNERR_NO_LOGFILE;
    queryregistryvalue('logfile',_LOGFILENAME);
    _LOGFILENAME:=trim(_LOGFILENAME);
    if _LOGFILENAME='' then begin
      _LOGFILENAME:=LOG_FILE;
      setregistryvalue('logfile',_LOGFILENAME);
    end;
    assignfile(logfile,_LOGFILENAME);
    if fileexists(_LOGFILENAME) then
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
    _BINDIR:=getcurrentdir;
    binfolderOK:=lowercase(extractfilename(_BINDIR))=lowercase(BINARIES_FOLDER_NAME);
    if binfolderOK then
      _DEPTOCOMDIR:=extractfiledir(_BINDIR)
    else
      _DEPTOCOMDIR:=_BINDIR;
    setregistryvalue('bindir',_BINDIR);
    setregistryvalue('deptocomdir',_DEPTOCOMDIR);
  except
    on e:exception do
      logwarn(SOFTWARE_NAME+': app: initialization: '+e.classname+': '+e.message);
  end;

  //verifica a exist�ncia de um diret�rio para arquivos tempor�rios
  //n�o existindo, tenta cri�-lo
  try
    straux:=specialdir(csidAppData);
    //APENAS POR COMPLETUDE! N�O OCORRE!
    if not directoryexists(straux) then begin
      logwarn(SOFTWARE_NAME+': app: initialization: o diret�rio '+straux+' n�o existe');
      straux:=specialdir(csidMyDocuments);
      if not directoryexists(straux) then
        logwarn(SOFTWARE_NAME+': app: initialization: o diret�rio '+straux+' n�o existe');
    end;

    _TMPDIR:=straux+DIRECTORY_SEPARATOR+SOFTWARE_NAME;
    if not directoryexists(_TMPDIR) then
      if not forcedirectories(_TMPDIR) then begin
        _TMPDIR:=_DEPTOCOMDIR+DIRECTORY_SEPARATOR+'temp';
        if not directoryexists(_TMPDIR) then
          if not forcedirectories(_TMPDIR) then
            raise exception.create('NO TEMPORARY DIRECTORY');
      end;
  except
    on e:exception do begin
      logfatal(SOFTWARE_NAME+': app: initialization: '+e.classname+': '+e.message+': N�o foi poss�vel criar um diret�rio para arquivos tempor�rios.',
      RUNERR_NO_TMPDIR); //sem um diret�rio para arquivos tempor�rios
                          //n�o podemos iniciar o programa
    end;
  end;

  try
    setregistryvalue('tmpdir',_TMPDIR);
  except
    on e:exception do
      logwarn(SOFTWARE_NAME+': app: initialization: '+e.classname+': '+e.message);
  end;

  straux:='';
  errcode:=0;
finalization
  if logfileOK then
    closefile(logfile);
end.
