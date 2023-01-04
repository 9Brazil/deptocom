unit threads;

interface

uses
  Classes,
  SysUtils,
  Windows;

type
  TObjProc=procedure of object;
  TProcThread=class(TThread)
  private
    fProc
      :TProcedure;
    fObjProc
      :TObjProc;
    fIsObjProc,
    fSync
      :boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(proc:TProcedure);overload;
    constructor Create(proc:TObjProc; const sync:boolean=FALSE);overload;
    destructor Destroy;override;
  end;

procedure RunAsync(proc:TProcedure);overload;
procedure RunAsync(proc:TObjProc);overload;
procedure RunSync(proc:TObjProc);

implementation

constructor TProcThread.Create(proc:TProcedure);
begin
  inherited Create(TRUE);
  fIsObjProc:=FALSE;
  fProc:=proc;
  FreeOnTerminate:=TRUE;
end;

constructor TProcThread.Create(proc:TObjProc; const sync:boolean=FALSE);
begin
  inherited Create(TRUE);
  fIsObjProc:=TRUE;
  fObjProc:=proc;
  fSync:=sync;
  FreeOnTerminate:=TRUE;
end;

procedure TProcThread.Execute;
begin
  if not fIsObjProc then
    fProc
  else
  if fSync then
    Synchronize(fObjProc)
  else
    fObjProc;
end;

destructor TProcThread.Destroy;
begin
  fProc:=NIL;
  fObjProc:=NIL;
  inherited Destroy;
end;

procedure RunAsync(proc:TProcedure);
begin
  (TProcThread.Create(proc)).Resume;
end;

procedure RunAsync(proc:TObjProc);
begin
  (TProcThread.Create(proc)).Resume;
end;

procedure RunSync(proc:TObjProc);
begin
  (TProcThread.Create(proc,TRUE)).Resume;
end;

end.


