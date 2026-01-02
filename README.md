# Koinós (κοινός) — common, shared! For any GNU/Linux OS

**Koinós** is a universal Linux system setup tool that works across all major distributions. Written in V (Vlang), it automates the installation of system packages, Flatpak applications, and script-based tools with a simple, declarative configuration file.

## 🚀 Quick Start

### Download and Run

1. **Download the binary and config:**
   ```bash
   wget https://github.com/your-repo/koinos/releases/latest/download/koinos
   wget https://github.com/your-repo/koinos/releases/latest/download/config.toml
   chmod +x koinos
   ```

2. **Edit the configuration** (optional):
   ```bash
   vim config.toml
   ```

3. **Run the installer:**
   ```bash
   sudo ./koinos
   ```

That's it! Koinós will automatically detect your distribution and install everything configured in `config.toml`.

## ✨ Features

- 🔍 **Auto-detection** - Automatically identifies your Linux distribution and package manager
- 📦 **Multi-source** - Installs from system repos, Flatpak, and shell scripts
- 🛡️ **Robust** - Continues on failures, provides detailed reports
- 🎯 **Universal** - Works on Debian, Ubuntu, Fedora, Arch, openSUSE, and more
- ⚙️ **Configurable** - Single TOML file for all settings
- 🔧 **Modular** - Clean architecture, easy to extend

## 🐧 Supported Distributions

| Family | Distributions | Package Manager |
|--------|--------------|----------------|
| **Debian** | Debian, Ubuntu, Linux Mint, Pop!_OS, Elementary, Zorin, Kali | `apt` |
| **Red Hat** | Fedora, RHEL, CentOS, Rocky, AlmaLinux | `dnf` |
| **Arch** | Arch, Manjaro, EndeavourOS, Garuda | `pacman` |
| **SUSE** | openSUSE Leap, Tumbleweed | `zypper` |
| **Others** | Gentoo, Alpine, Void, Solus, NixOS | `emerge`, `apk`, `xbps-install`, `eopkg`, `nix-env` |

## 📋 Configuration

Edit `config.toml` to customize what gets installed:

```toml
[system]
# Packages from your distribution's package manager
basic_packages = [
    "curl",
    "git",
    "vim",
    "htop",
    "wget"
]

[flatpak]
# Flatpak repository
flathub_repo = "https://flathub.org/repo/flathub.flatpakrepo"

# Flatpak applications
packages = [
    "com.spotify.Client",
    "org.telegram.desktop",
    "com.brave.Browser"
]

[scripts]
# Applications installed via shell scripts
[scripts.apps]
nextdns = 'sh -c "$(curl -sL https://nextdns.io/install)"'
brave = "curl -fsS https://dl.brave.com/install.sh | sh"
zed = "curl -f https://zed.dev/install.sh | sh"
ohmyzsh = 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'

[configs]
# Fonts installation
[configs.fonts]
hack_url = "https://github.com/ryanoasis/nerd-fonts/releases/download/v2.2.2/Hack.zip"
jetbrains_url = "https://download.jetbrains.com/fonts/JetBrainsMono-2.242.zip"

# Zsh plugins (requires oh-my-zsh)
[configs.zsh]
syntax_highlighting_repo = "https://github.com/zsh-users/zsh-syntax-highlighting.git"
autosuggestions_repo = "https://github.com/zsh-users/zsh-autosuggestions"
powerlevel10k_repo = "https://github.com/romkatv/powerlevel10k.git"

# Standard dotfiles
[configs.dotfiles]
sysctl_url = "https://raw.githubusercontent.com/Esl1h/dotfiles/main/etc/sysctl.conf"
ssh_config_url = "https://raw.githubusercontent.com/Esl1h/dotfiles/main/etc/ssh/ssh_config"
vimrc_url = "https://raw.githubusercontent.com/Esl1h/dotfiles/main/.vimrc"
vim_plug_url = "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
zshrc_url = "https://raw.githubusercontent.com/Esl1h/dotfiles/main/.zshrc"

# Custom dotfiles (with flexible paths)
[[configs.custom_dotfiles]]
url = "https://raw.githubusercontent.com/Esl1h/dotfiles/main/.tmux.conf"
destination = "~/.tmux.conf"
needs_sudo = false

[[configs.custom_dotfiles]]
url = "https://raw.githubusercontent.com/Esl1h/dotfiles/main/.gitconfig"
destination = "~/.gitconfig"
needs_sudo = false

[[configs.custom_dotfiles]]
url = "https://raw.githubusercontent.com/Esl1h/dotfiles/main/etc/hosts"
destination = "/etc/hosts"
needs_sudo = true
```

### Adding New Dotfiles

To add new dotfiles, simply add entries to `[[configs.custom_dotfiles]]`:

```toml
[[configs.custom_dotfiles]]
url = "https://raw.githubusercontent.com/Esl1h/dotfiles/main/PATH/TO/FILE"
destination = "~/destination/path"  # Use ~ for home directory
needs_sudo = false                   # Set to true for system files

[[configs.custom_dotfiles]]
url = "https://raw.githubusercontent.com/Esl1h/dotfiles/main/etc/nginx/nginx.conf"
destination = "/etc/nginx/nginx.conf"
needs_sudo = true
```

**Features:**
- ✅ **Multi-mirror fallback** - Automatically tries GitHub → GitLab → Codeberg
- ✅ **Automatic backup** - Existing files backed up to `.backup`
- ✅ **Flexible paths** - Install to any location (home or system)
- ✅ **Sudo support** - Set `needs_sudo = true` for system files
- ✅ **Directory creation** - Parent directories created automatically
- ✅ **No code changes needed** - Just edit the TOML file!

## 🏗️ Architecture

Koinós is built with a modular architecture:

```
koinos/
├── main.v              # Orchestration layer
├── pkgdetect/          # OS and package manager detection
├── installer/          # System package installation
├── flatpak/            # Flatpak setup and installation
└── scripts/            # Script-based installations
```

### Installation Flow

```
1. Detection  → Identify OS and package manager
2. System     → Install packages via apt/dnf/pacman/etc
3. Flatpak    → Setup Flathub and install apps
4. Scripts    → Execute custom installation scripts
5. Summary    → Report what succeeded, skipped, or failed
```

## 📊 Example Output

```
=== Package Manager Detection ===
Distribution: Ubuntu 24.04 LTS
ID: ubuntu
Default Package Manager: apt

=== Installing Packages ===
[1/5] Installing: curl
  ✓ curl installed successfully
[2/5] Installing: git
  ✓ git installed successfully
...

=== Installation Summary ===
Total packages: 5
Successful: 5
  ✓ curl
  ✓ git
  ✓ vim
  ✓ htop
  ✓ wget

=== Setting up Flatpak ===
✓ Flatpak is installed
✓ Flathub repository added successfully

=== Installing Flatpak Packages ===
[1/2] Installing: com.spotify.Client
  ✓ com.spotify.Client installed successfully
...

=== Installing Script-Based Applications ===
[1/3] Installing: nextdns
  Command: sh -c "$(curl -sL https://nextdns.io/install)"
  ✓ nextdns installed successfully
...

🎉 All installations completed!
```

## 🛠️ Development

### Prerequisites

- **V (Vlang)** version `0.4.12 8241859`
  ```bash
  git clone https://github.com/vlang/v
  cd v
  make
  sudo ./v symlink
  ```

### Building from Source

```bash
# Clone the repository
git clone https://github.com/your-repo/koinos
cd koinos

# Run directly
v run main.v

# Build binary
v main.v

# Build optimized binary
v -prod -o koinos main.v
```

### Project Structure

```
koinos/
├── main.v                  # Main entry point
├── config.toml             # Configuration file
├── README.md               # This file
├── ARCHITECTURE.md         # Technical documentation
│
├── pkgdetect/             # Package manager detection
│   └── pkgdetect.v
│
├── installer/             # System package installer
│   └── installer.v
│
├── flatpak/               # Flatpak manager
│   └── flatpak.v
│
└── scripts/               # Script installer
    └── scripts.v
```

### Adding New Features

**Example: Adding Snap support**

1. Create module: `snap/snap.v`
   ```v
   module snap

   pub fn install_packages(packages []string) ! {
       // Implementation
   }
   ```

2. Update config: `config.toml`
   ```toml
   [snap]
   packages = ["app1", "app2"]
   ```

3. Update main: `main.v`
   ```v
   import snap

   snap.install_packages(config.snap.packages) or { ... }
   ```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Guidelines

- Follow V language conventions
- Keep modules independent
- Add tests for new features
- Update documentation

## 📝 License

[Your chosen license here]

## 🙏 Acknowledgments

- Built with [V (Vlang)](https://vlang.io)
- Inspired by the need for a universal Linux setup tool
- Name "Koinós" (κοινός) means "common" or "shared" in Greek

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/your-repo/koinos/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-repo/koinos/discussions)
- **Troubleshooting**: See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues and solutions

---

**Koinós** — One tool for all Linux distributions. Configure once, deploy anywhere.

## 📚 Usage Examples

### Example 1: Minimal Setup (Git + Vim only)

```toml
[system]
basic_packages = ["git", "vim"]

[[configs.custom_dotfiles]]
url = "https://raw.githubusercontent.com/Esl1h/dotfiles/main/.vimrc"
destination = "~/.vimrc"
needs_sudo = false
```

### Example 2: Full Development Environment

```toml
[system]
basic_packages = ["git", "vim", "tmux", "zsh", "curl", "wget"]

[scripts.apps]
ohmyzsh = 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'

[configs.fonts]
hack_url = "https://github.com/ryanoasis/nerd-fonts/releases/download/v2.2.2/Hack.zip"

[configs.zsh]
syntax_highlighting_repo = "https://github.com/zsh-users/zsh-syntax-highlighting.git"
autosuggestions_repo = "https://github.com/zsh-users/zsh-autosuggestions"

[[configs.custom_dotfiles]]
url = "https://raw.githubusercontent.com/Esl1h/dotfiles/main/.tmux.conf"
destination = "~/.tmux.conf"
needs_sudo = false

[[configs.custom_dotfiles]]
url = "https://raw.githubusercontent.com/Esl1h/dotfiles/main/.gitconfig"
destination = "~/.gitconfig"
needs_sudo = false
```

### Example 3: System Administrator Setup

```toml
[system]
basic_packages = ["vim", "htop", "tmux", "openssh-server"]

[[configs.custom_dotfiles]]
url = "https://raw.githubusercontent.com/Esl1h/dotfiles/main/etc/sysctl.conf"
destination = "/etc/sysctl.conf"
needs_sudo = true

[[configs.custom_dotfiles]]
url = "https://raw.githubusercontent.com/Esl1h/dotfiles/main/etc/ssh/sshd_config"
destination = "/etc/ssh/sshd_config"
needs_sudo = true

[[configs.custom_dotfiles]]
url = "https://raw.githubusercontent.com/Esl1h/dotfiles/main/.vimrc"
destination = "/root/.vimrc"
needs_sudo = true
```

## 🔄 Multi-Mirror Support

All dotfiles are downloaded with **automatic fallback**:

1. **Primary**: GitHub (`raw.githubusercontent.com`)
2. **Fallback 1**: GitLab (`gitlab.com/-/raw/`)
3. **Fallback 2**: Codeberg (`codeberg.org/raw/`)

This ensures your setup works even if one service is down!

**Example:**
```
Trying: https://raw.githubusercontent.com/
✓ Downloaded from https://raw.githubusercontent.com/

# If GitHub fails:
Trying: https://raw.githubusercontent.com/
  (failed)
Trying: https://gitlab.com/
✓ Downloaded from https://gitlab.com/
```
