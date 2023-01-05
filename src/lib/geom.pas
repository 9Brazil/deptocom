unit geom;

interface

uses
  Types;

const
  NOWHERE     = 0;
  INSIDE      = 1;
  OUTSIDE     = 2;
  LEFTSIDE    = 4;
  TOPSIDE     = 8;
  RIGHTSIDE   = 16;
  BOTTOMSIDE  = 32;
  BOUNDARY    = LEFTSIDE or TOPSIDE or RIGHTSIDE or BOTTOMSIDE;

  OUT_LEFT    = 1;
  OUT_TOP     = 2;
  OUT_RIGHT   = 4;
  OUT_BOTTOM  = 8;

type
  //v. https://learn.microsoft.com/pt-br/windows/win32/api/windef/ns-windef-rect
  tagRECT=packed record
    left,
    top,
    right,
    bottom
      :longint;
  end;
  RECT=tagRECT;
  _RECT=RECT;
  RECTL=_RECT;

  Dimension2D=class(TInterfacedObject)
  private
    fSize:tagSIZE;
  public
    constructor Create;overload;
    constructor Create(const width,height : longint);overload;
    constructor Create(const d:Dimension2D);overload;
    function Equals(obj:TObject):boolean;
    function ToString:string;
    function Clone:Dimension2D;
    property Width:longint read fSize.cx write fSize.cx;
    property Height:longint read fSize.cy write fSize.cy;
    property Value:tagSIZE read fSize;
    procedure Resize(const newWidth,newHeight:integer);overload;
    procedure Resize(const newSize:Dimension2D);overload;
  end;

  Point2D=class(TInterfacedObject)
  private
    fPoint:tagPOINT;
  public
    constructor Create;overload;
    constructor Create(const x,y:longint);overload;
    constructor Create(const p:Point2D);overload;
    function Equals(obj:TObject):boolean;
    function ToString:string;
    function Clone:Point2D;
    property X:longint read fPoint.X write fPoint.X;
    property Y:longint read fPoint.Y write fPoint.Y;
    property Value:tagPoint read fPoint;
    procedure MoveTo(const x,y:longint);overload;
    procedure MoveTo(const p:Point2D);overload;
    procedure Translate(const dx,dy:longint);overload;
    procedure Translate(const d:Dimension2D);overload;
    class function DistanceSq(const p1,p2:Point2D):extended;overload;
    function DistanceSq(const p:Point2D):extended;overload;
    class function Distance(const p1,p2:Point2D):extended;overload;
    function Distance(const p:Point2D):extended;overload;
  end;

  Rectangle=class(TInterfacedObject)
  private
    fRect:tagRECT;
    function GetTopLeft:Point2D;
    function GetBottomLeft:Point2D;
    function GetTopRight:Point2D;
    function GetBottomRight:Point2D;
    function GetSize:Dimension2D;
    function GetDiagonalLength:extended;
    function GetPerimeter:extended;
    function GetArea:extended;
    function IsEmpty:boolean;
    function IsSquare:boolean;
  public
    constructor Create;overload;
    constructor Create(const x1,y1,x2,y2:longint);overload;
    constructor Create(const p1,p2:Point2D);overload;
    constructor Create(const origin:Point2D; const size:Dimension2D);overload;
    constructor Create(const cx,cy:longint);overload;
    constructor Create(const size:Dimension2D);overload;
    constructor Create(const p:Point2D);overload;
    constructor Create(const r:Rectangle);overload;
    constructor CreateSquare(const size:longint);overload;
    constructor CreateSquare(const x,y,size:longint);overload;
    constructor CreateSquare(const p:Point2D; const size:longint);overload;
    function Equals(obj:TObject):boolean;
    function ToString:string;
    function Clone:Rectangle;
    property Top:longint read fRect.top;
    property Left:longint read fRect.left;
    property Bottom:longint read fRect.bottom;
    property Right:longint read fRect.right;
    property TopLeft:Point2D read GetTopLeft;
    property BottomLeft:Point2D read GetBottomLeft;
    property TopRight:Point2D read GetTopRight;
    property BottomRight:Point2D read GetBottomRight;
    property Value:tagRECT read fRect;
    property Size:Dimension2D read GetSize;
    property DiagonalLength:extended read GetDiagonalLength;
    property Perimeter:extended read GetPerimeter;
    property Area:extended read GetArea;
    function HasWidth:boolean;
    function HasHeight:boolean;
    property Empty:boolean read IsEmpty;
    property Square:boolean read IsSquare;
    procedure Inflate(const dx,dy:integer);//v. https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-inflaterect
    procedure Resize(const newWidth,newHeight:integer);overload;
    procedure Resize(const newSize:Dimension2D);overload;
    procedure Offset(const dx,dy:integer);//v. https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-offsetrect
    procedure MoveTo(const x,y:integer);overload;
    procedure MoveTo(const p:Point2D);overload;
    function PtInRect(const p:Point2D):boolean;overload;//v. https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-ptinrect
    function PtInRect(const x,y:integer):boolean;overload;
    function WhereIs(const x,y:longint):integer;overload;
    function WhereIs(const p:Point2D):integer;overload;
    function Outcode(const x,y:longint):integer;overload;
    function Outcode(const p:Point2D):integer;overload;
    function IsVertex(const p:Point2D):boolean;overload;
    function IsVertex(const x,y:longint):boolean;overload;
  end;

function SizeToString(const size:tagSIZE):string;
function PointToString(const point:tagPOINT):string;
function RectToString(const rect:tagRECT):string;overload;
function RectToString(const rect:TRect):string;overload;

implementation

uses
  Math,
  SysUtils;

function SizeToString(const size:tagSIZE):string;
begin
  result:='[cx='+IntToStr(size.cx)+',cy='+IntToStr(size.cy)+']'
end;

function PointToString(const point:tagPOINT):string;
begin
  result:='[X='+IntToStr(point.X)+',Y='+IntToStr(point.Y)+']';
end;

function RectToString(const rect:tagRECT):string;
begin
  result:='[TopLeft=('+IntToStr(rect.left)+','+IntToStr(rect.top)+'),BottomRight=('+IntToStr(rect.right)+','+IntToStr(rect.bottom)+')]';
end;

function RectToString(const rect:TRect):string;
begin
  result:='[TopLeft=('+IntToStr(rect.left)+','+IntToStr(rect.top)+'),BottomRight=('+IntToStr(rect.right)+','+IntToStr(rect.bottom)+')]';
end;

constructor Dimension2D.Create;
begin
  inherited Create;
  self.fSize.cx:=0;
  self.fSize.cy:=0;
end;

constructor Dimension2D.Create(const width,height : longint);
begin
  if (width or height)<0 then
    raise Exception.Create('geom.Dimension2D.Create(longint,longint): negative size');

  inherited Create;
  self.fSize.cx:=width;
  self.fSize.cy:=height;
end;

constructor Dimension2D.Create(const d:Dimension2D);
begin
  if d=NIL then
    raise Exception.Create('geom.Dimension2D.Create(Dimension2D): Nil pointer');

  inherited Create;
  self.fSize.cx:=d.fSize.cx;
  self.fSize.cy:=d.fSize.cy;
end;

function Dimension2D.Equals(obj:TObject):boolean;
begin
  if obj=NIL then
    raise Exception.Create('geom.Dimension2D.Equals(TObject): Nil pointer');

  if obj.ClassType<>self.ClassType then
    result:=FALSE
  else
    result:=((obj as Dimension2D).fSize.cx=self.fSize.cx) and ((obj as Dimension2D).fSize.cy=self.fSize.cy);
end;

function Dimension2D.ToString:string;
begin
  result:='geom.Dimension2D'+SizeToString(self.fSize);
end;

function Dimension2D.Clone:Dimension2D;
begin
  result:=Dimension2D.Create(self);
end;

procedure Dimension2D.Resize(const newWidth,newHeight:integer);
begin
  if (newWidth or newHeight)<0 then
    raise Exception.Create('geom.Dimension2D.Resize(integer,integer): negative size');

  self.fSize.cx:=newWidth;
  self.fSize.cy:=newHeight;
end;

procedure Dimension2D.Resize(const newSize:Dimension2D);
begin
  if newSize=NIL then
    Exception.Create('geom.Dimension2D.Resize(Dimension2D): Nil pointer');

  self.Resize(newSize.Width,newSize.Height);
end;

constructor Point2D.Create;
begin
  inherited Create;
  self.fPoint.X:=0;
  self.fPoint.Y:=0;
end;

constructor Point2D.Create(const x,y:longint);
begin
  inherited Create;
  self.fPoint.X:=x;
  self.fPoint.Y:=y;
end;

constructor Point2D.Create(const p:Point2D);
begin
  if p=NIL then
    raise Exception.Create('geom.Point2D.Create(Point2D): Nil pointer');

  inherited Create;
  self.fPoint.X:=p.fPoint.X;
  self.fPoint.Y:=p.fPoint.Y;
end;

function Point2D.Equals(obj:TObject):boolean;
begin
  if obj=NIL then
    raise Exception.Create('geom.Point2D.Equals(TObject): Nil pointer');

  if obj.ClassType<>self.ClassType then
    result:=FALSE
  else
    result:=((obj as Point2D).fPoint.X=self.fPoint.X) and ((obj as Point2D).fPoint.Y=self.fPoint.Y);
end;

function Point2D.ToString:string;
begin
  result:='geom.Point2D'+PointToString(self.fPoint);
end;

function Point2D.Clone:Point2D;
begin
  result:=Point2D.Create(self);
end;

procedure Point2D.MoveTo(const x,y:longint);
begin
  self.fPoint.X:=x;
  self.fPoint.Y:=y;
end;

procedure Point2D.MoveTo(const p:Point2D);
begin
  if p=NIL then
    raise Exception.Create('geom.Point2D.Move(Point): Nil pointer');

  self.fPoint.X:=p.fPoint.X;
  self.fPoint.Y:=p.fPoint.Y;
end;

procedure Point2D.Translate(const dx,dy:longint);
begin
  self.fPoint.X:=self.fPoint.X+dx;
  self.fPoint.Y:=self.fPoint.Y+dy;
end;

procedure Point2D.Translate(const d:Dimension2D);
begin
  if d=NIL then
    raise Exception.Create('geom.Point2D.Translate(Dimension2D): Nil pointer');

  self.fPoint.X:=self.fPoint.X+d.fSize.cx;
  self.fPoint.Y:=self.fPoint.Y+d.fSize.cy;
end;


class function Point2D.DistanceSq(const p1,p2:Point2D):extended;
begin
  result:=(p2.fPoint.X-p1.fPoint.X)*(p2.fPoint.X-p1.fPoint.X) + (p2.fPoint.Y-p1.fPoint.Y)*(p2.fPoint.Y-p1.fPoint.Y);
end;

function Point2D.DistanceSq(const p:Point2D):extended;
begin
  result:=Point2D.DistanceSq(self,p);
end;

class function Point2D.Distance(const p1,p2:Point2D):extended;
begin
  result:=Sqrt(Point2D.DistanceSq(p1,p2));
end;

function Point2D.Distance(const p:Point2D):extended;
begin
  result:=Point2D.Distance(self,p);
end;

constructor Rectangle.Create;
begin
  inherited Create;

  fRect.left:=0;
  fRect.top:=0;
  fRect.right:=0;
  fRect.bottom:=0;
end;

constructor Rectangle.Create(const x1,y1,x2,y2:longint);
begin
  inherited Create;

  fRect.left:=Min(x1,x2);
  fRect.top:=Min(y1,y2);
  fRect.right:=Max(x1,x2);
  fRect.bottom:=Max(y1,y2);
end;

constructor Rectangle.Create(const p1,p2:Point2D);
begin
  if (p1=NIL) or (p2=NIL) then
    raise Exception.Create('geom.Rectangle.Create(Point2D,Point2D): Nil pointer');

  Create(p1.X,p1.Y,p2.X,p2.Y);
end;

constructor Rectangle.Create(const origin:Point2D; const size:Dimension2D);
begin
  if (origin=NIL) or (size=NIL) then
    raise Exception.Create('geom.Rectangle.Create(Point2D,Dimension2D): Nil pointer');

  Create(origin.X,origin.Y,origin.X+size.Width,origin.Y+size.Height);
end;

constructor Rectangle.Create(const cx,cy:longint);
begin
  Create(0,0,cx,cy);
end;

constructor Rectangle.Create(const size:Dimension2D);
begin
  if size=NIL then
    raise Exception.Create('geom.Rectangle.Create(Dimension2D): Nil pointer');

  Create(size.fSize.cx,size.fSize.cy);
end;

constructor Rectangle.Create(const p:Point2D);
begin
  if p=NIL then
    raise Exception.Create('geom.Rectangle.Create(Point2D): Nil pointer');

  Create(p,Dimension2D.Create(0,0));
end;

constructor Rectangle.Create(const r:Rectangle);
begin
  if r=NIL then
    raise Exception.Create('geom.Rectangle.Create(Rectangle): Nil pointer');

  Create(r.TopLeft,r.BottomRight);
end;

constructor Rectangle.CreateSquare(const size:longint);
begin
  if size<0 then
    raise Exception.Create('geom.Rectangle.CreateSquare(longint): negative size');
  Create(0,0,size,size);
end;

constructor Rectangle.CreateSquare(const x,y,size:longint);
begin
  if size<0 then
    raise Exception.Create('geom.Rectangle.CreateSquare(longint,longint,longint): negative size');
  Create(x,y,x+size,y+size);
end;

constructor Rectangle.CreateSquare(const p:Point2D; const size:longint);
begin
  if p=NIL then
    raise Exception.Create('geom.Rectangle.CreateSquare(Point2D,longint): Nil pointer');

  CreateSquare(p.fPoint.X,p.fPoint.Y,size);
end;

function Rectangle.Equals(obj:TObject):boolean;
begin
  if obj=NIL then
    raise Exception.Create('geom.Rectangle.Equals(TObject): Nil pointer');

  if obj.ClassType<>self.ClassType then
    result:=FALSE
  else
    result:=self.TopLeft.Equals((obj as Rectangle).TopLeft) and self.BottomRight.Equals((obj as Rectangle).BottomRight);
end;

function Rectangle.ToString:string;
begin
  result:='geom.Rectangle'+RectToString(self.fRect);
end;

function Rectangle.Clone:Rectangle;
begin
  result:=Rectangle.Create(self);
end;

function Rectangle.GetTopLeft:Point2D;
begin
  result:=Point2D.Create(left,top);
end;

function Rectangle.GetBottomLeft:Point2D;
begin
  result:=Point2D.Create(left,bottom);
end;

function Rectangle.GetTopRight:Point2D;
begin
  result:=Point2D.Create(right,top);
end;

function Rectangle.GetBottomRight:Point2D;
begin
  result:=Point2D.Create(right,bottom);
end;

function Rectangle.GetSize:Dimension2D;
begin
  result:=Dimension2D.Create(right-left,bottom-top);
end;

function Rectangle.GetDiagonalLength:extended;
begin
  result:=Point2D.Distance(TopLeft,BottomRight);
end;

function Rectangle.GetPerimeter:extended;
begin
  result:=2*self.Size.Width+2*self.Size.Height;
end;

function Rectangle.GetArea:extended;
begin
  result:=self.Size.Width*self.Size.Height;
end;

function Rectangle.HasWidth:boolean;
begin
  result:=Left<>Right;
end;

function Rectangle.HasHeight:boolean;
begin
  result:=Top<>Bottom;
end;

function Rectangle.IsEmpty:boolean;
begin
  result:=(Left=Right) or (Top=Bottom);
end;

function Rectangle.IsSquare:boolean;
begin
  result:=(Right-Left)*(Right-Left)=(Bottom-Top)*(Bottom-Top);
end;

procedure Rectangle.Inflate(const dx,dy:integer);
begin
  self.fRect.left:=self.fRect.left-dx;
  self.fRect.right:=self.fRect.right+dx;
  self.fRect.top:=self.fRect.top-dy;
  self.fRect.bottom:=self.fRect.bottom+dy;
end;

procedure Rectangle.Resize(const newWidth,newHeight:integer);
begin
  if (newWidth or newHeight)<0 then
    raise Exception.Create('geom.Rectangle.Resize(integer,integer): negative size');
  self.fRect.right:=self.fRect.left+newWidth;
  self.fRect.bottom:=self.fRect.top+newHeight;
end;

procedure Rectangle.Resize(const newSize:Dimension2D);
begin
  if newSize=NIL then
    raise Exception.Create('geom.Rectangle.Resize(Dimension2D): Nil pointer');

  self.Resize(newSize.Width,newSize.Height);
end;

procedure Rectangle.Offset(const dx,dy:integer);
begin
  self.fRect.left:=self.fRect.left+dx;
  self.fRect.right:=self.fRect.right+dx;
  self.fRect.top:=self.fRect.top+dy;
  self.fRect.bottom:=self.fRect.bottom+dy;
end;

procedure Rectangle.MoveTo(const x,y:integer);
var
  sz:Dimension2D;
begin
  sz:=self.GetSize;
  self.fRect.left:=x;
  self.fRect.top:=y;
  self.fRect.right:=x+sz.Width;
  self.fRect.bottom:=y+sz.Height;
end;

procedure Rectangle.MoveTo(const p:Point2D);
begin
  if p=NIL then
    raise Exception.Create('geom.Rectangle.MoveTo(Point2D): Nil pointer');

  self.MoveTo(p.X,p.Y);
end;

function Rectangle.PtInRect(const x,y:integer):boolean;
begin
  result:=
    (x>=self.fRect.left)
    and
    (x<self.fRect.right)
    and
    (y>=self.fRect.top)
    and
    (y<self.fRect.bottom);
end;

function Rectangle.PtInRect(const p:Point2D):boolean;
begin
  if p=NIL then
    raise Exception.Create('geom.Rectangle.PtInRect(Point2D): Nil pointer');

  result:=self.PtInRect(p.X,p.Y);
end;

function Rectangle.WhereIs(const x,y:longint):integer;
begin
  result:=NOWHERE;
  if
    (x>self.fRect.left)
    and
    (x<self.fRect.right)
    and
    (y>self.fRect.top)
    and
    (y<self.fRect.bottom)
  then//the point (x,y) is inside the region (in the interior)
    result:=result or INSIDE
  else
  if
    (x<self.fRect.left)
    or
    (x>self.fRect.right)
    or
    (y<self.fRect.top)
    or
    (y>self.fRect.bottom)
  then//the point (x,y) is outside the region (in the exterior)
    result:=result or OUTSIDE
  else begin//the point (x,y) is in the boundary (LEFTSIDE U TOPSIDE U RIGHTSIDE U BOTTOMSIDE)
    if (x=self.fRect.left) and (y>=self.fRect.top) and (y<=self.fRect.bottom) then
      result:=result or LEFTSIDE;
    if (x>=self.fRect.left) and (x<=self.fRect.right) and (y=self.fRect.top) then
      result:=result or TOPSIDE;
    if (x=self.fRect.right) and (y>=self.fRect.top) and (y<=self.fRect.bottom) then
      result:=result or RIGHTSIDE;
    if (x>=self.fRect.left) and (x<=self.fRect.right) and (y=self.fRect.bottom) then
      result:=result or BOTTOMSIDE;
  end;
end;

function Rectangle.WhereIs(const p:Point2D):integer;
begin
  if p=NIL then
    raise Exception.Create('geom.Rectangle.WhereIs(Point2D): Nil pointer');

  result:=WhereIs(p.X,p.Y);
end;

function Rectangle.Outcode(const x,y:longint):integer;
begin
  //v. https://docs.oracle.com/javase/7/docs/api/java/awt/geom/Rectangle2D.html#outcode(double,%20double)
  //https://github.com/openjdk-mirror/jdk7u-jdk/blob/master/src/share/classes/java/awt/geom/Rectangle2D.java#L217

  result:=NOWHERE;

  if not self.HasWidth then
    result:=result or OUT_LEFT or OUT_RIGHT
  else
  if x<self.Left then
    result:=result or OUT_LEFT
  else
  if x>self.Right then
    result:=result or OUT_RIGHT;

  if not self.HasHeight then
    result:=result or OUT_TOP or OUT_BOTTOM
  else
  if y<self.Top then
    result:=result or OUT_TOP
  else
  if y>self.Bottom then
    result:=result or OUT_BOTTOM;
end;

function Rectangle.Outcode(const p:Point2D):integer;
begin
  if p=NIL then
    raise Exception.Create('geom.Rectangle.Outcode(Point2D): Nil pointer');

  result:=Outcode(p.X,p.Y);
end;

function Rectangle.IsVertex(const p:Point2D):boolean;
begin
  if p=NIL then
    raise Exception.Create('geom.Rectangle.IsVertex(Point2D): Nil pointer');

  result:= p.Equals(self.TopLeft) or p.Equals(self.TopRight) or p.Equals(self.BottomRight) or p.Equals(self.BottomLeft);
end;

function Rectangle.IsVertex(const x,y:longint):boolean;
begin
  result:=self.IsVertex(Point2D.Create(x,y));
end;

end.