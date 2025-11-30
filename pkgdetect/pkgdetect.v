module pkgdetect

import os

pub struct PackageManager {
pub:
	name string
	path string
}

pub struct OSInfo {
pub mut:
	id      string
	id_like string
	name    string
}

pub fn read_os_release() ?OSInfo {
	content := os.read_file('/etc/os-release') or {
		return none
	}

	mut info := OSInfo{}

	for line in content.split_into_lines() {
		trimmed := line.trim_space()

		if trimmed.starts_with('ID=') {
			info.id = trimmed.all_after('ID=').trim('"').to_lower()
		} else if trimmed.starts_with('ID_LIKE=') {
			info.id_like = trimmed.all_after('ID_LIKE=').trim('"').to_lower()
		} else if trimmed.starts_with('NAME=') {
			info.name = trimmed.all_after('NAME=').trim('"')
		}
	}

	return info
}

pub fn get_default_package_manager(os_info OSInfo) ?string {
	// Direct ID mapping
	default_map := {
		// Debian-based
		'debian':      'apt'
		'ubuntu':      'apt'
		'linuxmint':   'apt'
		'pop':         'apt'
		'elementary':  'apt'
		'zorin':       'apt'
		'kali':        'apt'
		'parrot':      'apt'
		'mx':          'apt'

		// Red Hat-based
		'fedora':      'dnf'
		'rhel':        'dnf'
		'centos':      'dnf'
		'rocky':       'dnf'
		'almalinux':   'dnf'
		'alma':        'dnf'

		// Arch-based
		'arch':        'pacman'
		'manjaro':     'pacman'
		'endeavouros': 'pacman'
		'garuda':      'pacman'
		'arcolinux':   'pacman'

		// openSUSE
		'opensuse':            'zypper'
		'opensuse-leap':       'zypper'
		'opensuse-tumbleweed': 'zypper'
		'suse':                'zypper'

		// Others
		'gentoo':      'emerge'
		'alpine':      'apk'
		'void':        'xbps-install'
		'solus':       'eopkg'
		'nixos':       'nix-env'
		'guix':        'guix'
		'slackware':   'slackpkg'
		'clearlinux':  'swupd'
	}

	// Try direct ID match
	if pm := default_map[os_info.id] {
		return pm
	}

	// Fallback to ID_LIKE
	if os_info.id_like != '' {
		id_like_parts := os_info.id_like.split(' ')

		for part in id_like_parts {
			if pm := default_map[part] {
				return pm
			}
		}
	}

	return none
}

pub fn detect_all() []PackageManager {
	mut managers := []PackageManager{}

	package_manager_names := [
		'apt', 'apt-get', 'aptitude', 'nala',
		'dnf', 'yum', 'rpm-ostree',
		'pacman', 'yay', 'paru', 'pikaur', 'trizen',
		'zypper',
		'emerge', 'portage',
		'apk',
		'xbps-install', 'xbps-query',
		'eopkg',
		'nix-env', 'nix',
		'guix',
		'flatpak', 'snap',
		'brew', 'port',
		'pkg', 'slackpkg', 'slapt-get', 'swupd',
	]

	for pm_name in package_manager_names {
		if path := os.find_abs_path_of_executable(pm_name) {
			managers << PackageManager{
				name: pm_name
				path: path
			}
		}
	}

	return managers
}

pub struct DetectionResult {
pub:
	os_info    OSInfo
	default_pm string
	all_pms    []PackageManager
}

pub fn detect() ?DetectionResult {
	os_info := read_os_release()?
	default_pm := get_default_package_manager(os_info)?
	all_pms := detect_all()

	return DetectionResult{
		os_info: os_info
		default_pm: default_pm
		all_pms: all_pms
	}
}

pub fn (r DetectionResult) print() {
	println('=== Package Manager Detection ===\n')

	println('Distribution: ${r.os_info.name}')
	println('ID: ${r.os_info.id}')
	if r.os_info.id_like != '' {
		println('ID_LIKE: ${r.os_info.id_like}')
	}
	println('')

	println('Default Package Manager: ${r.default_pm}')

	if path := os.find_abs_path_of_executable(r.default_pm) {
		println('Path: ${path}')
	} else {
		println('Warning: ${r.default_pm} not found in PATH')
	}

	println('\n--- All Detected Package Managers ---\n')

	if r.all_pms.len == 0 {
		println('No package managers detected')
		return
	}

	println('Found ${r.all_pms.len} package manager(s):\n')

	for pm in r.all_pms {
		marker := if pm.name == r.default_pm { ' [DEFAULT]' } else { '' }
		println('${pm.name}${marker}')
		println('  Path: ${pm.path}')
	}
}
