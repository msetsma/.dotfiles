; A function to display a message box with custom text and title
toggleMonitorInputs(monitor, first, second) {
    cmd := 'ControlMyMonitor.exe /SwitchValue ' . monitor . ' 60 ' . first . ' ' . second
    Run(cmd, "", "Hide")
}