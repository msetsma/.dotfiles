# Dotfiles

Please copy what you want, but I would advice against blindly installing. 
These dotfiles are a bit more complicated due to the cross platform compatability.


## How to install?

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
   Ensure Rust is installed correctly by checking the versions:  
   ```bash
   rustc --version
   cargo --version
   ```

3. **Install Cargo-Make**  
   ```bash
   cargo install cargo-make
   ```

4. **Clone This Repos**  

   ```bash
   git clone <repository-url>
   cd <repository-folder>
   ```

5. **Run the Makefile**  
   Execute the `Makefile.toml` tasks using Cargo-Make:  
   ```bash
   cargo make
   ```

## Tools
> Note: Tools listed under "common" do not imply they are installed using a universal  method. The installation process may vary depending on the system, such as system package manager (Scoop, Homebrew, or APT).

#### Common
- [mise](https://github.com/jdx/mise)
- [nushell](https://github.com/nushell/nushell) 
- [dotter](https://github.com/SuperCuber/dotter)
- [cargo-make](https://github.com/sagiegurari/cargo-make)
- [bottom](https://github.com/ClementTsang/bottom)
- [duckypad](https://github.com/dekuNukem/duckyPad-Pro)
- [wezterm](https://github.com/wez/wezterm)
- [starship](https://github.com/starship/starship)
- [ruff](https://github.com/astral-sh/ruff)
- [vivid](https://github.com/sharkdp/vivid)
- [firacode](https://github.com/tonsky/FiraCode)

#### OSX
- [karabiner](https://github.com/pqrs-org/Karabiner-Elements)
- [skhd](https://github.com/koekeishiya/skhd)

#### Windows
- [ahk](https://github.com/AutoHotkey/AutoHotkey)
- [komorebi](https://github.com/LGUG2Z/komorebi)
- [audioswitcher](https://github.com/xenolightning/AudioSwitcher_v1)
- [gsudo](https://github.com/gerardog/gsudo)


#### Linux (WIP)
- []()

## **Requirements**

1. **Cross-Platform**  
   Tools must work on Windows, macOS, and Linux for a consistent setup.

2. **Rust-First**  
   Preference for Rust-based tools due to performance, safety, and portability. `uutils` is a prime example, replacing core Unix utilities with modern equivalents.

3. **Easy Installation**  
   Tools should be quick to set up with minimal configuration. Examples: `dotter` for managing dotfiles and `starship` for a configurable prompt.


## Gotchas

#### **Installing a Compiler Suite**

For Rust to work properly, you'll need to have a compatible compiler suite installed on your system. These are the recommended compiler suites:

- Linux: GCC or Clang
- macOS: Clang (install Xcode)
- Windows: MSVC (Visual Studio Build Tools) Make sure to install the "Desktop development with C++" workload.