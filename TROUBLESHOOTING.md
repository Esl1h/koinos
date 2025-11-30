# Troubleshooting Guide

## Common Issues and Solutions

### 1. Installation Stops at First Failed Package

**Problem:**
```
Failed: 1
  ✗ openssh-server
Error: 1 package(s) failed to install
```

**Solution:**
✅ **Fixed in latest version** - The installer now continues even if packages fail.

If you're using an old version:
- Remove the problematic package from `config.toml`
- Or update to the latest version where this is fixed

**Why it happens:**
Package names differ across distributions:
- `openssh-server` (Debian/Ubuntu)
- `openssh` (Fedora/Arch)
- `openssh-clients` (RHEL/CentOS)

**Current solution:**
The installer now tries alternatives automatically!

---

### 2. Config Module Not Running

**Problem:**
Fonts, Zsh plugins, or dotfiles don't install.

**Diagnosis:**
Look for debug output:
```
--- Checking fonts configuration ---
Hack URL: https://...
```

**Common causes:**

#### A. TOML Parse Error
Check if your `config.toml` is valid:
```bash
# Missing section headers
❌ [configs]
   [fonts]  # Missing 'configs.' prefix

✅ [configs]
   [configs.fonts]
```

#### B. Empty Configuration
```toml
# This will skip:
[configs.fonts]
# No hack_url or jetbrains_url

# This works:
[configs.fonts]
hack_url = "https://..."
jetbrains_url = "https://..."
```

#### C. Prerequisites Missing
```bash
# Fonts need: wget, unzip
# Zsh plugins need: oh-my-zsh installed first
# Dotfiles need: curl
```

**Solution:**
1. Check debug output
2. Verify TOML syntax
3. Ensure prerequisites are installed

---

### 3. Package Name Doesn't Exist

**Problem:**
```
⚠ package-name not found in repositories
```

**Solutions:**

**Option 1: Use correct name for your distro**
```toml
# Debian/Ubuntu
basic_packages = ["openssh-server"]

# Fedora/Arch
basic_packages = ["openssh"]
```

**Option 2: Let the installer try alternatives**
Update to latest version - it tries common alternatives automatically!

**Option 3: Remove from config**
If the package isn't critical, just remove it:
```toml
basic_packages = [
    "curl",
    "git",
    # "problematic-package",  # Commented out
    "vim"
]
```

---

### 4. Flatpak Not Found

**Problem:**
```
Error: Flatpak is not installed. Please install it first.
```

**Solution:**
Flatpak must be in `basic_packages`:
```toml
[system]
basic_packages = [
    "flatpak",  # ← Make sure this is here!
    "git",
    "vim"
]
```

Or install manually:
```bash
# Debian/Ubuntu
sudo apt install flatpak

# Fedora
sudo dnf install flatpak

# Arch
sudo pacman -S flatpak
```

---

### 5. Oh My Zsh Not Installed (Zsh Plugins Fail)

**Problem:**
```
⚠ Oh My Zsh not installed. Install it first via scripts.
  Skipping zsh plugins setup
```

**Solution:**
Add Oh My Zsh to scripts:
```toml
[scripts.apps]
ohmyzsh = 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
```

**Note:** Scripts run BEFORE configs, so Oh My Zsh will be ready for plugins.

---

### 6. Download Fails (All Mirrors)

**Problem:**
```
Trying: https://raw.githubusercontent.com/
  (failed)
Trying: https://gitlab.com/
  (failed)
Trying: https://codeberg.org/
  (failed)
✗ Failed to download from all mirrors
```

**Common causes:**
1. No internet connection
2. Firewall blocking connections
3. Repository doesn't exist
4. Wrong URL format

**Solutions:**
```bash
# Test connectivity
curl -I https://raw.githubusercontent.com

# Check firewall
sudo iptables -L

# Verify URL exists
curl -I https://raw.githubusercontent.com/USER/REPO/main/FILE
```

---

### 7. Permission Denied

**Problem:**
```
✗ Failed to write to /etc/hosts
Permission denied
```

**Solution:**
Set `needs_sudo = true` for system files:
```toml
[[configs.custom_dotfiles]]
url = "https://..."
destination = "/etc/hosts"
needs_sudo = true  # ← Important!
```

---

### 8. Compilation Warnings

**Problem:**
```
warning: `or {}` block required when indexing a map
```

**Impact:** Warnings don't prevent execution - the program still works.

**To fix (for developers):**
Update to latest V version or suppress warnings:
```bash
v -w main.v
```

---

### 9. Custom Dotfiles Not Installing

**Checklist:**
```toml
# ✅ Correct format:
[[configs.custom_dotfiles]]  # ← Double brackets!
url = "https://full/url/to/file"
destination = "~/full/path"
needs_sudo = false

# ❌ Wrong:
[configs.custom_dotfiles]  # Single bracket
url = "..."
```

**Verify:**
1. Double brackets `[[...]]`
2. Full URLs (not relative)
3. Absolute destination paths
4. `needs_sudo` is boolean (not string)

---

### 10. Script Installation Hangs

**Problem:**
Installation stops at a script (e.g., NextDNS).

**Cause:**
Script is waiting for user input.

**Solutions:**

**Option 1: Interact**
Scripts use `os.system()` - you can type responses.

**Option 2: Skip**
Comment out the script:
```toml
[scripts.apps]
# nextdns = 'sh -c "$(curl -sL https://nextdns.io/install)"'
brave = "curl -fsS https://dl.brave.com/install.sh | sh"
```

**Option 3: Add flags**
Some scripts support non-interactive mode:
```toml
nextdns = 'sh -c "$(curl -sL https://nextdns.io/install)" -- -y'
```

---

## Debug Mode

To see what's happening:

1. **Check debug output** (added in latest version):
```
--- Checking fonts configuration ---
Hack URL: https://...
```

2. **Run individual modules:**
```bash
# Test package manager detection only
v run -d pkgdetect main.v

# Verbose output
v -cg run main.v
```

3. **Check logs:**
Most errors are printed to stderr - redirect to file:
```bash
./koinos 2> errors.log
```

---

## Getting Help

If you're still stuck:

1. **Check documentation:**
   - README.md - General usage
   - QUICKSTART.md - Custom dotfiles
   - FEATURES.md - Feature details

2. **Verify config.toml syntax:**
   ```bash
   # Use a TOML validator
   python3 -c "import toml; toml.load('config.toml')"
   ```

3. **Report an issue:**
   Include:
   - Your Linux distribution
   - config.toml content
   - Full error output
   - V version: `v version`

---

## Common Config.toml Mistakes

```toml
# ❌ WRONG - Missing [configs] parent
[fonts]
hack_url = "..."

# ✅ CORRECT
[configs]
[configs.fonts]
hack_url = "..."

# ❌ WRONG - Single brackets for array items
[configs.custom_dotfiles]
url = "..."

# ✅ CORRECT - Double brackets
[[configs.custom_dotfiles]]
url = "..."

# ❌ WRONG - String boolean
needs_sudo = "true"

# ✅ CORRECT - Actual boolean
needs_sudo = true
```

---

## Quick Fixes Cheatsheet

| Problem | Quick Fix |
|---------|-----------|
| Package not found | Remove from config or wait for auto-alternatives |
| Installation stops | Latest version continues automatically |
| Flatpak missing | Add to `basic_packages` |
| Oh My Zsh missing | Add to `[scripts.apps]` |
| Permission denied | Set `needs_sudo = true` |
| Download fails | Check internet, verify URLs |
| Script hangs | Interact or comment out |
| TOML parse error | Check syntax, brackets, quotes |

---

**Remember:** The installer is designed to be resilient - it continues even when things fail!
