program deptocom;

//{$APPTYPE Console}

uses
  env in 'src\lib\env.pas',
  gui in 'src\lib\gui.pas',
  threads in 'src\lib\threads.pas',
  mwFastTime in 'src\lib\mwFastTime.pas';

var
  mainWindow:Window;

begin
  mainWindow:=Window.create;
  myApp.MainWindow:=mainWindow;
  myApp.run;
end.
