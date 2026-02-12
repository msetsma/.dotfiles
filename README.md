# **Dotfiles**

Feel free to take what you want, but I would advice against blindly installing without reviewing.

> [!NOTE] These dotfiles complex due to specific requirements (see below).

---

## **Requirements**

1. **Cross-Platform Compatibility**  
   Tools must work seamlessly on Windows, macOS, and Linux for a consistent experience.

2. **Performance-First Approach**  
   Preference for modern, high-performance tools (e.g., Rust-based tools like `uutils`) that replace core utilities across major platforms.

3. **Easy Installation**  
   Tools should have minimal setup time. Examples include `dotter` for dotfile management and `cargo-make` for setup tasks.

---

## **How to Install**

1. **Install Rust**

   - **Windows**:

     ```cmd
     curl -o rustup-init.exe https://win.rustup.rs
     rustup-init.exe
     ```

   - **UNIX**:

     ```bash
     curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
     ```

2. **Verify Rust Installation**  
   Check if Rust is installed correctly:

   ```bash
   rustc --version
   cargo --version
   ```

3. **Install Cargo-Make**

   ```bash
   cargo install cargo-make
   ```

4. **Clone This Repo**

   ```bash
   git clone git@github.com:msetsma/.dotfiles.git
   cd .dotfiles
   ```

5. **Run the Makefile**
   Use `cargo-make` to execute tasks from the `Makefile.toml`:

   ```bash
   cargo make init
   ```

6. **View Available Commands**

   Quick reference (most common commands):

   ```bash
   cargo make help
   ```

   Detailed information (all commands):

   ```bash
   cargo make info
   ```

---

## **Common Tasks**

### **Initial Setup**

```bash
cargo make init          # Complete environment setup
```

### **Updates**

```bash
cargo make update        # Update all tools and packages
cargo make check-outdated # Check for available updates
```

### **Package Manager (Cross-Platform)**

```bash
cargo make pkg-export    # Export packages (works on macOS & Windows)
cargo make pkg-import    # Import packages (works on macOS & Windows)
cargo make pkg-cleanup   # Cleanup old versions
cargo make pkg-doctor    # Check for issues
```

### **Homebrew Management** (macOS)

```bash
cargo make brew-export   # Export current packages to Brewfile
cargo make brew-import   # Install from Brewfile
cargo make brew-cleanup  # Cleanup old versions
cargo make brew-doctor   # Check for issues
```

### **Scoop Management** (Windows)

```bash
cargo make scoop-export  # Export current packages to scoopfile.json
cargo make scoop-import  # Install from scoopfile.json
cargo make scoop-cleanup # Cleanup old versions
cargo make scoop-doctor  # Check for issues
```

### **Python/pipx Management**

```bash
cargo make pipx-list     # List installed pipx packages
cargo make pipx-export   # Export packages to file
cargo make pipx-install  # Install from file
```

### **Dotfile Management**

```bash
cargo make deploy         # Deploy dotfiles via dotter (easy to remember!)
cargo make dotfiles       # Same as above
cargo make dotfiles-check # Validate configuration
```

### **Git Backup**

```bash
cargo make backup         # Quick backup (auto-generated commit message)
cargo make deploy-and-backup  # Deploy dotfiles + backup to git (all-in-one!)

# Custom message example:
cargo make backup-with-message -- "Updated zsh config"
```

### **Utilities**

```bash
cargo make doctor        # System health check
cargo make clean         # Cleanup caches
cargo make info          # Show all available commands
```

---

## **Tools**

> [!NOTE] Common tools are cross-platform, but installation methods may differ by OS.

### **Common Tools**

- [Neovim](https://neovim.io/)
- [Mise](https://github.com/jdx/mise)
- [Nushell](https://github.com/nushell/nushell)
- [Dotter](https://github.com/SuperCuber/dotter)
- [Cargo-Make](https://github.com/sagiegurari/cargo-make)
- [Bottom](https://github.com/ClementTsang/bottom)
- [Duckypad](https://github.com/dekuNukem/duckyPad-Pro)
- [WezTerm](https://github.com/wez/wezterm)
- [Starship](https://github.com/starship/starship)
- [Ruff](https://github.com/astral-sh/ruff)
- [Vivid](https://github.com/sharkdp/vivid)
- [FiraCode](https://github.com/tonsky/FiraCode)

### **macOS-Specific Tools**

- [Karabiner-Elements](https://github.com/pqrs-org/Karabiner-Elements)
- [skhd](https://github.com/koekeishiya/skhd)

### **Windows-Specific Tools**

- [AutoHotkey (AHK)](https://github.com/AutoHotkey/AutoHotkey)
- [Komorebi](https://github.com/LGUG2Z/komorebi)
- [AudioSwitcher](https://github.com/xenolightning/AudioSwitcher_v1)
- [Scoop](https://scoop.sh/)

---

## **Gotchas**

### **Installing a Compiler Suite**

To ensure tools work correctly, you’ll need a suitable compiler suite:

- **Linux**: GCC or Clang
- **macOS**: Clang (via Xcode)
- **Windows**: MSVC (Visual Studio Build Tools)
  - Install the "Desktop development with C++" workload.
