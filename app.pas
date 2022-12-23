unit app;

interface

uses
  shlobj,
  sysutils,
  windows;

const
  DIRECTORY_SEPARATOR='\';
  DRIVE_SEPARATOR=':';
  EOL=#13#10;

  SOFTWARE_NAME='deptocom';
  LOG_SUFFIX='.log';
  LOG_FILE=SOFTWARE_NAME+LOG_SUFFIX;
  REGISTRY_MAINKEY='Software'+DIRECTORY_SEPARATOR+SOFTWARE_NAME+DIRECTORY_SEPARATOR;
  BINARIES_FOLDER_NAME='bin';//default
  DATA_FOLDER_NAME='data';//default
  TABLE_SUFFIX='.dat';
  HISTORY_TABLE_SUFFIX='.h.dat';

  //CUSTOM RUNTIME ERROR CODES
  RUNERR_NO_REGISTRY_MAINKEY=71;
  RUNERR_NO_LOGFILE=72;
  //RUNERR_INVALID_BINDIR=73;
  //RUNERR_INVALID_SOFTWAREDIR=74;
  RUNERR_NO_TEMPDIR=75;

type
  float=single;
  //byte1=byte;
  byte2=word;
  byte4=cardinal;
  int8=shortint;
  int16=smallint;
  int32=integer;
  //utf8string=

  csid=(
    csidDesktop=CSIDL_DESKTOP,
    csidMyDocuments=CSIDL_PERSONAL,
    csidFavorites=CSIDL_FAVORITES,
    csidStartup=CSIDL_STARTUP,
    csidStartMenu=CSIDL_STARTMENU,
    csidFonts=CSIDL_FONTS,
    csidAppData=CSIDL_APPDATA
  );

  edeptocom=class(exception);

function specialdir(const dirnum:csid):ansistring;
function queryregistry(const nome:ansistring; out valor:ansistring; const rootkey:HKEY=HKEY_CURRENT_USER):boolean;
function OS_USER:ansistring;
function COMPUTERNAME:ansistring;
function LOGFILENAME:ansistring;
function DEPTOCOMDIR:ansistring;
function BINDIR:ansistring;
function DATADIR:ansistring;
function TEMPDIR:ansistring;
procedure logdebug(const msg:ansistring);
procedure logerror(const msg:ansistring);
procedure logfatal(const msg:ansistring);
procedure loginfo(const msg:ansistring);
procedure logwarn(const msg:ansistring);

implementation

uses
  activex,
  registry;

//cria a pasta (chave) Computador\HKEY_CURRENT_USER\Software\deptcom no registro do Windows, se ela não existe
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

function queryregistry(const nome:ansistring; out valor:ansistring; const rootkey:HKEY=HKEY_CURRENT_USER):boolean;
var
  reg:tregistry;
begin
  reg:=tregistry.create(KEY_QUERY_VALUE);
  try
    reg.rootkey:=rootkey;
    result:=reg.openkey(REGISTRY_MAINKEY,false);
    if not result then exit;
    result:=reg.valueexists(nome);
    if result then
      valor:=reg.readstring(nome);
    reg.closekey;
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
  _TEMPDIR
    :ansistring;
  logfile
    :textfile;

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

function TEMPDIR:ansistring;
begin
  result:=_TEMPDIR;
end;

procedure logdebug(const msg:ansistring);
begin

end;

procedure logerror(const msg:ansistring);
begin

end;

procedure logfatal(const msg:ansistring);
begin

end;

procedure loginfo(const msg:ansistring);
begin

end;

procedure logwarn(const msg:ansistring);
begin

end;

var
  reg
    :tregistry;
  straux
    :ansistring;
  errcode
    :int32;
  binfolderOK,
  //softwarefolderOK,
  logfileOK
    :boolean;

initialization
  try
    errcode:=RUNERR_NO_REGISTRY_MAINKEY;
    createmainkey;
    errcode:=RUNERR_NO_LOGFILE;
    queryregistry('logfile',_LOGFILENAME);
    _LOGFILENAME:=trim(_LOGFILENAME);
    if _LOGFILENAME='' then begin
      _LOGFILENAME:=LOG_FILE;
      //registra o novo nome do arquivo de log
    end;
    assignfile(logfile,_LOGFILENAME);
    if fileexists(_LOGFILENAME) then
      append(logfile)
    else
      rewrite(logfile);
    logfileOK:=true;
  except
    on e:exception do begin
      writeln(e.classname+': '+e.message);
      runerror(errcode);
    end;
  end;

  _BINDIR:=getcurrentdir;
  binfolderOK:=lowercase(extractfilename(_BINDIR))=lowercase(BINARIES_FOLDER_NAME);
  (*
  if not binfolderOK then begin
    //logfatal(SOFTWARE_NAME+': app: Runtime Error: '+inttostr(RUNERR_INVALID_BINDIR)+': O diretório dos binários não coincide com a especificação do software.');
    runerror(RUNERR_INVALID_BINDIR);//a pasta dos binários deve coincidir com o especificado no código
  end;
  *)

  if binfolderOK then
    _DEPTOCOMDIR:=extractfiledir(_BINDIR)
  else
    _DEPTOCOMDIR:=_BINDIR;

  //softwarefolderOK:=lowercase(extractfilename(_DEPTOCOMDIR))=lowercase(SOFTWARE_NAME);
  (*
  if not softwarefolderOK then begin
    //logfatal(SOFTWARE_NAME+': app: Runtime Error: '+inttostr(RUNERR_INVALID_SOFTWAREDIR)+': O diretório do software é inválido.');
    runerror(RUNERR_INVALID_SOFTWAREDIR);//a pasta do software deve coincidir com o nome do software especificado no código
  end;
  *)

  //verifica a existência de um diretório para arquivos temporários
  //não existindo, tenta criá-lo
  try
    straux:=specialdir(csidAppData);
    //APENAS POR COMPLETUDE! NÃO OCORRE!
    if not directoryexists(straux) then begin
      logwarn(SOFTWARE_NAME+': app: o diretório '+straux+' não existe');
      straux:=specialdir(csidMyDocuments);
      if not directoryexists(straux) then
        logwarn(SOFTWARE_NAME+': app: o diretório '+straux+' não existe');
    end;

    _TEMPDIR:=straux+DIRECTORY_SEPARATOR+SOFTWARE_NAME;
    if not directoryexists(_TEMPDIR) then
      if not forcedirectories(_TEMPDIR) then begin
        _TEMPDIR:=_DEPTOCOMDIR+DIRECTORY_SEPARATOR+'temp';
        if not directoryexists(_TEMPDIR) then
          if not forcedirectories(_TEMPDIR) then
            raise exception.create('NO TEMPORARY DIRECTORY');
      end;
  except
    on e:exception do begin
      logfatal(SOFTWARE_NAME+': app: Runtime Error: '+inttostr(RUNERR_NO_TEMPDIR)+': '+e.classname+': '+e.message+': Não foi possível criar um diretório para arquivos temporários.');
      runerror(RUNERR_NO_TEMPDIR);  //sem um diretório para arquivos temporários
                                    //não podemos iniciar o programa
    end;
  end;

  straux:='';
  errcode:=0;
finalization
  if logfileOK then
    closefile(logfile);
end.
