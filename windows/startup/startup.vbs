Set WshShell = CreateObject("WScript.Shell")

' Start komorebi with whkd
WshShell.Run "komorebic start --whkd", 0, True

' Start yasb (after komorebi is ready)
WshShell.Run "cmd /c start """" yasb", 0, False
