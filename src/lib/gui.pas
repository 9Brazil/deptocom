unit gui;

interface

uses
  Classes,
  env,
  Graphics,
  Messages,
  Windows;

const
  DEFAULT_WINDOW_X=40;
  DEFAULT_WINDOW_Y=40;
  DEFAULT_WINDOW_WIDTH=400;
  DEFAULT_WINDOW_HEIGHT=200;

type
  GDIObject=class(TObject);

  Font=class(GDIObject)
  private
    fHndl:HFONT;
    fLF:TLogFont;
  public
  
  end;

  WindowState=(wsNormal, wsMinimized, wsMaximized);

  Container=class;

  Component=class(TInterfacedObject)
  private
    fId,
    fHWndIdListIndex
      :cardinal;
    fHandle:HWND;
    fVisible,
    fEnabled
      :boolean;
    fParent:Container;
    fLeft,
    fTop,
    fHeight,
    fWidth
      :int32;
    procedure SetVisible(isVisible:boolean);
    procedure _SetSize(const x,y,width,height:int32);
    procedure SetLeft(const x:int32);
    procedure SetTop(const y:int32);
    procedure SetWidth(const width:int32);
    procedure SetHeight(const height:int32);
  protected
    procedure SetEnabled(isEnabled:boolean); virtual;
    procedure Paint(var g:TCanvas);virtual;
  public
    constructor Create(parent:Container=NIL);virtual;
    destructor Destroy;override;
    function Equals(obj:TObject):boolean;
    procedure SetSize(const x,y,width,height:int32);
    property Id:cardinal read fId;
    property Parent:Container read fParent;
    property Enabled:boolean read fEnabled write setEnabled;
    property Visible:boolean read fVisible write setVisible;
    property Left:int32 read fLeft write setLeft;
    property Top:int32 read fTop write setTop;
    property Width:int32 read fWidth write setWidth;
    property Height:int32 read fHeight write setHeight;
  end;

  Container=class(Component)
  private
    fCaption:PAnsiChar;
    procedure SetCaption(const newCaption:PAnsiChar);
  protected
    fArrayOfComponents:array of Component;
  public
    property Caption:PAnsiChar read fCaption write SetCaption;
  end;

  Window=class(Container)
  private
    fWndClass:TWndClass;
    fWindowState:WindowState;
  protected
    procedure Paint(var g:TCanvas);override;
  public
    constructor Create(parent:Window=NIL); reintroduce; virtual;
  end;

  Edit=class(Component)
  public
    constructor Create(parent:Container);override;
  end;

  Button=class(Component)
  public
    constructor Create(parent:Container);override;
  end;

  deptocomApp=class
  private
    fMainWindow:Window;
    procedure SetMainWindow(mw:Window);
  public
    constructor Create;
    procedure Run;
    property MainWindow:Window read fMainWindow write SetMainWindow;
  end;

var
  myApp:deptocomApp;

implementation

uses
  SysUtils;

const
  DWMAPI = 'DWMAPI.DLL';

var
  mainWindowHandle:HWND=0;
  componentId,
  windowNum
    :cardinal;

type
  hWndId=record
    hndl:HWND;
    id:cardinal;
  end;
  hWndIdList=array of hWndId;

var
  arrayOfComponents:array of Component; //todo componente criado vem para esse array...
                                        //os que foram liberados da memória marcamos com NIL
  hWndIdSlot:array[WORD] of hWndIdList;

constructor Component.Create(parent:Container=NIL);
begin
  inherited create;
  if parent<>NIL then
    fParent:=parent;
  Inc(componentId);
  fId:=componentId;
  SetLength(arrayOfComponents,componentId);
end;

destructor Component.Destroy;
var
  i,l:integer;
  list:hWndIdList;
begin
  if (fHandle<>0) and (fHandle<>INVALID_HANDLE_VALUE) then begin
    DestroyWindow(fHandle);
    list:=HWndIdSlot[fHandle mod 65536];
    l:=Length(list)-1;
    for i:=fHWndIdListIndex+1 to l do begin
      list[i-1].hndl:=list[i].hndl;
      list[i-1].id:=list[i].id;
      arrayOfComponents[list[i-1].id].fHWndIdListIndex:=i-1;
    end;
    SetLength(list,l);
  end;
  arrayOfComponents[fId-1]:=NIL;
  fHandle:=0;
  fId:=0;
  fHWndIdListIndex:=0;
  fLeft:=0;
  fTop:=0;
  fWidth:=0;
  fHeight:=0;
  fEnabled:=FALSE;
  fVisible:=FALSE;
  fParent:=NIL;
  inherited Destroy;
end;

function Component.Equals(obj:TObject):boolean;
begin
  if (obj=NIL) or (obj.ClassType<>self.ClassType) then
    result:=FALSE
  else
    result:=Component(obj).ID=Component(self).ID;
end;

procedure Component.SetEnabled(isEnabled:boolean);
begin
  fEnabled:=isEnabled;
end;

procedure Component.SetVisible(isVisible:boolean);
begin
  if (fHandle<>0) and (fHandle<>INVALID_HANDLE_VALUE) and (isVisible<>fVisible) then begin
    fVisible:=isVisible;
    if isVisible then
      ShowWindow(fHandle,SW_SHOWNORMAL)
    else
      ShowWindow(fHandle,SW_HIDE);
  end;
end;

procedure Component._SetSize(const x,y,width,height:int32);
begin
  if (fHandle<>0) and (fHandle<>INVALID_HANDLE_VALUE) and ((x<>fLeft) or (y<>fTop) or (width<>fWidth) or (height<>fHeight)) then begin
    fLeft:=x;
    fTop:=y;
    fWidth:=width;
    fHeight:=height;

    if self is Window then
      SetWindowPos(fHandle,0,x,y,width,height,SWP_FRAMECHANGED);
  end;
end;

procedure Component.SetSize(const x,y,width,height:int32);
begin
  _SetSize(x,y,width,height);
end;

procedure Component.SetLeft(const x:int32);
begin
  _SetSize(x,fTop,fWidth,fHeight);
end;

procedure Component.SetTop(const y:int32);
begin
  _SetSize(fLeft,y,fWidth,fHeight);
end;

procedure Component.SetWidth(const width:int32);
begin
  _SetSize(fLeft,fTop,width,fHeight);
end;

procedure Component.SetHeight(const height:int32);
begin
  _SetSize(fLeft,fTop,fWidth,height);
end;

procedure Component.Paint(var g:TCanvas);
begin
  //NADA!
end;

procedure Container.SetCaption(const newCaption:PAnsiChar);
begin
  if (fHandle<>0) and (fHandle<>INVALID_HANDLE_VALUE) and (newCaption<>self.fCaption) then
  begin
    SetWindowText(self.fHandle,newCaption);
    fCaption:=newCaption;
  end;
end;

function HWndToId(const hWnd:HWND):int32;
var
  list:hWndIdList;
  i:integer;
begin
  list:=hWndIdSlot[hWnd mod 65536];
  i:=0;
  while list[i].hndl<>hWnd do
    Inc(i);
  result:=list[i].id;
end;

function GetComponent(const hWnd:HWND):Component;
begin
  result:=arrayOfComponents[hWndToId(hWnd)-1];
end;

function WindowProc(hndl: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM):
  LRESULT; stdcall;
var
  _component:Component;
  _g:TCanvas;
  wParamLWord,
  wParamHWord,
  lParamLWord,
  lParamHWord
    :WORD;
begin
  //usamos o processamento default de mensagem
  result:=DefWindowProc(hndl,uMsg,wParam,lParam);

  wParamLWord:=LOWORD(wParam);
  wParamHWord:=HIWORD(wParam);

  lParamLWord:=LOWORD(lParam);
  lParamHWord:=HIWORD(lParam);

  case uMsg of
    WM_DESTROY:
      if hndl=mainWindowHandle then //apenas o fechamento da janela principal pode encerrar a aplicação!
        PostQuitMessage(0);

    WM_PAINT:begin
      _component:=GetComponent(hndl); //obtemos o componente destinatário da mensagem
      if _component<>NIL then begin   //e delegamos um canvas para a procedure _WM_PAINT do componente
        _g:=TCanvas.Create;           //para que ela faça o trabalho
        _g.handle:=GetDC(hndl);
        _component.Paint(_g);
        ReleaseDC(hndl,_g.handle);
        _g.Free;  //NÃO LIBERE O CANVAS NA PROCEDURE _WM_PAINT!
      end;//end-if
    end;//case:WM_PAINT

    //v. https://learn.microsoft.com/pt-br/windows/win32/menurc/wm-command
    WM_COMMAND:begin
      case wParamHWord+lParam{fonte da mensagem} of

        //MENU
        0:begin

        end;//MENU-fim

        //ACELERADOR
        1:begin

        end//ACELERADOR-fim

        //CONTROLE
        else begin

          case wParamHWord{código da mensagem/notificação do controle} of

            //um botão foi clicado
            BN_CLICKED{=0}:begin
              _component:=GetComponent(HWND(lParam));
              if _component<>NIL then begin
                //
                //
                //
              end;
            end;//BN_CLICKED-fim

          end;//case:código da mensagem/notificação do controle (wParamHWord)

        end;//CONTROLE-fim

      end;//case:fonte da mensagem (wParamHWord+lParam)

    end;//case:WM_COMMAND


    //
    //outras mensagens
    //


  end;//case:uMsg
end;

constructor Window.Create(parent:Window=NIL);
var
  styleFlags:cardinal;
  parentHandle:HWND;
  len:integer;
begin
  inherited Create(parent);
  Inc(windowNum);
  // Set up window class
  with fWndClass do begin
    style:=0;
    lpfnWndProc:=@WindowProc;
    cbClsExtra:=0; // no extra class memory
    cbWndExtra:=0; // no extra window memory
    hInstance:=SysInit.HInstance; // application instance
    hIcon:=0; // use default icon
    hCursor:=LoadCursor(0, IDC_ARROW); // use arrow cursor
    hbrBackground:=COLOR_WINDOW; // standard window colour
    lpszMenuName:=NIL; // no menu resource
    lpszClassName:=PAnsiChar(ansistring(classname));
  end;

  Windows.RegisterClass(self.fWndClass);  //Don't use Delphi's version of RegisterClass

  if parent=NIL then begin
    styleFlags:=WS_OVERLAPPEDWINDOW;
    parentHandle:=0;
  end else begin
    styleFlags:=WS_OVERLAPPEDWINDOW or WS_CHILD;
    parentHandle:=parent.fHandle;
  end;

  fLeft:=DEFAULT_WINDOW_X;
  fTop:=DEFAULT_WINDOW_Y;
  fWidth:=DEFAULT_WINDOW_WIDTH;
  fHeight:=DEFAULT_WINDOW_HEIGHT;

  fHandle:= CreateWindow(fWndClass.lpszClassName,
    PAnsiChar('Window'+intToStr(windowNum)),  //window caption
    styleFlags, //standard window style
    fLeft,fTop,
    fWidth, fHeight,  //size
    parentHandle, //no owner window
    0,  //no menu
    SysInit.hInstance,  //application instance
    nil);

  if (fHandle=0) or (fHandle=INVALID_HANDLE_VALUE) then begin
    LogError('libgui: Window.Create(Window): [GDI] CreateWindow falhou: HWnd = '+IntToStr(fHandle)+': não foi possível criar a janela: Erro '+IntToStr(GetLastError));
    Exit;
  end;

  arrayOfComponents[fId-1]:=self;
  len:=Length(hWndIdSlot[fHandle mod 65536])+1;
  SetLength(hWndIdSlot[fHandle mod 65536],len);
  hWndIdSlot[fHandle mod 65536][len-1].hndl:=fHandle;
  hWndIdSlot[fHandle mod 65536][len-1].id:=fId;
end;

procedure Window.Paint(var g:TCanvas);
var
  _rect:TRect;
begin
  inherited Paint(g);
  _rect.Left:=50;
  _rect.Top:=50;
  _rect.Bottom:=150;
  _rect.Right:=200;
  g.FillRect(_rect);
  g.Ellipse(60,60,200,200);
  g.PenPos:=point(90,100);
  g.LineTo(90,400);
end;

constructor Edit.Create(parent:Container);
var
  hControlFont:HFONT;
  lfControl:TLogFont;
  parentHandle:HWND;
  len:integer;
begin
  inherited Create(parent);
  if parent=NIL then begin
    parentHandle:=0;
    fParent:=NIL;
  end else begin
    parentHandle:=parent.fHandle;
    fParent:=parent;
  end;
  fHandle:=CreateWindowEx(WS_EX_CLIENTEDGE, // Extended style
    'EDIT', // EDIT creates an edit box
    'Edit1',// Name of window - also the text that will be in it
    WS_CHILD or WS_VISIBLE or ES_AUTOHSCROLL or ES_NOHIDESEL, // style flags
    8, 16, 160, 21, // Position and size
    parentHandle, // Parent window
    0, // Menu - none because it's an edit box(!)
    SysInit.HInstance, // Application instance
    NIL); // No creation data

  if (fHandle=0) or (fHandle=INVALID_HANDLE_VALUE) then begin
    LogError('libgui: Edit.Create(Container): [GDI] CreateWindowEx falhou: HWnd = '+IntToStr(fHandle)+': não foi possível criar o edit: Erro '+IntToStr(GetLastError));
    Exit;
  end;

  arrayOfComponents[fId-1]:=self;
  len:=Length(hWndIdSlot[fHandle mod 65536])+1;
  SetLength(hWndIdSlot[fHandle mod 65536],len);
  hWndIdSlot[fHandle mod 65536][len-1].hndl:=fHandle;
  hWndIdSlot[fHandle mod 65536][len-1].id:=fId;

  // Set up the font
  { Calculate font height from point size - they are not the same thing!
    The first parameter of MulDiv is the point size. }
  lfControl.lfHeight:=-MulDiv(8, GetDeviceCaps(GetDC(0), LOGPIXELSY), 96);
  lfControl.lfFaceName:='MS Sans Serif';
  // Create the font
  hControlFont:=CreateFontIndirect(lfControl);
  SendMessage(self.fHandle, WM_SETFONT, hControlFont, 1);
end;

constructor Button.Create(parent:Container);
var
  hControlFont:HFONT;
  lfControl:TLogFont;
  parentHandle:HWND;
  len:integer;
begin
  inherited Create(parent);
  if parent=NIL then begin
    parentHandle:=0;
    fParent:=NIL;
  end else begin
    parentHandle:=parent.fHandle;
    fParent:=parent;
  end;
  fHandle:=CreateWindow('BUTTON', // BUTTON creates an button, obviously
    'Show Message', // Name of window - also the text that will be in it
    WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON or BS_TEXT, // style flags
    8, 40, 96, 25, // Position and size
    parentHandle, // Parent window
    0, // Menu - none because it's a button
    SysInit.HInstance, // Application instance
    NIL); // No creation data

  if (fHandle=0) or (fHandle=INVALID_HANDLE_VALUE) then begin
    LogError('libgui: Button.Create(Container): [GDI] CreateWindow falhou: HWnd = '+IntToStr(fHandle)+': não foi possível criar o botão: Erro '+IntToStr(GetLastError));
    Exit;
  end;

  arrayOfComponents[fId-1]:=self;
  len:=Length(hWndIdSlot[fHandle mod 65536])+1;
  SetLength(hWndIdSlot[fHandle mod 65536],len);
  hWndIdSlot[fHandle mod 65536][len-1].hndl:=fHandle;
  hWndIdSlot[fHandle mod 65536][len-1].id:=fId;

  // Set up the font
  { Calculate font height from point size - they are not the same thing!
    The first parameter of MulDiv is the point size. }
  lfControl.lfHeight:=-MulDiv(8, GetDeviceCaps(GetDC(0), LOGPIXELSY), 96);
  lfControl.lfFaceName:='MS Sans Serif';
  // Create the font
  hControlFont:=CreateFontIndirect(lfControl);
  SendMessage(self.fHandle, WM_SETFONT, hControlFont, 1);
end;

constructor deptocomApp.Create;
begin
  inherited Create;
  fMainWindow:=NIL;
end;

procedure deptocomApp.SetMainWindow(mw:Window);
begin
  if mainWindowHandle<>0 then
    raise Exception.Create('Já há uma MainWindow definida. Não é possível redefiní-la.');
  if mw<>NIL then begin
    fMainWindow:=mw;
    mainWindowHandle:=mw.fHandle;
  end;
end;

procedure deptocomApp.Run;
var
  msg:TMsg;
begin
  if fMainWindow<>NIL then begin
    fMainWindow.Visible:=TRUE;
    while GetMessage(msg,0,0,0)<>BOOL(FALSE) do begin
      TranslateMessage(msg);
      DispatchMessage(msg);
    end;
  end;
end;

initialization
  componentId:=0;
  windowNum:=0;
  myApp:=deptocomApp.Create;
finalization
  componentId:=0;
  windowNum:=0;
end.
