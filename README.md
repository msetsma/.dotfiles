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

### **Linux (WIP)**

- _(To be added)_

---

## **Gotchas**

### **Installing a Compiler Suite**

To ensure tools work correctly, you’ll need a suitable compiler suite:

- **Linux**: GCC or Clang
- **macOS**: Clang (via Xcode)
- **Windows**: MSVC (Visual Studio Build Tools)
  - Install the "Desktop development with C++" workload.
