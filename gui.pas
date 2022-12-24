unit gui;

interface

uses
  classes,
  messages,
  windows;

type
  Window=class
  private
    fHandle:HWND;
    fName:PAnsiChar;
  public
    property handle:HWND read fHandle;
    property name:PAnsiChar read fName;
  end;

  Edit=class
  private
    fHandle:HWND;
    fParentHandle:HWND;
    fName:PAnsiChar;
  public
    property handle:HWND read fHandle;
    property parent:HWND read fParentHandle;
    property name:PAnsiChar read fName;
  end;

  Button=class
  private
    fHandle:HWND;
    fParentHandle:HWND;
    fName:PAnsiChar;
  public
    property handle:HWND read fHandle;
    property parent:HWND read fParentHandle;
    property name:PAnsiChar read fName;    
  end;

function newWindow:Window;
function newEdit(const parent:HWND=0):Edit;
function newButton(const parent:HWND=0):Button;

implementation

var
  HAppInstance:integer;

function newWindow:Window;
begin
  result:=Window.create;
end;

function newEdit(const parent:HWND=0):Edit;
var
  hControlFont:HFONT;
  lfControl:TLogFont;
begin
  result:=Edit.create;
  result.fName:='Edit1';// Name of window - also the text that will be in it
  result.fHandle:=createWindowEx(WS_EX_CLIENTEDGE, // Extended style
    'EDIT', // EDIT creates an edit box
    result.fName,
    WS_CHILD OR WS_VISIBLE OR ES_AUTOHSCROLL OR ES_NOHIDESEL, // style flags
    8, 16, 160, 21, // Position and size
    parent, // Parent window
    0, // Menu - none because it's an edit box(!)
    HAppInstance, // Application instance
    nil); // No creation data
  result.fParentHandle:=parent;
  // Set up the font
  { Calculate font height from point size - they are not the same thing!
    The first parameter of MulDiv is the point size. }
  lfControl.lfHeight:=-MulDiv(8, GetDeviceCaps(GetDC(0), LOGPIXELSY), 96);
  lfControl.lfFaceName:='MS Sans Serif';
  // Create the font
  hControlFont:=CreateFontIndirect(lfControl);
  sendMessage(result.fHandle, WM_SETFONT, hControlFont, 1);
end;

function newButton(const parent:HWND=0):Button;
var
  hControlFont:HFONT;
  lfControl:TLogFont;
begin
  result:=Button.create;
  result.fHandle:=createWindow('BUTTON', // BUTTON creates an button, obviously
    'Show Message', // Name of window - also the text that will be in it
    WS_CHILD OR WS_VISIBLE OR BS_PUSHBUTTON OR BS_TEXT, // style flags
    8, 40, 96, 25, // Position and size
    parent, // Parent window
    0, // Menu - none because it's a button
    HAppInstance, // Application instance
    nil); // No creation data
  result.fParentHandle:=parent;
  // Set up the font
  { Calculate font height from point size - they are not the same thing!
    The first parameter of MulDiv is the point size. }
  lfControl.lfHeight:=-MulDiv(8, GetDeviceCaps(GetDC(0), LOGPIXELSY), 96);
  lfControl.lfFaceName:='MS Sans Serif';
  // Create the font
  hControlFont:=CreateFontIndirect(lfControl);
  sendMessage(result.fHandle, WM_SETFONT, hControlFont, 1);
end;

end.
