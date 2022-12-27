unit gui;

interface

uses
  classes,
  dialogs,
  messages,
  windows;

type
  Container=class;
  Component=class(TInterfacedObject)
  private
    fID:cardinal;
    fHandle:HWND;
    fVisible,
    fEnabled
      :boolean;
    fParent:Container;
    procedure setVisible(isVisible:boolean);      
  protected
    procedure setEnabled(isEnabled:boolean); virtual;
  public
    constructor create(parent:Container=nil);virtual;
    destructor destroy;override;
    function equals(obj:TObject):boolean;
    property ID:cardinal read fID;
    property Handle:HWND read fHandle;
    property Parent:Container read fParent;
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
    constructor create(parent:Container=nil);
    property Caption:PAnsiChar read fCaption write setCaption;
  end;

  Window=class(Container)
  private
    fWndClass:TWndClass;
  protected
    //
  public
    constructor create(parent:Window=nil);
  end;

  Edit=class(Component)
  public
    constructor create(parent:Container);override;
  end;

  Button=class(Component)
  public
    constructor create(parent:Container);override;
  end;

  deptocomApp=class
  private
    fMainWindow:Window;
    procedure setMainWindow(mw:Window);
  public
    constructor create;
    procedure run;
    property MainWindow:Window read fMainWindow write setMainWindow;
  end;

var
  myApp:deptocomApp;

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
  mainWindowHandle:HWND=0;
  componentID,
  windowNum
    :cardinal;

constructor Component.create(parent:Container=nil);
begin
  inherited create;
  if Parent<>nil then
    fParent:=parent;
  inc(componentID);
end;

destructor Component.destroy;
begin
  if fHandle<>0 then destroyWindow(fHandle);
  fID:=0;
  fEnabled:=false;
  fVisible:=false;
  fParent:=nil;
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
  if (obj=nil) or (obj.ClassType<>self.ClassType) then
    result:=false
  else
    result:=Component(obj).ID=Component(self).ID;
end;

constructor Container.create(parent:Container=nil);
begin
  inherited create(parent);
end;

procedure Container.setCaption(const newCaption:PAnsiChar);
begin
  if newCaption<>self.fCaption then
  begin
    setWindowText(self.Handle,newCaption);
    fCaption:=newCaption;
  end;
end;

function WindowProc(hwnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM):
  LRESULT; stdcall;
begin
  // This is the function Windows calls when a message is sent to the application
  case uMsg of // Check which message was sent
    WM_DESTROY:
      if hwnd=mainWindowHandle then PostQuitMessage(0); // Otherwise app will continue to run

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

constructor Window.create(parent:Window=nil);
var
  styleFlags:cardinal;
  parentHandle:HWND;
begin
  inherited create(parent);
  self.fID:=componentID;
  inc(windowNum);
  // Set up window class
  with self.fWndClass do begin
    Style := 0;
    lpfnWndProc := @WindowProc; // See function above
    cbClsExtra := 0; // no extra class memory
    cbWndExtra := 0; // no extra window memory
    hInstance := SysInit.HInstance; // application instance
    hIcon := 0; // use default icon
    hCursor := LoadCursor(0, IDC_ARROW); // use arrow cursor
    hbrBackground := COLOR_WINDOW; // standard window colour
    lpszMenuName := nil; // no menu resource
    lpszClassName := pansichar(ansistring(classname));
  end;

  Windows.RegisterClass(self.fWndClass); // Don't use Delphi's version of RegisterClass

  if parent=nil then begin
    styleFlags:=WS_OVERLAPPEDWINDOW;
    parentHandle:=0;
  end else begin
    styleFlags:=WS_OVERLAPPEDWINDOW or WS_CHILD;
    parentHandle:=parent.Handle;
  end;

  self.fHandle:= CreateWindow(self.fWndClass.lpszClassName,
    PAnsiChar('Window'+intToStr(windowNum)), // window caption
    styleFlags, // standard window style
    CW_USEDEFAULT, CW_USEDEFAULT, // default position
    880, 400, // size
    parentHandle, // no owner window
    0, // no menu
    SysInit.hInstance, // application instance
    nil);
end;

constructor Edit.create(parent:Container);
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
    parent.Handle, // Parent window
    0, // Menu - none because it's an edit box(!)
    SysInit.HInstance, // Application instance
    nil); // No creation data
  self.fParent:=parent;
  // Set up the font
  { Calculate font height from point size - they are not the same thing!
    The first parameter of MulDiv is the point size. }
  lfControl.lfHeight:=-MulDiv(8, GetDeviceCaps(GetDC(0), LOGPIXELSY), 96);
  lfControl.lfFaceName:='MS Sans Serif';
  // Create the font
  hControlFont:=CreateFontIndirect(lfControl);
  sendMessage(self.fHandle, WM_SETFONT, hControlFont, 1);
end;

constructor Button.create(parent:Container);
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
    parent.Handle, // Parent window
    0, // Menu - none because it's a button
    SysInit.HInstance, // Application instance
    nil); // No creation data
  self.fParent:=parent;
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
  fMainWindow:=nil;
end;

procedure deptocomApp.setMainWindow(mw:Window);
begin
  if mainWindowHandle<>0 then
    raise exception.create('Já há uma MainWindow definida. Não é possível redefiní-la.');
  if mw<>nil then begin
    self.fMainWindow:=mw;
    mainWindowHandle:=mw.Handle;
  end;
end;

procedure deptocomApp.run;
var
  msg:tmsg;
begin
  if self.fMainWindow<>nil then begin
    self.fMainWindow.Visible:=true;
    while getMessage(msg,0,0,0)<>BOOL(FALSE) do begin
      translateMessage(msg);
      dispatchMessage(msg);
    end;
  end;
end;

initialization
  componentID:=0;
  windowNum:=0;
  myApp:=deptocomApp.create;
finalization
  componentID:=0;
  windowNum:=0;
end.
