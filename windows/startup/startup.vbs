Set WshShell = CreateObject("WScript.Shell")

' Start komorebi with whkd
WshShell.Run "komorebic start --whkd", 0, True

' Start yasb (after komorebi is ready)
WshShell.Run "cmd /c start """" yasb", 0, False

' Start Handy (speech-to-text) in the tray; whkd alt+v toggles it.
' Handy's own autostart is off (windows/handy/settings_store.json) so this is the only launcher.
Dim handyExe : handyExe = HandyPath()
If handyExe <> "" Then WshShell.Run """" & handyExe & """ --start-hidden", 0, False

' Resolve handy.exe from the installer's uninstall key (per-user first, then machine-wide).
Function HandyPath()
    Dim root, value
    HandyPath = ""
    On Error Resume Next
    For Each root In Array("HKCU", "HKLM")
        value = WshShell.RegRead(root & "\Software\Microsoft\Windows\CurrentVersion\Uninstall\Handy\DisplayIcon")
        If Err.Number = 0 And value <> "" Then
            HandyPath = Replace(value, """", "")
            Exit Function
        End If
        Err.Clear
    Next
End Function
