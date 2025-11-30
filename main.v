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
			url: item_map['url'].string()
			destination: item_map['destination'].string()
			needs_sudo: item_map['needs_sudo'].bool()
		}
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
			fonts: configs.FontsConfig{
				hack_url: doc.value('configs.fonts.hack_url').string()
				jetbrains_url: doc.value('configs.fonts.jetbrains_url').string()
			}
			zsh: configs.ZshConfig{
				syntax_highlighting_repo: doc.value('configs.zsh.syntax_highlighting_repo').string()
				autosuggestions_repo: doc.value('configs.zsh.autosuggestions_repo').string()
				powerlevel10k_repo: doc.value('configs.zsh.powerlevel10k_repo').string()
			}
			dotfiles: configs.DotfilesConfig{
				sysctl_url: doc.value('configs.dotfiles.sysctl_url').string()
				ssh_config_url: doc.value('configs.dotfiles.ssh_config_url').string()
				vimrc_url: doc.value('configs.dotfiles.vimrc_url').string()
				vim_plug_url: doc.value('configs.dotfiles.vim_plug_url').string()
				zshrc_url: doc.value('configs.dotfiles.zshrc_url').string()
			}
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

	println('Package Manager: ${package_manager}')
	println('Basic packages to install: ${config.system.basic_packages.len}')
	for pkg in config.system.basic_packages {
		println('  - ${pkg}')
	}
	println('')

	result.print()

	// Install basic packages
	installer.install_packages(package_manager, config.system.basic_packages) or {
		eprintln('\nError: ${err}')
		return
	}

	// Setup Flatpak repository
	flatpak.setup(config.flatpak.flathub_repo) or {
		eprintln('\nError: ${err}')
		return
	}

	// Install Flatpak packages
	flatpak.install_packages(config.flatpak.packages) or {
		eprintln('\nError: ${err}')
		return
	}

	// Install script-based applications
	scripts.install_from_scripts(config.scripts.apps) or {
		eprintln('\nError: ${err}')
		return
	}

	// Install fonts
	configs.install_fonts(config.configs.fonts) or {
		eprintln('\nError: ${err}')
		// Continue even if fonts fail
	}

	// Setup zsh plugins
	configs.setup_zsh_plugins(config.configs.zsh) or {
		eprintln('\nError: ${err}')
		// Continue even if zsh plugins fail
	}

	// Install dotfiles
	configs.install_dotfiles(config.configs.dotfiles) or {
		eprintln('\nError: ${err}')
		// Continue even if dotfiles fail
	}

	// Install custom dotfiles
	if config.configs.custom_dotfiles.len > 0 {
		configs.install_custom_dotfiles(config.configs.custom_dotfiles) or {
			eprintln('\nError: ${err}')
			// Continue even if custom dotfiles fail
		}
	}

	println('\n🎉 All installations completed!')
}
