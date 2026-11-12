Set WshShell = CreateObject("WScript.Shell")

' Start komorebi with whkd
WshShell.Run "komorebic start --whkd", 0, True

' Start yasb (after komorebi is ready)
WshShell.Run "cmd /c start """" yasb", 0, False

' Start Glance (Firefox homepage on :8280) hidden, appending output to its log.
Dim glanceDir : glanceDir = WshShell.ExpandEnvironmentStrings("%USERPROFILE%\.glance")
WshShell.Run "cmd /c """"" & glanceDir & "\glance.exe"" --config """ & glanceDir & "\glance.yml"" >> """ & glanceDir & "\glance.log"" 2>&1""", 0, False
