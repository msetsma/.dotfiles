# platform.zsh — detect runtime environment
# Sets: PLATFORM = "mac" | "wsl" | "linux"
# Sets: IS_MAC, IS_WSL, IS_LINUX (boolean 0/1)

_detect_platform() {
    if [[ "$(uname -s)" == "Darwin" ]]; then
        PLATFORM="mac"
    elif grep -qi "microsoft\|wsl" /proc/version 2>/dev/null; then
        PLATFORM="wsl"
    else
        PLATFORM="linux"
    fi

    IS_MAC=0; IS_WSL=0; IS_LINUX=0
    case "$PLATFORM" in
        mac)   IS_MAC=1 ;;
        wsl)   IS_WSL=1 ;;
        linux) IS_LINUX=1 ;;
    esac

    export PLATFORM IS_MAC IS_WSL IS_LINUX
}

_detect_platform
