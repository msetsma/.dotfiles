# Windows Changes

## Disable 'Microsoft Hotkeys'

To disable the annoying hotkeys that open microsft apps like copilot, teams, linkedin, etc
run this command as admin in a command prompt.

```cmd
REG ADD HKCU\Software\Classes\ms-officeapp\Shell\Open\Command /t REG_SZ /d rundll32
```
