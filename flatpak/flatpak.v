module flatpak

import os

pub fn setup(repo_url string) ! {
	println('\n=== Setting up Flatpak ===\n')

	// Check if flatpak is installed
	if _ := os.find_abs_path_of_executable('flatpak') {
		println('✓ Flatpak is installed')
	} else {
		return error('Flatpak is not installed. Please install it first.')
	}

	// Add Flathub repository
	println('Adding Flathub repository...')
	cmd := 'sudo flatpak remote-add --if-not-exists flathub ${repo_url}'
	println('Command: ${cmd}\n')

	result := os.execute(cmd)

	if result.exit_code == 0 {
		println('✓ Flathub repository added successfully')
	} else {
		println('⚠ Failed to add Flathub repository')
		println('Exit code: ${result.exit_code}')
		if result.output.len > 0 {
			println('Output: ${result.output}')
		}
		return error('Failed to add Flathub repository')
	}
}

pub fn install_packages(packages []string) ! {
	if packages.len == 0 {
		println('No Flatpak packages to install')
		return
	}

	println('\n=== Installing Flatpak Packages ===\n')

	// Update Flatpak appstream data
	println('Updating Flatpak appstream data...')
	update_cmd := 'flatpak update --appstream -y'
	os.execute(update_cmd)
	println('')

	mut successful := []string{}
	mut failed := []string{}
	mut skipped := []string{}

	for pkg in packages {
		cmd := 'flatpak install flathub ${pkg} --noninteractive -y'

		println('[${packages.index(pkg) + 1}/${packages.len}] Installing: ${pkg}')

		result := os.execute(cmd)

		if result.exit_code == 0 {
			println('  ✓ ${pkg} installed successfully')
			successful << pkg
		} else {
			// Check if package not found or other error
			output_lower := result.output.to_lower()

			if output_lower.contains('not found') ||
			   output_lower.contains('no remote') ||
			   output_lower.contains('no such ref') {
				println('  ⚠ ${pkg} not found in Flathub')
				skipped << pkg
			} else {
				println('  ✗ ${pkg} failed to install')
				println('    Exit code: ${result.exit_code}')
				failed << pkg
			}
		}
		println('')
	}

	// Summary
	println('=== Flatpak Installation Summary ===')
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
		println('\n⚠ Warning: ${failed.len} Flatpak package(s) failed, but continuing...')
		// Don't return error - let installation continue
	}

	println('\n✓ Flatpak installation process completed')
}
