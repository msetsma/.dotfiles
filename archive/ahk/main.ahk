#Requires AutoHotkey v2.0
#Include functions.ahk

/*
=====================================================
                   Input Workflow
=====================================================

    +-----------------------+          +-----------------------+
    | Macro Pad (DuckyPad)  |          | Keyboard              |
    |-----------------------|          |-----------------------|
    | [Key1]  ->  AHK       |          | [Alt+F13]  ->  AHK    |
    | [Key2]  ->  AHK       |          | [Ctrl+X]   ->  AHK    |
    | [Key3]  ->  AHK       |          | [Alt+F14]  ->  AHK    |
    | [Key4]  ->  AHK       |          | [Win+F15]  ->  AHK    |
    +-----------------------+          +-----------------------+
              |                                  |
              +---+------------------------------+
                  |
                  V         
    +-----------------------+
    | AutoHotkey Scripts    |
    |-----------------------|
    | Key1.ahk -> app1.exe  |
    | Key2.ahk -> app2.exe  |
    | Key3.ahk -> task.bat  |
    | Key4.ahk -> custom.py |
    +-----------------------+

=====================================================
*/
; HOME := StrReplace(A_Desktop, "\Desktop") ; Does AHK 2 not have a $HOME dir var?

; [CTRL ALT SHIFT F20] - HP24 switch between: display port <-> HDMI
^!+F20::{
    toggleMonitorInputs("HPN3688", 15, 17) 
}


; [CTRL ALT SHIFT F19] - M32U switch between: display port <-> USB-C
^!+F19::{
    toggleMonitorInputs("GBT3204", 15, 16) 
}


; [CTRL ALT F18] - toggle between two audio devices (Audio Switcher)
^!F18::{
    static toggle := false
    Sleep(10)
    if (toggle) {
        Send("^!+y") ; Sends [CTRL ALT SHIFT y]
        toggle := false
    } else {
        Send("^!+u") ; Sends [CTRL ALT SHIFT u]
        toggle := true
    }
}


/*
==========================================
           AHK Cheat Sheet
==========================================

--- Modifier Keys ---
^   = Ctrl
!   = Alt
+   = Shift
#   = Windows Key (Super)

--- Mouse Actions ---
LButton = Left Mouse Button
RButton = Right Mouse Button
MButton = Middle Mouse Button
WheelUp/WheelDown = Mouse Wheel Scroll

--- Function Keys ---
F1, F2, ... F24 = Function keys
Note: Some keyboards may not support F13–F24.

--- Common Hotkey Examples ---
^c            = Ctrl + C
^!+F15        = Ctrl + Alt + Shift + F15
#e            = Windows + E
^#Left        = Ctrl + Windows + Left Arrow

--- Send Examples ---
Send("^c")    = Sends Ctrl + C
Send("{Enter}") = Sends Enter key
Send("{Shift Down}a{Shift Up}") = Sends capital A

--- Mouse Commands ---
Click         = Simulate a mouse click
Click Right   = Right-click
Click 100, 200 = Click at screen coordinates (x: 100, y: 200)
MouseMove, X, Y = Move mouse to X, Y coordinates

--- Loops ---
Loop, 5 {     = Repeat 5 times
    MsgBox("Loop #" A_Index)
}

--- Variables ---
myVar := "Hello, World!" = Define a variable
MsgBox(myVar)            = Display variable in a message box

--- Functions ---
myFunction(param1) {
    MsgBox("You passed: " param1)
}

--- Conditional Statements ---
if (A_DesktopWidth > 1920) {
    MsgBox("Your desktop width is larger than 1920 pixels!")
}

--- Window Commands ---
WinActivate, Notepad         = Activate Notepad window
WinClose, Untitled - Notepad = Close a specific window

==========================================
    End of Cheat Sheet
==========================================
*/
   