# General tools: copy, ltcopy, archive, rld, update, ruff helpers, emoji2ascii.
# Ported from windows/nushell/autoload/40-tools.nu.

# .SYNOPSIS
# Copy piped input to the clipboard (OSC 52 over SSH, so it reaches the client)
function copy {
    $text = ($input | Out-String).TrimEnd("`r", "`n")
    if ($env:SSH_CONNECTION) {
        $b64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($text))
        [Console]::Write("`e]52;c;$b64`a")
    } else {
        Set-Clipboard -Value $text
    }
}

# .SYNOPSIS
# Copy the eza tree of the current directory
function ltcopy { eza --tree | copy }

# .SYNOPSIS
# Fuzzy multi-select entries in the current dir and move them to ~/ARCHIVE
function archive {
    $archiveDir = Join-Path $HOME 'ARCHIVE'
    $null = New-Item -ItemType Directory -Force $archiveDir

    $picks = Get-ChildItem -Force -Name |
        fzf --multi --prompt 'archive > ' --header 'tab: multi-select' --preview-window right:60%:wrap `
            --preview 'bat --color=always --style=numbers {} 2>nul || eza --icons --tree --level=2 --color=always {}'
    if (-not $picks) { Write-Host 'No items selected'; return }

    foreach ($item in @($picks)) {
        Move-Item -LiteralPath $item -Destination $archiveDir
        Write-Host "$($PSStyle.Foreground.Green)✓$($PSStyle.Reset) Archived: $($PSStyle.Foreground.Cyan)$item$($PSStyle.Reset)"
    }
    Write-Host "`n$(@($picks).Count) items moved to $($PSStyle.Foreground.Cyan)$archiveDir$($PSStyle.Reset)"
}

# .SYNOPSIS
# Restart the shell; optionally redeploy dotfiles or regenerate tool init files
function rld {
    param([switch]$Deploy, [switch]$Regen)
    if ($Deploy) {
        Write-Host 'deploying dotfiles...'
        Push-Location ~/.dotfiles
        try { dotter deploy } finally { Pop-Location }
    }
    if ($Regen) {
        Get-ChildItem $PowerShellCacheDir -Filter *.ps1 | Remove-Item
    }
    Write-Host 'Reloading pwsh...'
    # No exec in PowerShell: run a fresh shell, then leave this one when it ends
    & (Get-Process -Id $PID).Path -NoLogo
    exit
}

function _update-managers {
    @(
        @{ Name = 'Scoop'; Bin = 'scoop'
           # rows after the "----" header line of `scoop status`
           Check = { $lines = @(scoop status 6>&1 | Out-String -Stream | ForEach-Object { $_ -replace "`e\[[0-9;]*m" } |
                         Where-Object { $_.Trim() })
                     $header = [array]::FindIndex($lines, [Predicate[string]] { $args[0].StartsWith('----') })
                     if ($header -lt 0) { 0 } else { $lines.Count - $header - 1 } }
           Apply = { scoop update; scoop update --all; scoop cleanup --all } }
        @{ Name = 'mise'; Bin = 'mise'
           Check = { @((mise outdated --json | Out-String | ConvertFrom-Json).PSObject.Properties).Count }
           Apply = { mise upgrade } }
        @{ Name = 'Rust toolchains'; Bin = 'rustup'
           Check = { @(rustup check | Select-String 'Update available').Count }
           Apply = { rustup self update; rustup update } }
        @{ Name = 'Cargo installs'; Bin = 'cargo-install-update'
           Check = { @(cargo install-update -l | Where-Object { $_.TrimEnd().EndsWith('Yes') }).Count }
           Apply = { cargo install-update -a } }
        @{ Name = 'uv tools'; Bin = 'uv'; Check = { $null }; Apply = { uv tool upgrade --all } }
        @{ Name = 'npm globals'; Bin = 'npm'
           Check = { @((npm outdated -g --json | Out-String | ConvertFrom-Json).PSObject.Properties).Count }
           Apply = { npm update -g } }
        @{ Name = 'Bun globals'; Bin = 'bun'
           Check = { @(bun outdated -g 2>$null | Where-Object { $_.StartsWith('│') -and $_ -notmatch 'Package|─' }).Count }
           Apply = { bun update -g } }
    ) | Where-Object { Get-Command $_.Bin -CommandType Application -ErrorAction SilentlyContinue }
}

# .SYNOPSIS
# Check package managers for updates, then optionally apply them
function update {
    $managers = _update-managers
    if (-not $managers) { Write-Host 'No supported package managers were found.'; return }

    Write-Host 'Update summary' -ForegroundColor Yellow
    $summary = foreach ($m in $managers) {
        $count = try { & $m.Check } catch { $null }
        [pscustomobject]@{ Manager = $m.Name; Outdated = $(if ($null -eq $count) { '?' } else { $count }) }
    }
    $summary | Format-Table -AutoSize | Out-Host
    $known = ($summary.Outdated | Where-Object { $_ -is [int] } | Measure-Object -Sum).Sum
    Write-Host "$known known outdated (? = no quiet check)"

    if ((Read-Host 'Run updates now? [y/N]') -ne 'y') { Write-Host "`nNo updates applied."; return }
    foreach ($m in $managers) {
        Write-Host "--- Updating $($m.Name)" -ForegroundColor Cyan
        try { & $m.Apply; Write-Host "$($m.Name) complete.`n" -ForegroundColor Green }
        catch { Write-Host "$($m.Name) failed; continuing.`n" -ForegroundColor Red }
    }
    Write-Host 'Update run complete.' -ForegroundColor Blue
}

# .SYNOPSIS
# ruff check --fix, then ruff format (default target: .)
function ruff-fmt {
    $targets = if ($args) { $args } else { '.' }
    ruff check --fix @targets
    if ($LASTEXITCODE -ne 0) { return }
    ruff format @targets
}

# .SYNOPSIS
# ruff check without fixes (default target: .)
function ruff-lint {
    $targets = if ($args) { $args } else { '.' }
    ruff check @targets
}

# .SYNOPSIS
# Render an emoji (via noto-emoji) or an image file as colored ASCII art
function emoji2ascii {
    param([Parameter(Mandatory)][string]$Emoji, [int]$Width = 40)
    $img = $Emoji
    if (-not (Test-Path -LiteralPath $Emoji)) {
        $img = Join-Path ([IO.Path]::GetTempPath()) 'emoji.png'
        $code = '{0:x}' -f [char]::ConvertToUtf32($Emoji, 0)
        Invoke-WebRequest "https://raw.githubusercontent.com/googlefonts/noto-emoji/main/png/128/emoji_u$code.png" -OutFile $img
    }
    ascii-image-converter $img -C -W $Width
}
