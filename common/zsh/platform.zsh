# Detect platform
IS_MAC=0
IS_LINUX=0
IS_WSL=0
IS_WSL_INTEROP=0

case "$(uname -s)" in
  Darwin) IS_MAC=1 ;;
  Linux)
    IS_LINUX=1
    if [[ -n "${WSL_DISTRO_NAME:-}" || -n "${WSL_INTEROP:-}" ]] || grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null; then
      IS_WSL=1
    fi
    ;;
esac

if (( IS_WSL )) && [[ -n "${WSL_INTEROP:-}" && -e /proc/sys/fs/binfmt_misc/WSLInterop ]]; then
  IS_WSL_INTEROP=1
fi

# Package manager prefix (Homebrew on Mac, Linuxbrew on Linux if present)
if (( IS_MAC )); then
  PKG_PREFIX="/opt/homebrew"
elif [[ -d /home/linuxbrew/.linuxbrew ]]; then
  PKG_PREFIX="/home/linuxbrew/.linuxbrew"
fi
export PKG_PREFIX
