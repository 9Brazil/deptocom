program deptocom;

uses
  Windows,
  Messages,
  sysutils,
  app in 'app.pas',
  locale in 'locale.pas',
  gui in 'gui.pas',
  threads in 'threads.pas';

var
  mainWindow:Window;

begin
  mainWindow:=window.create;
  myApp.mainWindow:=mainWindow;
  myApp.run;
end.
