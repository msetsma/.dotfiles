# required for starship and will require changes in the future.
mkdir ~/.cache/starship
starship init nu | save -f ~/.cache/starship/init.nu

# required for zoxide
zoxide init nushell | save -f ~/.config/zoxide.nu
