# Komorebi config notes

## `display_index_preferences`

Pins monitor indexes to specific physical displays so layouts stick to the
right monitor across restarts, unplugs, and Windows monitor re-enumeration.

Current mapping in `komorebi.json`:

| Index | Device ID                          | Monitor        | Orientation | Layout |
|-------|------------------------------------|----------------|-------------|--------|
| 0     | `GBT3204-5&11d5afbc&0&UID4353`     | Gigabyte M32U  | Landscape   | BSP    |
| 1     | `SAM0E14-5&11d5afbc&0&UID4357`     | Samsung C32HG7x| Vertical    | Rows   |

### How to find your device IDs

If you change monitors (new display, swap, etc.), regenerate the IDs with:

```bash
# With komorebi running:
komorebic state | jq '.monitors.elements[] | {name, device, device_id, size}'

# Or from the state dump file:
cat "$Env:TEMP/komorebi.state.json" | jq '.monitors.elements[] | {name, device, device_id}'
```

You can also derive the ID directly from Windows without komorebi:

```powershell
Get-CimInstance -Namespace root/wmi -ClassName WmiMonitorID |
  ForEach-Object {
    $mfg  = -join ($_.ManufacturerName  | Where-Object {$_ -ne 0} | ForEach-Object {[char]$_})
    $prod = -join ($_.UserFriendlyName  | Where-Object {$_ -ne 0} | ForEach-Object {[char]$_})
    [PSCustomObject]@{
      Monitor  = "$mfg $prod"
      DeviceId = $_.InstanceName -replace '^DISPLAY\\','' -replace '\\','-' -replace '_0$',''
    }
  }
```

The `DeviceId` from that PowerShell output matches what komorebi expects in
`display_index_preferences`.
