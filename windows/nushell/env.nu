# Nushell env (native Windows). Runs before config.nu.
#
# Tool init scripts are generated once into the vendor autoload dir instead of
# on every startup. After upgrading one of these tools run `rld --regen`.
#
# mise is intentionally absent: `mise activate nu` bakes the current PATH into
# its output, so a cached copy goes stale. The mise shims dir on PATH covers it.

let vendor_generators = {
    starship: {|| ^starship init nu }
    zoxide: {|| ^zoxide init nushell }
    carapace: {|| ^carapace _carapace nushell }
    vivid: {|| $"$env.LS_COLORS = (^vivid generate catppuccin-mocha | str trim | to nuon)\n" }
}

let vendor_dir = $nu.vendor-autoload-dirs | last
mkdir $vendor_dir

for tool in ($vendor_generators | columns) {
    let target = $vendor_dir | path join $"($tool).nu"
    if ($target | path exists) or (which $tool | is-empty) { continue }
    do ($vendor_generators | get $tool) | save --force $target
}
