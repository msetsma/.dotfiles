rld() {
    echo "Reloading Zsh configuration..."

    if [[ -n "$ZDOTDIR" ]]; then
        source "$ZDOTDIR/.zshrc"
    else
        source "$HOME/.zshrc"
    fi

    exec zsh
    echo "Done"
}
