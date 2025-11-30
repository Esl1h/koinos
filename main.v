module main

import pkgdetect
import installer
import flatpak
import scripts
import configs
import os
import toml

struct Config {
	system  SystemConfig
	flatpak FlatpakConfig
	scripts ScriptsConfig
	configs ConfigsSection
}

struct SystemConfig {
	basic_packages []string
}

struct FlatpakConfig {
	flathub_repo string
	packages     []string
}

struct ScriptsConfig {
	apps map[string]string
}

struct ConfigsSection {
	fonts          configs.FontsConfig
	zsh            configs.ZshConfig
	dotfiles       configs.DotfilesConfig
	custom_dotfiles []configs.CustomDotfile
}

fn load_config() !Config {
	config_path := './config.toml'

	if !os.exists(config_path) {
		return error('config.toml not found')
	}

	content := os.read_file(config_path)!
	doc := toml.parse_text(content)!

	// Parse basic_packages array
	basic_packages_any := doc.value('system.basic_packages').array()
	mut basic_packages := []string{}
	for pkg in basic_packages_any {
		basic_packages << pkg.string()
	}

	// Parse flatpak packages array
	flatpak_packages_any := doc.value('flatpak.packages').array()
	mut flatpak_packages := []string{}
	for pkg in flatpak_packages_any {
		flatpak_packages << pkg.string()
	}

	// Convert toml.Any map to string map for scripts
	toml_apps := doc.value('scripts.apps').as_map()
	mut apps := map[string]string{}
	for key, value in toml_apps {
		apps[key] = value.string()
	}

	// Parse custom dotfiles if they exist
	mut custom_dotfiles := []configs.CustomDotfile{}
	custom_dotfiles_toml := doc.value('configs.custom_dotfiles').array()
	for item in custom_dotfiles_toml {
		item_map := item.as_map()
		custom_dotfiles << configs.CustomDotfile{
			url: item_map['url'] or { continue }.string()
			destination: item_map['destination'] or { continue }.string()
			needs_sudo: item_map['needs_sudo'] or { continue }.bool()
		}
	}

	// Safe parsing with fallback to empty strings
	fonts_config := configs.FontsConfig{
		hack_url: doc.value('configs.fonts.hack_url').default_to('').string()
		jetbrains_url: doc.value('configs.fonts.jetbrains_url').default_to('').string()
	}

	zsh_config := configs.ZshConfig{
		syntax_highlighting_repo: doc.value('configs.zsh.syntax_highlighting_repo').default_to('').string()
		autosuggestions_repo: doc.value('configs.zsh.autosuggestions_repo').default_to('').string()
		powerlevel10k_repo: doc.value('configs.zsh.powerlevel10k_repo').default_to('').string()
	}

	dotfiles_config := configs.DotfilesConfig{
		sysctl_url: doc.value('configs.dotfiles.sysctl_url').default_to('').string()
		ssh_config_url: doc.value('configs.dotfiles.ssh_config_url').default_to('').string()
		vimrc_url: doc.value('configs.dotfiles.vimrc_url').default_to('').string()
		vim_plug_url: doc.value('configs.dotfiles.vim_plug_url').default_to('').string()
		zshrc_url: doc.value('configs.dotfiles.zshrc_url').default_to('').string()
	}

	config := Config{
		system: SystemConfig{
			basic_packages: basic_packages
		}
		flatpak: FlatpakConfig{
			flathub_repo: doc.value('flatpak.flathub_repo').string()
			packages: flatpak_packages
		}
		scripts: ScriptsConfig{
			apps: apps
		}
		configs: ConfigsSection{
			fonts: fonts_config
			zsh: zsh_config
			dotfiles: dotfiles_config
			custom_dotfiles: custom_dotfiles
		}
	}

	return config
}

fn main() {
	// Detect package manager
	result := pkgdetect.detect() or {
		eprintln('Error: ${err}')
		return
	}

	package_manager := result.default_pm

	// Load configuration
	config := load_config() or {
		eprintln('Error loading config: ${err}')
		return
	}

	println('\n=== Configuration Loaded ===')
	println('System packages: ${config.system.basic_packages.len}')
	println('Flatpak apps: ${config.flatpak.packages.len}')
	println('Script apps: ${config.scripts.apps.len}')
	println('Fonts URLs configured: ${config.configs.fonts.hack_url.len > 0 || config.configs.fonts.jetbrains_url.len > 0}')
	println('Zsh repos configured: ${config.configs.zsh.syntax_highlighting_repo.len > 0}')
	println('Dotfiles URLs configured: ${config.configs.dotfiles.vimrc_url.len > 0 || config.configs.dotfiles.zshrc_url.len > 0}')
	println('Custom dotfiles: ${config.configs.custom_dotfiles.len}')
	println('============================\n')

	println('Package Manager: ${package_manager}')
	println('Basic packages to install: ${config.system.basic_packages.len}')
	for pkg in config.system.basic_packages {
		println('  - ${pkg}')
	}
	println('')

	result.print()

	// Install basic packages
	installer.install_packages(package_manager, config.system.basic_packages) or {
		eprintln('\nWarning: ${err}')
		eprintln('Continuing with remaining installations...')
	}

	// Setup Flatpak repository
	flatpak.setup(config.flatpak.flathub_repo) or {
		eprintln('\nError: ${err}')
		return
	}

	// Install Flatpak packages
	flatpak.install_packages(config.flatpak.packages) or {
		eprintln('\nWarning: ${err}')
		eprintln('Continuing with remaining installations...')
		// Don't return - continue!
	}

	// Install script-based applications
	scripts.install_from_scripts(config.scripts.apps) or {
		eprintln('\nWarning: ${err}')
		eprintln('Continuing with remaining installations...')
		// Don't return - continue!
	}

	println('\n========================================')
	println('Scripts completed - starting configs...')
	println('========================================')

	// Install fonts
	println('\n=== [1/4] FONTS MODULE ===')
	println('--- Checking fonts configuration ---')
	println('Hack URL: ${config.configs.fonts.hack_url}')
	println('JetBrains URL: ${config.configs.fonts.jetbrains_url}')

	if config.configs.fonts.hack_url.len > 0 || config.configs.fonts.jetbrains_url.len > 0 {
		println('Fonts configured, calling install_fonts()...')
		configs.install_fonts(config.configs.fonts) or {
			eprintln('\nWarning: Fonts failed - ${err}')
			// Continue even if fonts fail
		}
	} else {
		println('⚠ No fonts configured in config.toml, skipping fonts installation')
	}

	// Setup zsh plugins
	println('\n=== [2/4] ZSH PLUGINS MODULE ===')
	println('--- Checking zsh configuration ---')
	println('Syntax highlighting: ${config.configs.zsh.syntax_highlighting_repo}')
	println('Autosuggestions: ${config.configs.zsh.autosuggestions_repo}')
	println('Powerlevel10k: ${config.configs.zsh.powerlevel10k_repo}')

	if config.configs.zsh.syntax_highlighting_repo.len > 0 ||
	   config.configs.zsh.autosuggestions_repo.len > 0 ||
	   config.configs.zsh.powerlevel10k_repo.len > 0 {
		println('Zsh plugins configured, calling setup_zsh_plugins()...')
		configs.setup_zsh_plugins(config.configs.zsh) or {
			eprintln('\nWarning: Zsh plugins failed - ${err}')
			// Continue even if zsh plugins fail
		}
	} else {
		println('⚠ No zsh plugins configured in config.toml, skipping zsh setup')
	}

	// Install dotfiles
	println('\n=== [3/4] DOTFILES MODULE ===')
	println('--- Checking dotfiles configuration ---')
	println('Sysctl URL: ${config.configs.dotfiles.sysctl_url}')
	println('SSH config URL: ${config.configs.dotfiles.ssh_config_url}')
	println('Vimrc URL: ${config.configs.dotfiles.vimrc_url}')
	println('Vim plug URL: ${config.configs.dotfiles.vim_plug_url}')
	println('Zshrc URL: ${config.configs.dotfiles.zshrc_url}')

	if config.configs.dotfiles.sysctl_url.len > 0 ||
	   config.configs.dotfiles.ssh_config_url.len > 0 ||
	   config.configs.dotfiles.vimrc_url.len > 0 ||
	   config.configs.dotfiles.vim_plug_url.len > 0 ||
	   config.configs.dotfiles.zshrc_url.len > 0 {
		println('Dotfiles configured, calling install_dotfiles()...')
		configs.install_dotfiles(config.configs.dotfiles) or {
			eprintln('\nWarning: Dotfiles failed - ${err}')
			// Continue even if dotfiles fail
		}
	} else {
		println('⚠ No dotfiles configured in config.toml, skipping dotfiles installation')
	}

	// Install custom dotfiles
	println('\n=== [4/4] CUSTOM DOTFILES MODULE ===')
	if config.configs.custom_dotfiles.len > 0 {
		println('--- Installing ${config.configs.custom_dotfiles.len} custom dotfiles ---')
		configs.install_custom_dotfiles(config.configs.custom_dotfiles) or {
			eprintln('\nWarning: Custom dotfiles failed - ${err}')
			// Continue even if custom dotfiles fail
		}
	} else {
		println('⚠ No custom dotfiles configured in config.toml, skipping')
	}

	println('\n🎉 All installations completed!')
}
