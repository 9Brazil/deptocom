program deptocom;

{$APPTYPE Console}

uses
  env in 'src\lib\env.pas',
  threads in 'src\lib\threads.pas',
  geom in 'src\lib\geom.pas',
  gui in 'src\lib\gui.pas',
  io in 'src\lib\io.pas';

var
  mainWindow:Window;

begin
  mainWindow:=Window.Create;
  myApp.MainWindow:=mainWindow;
  myApp.Run;
end.
