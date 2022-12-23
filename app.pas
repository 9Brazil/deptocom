unit app;

interface

uses
  shlobj;

const
  DIRECTORY_SEPARATOR='\';
  DRIVE_SEPARATOR=':';
  EOL=#13#10;

  SOFTWARE_NAME='deptocom';
  REGISTRY_MAINKEY='Software'+DIRECTORY_SEPARATOR+SOFTWARE_NAME+DIRECTORY_SEPARATOR;
  BINARIES_FOLDER_NAME='bin';//default
  DATA_FOLDER_NAME='data';//default
  TABLE_SUFFIX='.dat';
  HISTORY_TABLE_SUFFIX='.h.dat';

  //RUNTIME ERROR CODES
  //RUNERR_INVALID_BINDIR=3;
  //RUNERR_INVALID_SOFTWAREDIR=5;
  RUNERR_NOTEMPDIR=7;

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

function specialdir(const dirnum:csid):ansistring;
function OS_USER:ansistring;
function COMPUTERNAME:ansistring;
function LOGFILE:ansistring;
function DEPTOCOMDIR:ansistring;
function BINDIR:ansistring;
function DATADIR:ansistring;
function TEMPDIR:ansistring;

implementation

uses
  activex,
  //log,
  sysutils,
  windows;

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
  _LOGFILE,
  _DEPTOCOMDIR,
  _BINDIR,
  _DATADIR,
  _TEMPDIR
    :ansistring;

function LOGFILE:ansistring;
begin
  result:=_LOGFILE;
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

var
  straux
    :ansistring;
  binfolderOK
  //,softwarefolderOK
    :boolean;

initialization
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
    if not directoryexists(straux) then
      straux:=specialdir(csidMyDocuments);
    _tempdir:=straux+DIRECTORY_SEPARATOR+SOFTWARE_NAME;
    if not directoryexists(_TEMPDIR) then
      if not forcedirectories(_TEMPDIR) then begin
        _TEMPDIR:=_DEPTOCOMDIR+DIRECTORY_SEPARATOR+'temp';
        if not directoryexists(_TEMPDIR) then
          if not forcedirectories(_TEMPDIR) then
            raise exception.create('NO TEMPORARY DIRECTORY');
      end;
  except
    //on e:exception do logfatal(SOFTWARE_NAME+': app: Runtime Error: '+inttostr(RUNERR_NOTEMPDIR)+': '+e.message+': Não foi possível criar um diretório para arquivos temporários.');
    runerror(RUNERR_NOTEMPDIR); //sem um diretório para arquivos temporários
                                //não podemos iniciar o programa
  end;

  straux:='';
finalization
  //
  //
  //
end.
