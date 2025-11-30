# Koinós Features

## Module Overview

### 1. **pkgdetect** - Package Manager Detection
- Detects Linux distribution from `/etc/os-release`
- Identifies default package manager
- Lists all installed package managers
- Supports 10+ distributions

### 2. **installer** - System Package Installation
- Installs packages via native package manager
- Individual installation with error handling
- Categorizes results: ✓ successful, ⚠ skipped, ✗ failed
- Continues on failures (non-blocking)

### 3. **flatpak** - Flatpak Management
- Adds Flathub repository
- Installs Flatpak applications
- Individual package installation
- Detailed error reporting

### 4. **scripts** - Script-Based Installation
- Executes remote installation scripts
- Interactive mode (uses `os.system()`)
- Supports complex shell commands
- Perfect for: Brave, Zed, NextDNS, Oh My Zsh

### 5. **configs** - Configuration & Dotfiles
**Sub-modules:**

#### 5.1. Fonts Installation
- Downloads Nerd Fonts (Hack, JetBrains Mono)
- Extracts to `~/.local/share/fonts`
- Updates font cache with `fc-cache`

#### 5.2. Zsh Plugins
- Creates Oh My Zsh directories
- Installs plugins:
  - zsh-syntax-highlighting
  - zsh-autosuggestions
- Installs Powerlevel10k theme
- Clones with `--depth=1` for speed

#### 5.3. Dotfiles Installation
- **Multi-mirror support** with automatic fallback:
  1. GitHub (primary)
  2. GitLab (fallback)
  3. Codeberg (fallback)
- Installs:
  - `.zshrc` with Oh My Zsh integration
  - Vim configuration + vim-plug
  - `sysctl.conf` (system performance)
  - SSH configuration
  - tmpfs mounts for `/tmp`, `/var/tmp`, `/var/log`
- Backs up existing configurations

#### 5.4. Custom Dotfiles (NEW!)
- **Flexible installation** to any path
- **User files** - Install to `~/.config/`, `~/.local/`, etc.
- **System files** - Install to `/etc/` with `needs_sudo` flag
- **Multi-mirror fallback** - Same GitHub → GitLab → Codeberg
- **Automatic features**:
  - Directory creation (parent dirs created automatically)
  - File backup (existing files → `.backup`)
  - No recompilation needed (just edit TOML)
- **Use cases**:
  - Additional dotfiles (`.bashrc`, `.tmux.conf`, `.gitconfig`)
  - Application configs (`.config/nvim/init.vim`)
  - System configurations (`/etc/hosts`, `/etc/nginx/nginx.conf`)

**Example configuration:**
```toml
[[configs.custom_dotfiles]]
url = "https://raw.githubusercontent.com/USER/dotfiles/main/.tmux.conf"
destination = "~/.tmux.conf"
needs_sudo = false

[[configs.custom_dotfiles]]
url = "https://raw.githubusercontent.com/USER/dotfiles/main/etc/hosts"
destination = "/etc/hosts"
needs_sudo = true
```

## Installation Flow

```
┌─────────────────────────────────────────┐
│ 1. Detect OS & Package Manager          │
│    (pkgdetect)                          │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ 2. Install System Packages              │
│    (installer)                          │
│    apt/dnf/pacman/zypper/etc            │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ 3. Setup Flatpak & Install Apps         │
│    (flatpak)                            │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ 4. Execute Installation Scripts         │
│    (scripts)                            │
│    Brave, Zed, NextDNS, Oh My Zsh      │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ 5. Install Fonts                        │
│    (configs.fonts)                      │
│    Hack, JetBrains Mono                │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ 6. Setup Zsh Plugins                    │
│    (configs.zsh)                        │
│    syntax-highlighting, autosuggestions │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ 7. Install Dotfiles                     │
│    (configs.dotfiles)                   │
│    .zshrc, .vimrc, sysctl, ssh, tmpfs  │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ 8. Install Custom Dotfiles              │
│    (configs.custom_dotfiles)            │
│    User-defined files with any path    │
└──────────────┬──────────────────────────┘
               │
               ▼
          ┌─────────┐
          │   🎉    │
          │  Done!  │
          └─────────┘
```

## Error Handling Strategy

| Module | Failure Behavior |
|--------|-----------------|
| **pkgdetect** | Fatal - stops execution |
| **installer** | Non-blocking - reports and continues |
| **flatpak** | Non-blocking - reports and continues |
| **scripts** | Non-blocking - reports and continues |
| **configs** | Non-blocking - reports and continues |

## Multi-Mirror Fallback

The `configs` module implements intelligent fallback for dotfiles:

```v
const dotfiles_mirrors = [
    'https://raw.githubusercontent.com/Esl1h/dotfiles/main/',  // Try first
    'https://gitlab.com/Esl1h/dotfiles/-/raw/main/',           // Fallback 1
    'https://codeberg.org/Esl1h/dotfiles/raw/branch/main/'     // Fallback 2
]
```

**Benefits:**
- ✅ Resilient against single-point failures
- ✅ Automatic retry mechanism
- ✅ Transparent to the user
- ✅ Works even if GitHub is down

## Configuration Examples

### Minimal Setup
```toml
[system]
basic_packages = ["git", "vim"]

[scripts.apps]
ohmyzsh = 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
```

### Full Setup
```toml
[system]
basic_packages = ["curl", "git", "vim", "htop", "zsh", "wget", "unzip"]

[flatpak]
flathub_repo = "https://flathub.org/repo/flathub.flatpakrepo"
packages = ["com.spotify.Client", "org.telegram.desktop"]

[scripts.apps]
brave = "curl -fsS https://dl.brave.com/install.sh | sh"
ohmyzsh = 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'

[configs.fonts]
hack_url = "https://github.com/ryanoasis/nerd-fonts/releases/download/v2.2.2/Hack.zip"

[configs.zsh]
syntax_highlighting_repo = "https://github.com/zsh-users/zsh-syntax-highlighting.git"

[configs.dotfiles]
vimrc_url = "https://raw.githubusercontent.com/Esl1h/dotfiles/main/.vimrc"

# Custom dotfiles - add as many as needed!
[[configs.custom_dotfiles]]
url = "https://raw.githubusercontent.com/Esl1h/dotfiles/main/.tmux.conf"
destination = "~/.tmux.conf"
needs_sudo = false

[[configs.custom_dotfiles]]
url = "https://raw.githubusercontent.com/Esl1h/dotfiles/main/.gitconfig"
destination = "~/.gitconfig"
needs_sudo = false
```

## Custom Dotfiles - Detailed Guide

The `custom_dotfiles` feature provides maximum flexibility for installing any configuration file to any location.

### How It Works

1. **Define in TOML** - Add entries to `[[configs.custom_dotfiles]]`
2. **Multi-mirror download** - Tries GitHub → GitLab → Codeberg
3. **Auto backup** - Existing files saved as `.backup`
4. **Auto directory creation** - Parent directories created if needed
5. **Smart sudo handling** - Uses `needs_sudo` flag for system files

### Use Cases

| Scenario | Example |
|----------|---------|
| **Shell configs** | `.bashrc`, `.zshrc`, `.profile` |
| **Development tools** | `.gitconfig`, `.tmux.conf`, `.editorconfig` |
| **Editor configs** | `.vimrc`, `.config/nvim/init.vim` |
| **Application configs** | `.config/alacritty/alacritty.yml` |
| **System files** | `/etc/hosts`, `/etc/nginx/nginx.conf` |
| **Root configs** | `/root/.vimrc`, `/root/.bashrc` |

### Advanced Examples

**Install to nested directory:**
```toml
[[configs.custom_dotfiles]]
url = "https://raw.githubusercontent.com/USER/dotfiles/main/.config/alacritty/alacritty.yml"
destination = "~/.config/alacritty/alacritty.yml"
needs_sudo = false
# Parent directory ~/.config/alacritty/ will be created automatically
```

**Install system configuration:**
```toml
[[configs.custom_dotfiles]]
url = "https://raw.githubusercontent.com/USER/dotfiles/main/etc/nginx/nginx.conf"
destination = "/etc/nginx/nginx.conf"
needs_sudo = true
# Requires sudo permissions
```

**Install to root's home:**
```toml
[[configs.custom_dotfiles]]
url = "https://raw.githubusercontent.com/USER/dotfiles/main/.vimrc"
destination = "/root/.vimrc"
needs_sudo = true
# Installing to /root requires sudo
```

### Mirror Format Reference

Your dotfiles can be hosted on any of these services:

| Service | URL Format | Example |
|---------|-----------|---------|
| **GitHub** | `https://raw.githubusercontent.com/USER/REPO/BRANCH/PATH` | `https://raw.githubusercontent.com/Esl1h/dotfiles/main/.vimrc` |
| **GitLab** | `https://gitlab.com/USER/REPO/-/raw/BRANCH/PATH` | `https://gitlab.com/Esl1h/dotfiles/-/raw/main/.vimrc` |
| **Codeberg** | `https://codeberg.org/USER/REPO/raw/branch/BRANCH/PATH` | `https://codeberg.org/Esl1h/dotfiles/raw/branch/main/.vimrc` |

**Note:** You only need to specify the GitHub URL - the fallback to GitLab and Codeberg happens automatically!

## Safety Features

1. **Backup existing files** before overwriting
2. **Skip if already exists** for plugins/themes
3. **Continue on failures** - one failure doesn't stop the entire process
4. **Detailed logging** - know exactly what succeeded/failed
5. **Mirror fallback** - redundancy for critical downloads

## Performance Optimizations

- `git clone --depth=1` for faster cloning
- `wget -c` for resumable downloads
- `unzip -o` to skip prompts
- Parallel installation where possible
- Smart caching and skip-if-exists logic
