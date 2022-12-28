unit gui;

interface

uses
  classes,
  graphics,
  messages,
  windows;

const
  DEFAULT_WINDOW_X=40;
  DEFAULT_WINDOW_Y=40;
  DEFAULT_WINDOW_WIDTH=400;
  DEFAULT_WINDOW_HEIGHT=200;

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
    fLeft,
    fTop,
    fHeight,
    fWidth
      :integer;
    procedure setVisible(isVisible:boolean);
    procedure _setSize(const x,y,width,height:integer);
    procedure setLeft(const x:integer);
    procedure setTop(const y:integer);
    procedure setWidth(const width:integer);
    procedure setHeight(const height:integer);
  protected
    procedure setEnabled(isEnabled:boolean); virtual;
    procedure _WM_PAINT(var canvas:tcanvas);virtual;
  public
    constructor create(parent:Container=nil);virtual;
    destructor destroy;override;
    function equals(obj:TObject):boolean;
    procedure setSize(const x,y,width,height:integer);
    property ID:cardinal read fID;
    property Handle:HWND read fHandle;
    property Parent:Container read fParent;
    property Enabled:boolean read fEnabled write setEnabled;
    property Visible:boolean read fVisible write setVisible;
    property Left:integer read fLeft write setLeft;
    property Top:integer read fTop write setTop;
    property Width:integer read fWidth write setWidth;
    property Height:integer read fHeight write setHeight;
  end;

  Container=class(Component)
  private
    fCaption:PAnsiChar;
    procedure setCaption(const newCaption:PAnsiChar);
  protected
    fArrayOfComponents:array of Component;
  public
    property Caption:PAnsiChar read fCaption write setCaption;
  end;

  Window=class(Container)
  private
    fWndClass:TWndClass;
  protected
    procedure _WM_PAINT(var canvas:tcanvas);override;
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
  dwmapi,
  sysUtils;

function GetConsoleWindow: HWND; stdcall; external kernel32;
procedure hideConsole;
begin
  if isConsole then
    showWindow(GetConsoleWindow, SW_HIDE);
end;
procedure showConsole;
begin
  if isConsole then
    showWindow(GetConsoleWindow, SW_NORMAL);
end;

var
  mainWindowHandle:HWND=0;
  componentID,
  windowNum
    :cardinal;

var
  arrayOfComponents:array of Component;
  handleIdMap:tstringlist;

constructor Component.create(parent:Container=nil);
begin
  inherited create;
  if parent<>nil then
    fParent:=parent;
  inc(componentID);
  fID:=componentID;
  setLength(arrayOfComponents,componentID);
end;

destructor Component.destroy;
begin
  if fHandle<>0 then destroyWindow(fHandle);
  arrayOfComponents[fID-1]:=nil;
  fHandle:=0;
  fID:=0;
  fLeft:=0;
  fTop:=0;
  fWidth:=0;
  fHeight:=0;
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
  if (fHandle<>0) and (isVisible<>fVisible) then begin
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

procedure Component._setSize(const x,y,width,height:integer);
begin
  if (fHandle<>0) and ((x<>fLeft) or (y<>fTop) or (width<>fWidth) or (height<>fHeight)) then begin
    fLeft:=x;
    fTop:=y;
    fWidth:=width;
    fHeight:=height;

    if self is Window then
      setWindowPos(fHandle,0,x,y,width,height,SWP_FRAMECHANGED);
  end;
end;

procedure Component.setSize(const x,y,width,height:integer);
begin
  _setSize(x,y,width,height);
end;

procedure Component.setLeft(const x:integer);
begin
  _setSize(x,fTop,fWidth,fHeight);
end;

procedure Component.setTop(const y:integer);
begin
  _setSize(fLeft,y,fWidth,fHeight);
end;

procedure Component.setWidth(const width:integer);
begin
  _setSize(fLeft,fTop,width,fHeight);
end;

procedure Component.setHeight(const height:integer);
begin
  _setSize(fLeft,fTop,fWidth,height);
end;

procedure Component._WM_PAINT(var canvas:tcanvas);
begin
  //NADA!
end;

procedure Container.setCaption(const newCaption:PAnsiChar);
begin
  if (fHandle<>0) and (newCaption<>self.fCaption) then
  begin
    setWindowText(self.Handle,newCaption);
    fCaption:=newCaption;
  end;
end;

function hWndToID(const hWnd:HWND):integer;
begin
  result:=strtoint(handleIdMap.Values[inttostr(hWND)]);
end;

function getComponent(const hWnd:HWND):Component;
begin
  result:=arrayOfComponents[hWndToID(hWnd)-1];
end;

function WindowProc(hwnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM):
  LRESULT; stdcall;
var
  _component:Component;
  _canvas:tcanvas;
begin
  //usamos o processamento default de mensagem
  result:=defWindowProc(hwnd,uMsg,wParam,lParam);

  case uMsg of
    WM_DESTROY:
      if hwnd=mainWindowHandle then//apenas o fechamento da janela principal pode encerrar a aplicação!
        PostQuitMessage(0);

    WM_PAINT:begin
      _component:=getComponent(hWnd); //obtemos o componente destinatário da mensagem
      if _component<>nil then begin   //e delegamos um canvas para a procedure _WM_PAINT do componente
        _canvas:=tcanvas.create;      //para que ela faça o trabalho
        _canvas.handle:=getDC(hWnd);
        _component._WM_PAINT(_canvas);
        releaseDC(hWnd,_canvas.handle);
        _canvas.free;//NÃO LIBERE O CANVAS NA PROCEDURE _WM_PAINT!
      end;//end-if
    end;//end-WM_PAINT

  end;//end-case
end;

constructor Window.create(parent:Window=nil);
var
  styleFlags:cardinal;
  parentHandle:HWND;
  flagArredondamentoCantosJanela:integer;
begin
  inherited create(parent);
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
    lpszClassName := PAnsiChar(ansistring(classname));
  end;

  Windows.RegisterClass(self.fWndClass);  //Don't use Delphi's version of RegisterClass

  if parent=nil then begin
    styleFlags:=WS_OVERLAPPEDWINDOW;
    parentHandle:=0;
  end else begin
    styleFlags:=WS_OVERLAPPEDWINDOW or WS_CHILD;
    parentHandle:=parent.Handle;
  end;

  fLeft:=DEFAULT_WINDOW_X;
  fTop:=DEFAULT_WINDOW_Y;
  fWidth:=DEFAULT_WINDOW_WIDTH;
  fHeight:=DEFAULT_WINDOW_HEIGHT;

  self.fHandle:= CreateWindow(self.fWndClass.lpszClassName,
    PAnsiChar('Window'+intToStr(windowNum)), // window caption
    styleFlags, // standard window style
    fLeft,fTop,//CW_USEDEFAULT, CW_USEDEFAULT, // default position
    fWidth, fHeight, // size
    parentHandle, // no owner window
    0, // no menu
    SysInit.hInstance, // application instance
    nil);

  arrayOfComponents[fID-1]:=self;
  handleIdMap.add(inttostr(fHandle)+'='+inttostr(fID));

  flagArredondamentoCantosJanela:=DWMWCP_DONOTROUND;
  DwmSetWindowAttribute(fHandle,DWMWA_WINDOW_CORNER_PREFERENCE,@flagArredondamentoCantosJanela,sizeOf(integer));
end;

procedure Window._WM_PAINT(var canvas:tcanvas);
var
  _rect:trect;
begin
  inherited _WM_PAINT(canvas);
  _rect.Left:=50;
  _rect.Top:=50;
  _rect.Bottom:=150;
  _rect.Right:=200;
  canvas.FillRect(_rect);
  canvas.Ellipse(60,60,200,200);
  canvas.PenPos:=point(90,100);
  canvas.LineTo(90,400);
  writeln('Window._WM_PAINT(wParam: WPARAM; lParam: LPARAM):LRESULT;');
end;

constructor Edit.create(parent:Container);
var
  hControlFont:HFONT;
  lfControl:TLogFont;
  parentHandle:HWND;
begin
  inherited create(parent);
  if parent=nil then begin
    parentHandle:=0;
    fParent:=nil;
  end else begin
    parentHandle:=parent.Handle;
    fParent:=parent;
  end;
  self.fHandle:=createWindowEx(WS_EX_CLIENTEDGE, // Extended style
    'EDIT', // EDIT creates an edit box
    'Edit1',// Name of window - also the text that will be in it
    WS_CHILD OR WS_VISIBLE OR ES_AUTOHSCROLL OR ES_NOHIDESEL, // style flags
    8, 16, 160, 21, // Position and size
    parentHandle, // Parent window
    0, // Menu - none because it's an edit box(!)
    SysInit.HInstance, // Application instance
    nil); // No creation data

  arrayOfComponents[fID-1]:=self;
  handleIdMap.add(inttostr(fHandle)+'='+inttostr(fID));

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
  parentHandle:HWND;
begin
  inherited create(parent);
  if parent=nil then begin
    parentHandle:=0;
    fParent:=nil;
  end else begin
    parentHandle:=parent.Handle;
    fParent:=parent;
  end;
  self.fHandle:=createWindow('BUTTON', // BUTTON creates an button, obviously
    'Show Message', // Name of window - also the text that will be in it
    WS_CHILD OR WS_VISIBLE OR BS_PUSHBUTTON OR BS_TEXT, // style flags
    8, 40, 96, 25, // Position and size
    parentHandle, // Parent window
    0, // Menu - none because it's a button
    SysInit.HInstance, // Application instance
    nil); // No creation data

  arrayOfComponents[fID-1]:=self;
  handleIdMap.add(inttostr(fHandle)+'='+inttostr(fID));

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
  if not isConsole then
    writeln('redirecionamos a saída padrão para o arquivo debug.log');
  componentID:=0;
  windowNum:=0;
  handleIdMap:=tstringlist.create;
  myApp:=deptocomApp.create;
finalization
  componentID:=0;
  windowNum:=0;
end.
