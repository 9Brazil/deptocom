unit threads;

interface

uses
  Classes,
  SysUtils,
  Windows;

type
  tobjproc=procedure of object;
  tprocthread=class(tthread)
  private
    fproc:tprocedure;
    fobjproc:tobjproc;
    fisobjproc,fsync:boolean;
  protected
    procedure execute; override;
  public
    constructor create(proc:tprocedure);overload;
    constructor create(proc:tobjproc; const sync:boolean=false);overload;
    destructor destroy;override;
  end;

procedure runAsync(proc:tprocedure);overload;
procedure runAsync(proc:tobjproc);overload;
procedure runSync(proc:tobjproc);

implementation

constructor tprocthread.create(proc:tprocedure);
begin
  inherited create(true);
  fisobjproc:=false;
  fproc:=proc;
  freeonterminate:=true;
end;

constructor tprocthread.create(proc:tobjproc; const sync:boolean=false);
begin
  inherited create(true);
  fisobjproc:=true;
  fobjproc:=proc;
  fsync:=sync;
  freeonterminate:=true;
end;

procedure tprocthread.execute;
begin
  if not fisobjproc then fproc else if fsync then synchronize(fobjproc) else fobjproc;
end;

destructor tprocthread.destroy;
begin
  fproc:=nil;
  fobjproc:=nil;
  inherited destroy;
end;

procedure runAsync(proc:tprocedure);
begin
  (tprocthread.create(proc)).resume;
end;

procedure runAsync(proc:tobjproc);
begin
  (tprocthread.create(proc)).resume;
end;

procedure runSync(proc:tobjproc);
begin
  (tprocthread.create(proc,true)).resume;
end;

end.
