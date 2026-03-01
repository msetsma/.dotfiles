; A function to display a message box with custom text and title
toggleMonitorInputs(monitor, first, second) {
    cmd := 'C:\Users\2015m\AppData\Local\control-my-monitor\ControlMyMonitor.exe /SwitchValue ' . monitor . ' 60 ' . first . ' ' . second
    Run(cmd, "", "Hide")
}
