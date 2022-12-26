unit gui;

interface

uses
  classes,
  dialogs,
  messages,
  windows;

type
  Component=class(TInterfacedObject)
  private
    fID:cardinal;
    fHandle:HWND;
    fVisible,
    fEnabled
      :boolean;
    procedure setVisible(isVisible:boolean);      
  protected
    procedure setEnabled(isEnabled:boolean); virtual;
  public
    constructor create;
    destructor destroy;override;
    function equals(obj:TObject):boolean;
    property ID:cardinal read fID;
    property Handle:HWND read fHandle;
    property Enabled:boolean read fEnabled write setEnabled;
    property Visible:boolean read fVisible write setVisible;
  end;

  Container=class(Component)
  private
    fCaption:PAnsiChar;
    procedure setCaption(const newCaption:PAnsiChar);
  protected
    fArrayOfComponents:array of Component;
  public
    constructor create(const parentHandle:HWND=0);
    destructor destroy;override;
    property Caption:PAnsiChar read fCaption write setCaption;
  end;

  Window=class(Container)
  private
    fWndClass:TWndClass;
  protected
    //
  public
    constructor create;
    destructor destroy;override;
  end;

  Edit=class(Component)
  private
    fParentHandle:HWND;
  public
    constructor create(parentHandle:HWND=0);
    property parent:HWND read fParentHandle;
  end;

  Button=class(Component)
  private
    fParentHandle:HWND;
  public
    constructor create(parentHandle:HWND=0);
    property parent:HWND read fParentHandle;
  end;

  deptocomApp=class
  private
  public
    constructor create;
    procedure run;
  end;

var
  myApp:deptocomApp;
  HAppInstance:integer;

procedure hideConsole;
procedure showConsole;

implementation

uses
  sysUtils;

function GetConsoleWindow: HWND; stdcall; external kernel32;
procedure hideConsole;
begin
  showWindow(GetConsoleWindow, SW_HIDE);
end;
procedure showConsole;
begin
  showWindow(GetConsoleWindow, SW_NORMAL);
end;

var
  componentID,
  windowNum
    :cardinal;

constructor Component.create;
begin
  inherited create;
  inc(componentID);
end;

destructor Component.destroy;
begin
  if fHandle<>0 then destroyWindow(fHandle);
  fID:=0;
  fEnabled:=false;
  fVisible:=false;
  inherited destroy;
end;

procedure Component.setEnabled(isEnabled:boolean);
begin
  fEnabled:=isEnabled;
end;

procedure Component.setVisible(isVisible:boolean);
begin
  if isVisible<>fVisible then begin
    fVisible:=isVisible;
    if isVisible then
      showWindow(self.fHandle,SW_SHOWNORMAL)
    else
      showWindow(self.fHandle,SW_HIDE);
  end;
end;

function Component.equals(obj:TObject):boolean;
begin
  if obj.ClassType<>self.ClassType then
    result:=false
  else
    result:=Component(obj).ID=Component(self).ID;
end;

constructor Container.create(const parentHandle:HWND=0);
begin
  inherited create;
end;

destructor Container.destroy;
begin
  inherited destroy;
end;

procedure Container.setCaption(const newCaption:PAnsiChar);
begin
  if newCaption<>self.fCaption then
  begin
    setWindowText(self.Handle,newCaption);
    fCaption:=newCaption;
  end;
end;

destructor Window.destroy;
begin
  inherited destroy;
end;

function WindowProc(hwnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM):
  LRESULT; stdcall;
begin
  // This is the function Windows calls when a message is sent to the application
  case uMsg of // Check which message was sent
    WM_DESTROY: PostQuitMessage(0); // Otherwise app will continue to run
    // Handle any other messages here
    WM_ACTIVATE:;
    {
    WM_COMMAND:
      begin
        Result := 0; // Default return value for this message
        if lParam = Button1 then
          case wParam of
            BN_CLICKED: Button1Click; // Button was clicked
          else Result := DefWindowProc(hwnd, uMsg, wParam, lParam);
          end; // case wNotifyCode of
      end; // case: WM_COMMAND
    // Use default message processing
    }
    else Result := DefWindowProc(hwnd, uMsg, wParam, lParam);
  end;
end;

constructor Window.create;
begin
  inherited create;
  self.fID:=componentID;
  inc(windowNum);
  // Set up window class
  with self.fWndClass do begin
    Style := 0;
    lpfnWndProc := @WindowProc; // See function above
    cbClsExtra := 0; // no extra class memory
    cbWndExtra := 0; // no extra window memory
    hInstance := HAppInstance; // application instance
    hIcon := 0; // use default icon
    hCursor := LoadCursor(0, IDC_ARROW); // use arrow cursor
    hbrBackground := COLOR_WINDOW; // standard window colour
    lpszMenuName := nil; // no menu resource
    lpszClassName := pansichar(ansistring(classname));
  end;

  Windows.RegisterClass(self.fWndClass); // Don't use Delphi's version of RegisterClass

  self.fHandle:= CreateWindow(self.fWndClass.lpszClassName,
    PAnsiChar('Window'+intToStr(windowNum)), // window caption
    WS_OVERLAPPEDWINDOW, // standard window style
    CW_USEDEFAULT, CW_USEDEFAULT, // default position
    880, 400, // size
    0, // no owner window
    0, // no menu
    hInstance, // application instance
    nil);
end;

constructor Edit.create(parentHandle:HWND=0);
var
  hControlFont:HFONT;
  lfControl:TLogFont;
begin
  inherited create;
  self.fID:=componentID;
  self.fHandle:=createWindowEx(WS_EX_CLIENTEDGE, // Extended style
    'EDIT', // EDIT creates an edit box
    'Edit1',// Name of window - also the text that will be in it
    WS_CHILD OR WS_VISIBLE OR ES_AUTOHSCROLL OR ES_NOHIDESEL, // style flags
    8, 16, 160, 21, // Position and size
    parentHandle, // Parent window
    0, // Menu - none because it's an edit box(!)
    HAppInstance, // Application instance
    nil); // No creation data
  self.fParentHandle:=parent;
  // Set up the font
  { Calculate font height from point size - they are not the same thing!
    The first parameter of MulDiv is the point size. }
  lfControl.lfHeight:=-MulDiv(8, GetDeviceCaps(GetDC(0), LOGPIXELSY), 96);
  lfControl.lfFaceName:='MS Sans Serif';
  // Create the font
  hControlFont:=CreateFontIndirect(lfControl);
  sendMessage(self.fHandle, WM_SETFONT, hControlFont, 1);
end;

constructor Button.create(parentHandle:HWND=0);
var
  hControlFont:HFONT;
  lfControl:TLogFont;
begin
  inherited create;
  self.fID:=componentID;
  self.fHandle:=createWindow('BUTTON', // BUTTON creates an button, obviously
    'Show Message', // Name of window - also the text that will be in it
    WS_CHILD OR WS_VISIBLE OR BS_PUSHBUTTON OR BS_TEXT, // style flags
    8, 40, 96, 25, // Position and size
    parentHandle, // Parent window
    0, // Menu - none because it's a button
    HAppInstance, // Application instance
    nil); // No creation data
  self.fParentHandle:=parentHandle;
  // Set up the font
  { Calculate font height from point size - they are not the same thing!
    The first parameter of MulDiv is the point size. }
  lfControl.lfHeight:=-MulDiv(8, GetDeviceCaps(GetDC(0), LOGPIXELSY), 96);
  lfControl.lfFaceName:='MS Sans Serif';
  // Create the font
  hControlFont:=CreateFontIndirect(lfControl);
  sendMessage(self.fHandle, WM_SETFONT, hControlFont, 1);
end;

constructor deptocomApp.create;
begin
  inherited create;
end;

procedure deptocomApp.run;
var
  msg:tmsg;
begin
  while getMessage(msg,0,0,0)<>BOOL(FALSE) do begin
    translateMessage(msg);
    dispatchMessage(msg);
  end;
end;

initialization
  componentID:=0;
  windowNum:=0;
finalization
  componentID:=0;
  windowNum:=0;
end.
