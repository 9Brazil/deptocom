unit geom;

interface

uses
  Types;

type
  Dimension2D=class(TInterfacedObject)
  private
    fSize:tagSIZE;
  public
    constructor Create;overload;
    constructor Create(const width,height : longint);overload;
    constructor Create(const d:Dimension2D);overload;
    property Width:longint read fSize.cx write fSize.cx;
    property Height:longint read fSize.cy write fSize.cy;
    property Value:tagSIZE read fSize;
  end;

  Point2D=class(TInterfacedObject)
  private
    fPoint:tagPOINT;
  public
    constructor Create;overload;
    constructor Create(const x,y:longint);overload;
    constructor Create(const p:Point2D);overload;
    property X:longint read fPoint.X write fPoint.X;
    property Y:longint read fPoint.Y write fPoint.Y;
    property Value:tagPoint read fPoint;
    procedure Move(const x,y:longint);overload;
    procedure Move(const p:Point2D);overload;
    procedure Translate(const dx,dy:longint);overload;
    procedure Translate(const d:Dimension2D);overload;
  end;

implementation

uses
  SysUtils;

constructor Dimension2D.Create;
begin
  inherited Create;
  self.fSize.cx:=0;
  self.fSize.cy:=0;
end;

constructor Dimension2D.Create(const width,height : longint);
begin
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

procedure Point2D.Move(const x,y:longint);
begin
  self.fPoint.X:=x;
  self.fPoint.Y:=y;
end;

procedure Point2D.Move(const p:Point2D);
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

end.