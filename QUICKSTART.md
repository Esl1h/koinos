# Quick Start: Adding Custom Dotfiles

## TL;DR

Just add to `config.toml`:

```toml
[[configs.custom_dotfiles]]
url = "https://raw.githubusercontent.com/YOUR_USER/dotfiles/main/PATH/TO/FILE"
destination = "~/where/to/install"
needs_sudo = false  # or true for system files
```

Run `./koinos` and it's installed! 🎉

---

## Detailed Guide

### 1. User Files (Home Directory)

For files in your home directory (`~`):

```toml
[[configs.custom_dotfiles]]
url = "https://raw.githubusercontent.com/Esl1h/dotfiles/main/.bashrc"
destination = "~/.bashrc"
needs_sudo = false
```

**Common examples:**
```toml
# Shell configurations
[[configs.custom_dotfiles]]
url = "https://raw.githubusercontent.com/Esl1h/dotfiles/main/.bashrc"
destination = "~/.bashrc"
needs_sudo = false

[[configs.custom_dotfiles]]
url = "https://raw.githubusercontent.com/Esl1h/dotfiles/main/.zshrc"
destination = "~/.zshrc"
needs_sudo = false

# Development tools
[[configs.custom_dotfiles]]
url = "https://raw.githubusercontent.com/Esl1h/dotfiles/main/.gitconfig"
destination = "~/.gitconfig"
needs_sudo = false

[[configs.custom_dotfiles]]
url = "https://raw.githubusercontent.com/Esl1h/dotfiles/main/.tmux.conf"
destination = "~/.tmux.conf"
needs_sudo = false

# Editor configurations
[[configs.custom_dotfiles]]
url = "https://raw.githubusercontent.com/Esl1h/dotfiles/main/.vimrc"
destination = "~/.vimrc"
needs_sudo = false

[[configs.custom_dotfiles]]
url = "https://raw.githubusercontent.com/Esl1h/dotfiles/main/.config/nvim/init.vim"
destination = "~/.config/nvim/init.vim"
needs_sudo = false
```

### 2. System Files (Require Sudo)

For system files in `/etc/` or other protected locations:

```toml
[[configs.custom_dotfiles]]
url = "https://raw.githubusercontent.com/Esl1h/dotfiles/main/etc/hosts"
destination = "/etc/hosts"
needs_sudo = true  # IMPORTANT!
```

**Common examples:**
```toml
# System configurations
[[configs.custom_dotfiles]]
url = "https://raw.githubusercontent.com/Esl1h/dotfiles/main/etc/sysctl.conf"
destination = "/etc/sysctl.conf"
needs_sudo = true

[[configs.custom_dotfiles]]
url = "https://raw.githubusercontent.com/Esl1h/dotfiles/main/etc/ssh/sshd_config"
destination = "/etc/ssh/sshd_config"
needs_sudo = true

# Network configuration
[[configs.custom_dotfiles]]
url = "https://raw.githubusercontent.com/Esl1h/dotfiles/main/etc/resolv.conf"
destination = "/etc/resolv.conf"
needs_sudo = true

# Web server configs
[[configs.custom_dotfiles]]
url = "https://raw.githubusercontent.com/Esl1h/dotfiles/main/etc/nginx/nginx.conf"
destination = "/etc/nginx/nginx.conf"
needs_sudo = true
```

### 3. Using Different Mirrors

The URL format depends on your git hosting:

#### GitHub
```toml
url = "https://raw.githubusercontent.com/USER/REPO/BRANCH/PATH"
# Example:
url = "https://raw.githubusercontent.com/Esl1h/dotfiles/main/.vimrc"
```

#### GitLab
```toml
url = "https://gitlab.com/USER/REPO/-/raw/BRANCH/PATH"
# Example:
url = "https://gitlab.com/Esl1h/dotfiles/-/raw/main/.vimrc"
```

#### Codeberg
```toml
url = "https://codeberg.org/USER/REPO/raw/branch/BRANCH/PATH"
# Example:
url = "https://codeberg.org/Esl1h/dotfiles/raw/branch/main/.vimrc"
```

**Note:** Koinos automatically tries all mirrors if one fails!

### 4. Directory Creation

Koinos **automatically creates parent directories**:

```toml
# This works even if ~/.config/nvim/ doesn't exist yet
[[configs.custom_dotfiles]]
url = "https://raw.githubusercontent.com/Esl1h/dotfiles/main/.config/nvim/init.vim"
destination = "~/.config/nvim/init.vim"
needs_sudo = false
```

### 5. Backup Protection

Existing files are **automatically backed up** with `.backup` extension:

```
Before:  ~/.vimrc
After:   ~/.vimrc.backup (old file)
         ~/.vimrc (new file)
```

### 6. Adding Multiple Files at Once

Just repeat the `[[configs.custom_dotfiles]]` block:

```toml
[[configs.custom_dotfiles]]
url = "https://raw.githubusercontent.com/Esl1h/dotfiles/main/.bashrc"
destination = "~/.bashrc"
needs_sudo = false

[[configs.custom_dotfiles]]
url = "https://raw.githubusercontent.com/Esl1h/dotfiles/main/.vimrc"
destination = "~/.vimrc"
needs_sudo = false

[[configs.custom_dotfiles]]
url = "https://raw.githubusercontent.com/Esl1h/dotfiles/main/.tmux.conf"
destination = "~/.tmux.conf"
needs_sudo = false

# Add as many as you need!
```

---

## FAQs

### Q: Do I need to recompile after adding dotfiles?
**A:** No! Just edit `config.toml` and run the binary.

### Q: What if a file already exists?
**A:** It's automatically backed up to `FILENAME.backup`

### Q: Can I use relative paths?
**A:** Use `~` for home directory. Absolute paths work too.

### Q: What happens if download fails?
**A:** Koinos tries GitHub → GitLab → Codeberg automatically.

### Q: Can I install to `/root/`?
**A:** Yes! Set `needs_sudo = true` and use `/root/` as destination.

### Q: How do I skip a dotfile temporarily?
**A:** Comment it out with `#`:
```toml
# [[configs.custom_dotfiles]]
# url = "..."
# destination = "..."
# needs_sudo = false
```

---

## Real-World Example

Complete setup for a developer workstation:

```toml
[system]
basic_packages = ["git", "vim", "tmux", "zsh", "curl", "wget", "htop"]

[scripts.apps]
ohmyzsh = 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'

[configs.fonts]
hack_url = "https://github.com/ryanoasis/nerd-fonts/releases/download/v2.2.2/Hack.zip"

[configs.zsh]
syntax_highlighting_repo = "https://github.com/zsh-users/zsh-syntax-highlighting.git"
autosuggestions_repo = "https://github.com/zsh-users/zsh-autosuggestions"
powerlevel10k_repo = "https://github.com/romkatv/powerlevel10k.git"

# User configurations
[[configs.custom_dotfiles]]
url = "https://raw.githubusercontent.com/Esl1h/dotfiles/main/.zshrc"
destination = "~/.zshrc"
needs_sudo = false

[[configs.custom_dotfiles]]
url = "https://raw.githubusercontent.com/Esl1h/dotfiles/main/.vimrc"
destination = "~/.vimrc"
needs_sudo = false

[[configs.custom_dotfiles]]
url = "https://raw.githubusercontent.com/Esl1h/dotfiles/main/.tmux.conf"
destination = "~/.tmux.conf"
needs_sudo = false

[[configs.custom_dotfiles]]
url = "https://raw.githubusercontent.com/Esl1h/dotfiles/main/.gitconfig"
destination = "~/.gitconfig"
needs_sudo = false

# System configurations (optional)
[[configs.custom_dotfiles]]
url = "https://raw.githubusercontent.com/Esl1h/dotfiles/main/etc/sysctl.conf"
destination = "/etc/sysctl.conf"
needs_sudo = true
```

Save, run `./koinos`, and enjoy your perfectly configured system! 🚀
