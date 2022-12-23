unit app;

interface

uses
  os;

const
  SOFTWARE_NAME='deptocom';

  BINARIES_FOLDER_NAME='bin';
  DATA_FOLDER_NAME='data';

  TABLE_SUFFIX='.dat';
  HISTORY_TABLE_SUFFIX='.h.dat';

  //RUNTIME ERROR CODES
  //RUNERR_INVALID_BINDIR=3;
  //RUNERR_INVALID_SOFTWAREDIR=5;
  RUNERR_NOTEMPDIR=7;

function DEPTOCOMDIR:ansistring;
function BINDIR:ansistring;
function DATADIR:ansistring;
function TEMPDIR:ansistring;

implementation

uses
  sysutils;

var
  _DEPTOCOMDIR,
  _BINDIR,
  _DATADIR,
  _TEMPDIR
    :ansistring;

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
  if not binfolderOK then
    runerror(RUNERR_INVALID_BINDIR);//a pasta dos binários deve coincidir com o especificado no código
  *)

  if binfolderOK then
    _DEPTOCOMDIR:=extractfiledir(_BINDIR)
  else
    _DEPTOCOMDIR:=_BINDIR;

  //softwarefolderOK:=lowercase(extractfilename(_DEPTOCOMDIR))=lowercase(SOFTWARE_NAME);
  (*
  if not softwarefolderOK then
    runerror(RUNERR_INVALID_SOFTWAREDIR);//a pasta do software deve coincidir com o nome do software especificado no código
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
    runerror(RUNERR_NOTEMPDIR); //sem um diretório para arquivo temporários
                                //não podemos iniciar o programa
  end;

  straux:='';
finalization
  //
  //
  //
end.
