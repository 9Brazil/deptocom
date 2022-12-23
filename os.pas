unit os;

interface

uses
  shlobj;

const
  DIRECTORY_SEPARATOR='\';
  DRIVE_SEPARATOR=':';
  EOL=#13#10;

type
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

implementation

uses
  activex,
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

end.
