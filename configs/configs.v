module configs

import os

// Mirror URLs priority: GitHub -> GitLab -> Codeberg
const dotfiles_mirrors = [
	'https://raw.githubusercontent.com/Esl1h/dotfiles/main/',
	'https://gitlab.com/Esl1h/dotfiles/-/raw/main/',
	'https://codeberg.org/Esl1h/dotfiles/raw/branch/main/'
]

pub struct FontsConfig {
pub:
	hack_url      string
	jetbrains_url string
}

pub struct ZshConfig {
pub:
	syntax_highlighting_repo string
	autosuggestions_repo     string
	powerlevel10k_repo       string
}

pub struct DotfilesConfig {
pub:
	sysctl_url     string
	ssh_config_url string
	vimrc_url      string
	vim_plug_url   string
	zshrc_url      string
}

pub struct CustomDotfile {
pub:
	url         string
	destination string
	needs_sudo  bool
}

pub fn install_custom_dotfiles(dotfiles []CustomDotfile) ! {
	if dotfiles.len == 0 {
		return
	}

	println('\n=== Installing Custom Dotfiles ===\n')

	home := os.home_dir()
	mut successful := 0
	mut failed := 0

	for i, dotfile in dotfiles {
		println('[${i + 1}/${dotfiles.len}] Installing: ${dotfile.destination}')

		// Expand ~ to home directory
		mut dest_path := dotfile.destination
		if dest_path.starts_with('~/') {
			dest_path = home + dest_path[1..]
		}

		// Create parent directory if needed
		dest_dir := os.dir(dest_path)
		if !os.exists(dest_dir) {
			if dotfile.needs_sudo {
				os.system('sudo mkdir -p ${dest_dir}')
			} else {
				os.mkdir_all(dest_dir) or {
					println('  ✗ Failed to create directory ${dest_dir}')
					failed++
					continue
				}
			}
		}

		// Backup existing file
		if os.exists(dest_path) {
			backup_path := dest_path + '.backup'
			if dotfile.needs_sudo {
				os.system('sudo mv ${dest_path} ${backup_path}')
			} else {
				os.mv(dest_path, backup_path) or {}
			}
			println('  Backed up existing file to ${backup_path}')
		}

		// Download with fallback
		content := download_with_fallback(dotfile.url) or {
			println('  ✗ Failed to download from all mirrors')
			failed++
			continue
		}

		// Write file
		if dotfile.needs_sudo {
			// Use tee for sudo write
			result := os.execute('echo "${content}" | sudo tee ${dest_path} > /dev/null')
			if result.exit_code == 0 {
				println('  ✓ Installed to ${dest_path}')
				successful++
			} else {
				println('  ✗ Failed to write to ${dest_path}')
				failed++
			}
		} else {
			os.write_file(dest_path, content) or {
				println('  ✗ Failed to write to ${dest_path}')
				failed++
				continue
			}
			println('  ✓ Installed to ${dest_path}')
			successful++
		}
	}

	println('\n=== Custom Dotfiles Summary ===')
	println('Successful: ${successful}')
	println('Failed: ${failed}')

	if failed > 0 {
		return error('${failed} custom dotfile(s) failed to install')
	}
}

// Download file with mirror fallback
fn download_with_fallback(url string) !string {
	// Extract the path from the URL
	path := url.all_after('main/')

	// Try each mirror
	for mirror in dotfiles_mirrors {
		full_url := mirror + path
		println('  Trying: ${mirror}')

		result := os.execute('curl -fsSL ${full_url}')
		if result.exit_code == 0 {
			println('  ✓ Downloaded from ${mirror}')
			return result.output
		}
	}

	return error('Failed to download from all mirrors')
}

pub fn install_fonts(fonts FontsConfig) ! {
	println('\n=== Installing Fonts ===\n')

	home := os.home_dir()
	local_fonts_dir := home + '/.local/share/fonts'

	// Create fonts directory
	if !os.exists(local_fonts_dir) {
		os.mkdir_all(local_fonts_dir) or {
			return error('Failed to create ${local_fonts_dir}')
		}
		println('✓ Created ${local_fonts_dir}')
	}

	// Download fonts
	println('Downloading Hack Nerd Font...')
	hack_result := os.execute('wget -c ${fonts.hack_url} -P ${local_fonts_dir}')
	if hack_result.exit_code != 0 {
		println('⚠ Failed to download Hack font')
	} else {
		println('✓ Hack font downloaded')
	}

	println('Downloading JetBrains Mono...')
	jetbrains_result := os.execute('wget -c ${fonts.jetbrains_url} -P ${local_fonts_dir}')
	if jetbrains_result.exit_code != 0 {
		println('⚠ Failed to download JetBrains Mono font')
	} else {
		println('✓ JetBrains Mono font downloaded')
	}

	// Change to fonts directory
	os.chdir(local_fonts_dir) or {
		return error('Failed to change directory to ${local_fonts_dir}')
	}

	// Unzip fonts
	println('Extracting fonts...')
	os.system('unzip -o Hack.zip 2>/dev/null')
	os.system('unzip -o JetBrainsMono-2.242.zip 2>/dev/null')

	// Update font cache
	println('Updating font cache...')
	result := os.execute('fc-cache -f -v')
	if result.exit_code == 0 {
		println('✓ Fonts installed successfully')
	} else {
		return error('Failed to update font cache')
	}
}

pub fn setup_zsh_plugins(zsh ZshConfig) ! {
	println('\n=== Setting up Zsh Plugins ===\n')

	home := os.home_dir()
	ohmyzsh_custom := home + '/.oh-my-zsh/custom'

	// Check if oh-my-zsh is installed
	if !os.exists(home + '/.oh-my-zsh') {
		println('⚠ Oh My Zsh not installed. Install it first via scripts.')
		println('  Skipping zsh plugins setup')
		return
	}

	// Create completions directory
	completions_dir := home + '/.oh-my-zsh/completions'
	os.mkdir_all(completions_dir) or {
		println('⚠ Failed to create completions directory')
	}

	// Install syntax highlighting
	println('[1/3] Installing zsh-syntax-highlighting...')
	plugins_dir := ohmyzsh_custom + '/plugins/zsh-syntax-highlighting'
	if os.exists(plugins_dir) {
		println('  Already exists, skipping')
	} else {
		result := os.system('git clone --depth=1 ${zsh.syntax_highlighting_repo} ${plugins_dir}')
		if result == 0 {
			println('  ✓ zsh-syntax-highlighting installed')
		} else {
			println('  ✗ Failed to install zsh-syntax-highlighting')
		}
	}

	// Install autosuggestions
	println('[2/3] Installing zsh-autosuggestions...')
	autosuggestions_dir := ohmyzsh_custom + '/plugins/zsh-autosuggestions'
	if os.exists(autosuggestions_dir) {
		println('  Already exists, skipping')
	} else {
		result := os.system('git clone --depth=1 ${zsh.autosuggestions_repo} ${autosuggestions_dir}')
		if result == 0 {
			println('  ✓ zsh-autosuggestions installed')
		} else {
			println('  ✗ Failed to install zsh-autosuggestions')
		}
	}

	// Install powerlevel10k theme
	println('[3/3] Installing Powerlevel10k theme...')
	p10k_dir := ohmyzsh_custom + '/themes/powerlevel10k'
	if os.exists(p10k_dir) {
		println('  Already exists, skipping')
	} else {
		result := os.system('git clone --depth=1 ${zsh.powerlevel10k_repo} ${p10k_dir}')
		if result == 0 {
			println('  ✓ Powerlevel10k installed')
		} else {
			println('  ✗ Failed to install Powerlevel10k')
		}
	}

	println('\n✓ Zsh plugins setup completed')
}

pub fn install_dotfiles(dotfiles DotfilesConfig) ! {
	println('\n=== Installing Dotfiles ===\n')

	home := os.home_dir()

	// Install .zshrc
	println('[1/5] Installing .zshrc...')
	zshrc_path := home + '/.zshrc'

	// Backup existing .zshrc
	if os.exists(zshrc_path) {
		backup_path := zshrc_path + '.backup'
		os.mv(zshrc_path, backup_path) or {
			println('  ⚠ Could not backup existing .zshrc')
		}
		println('  Backed up existing .zshrc to .zshrc.backup')
	}

	// Download .zshrc with fallback
	zshrc_content := download_with_fallback(dotfiles.zshrc_url) or {
		println('  ✗ Failed to download .zshrc')
		return error('Failed to download .zshrc')
	}

	// Add oh-my-zsh configuration
	final_content := zshrc_content + '\nexport ZSH="${home}/.oh-my-zsh"\nsource \$ZSH/oh-my-zsh.sh\n'

	os.write_file(zshrc_path, final_content) or {
		return error('Failed to write .zshrc')
	}
	println('  ✓ .zshrc installed')

	// Install vim configuration
	println('[2/5] Installing vim configuration...')
	vim_autoload := home + '/.vim/autoload'
	os.mkdir_all(vim_autoload) or {
		println('  ⚠ Failed to create vim directories')
	}

	os.system('curl -fLo ${vim_autoload}/plug.vim --create-dirs ${dotfiles.vim_plug_url}')
	os.system('curl -fsSL ${dotfiles.vimrc_url} > ${home}/.vimrc')
	println('  ✓ Vim configuration installed')

	// Install sysctl configuration
	println('[3/5] Installing sysctl configuration...')
	sysctl_content := download_with_fallback(dotfiles.sysctl_url) or {
		println('  ✗ Failed to download sysctl.conf')
		''
	}

	if sysctl_content.len > 0 {
		os.execute('echo "${sysctl_content}" | sudo tee -a /etc/sysctl.conf > /dev/null')
		os.system('sudo sysctl -p')
		println('  ✓ sysctl configuration applied')
	}

	// Install SSH configuration
	println('[4/5] Installing SSH configuration...')
	ssh_content := download_with_fallback(dotfiles.ssh_config_url) or {
		println('  ✗ Failed to download ssh_config')
		''
	}

	if ssh_content.len > 0 {
		os.execute('echo "${ssh_content}" | sudo tee /etc/ssh/ssh_config > /dev/null')
		os.system('sudo systemctl enable sshd 2>/dev/null')
		os.system('sudo systemctl start sshd 2>/dev/null')
		println('  ✓ SSH configuration applied')
	}

	// Configure tmpfs for /tmp, /var/tmp, /var/log
	println('[5/5] Configuring tmpfs mounts...')
	fstab_content := '\n# Tmpfs mounts for performance\ntmpfs /tmp tmpfs defaults,noatime,mode=1777 0 0\ntmpfs /var/tmp tmpfs defaults,noatime,mode=1777 0 0\ntmpfs /var/log tmpfs defaults,noatime,mode=0755 0 0\n'

	// Check if already configured
	existing_fstab := os.read_file('/etc/fstab') or { '' }
	if !existing_fstab.contains('tmpfs /tmp tmpfs') {
		os.execute('echo "${fstab_content}" | sudo tee -a /etc/fstab > /dev/null')
		println('  ✓ tmpfs mounts configured in /etc/fstab')
		println('  ⚠ Reboot required for tmpfs mounts to take effect')
	} else {
		println('  Already configured, skipping')
	}

	println('\n✓ Dotfiles installation completed')
}
