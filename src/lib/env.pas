unit env{ironment};

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
  LOG_SUFFIX='.log';//default
  LOG_FILE=SOFTWARE_NAME+LOG_SUFFIX;//default
  BINARIES_FOLDER_NAME='bin';//default
  DATA_FOLDER_NAME='data';//default
  TABLE_SUFFIX='.dat';//default
  HISTORY_TABLE_SUFFIX='.h.dat';//default
  LOGIN_TABLE='login.dat';//default

  //CUSTOM RUNTIME ERROR CODES
  RUNERR_NO_SOFTWARE_REGISTRYKEY=51;
  RUNERR_NO_LOGFILE=52;
  //RUNERR_INVALID_BINDIR=53;
  RUNERR_NO_TMPDIR=54;
  RUNERR_NO_DATADIR=55;
  RUNERR_NO_LOGINTABLE=56;

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

  Edeptocom=class(Exception);

function GetSpecialDir(const dirNum:csid):ansistring;

function QueryRegistryValue(const nome:ansistring; out valor:ansistring; const key:ansistring=SOFTWARE_REGISTRYKEY; const rootkey:HKEY=HKEY_CURRENT_USER):boolean;
function SetRegistryValue(const nome, valor : ansistring; const key:ansistring=SOFTWARE_REGISTRYKEY; const rootkey:HKEY=HKEY_CURRENT_USER):boolean;

function GetConsoleWindow:HWND; stdcall; external kernel32;
procedure HideConsole;
procedure ShowConsole;
function ConsoleIsVisible:boolean;

function SCREEN_SIZE:TSize;
function OS_USER:ansistring;
function COMPUTERNAME:ansistring;
function LOGFILENAME:ansistring;
function DEPTOCOMDIR:ansistring;
function BINDIR:ansistring;
function DATADIR:ansistring;
function TMPDIR:ansistring;

procedure LogDebug(const msg:ansistring; const flushmsg:boolean=false);
procedure LogError(const msg:ansistring; const flushmsg:boolean=false);overload;
procedure LogError(const e:Exception; const flushmsg:boolean=false);overload;
procedure LogFatal(const msg:ansistring; const errorCode:int32; const flushmsg:boolean=false);
procedure LogInfo(const msg:ansistring; const flushmsg:boolean=false);
procedure LogWarn(const msg:ansistring; const flushmsg:boolean=false);

implementation

uses
  activex,
  registry;

var
  _LOGFILENAME,
  _DEPTOCOMDIR,
  _BINDIR,
  _DATADIR,
  _TMPDIR
    :ansistring;
  logfile
    :textfile;
  logfileOK
    :boolean=false;
  consoleVisible
    :boolean=false;
  unitInitializationOK
    :boolean=false;

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
    if reg.OpenKey(SOFTWARE_REGISTRYKEY,true) then
      reg.CloseKey;
  finally
    reg.Free;
  end;
end;

function QueryRegistryValue(const nome:ansistring; out valor:ansistring; const key:ansistring=SOFTWARE_REGISTRYKEY; const rootkey:HKEY=HKEY_CURRENT_USER):boolean;
var
  reg:TRegistry;
begin
  result:=false;
  try
    reg:=TRegistry.Create(KEY_QUERY_VALUE);
    try
      reg.rootkey:=rootkey;
      if not reg.OpenKey(key,false) then Exit;
      try
        if reg.ValueExists(nome) then begin
          valor:=reg.ReadString(nome);
          result:=true;
        end;
      finally
        reg.CloseKey;
      end;
    finally
      reg.Free;
    end;
  except on e:Exception do begin
      if unitInitializationOK then
        LogError(e)
      else
      if unitInitializationOK and isConsole and consoleVisible then
        Writeln(SOFTWARE_NAME+': env.QueryRegistryValue: '+e.Classname+': '+e.message)
      else raise e;
    end;
  end;
end;

function SetRegistryValue(const nome, valor : ansistring; const key:ansistring=SOFTWARE_REGISTRYKEY; const rootkey:HKEY=HKEY_CURRENT_USER):boolean;
var
  reg:TRegistry;
begin
  result:=false;
  try
    reg:=TRegistry.Create(KEY_SET_VALUE);
    try
      reg.rootkey:=rootkey;
      if not reg.OpenKey(key,false) then Exit;
      reg.WriteString(nome,valor);
      reg.CloseKey;
      result:=true;
    finally
      reg.Free;
    end;
  except on e:Exception do begin
      if unitInitializationOK then
        LogError(e)
      else
      if unitInitializationOK and isConsole and consoleVisible then
        Writeln(SOFTWARE_NAME+': env.SetRegistryValue: '+e.Classname+': '+e.message)
      else raise e;
    end;
  end;
end;

procedure HideConsole;
begin
  if isConsole and consoleVisible then begin
    ShowWindow(GetConsoleWindow,SW_HIDE);
    consoleVisible:=false;
  end;
end;

procedure ShowConsole;
begin
  if isConsole and (not consoleVisible) then begin
    ShowWindow(GetConsoleWindow,SW_NORMAL);
    consoleVisible:=true;
  end;
end;

function ConsoleIsVisible:boolean;
begin
  result:=consoleVisible;
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

procedure LogDebug(const msg:ansistring; const flushmsg:boolean=false);
var
  line:ansistring;
begin
  line:=
    FormatDatetime('[dd/mm/yyyy hh:nn:ss.zzz]',now)
    +'['+OS_USER+']'
    +'[DEBUG] '
    +msg;
  Writeln(logfile,line);
  if flushmsg then
    flush(logfile);
end;

procedure LogError(const msg:ansistring; const flushmsg:boolean=false);
var
  line:ansistring;
begin
  line:=
    FormatDatetime('[dd/mm/yyyy hh:nn:ss.zzz]',now)
    +'['+OS_USER+']'
    +'[ERROR] '
    +msg;
  Writeln(logfile,line);
  if flushmsg then
    flush(logfile);
end;

procedure LogError(const e:Exception; const flushmsg:boolean=false);
var
  line:ansistring;
begin
  line:=
    FormatDatetime('[dd/mm/yyyy hh:nn:ss.zzz]',now)
    +'['+OS_USER+']'
    +'[ERROR] '
    +e.classname+': '+e.message;
  Writeln(logfile,line);
  if flushmsg then
    flush(logfile);
end;

procedure LogFatal(const msg:ansistring; const errorCode:int32; const flushmsg:boolean=false);
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
  if flushmsg then
    flush(logfile);
  Runerror(errorCode);
end;

procedure LogInfo(const msg:ansistring; const flushmsg:boolean=false);
var
  line:ansistring;
begin
  line:=
    FormatDatetime('[dd/mm/yyyy hh:nn:ss.zzz]',now)
    +'['+OS_USER+']'
    +'[INFO] '
    +msg;
  Writeln(logfile,line);
  if flushmsg then
    flush(logfile);
end;

procedure LogWarn(const msg:ansistring; const flushmsg:boolean=false);
var
  line:ansistring;
begin
  line:=
    FormatDatetime('[dd/mm/yyyy hh:nn:ss.zzz]',now)
    +'['+OS_USER+']'
    +'[WARN] '
    +msg;
  Writeln(logfile,line);
  if flushmsg then
    flush(logfile);
end;

var
  straux
    :ansistring='';
  errcode
    :int32=0;
  folderOK
    :boolean=false;

initialization
  consoleVisible:=isConsole;

  //verifica o diretório (chave) do software no registro do Windows
  //e o arquivo de log da aplicação
  //(sem um arquivo de log, não iniciamos a aplicação!)
  errcode:=RUNERR_NO_SOFTWARE_REGISTRYKEY;
  logfileOK:=false;
  try
    CreateSoftwareRegistryKey;
    errcode:=RUNERR_NO_LOGFILE;
    try
      if isConsole and consoleVisible and (not QueryRegistryValue('logfile',_LOGFILENAME)) then
        Writeln(SOFTWARE_NAME+': env: initialization: nao conseguimos consultar o valor de logfile no registro do Windows');
    except
      on e:Exception do begin
        if isConsole and consoleVisible then
          Writeln(SOFTWARE_NAME+': env: initialization: nao conseguimos consultar o valor de logfile no registro do Windows: '
            +e.Classname+': '+e.message);
      end;
    end;
    _LOGFILENAME:=Trim(_LOGFILENAME);
    if _LOGFILENAME='' then begin
      _LOGFILENAME:=GetCurrentDir+DIRECTORY_SEPARATOR+LOG_FILE;
      try
        if (not SetRegistryValue('logfile',_LOGFILENAME)) and isConsole and consoleVisible then
          Writeln(SOFTWARE_NAME+': env: initialization: nao conseguimos registrar logfile='+_LOGFILENAME+' no registro do Windows');
      except
        on e:Exception do begin
          if isConsole and consoleVisible then
            Writeln(SOFTWARE_NAME+': env: initialization: nao conseguimos registrar logfile='
              +_LOGFILENAME+' no registro do Windows: '+e.Classname+': '+e.message);
        end;
      end;
    end;
    AssignFile(logfile,_LOGFILENAME);
    if FileExists(_LOGFILENAME) then
      Append(logfile)
    else
      Rewrite(logfile);
    LogInfo('Arquivo de log OK.',true);
    logfileOK:=true;
    errcode:=0;
    //ARQUIVO DE LOG OK: aberto para uso!
  except
    on e:Exception do begin
      if isConsole and consoleVisible then
        Writeln(SOFTWARE_NAME+': env: initialization: nao conseguimos criar um arquivo de log para a aplicacao: '+e.Classname+': '+e.message);
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
      raise Edeptocom.Create('não foi possível registrar o diretório do software no registro do Windows');
  except
    on e:Exception do
      LogWarn(SOFTWARE_NAME+': env: initialization: '+e.Classname+': '+e.message,true);
  end;

  //verifica a existência de um diretório para arquivos temporários:
  //não existindo, tenta criá-lo;
  //não existindo e não sendo possível criá-lo, lança o runerror RUNERR_NO_TMPDIR (FATAL!);
  //existindo, mas não sendo possível ler ou/e criar arquivos no diretório, lança também o RUNERR_NO_TMPDIR runerror (FATAL!)
  errcode:=RUNERR_NO_TMPDIR;
  folderOK:=false;
  try
    if not QueryRegistryValue('tmpdir',_TMPDIR) then
      raise Edeptocom.Create('falha em recuperar o diretório de arquivos temporários do registro do Windows')
    else
      errcode:=0;
  except
    on e:Exception do
      LogWarn(SOFTWARE_NAME+': env: initialization: '+e.Classname+': '+e.message,true);
  end;

  folderOK:=not(errcode=RUNERR_NO_TMPDIR);

  try
    if not folderOK then begin
      straux:=GetSpecialDir(csidAppData);
      //APENAS POR COMPLETUDE! NÃO OCORRE!
      if not DirectoryExists(straux) then begin
        LogWarn(SOFTWARE_NAME+': env: initialization: o diretório '+straux+' não existe',true);
        straux:=GetSpecialDir(csidMyDocuments);
        //TAMBÉM APENAS POR COMPLETUDE! NÃO OCORRE!
        if not DirectoryExists(straux) then
          LogWarn(SOFTWARE_NAME+': env: initialization: o diretório '+straux+' não existe',true);
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

      //tentamos registrar o diretório temporário no registro do Windows,
      //na chave do software
      try
        if not SetRegistryValue('tmpdir',_TMPDIR) then
          raise Edeptocom.Create('não foi possível registrar o diretório de arquivos temporários no registro do Windows');
      except
        on e:Exception do
          LogWarn(SOFTWARE_NAME+': env: initialization: '+e.Classname+': '+e.message,true);
          //ainda que não tenhamos conseguido registrar o diretório
          //nós o temos e é possível iniciar a aplicação
          //emitimos apenas um aviso no arquivo de log
      end;
    end;

    //testar aqui os direitos de leitura e escrita no diretório de arquivos temporários

    folderOK:=true;
  except
    on e:Exception do begin
      LogFatal(SOFTWARE_NAME+': env: initialization: '+e.Classname+': '+e.message+': não foi possível criar um diretório para arquivos temporários',
      RUNERR_NO_TMPDIR,true); //sem um diretório para arquivos temporários
                              //não podemos iniciar o programa
    end;
  end;

  //verificar diretório de dados aqui
  errcode:=RUNERR_NO_DATADIR;
  folderOK:=false;

  straux:='';
  errcode:=0;
  unitInitializationOK:=true;
finalization
  if logfileOK then
    CloseFile(logfile);
end.
