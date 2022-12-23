unit app;

interface

uses
  os;

const
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

function LOGFILE:ansistring;
function DEPTOCOMDIR:ansistring;
function BINDIR:ansistring;
function DATADIR:ansistring;
function TEMPDIR:ansistring;

implementation

uses
  //log,
  sysutils;

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
    //logfatal(SOFTWARE_NAME+': app: Runtime Error: '+inttostr(RUNERR_INVALID_BINDIR)+': O diret�rio dos bin�rios n�o coincide com a especifica��o do software.');
    runerror(RUNERR_INVALID_BINDIR);//a pasta dos bin�rios deve coincidir com o especificado no c�digo
  end;
  *)

  if binfolderOK then
    _DEPTOCOMDIR:=extractfiledir(_BINDIR)
  else
    _DEPTOCOMDIR:=_BINDIR;

  //softwarefolderOK:=lowercase(extractfilename(_DEPTOCOMDIR))=lowercase(SOFTWARE_NAME);
  (*
  if not softwarefolderOK then begin
    //logfatal(SOFTWARE_NAME+': app: Runtime Error: '+inttostr(RUNERR_INVALID_SOFTWAREDIR)+': O diret�rio do software � inv�lido.');
    runerror(RUNERR_INVALID_SOFTWAREDIR);//a pasta do software deve coincidir com o nome do software especificado no c�digo
  end;
  *)

  //verifica a exist�ncia de um diret�rio para arquivos tempor�rios
  //n�o existindo, tenta cri�-lo
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
    //on e:exception do logfatal(SOFTWARE_NAME+': app: Runtime Error: '+inttostr(RUNERR_NOTEMPDIR)+': '+e.message+': N�o foi poss�vel criar um diret�rio para arquivos tempor�rios.');
    runerror(RUNERR_NOTEMPDIR); //sem um diret�rio para arquivos tempor�rios
                                //n�o podemos iniciar o programa
  end;

  straux:='';
finalization
  //
  //
  //
end.
