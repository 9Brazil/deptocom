program deptocom;

{$APPTYPE Console}

uses
  app in 'app.pas',
  locale in 'locale.pas',
  gui in 'gui.pas',
  threads in 'threads.pas',
  dwmapi in 'dwmapi.pas';

var
  mainWindow:Window;

begin
  mainWindow:=Window.create;
  myApp.MainWindow:=mainWindow;
  myApp.run;
end.
