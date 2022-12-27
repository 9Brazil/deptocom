program deptocom;

uses
  app in 'app.pas',
  locale in 'locale.pas',
  gui in 'gui.pas',
  threads in 'threads.pas';

var
  mainWindow:Window;

begin
  mainWindow:=Window.create;
  myApp.MainWindow:=mainWindow;
  myApp.run;
end.
