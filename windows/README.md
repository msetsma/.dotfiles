# Windows Changes

## Disable 'Microsoft Hotkeys'

To disable the annoying hotkeys that open microsft apps like copilot, teams, linkedin, etc
run this command as admin in a command prompt.

```cmd
REG ADD HKCU\Software\Classes\ms-officeapp\Shell\Open\Command /t REG_SZ /d rundll32
```

## Firefox

- `firefox/user.js`: [Betterfox](https://github.com/yokoffing/Betterfox) plus personal overrides (see `MY OVERRIDES`). Symlinked into the profile by dotter; the profile path is per host, so it is mapped in `.dotter/<hostname>.toml`.
- `firefox/autoconfig/`: makes Glance (`http://localhost:8280/`) the real new-tab page, so the address bar stays empty and focused. Needs admin to copy into the Firefox install dir:

  ```cmd
  cargo make firefox-autoconfig
  ```

  Re-run after a Firefox reinstall, then restart Firefox.
