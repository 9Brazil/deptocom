program deptocom;

{$APPTYPE CONSOLE}

uses
  app in 'app.pas',
  locale in 'locale.pas',
  gui in 'gui.pas';

var
  minhaJanela:Window;
  meuBotao:Button;

begin
  minhaJanela:=newWindow;
  meuBotao:=newButton;

  readln;
end.
