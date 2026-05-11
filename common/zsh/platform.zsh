# Detect platform
case "$(uname -s)" in
  Darwin) IS_MAC=1 ;;
  Linux)  IS_LINUX=1 ;;
esac

# Package manager prefix (Homebrew on Mac, Linuxbrew on Linux if present)
if (( IS_MAC )); then
  PKG_PREFIX="/opt/homebrew"
elif [[ -d /home/linuxbrew/.linuxbrew ]]; then
  PKG_PREFIX="/home/linuxbrew/.linuxbrew"
fi
export PKG_PREFIX