module installer

import os

// Package name alternatives across distributions
const package_aliases = {
	'openssh': ['openssh-server', 'openssh', 'openssh-clients']
	'vim': ['vim', 'vim-enhanced']
}

fn try_package_alternatives(pm string, pkg string) (bool, string) {
	// Check if package has alternatives
	if alternatives := package_aliases[pkg] {
		for alt in alternatives {
			mut cmd := ''

			match pm {
				'apt', 'apt-get' {
					cmd = 'sudo ${pm} install -y ${alt}'
				}
				'dnf' {
					cmd = 'sudo dnf install -y ${alt}'
				}
				'yum' {
					cmd = 'sudo yum install -y ${alt}'
				}
				'pacman' {
					cmd = 'sudo pacman -S --noconfirm ${alt}'
				}
				'zypper' {
					cmd = 'sudo zypper install -y ${alt}'
				}
				'emerge' {
					cmd = 'sudo emerge --ask=n ${alt}'
				}
				'apk' {
					cmd = 'sudo apk add ${alt}'
				}
				'xbps-install' {
					cmd = 'sudo xbps-install -y ${alt}'
				}
				'eopkg' {
					cmd = 'sudo eopkg install -y ${alt}'
				}
				else {
					continue
				}
			}

			result := os.execute(cmd)
			if result.exit_code == 0 {
				return true, alt
			}
		}
	}

	return false, ''
}

pub fn install_packages(pm string, packages []string) ! {
	if packages.len == 0 {
		println('No packages to install')
		return
	}

	println('\n=== Installing Packages ===\n')

	mut successful := []string{}
	mut failed := []string{}
	mut skipped := []string{}

	for pkg in packages {
		// Build command for single package
		mut cmd := ''

		match pm {
			'apt', 'apt-get' {
				cmd = 'sudo ${pm} install -y ${pkg}'
			}
			'dnf' {
				cmd = 'sudo dnf install -y ${pkg}'
			}
			'yum' {
				cmd = 'sudo yum install -y ${pkg}'
			}
			'pacman' {
				cmd = 'sudo pacman -S --noconfirm ${pkg}'
			}
			'zypper' {
				cmd = 'sudo zypper install -y ${pkg}'
			}
			'emerge' {
				cmd = 'sudo emerge --ask=n ${pkg}'
			}
			'apk' {
				cmd = 'sudo apk add ${pkg}'
			}
			'xbps-install' {
				cmd = 'sudo xbps-install -y ${pkg}'
			}
			'eopkg' {
				cmd = 'sudo eopkg install -y ${pkg}'
			}
			else {
				return error('Installation command not defined for ${pm}')
			}
		}

		println('[${packages.index(pkg) + 1}/${packages.len}] Installing: ${pkg}')

		result := os.execute(cmd)

		if result.exit_code == 0 {
			println('  ✓ ${pkg} installed successfully')
			successful << pkg
		} else {
			// Check if package not found or other error
			output_lower := result.output.to_lower()

			if output_lower.contains('unable to locate') ||
			   output_lower.contains('no package') ||
			   output_lower.contains('not found') ||
			   output_lower.contains('no such') ||
			   output_lower.contains('target not found') {

				// Try alternatives if available
				println('  ⚠ ${pkg} not found, trying alternatives...')
				success, alt_name := try_package_alternatives(pm, pkg)
				if success {
					println('  ✓ Installed alternative: ${alt_name}')
					successful << alt_name
				} else {
					println('  ⚠ ${pkg} not found in repositories (no alternatives worked)')
					skipped << pkg
				}
			} else {
				println('  ✗ ${pkg} failed to install')
				println('    Exit code: ${result.exit_code}')
				failed << pkg
			}
		}
		println('')
	}

	// Summary
	println('=== Installation Summary ===')
	println('Total packages: ${packages.len}')
	println('Successful: ${successful.len}')
	if successful.len > 0 {
		for pkg in successful {
			println('  ✓ ${pkg}')
		}
	}

	if skipped.len > 0 {
		println('\nSkipped (not found): ${skipped.len}')
		for pkg in skipped {
			println('  ⚠ ${pkg}')
		}
	}

	if failed.len > 0 {
		println('\nFailed: ${failed.len}')
		for pkg in failed {
			println('  ✗ ${pkg}')
		}
		println('\n⚠ Warning: ${failed.len} package(s) failed to install, but continuing...')
		// Don't return error - continue with the rest of the installation
	}

	println('\n✓ Installation process completed')
}
